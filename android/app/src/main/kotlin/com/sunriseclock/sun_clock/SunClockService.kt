package com.sunriseclock.sun_clock

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.floor

/**
 * Foreground service that keeps a notification showing the current sun time.
 * The small (status-bar) icon is drawn on the fly with the hours above the
 * minutes, so the sun time is visible in the status bar itself.
 *
 * It wakes once per sun-minute (the handler pauses while the device sleeps)
 * and, when the app uses GPS, follows the device location with low-power
 * updates so the sun times stay right after travelling with the app closed.
 * Location access relies on the app's while-in-use permission: the service
 * runs with the "location" foreground type when started from the app. After
 * a reboot it can only use the last stored position until the app is opened.
 */
class SunClockService : Service() {

    companion object {
        private const val CHANNEL_ID = "sun_time"
        private const val NOTIFICATION_ID = 1
        private const val DAY_MS = 86_400_000L

        /** Read by the home-screen widget: while true, this service updates it. */
        @Volatile
        var running = false
            private set

        fun start(c: Context) {
            val i = Intent(c, SunClockService::class.java)
            if (Build.VERSION.SDK_INT >= 26) c.startForegroundService(i) else c.startService(i)
        }

        fun stop(c: Context) {
            c.stopService(Intent(c, SunClockService::class.java))
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var params: ClockParams? = null
    private var data: SunData? = null
    private var listening = false

    private val tick = object : Runnable {
        override fun run() {
            val delay = update()
            handler.postDelayed(this, delay)
        }
    }

    /** Refresh right away when the screen comes on or the clock changes. */
    private val refresh = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            handler.removeCallbacks(tick)
            handler.post(tick)
        }
    }

    private val locationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) = onMoved(location)

        // Needed before API 30, where these are not default methods.
        @Deprecated("Deprecated in Java")
        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        override fun onProviderEnabled(provider: String) {}
        override fun onProviderDisabled(provider: String) {}
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running = true
        createChannel()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_TIME_CHANGED)
            addAction(Intent.ACTION_TIMEZONE_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(refresh, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(refresh, filter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val p = SunClockStore.load(this)
        params = p
        data = p?.let { SolarCalc.build(it.lat, it.lon, System.currentTimeMillis(), it.label) }

        val wantLocation = p != null && p.followLocation && hasLocationPermission()
        val withLocation = goForeground(build(System.currentTimeMillis()), wantLocation)

        if (p == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        stopLocation()
        if (withLocation) startLocation(p.precise)
        handler.removeCallbacks(tick)
        handler.post(tick)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        stopLocation()
        unregisterReceiver(refresh)
        running = false
        SunWidget.updateAll(this) // hand the widget back its own alarms
        super.onDestroy()
    }

    /**
     * Enters the foreground. With [wantLocation] it asks for the location type
     * too, which Android only allows while the app is in use (not after a
     * reboot); then it falls back to the plain type. Returns whether location
     * access is available.
     */
    private fun goForeground(n: Notification, wantLocation: Boolean): Boolean {
        if (Build.VERSION.SDK_INT >= 34) {
            val special = ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            if (wantLocation) {
                try {
                    startForeground(
                        NOTIFICATION_ID, n,
                        special or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
                    )
                    return true
                } catch (_: Exception) {
                    // Started from the background: no while-in-use location.
                }
            }
            startForeground(NOTIFICATION_ID, n, special)
            return false
        }
        if (Build.VERSION.SDK_INT >= 29 && wantLocation) {
            startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            return true
        }
        startForeground(NOTIFICATION_ID, n)
        return wantLocation
    }

    private fun granted(p: String) = checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED

    private fun hasLocationPermission() =
        granted(Manifest.permission.ACCESS_COARSE_LOCATION) ||
            granted(Manifest.permission.ACCESS_FINE_LOCATION)

    /**
     * Low-power updates: approximate uses the network provider every 15 min
     * or 1 km; precise uses the fused/GPS provider every 5 min or 250 m. The
     * passive provider adds fixes other apps (e.g. navigation) request anyway.
     */
    private fun startLocation(precise: Boolean) {
        val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val fine = granted(Manifest.permission.ACCESS_FINE_LOCATION)
        val requests = mutableListOf<Triple<String, Long, Float>>()
        if (precise && fine) {
            val provider = if (Build.VERSION.SDK_INT >= 31 &&
                lm.allProviders.contains(LocationManager.FUSED_PROVIDER)
            ) LocationManager.FUSED_PROVIDER else LocationManager.GPS_PROVIDER
            requests.add(Triple(provider, 5 * 60_000L, 250f))
        } else {
            requests.add(Triple(LocationManager.NETWORK_PROVIDER, 15 * 60_000L, 1000f))
        }
        requests.add(Triple(LocationManager.PASSIVE_PROVIDER, 60_000L, if (precise) 100f else 1000f))

        for ((provider, minTime, minDistance) in requests) {
            try {
                if (!lm.allProviders.contains(provider)) continue
                lm.requestLocationUpdates(provider, minTime, minDistance, locationListener, Looper.getMainLooper())
                listening = true
                lm.getLastKnownLocation(provider)?.let { onMoved(it) }
            } catch (_: SecurityException) {
            } catch (_: IllegalArgumentException) {
            }
        }
    }

    private fun stopLocation() {
        if (!listening) return
        val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        try {
            lm.removeUpdates(locationListener)
        } catch (_: Exception) {
        }
        listening = false
    }

    private fun onMoved(location: Location) {
        val p = params ?: return
        if (!p.followLocation) return
        if (location.time < System.currentTimeMillis() - 6 * 3_600_000L) return // stale fix
        var lat = location.latitude
        var lon = location.longitude
        if (!p.precise) { // same rounding as the app: about 1 km
            lat = Math.round(lat * 100) / 100.0
            lon = Math.round(lon * 100) / 100.0
        }
        val threshold = if (p.precise) 0.002 else 0.01 // degrees, ~200 m / ~1 km
        if (abs(lat - p.lat) < threshold && abs(lon - p.lon) < threshold) return

        // The place name came from the app's time-zone lookup; drop it once
        // the phone is more than ~25 km away and show coordinates instead.
        val far = abs(lat - p.lat) > 0.25 || abs(lon - p.lon) > 0.25
        val label = if (far || p.label.isEmpty()) coordLabel(lat, lon, p.precise) else p.label
        val moved = p.copy(lat = lat, lon = lon, label = label)
        params = moved
        SunClockStore.save(this, moved)
        data = SolarCalc.build(lat, lon, System.currentTimeMillis(), label)
        handler.removeCallbacks(tick)
        handler.post(tick)
    }

    private fun coordLabel(lat: Double, lon: Double, precise: Boolean): String {
        val f = if (precise) "%.3f" else "%.2f"
        val ns = if (lat >= 0) "N" else "S"
        val ew = if (lon >= 0) "E" else "W"
        return "${String.format(f, abs(lat))}° $ns ${String.format(f, abs(lon))}° $ew"
    }

    /** Posts the notification; returns the delay until the next sun-minute. */
    private fun update(): Long {
        val now = System.currentTimeMillis()
        val p = params
        // Keep the computed days ahead of the clock (data covers two weeks).
        if (p != null && (data == null || now - data!!.computedAt > DAY_MS)) {
            data = SolarCalc.build(p.lat, p.lon, now, p.label)
        }
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, build(now))
        SunWidget.updateAll(this, schedule = false)
        val r = data?.let { SunTime.read(now, it) } ?: return 60_000L
        val toNextMinute = (1.0 - (r.sunMinutes - floor(r.sunMinutes))) * r.msPerSunMinute
        return ceil(toNextMinute).toLong().coerceIn(1_000L, 120_000L) + 50L
    }

    private fun build(now: Long): Notification {
        val d = data
        val r = d?.let { SunTime.read(now, it) }

        val builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_LOW)
        }

        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pending = PendingIntent.getActivity(
            this, 0, launch,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        builder.setContentIntent(pending)
            .setOngoing(true)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)

        if (r == null) {
            return builder.setSmallIcon(R.drawable.ic_stat_sun)
                .setContentTitle("Sun time")
                .setContentText("Open Sun Clock to set a location.")
                .build()
        }

        val total = floor(r.sunMinutes).toInt()
        val hh = (total / 60).toString().padStart(2, '0')
        val mm = (total % 60).toString().padStart(2, '0')

        val detail = buildString {
            append(if (r.isDay) "Day" else "Night")
            val next = r.next
            if (next != null) {
                append(" · ")
                append(if (next.second) "sunrise in " else "sunset in ")
                append(duration(next.first - now))
            } else {
                append(" · solar time (no sunrise/sunset)")
            }
            r.realMinutesPerHour?.let { append(" · 1 h = ${Math.round(it)} min") }
        }

        builder.setContentTitle("$hh:$mm sun time")
            .setContentText(detail)
        if (d.label.isNotEmpty()) builder.setSubText(d.label)
        builder.setSmallIcon(Icon.createWithBitmap(timeIcon(hh, mm)))
        return builder.build()
    }

    private fun duration(ms: Long): String {
        val min = (ms / 60000L).coerceAtLeast(0)
        return if (min >= 60) "${min / 60} h ${min % 60} min" else "$min min"
    }

    /**
     * Status-bar icon: hours above minutes, as large as the square icon slot
     * allows (Android keeps only the alpha channel). The digits keep their
     * normal proportions and are sized so the two lines fill the full height.
     */
    private fun timeIcon(hh: String, mm: String): Bitmap {
        val size = 96
        val gap = 4f
        val lineHeight = (size - gap) / 2f - 1f // 1 px margin: round digits overshoot
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            textSize = 100f
        }
        // Digit height (all digits share the cap height) → fill half the icon.
        val bounds = android.graphics.Rect()
        paint.getTextBounds("00", 0, 2, bounds)
        paint.textSize *= lineHeight / bounds.height()
        // Two digits are narrower than the icon at this height, so no
        // squeezing is needed; guard anyway for unusually wide fonts.
        val widest = maxOf(paint.measureText(hh), paint.measureText(mm))
        if (widest > size) paint.textSize *= size / widest
        // Baselines: digits have no descenders, so bottom = baseline.
        canvas.drawText(hh, size / 2f, 1f + lineHeight, paint)
        canvas.drawText(mm, size / 2f, size - 1f, paint)
        return bmp
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID, "Sun time in status bar", NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows the current sun time in the status bar."
            setShowBadge(false)
            setSound(null, null)
            enableVibration(false)
        }
        nm.createNotificationChannel(channel)
    }
}
