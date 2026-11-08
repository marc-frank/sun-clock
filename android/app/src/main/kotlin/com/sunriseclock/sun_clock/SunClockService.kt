package com.sunriseclock.sun_clock

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import kotlin.math.ceil
import kotlin.math.floor

/**
 * Foreground service that keeps a notification showing the current sun time.
 * The small (status-bar) icon is drawn on the fly with the hours above the
 * minutes, so the sun time is visible in the status bar itself.
 * It wakes once per sun-minute; the handler pauses while the device sleeps.
 */
class SunClockService : Service() {

    companion object {
        private const val CHANNEL_ID = "sun_time"
        private const val NOTIFICATION_ID = 1

        fun start(c: Context) {
            val i = Intent(c, SunClockService::class.java)
            if (Build.VERSION.SDK_INT >= 26) c.startForegroundService(i) else c.startService(i)
        }

        fun stop(c: Context) {
            c.stopService(Intent(c, SunClockService::class.java))
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var data: SunData? = null

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

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
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
        data = SunClockStore.load(this)
        val notification = build(System.currentTimeMillis())
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        if (data == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        handler.removeCallbacks(tick)
        handler.post(tick)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        unregisterReceiver(refresh)
        super.onDestroy()
    }

    /** Posts the notification; returns the delay until the next sun-minute. */
    private fun update(): Long {
        val now = System.currentTimeMillis()
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, build(now))
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
            }
            r.realMinutesPerHour?.let { append(" · 1 h = ${Math.round(it)} min") }
            if (r.stale) append(" · open Sun Clock to refresh")
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

    /** Status-bar icon: hours over minutes. Android keeps only the alpha channel. */
    private fun timeIcon(hh: String, mm: String): Bitmap {
        val size = 96
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            textSize = 50f
            letterSpacing = -0.05f
        }
        // Two lines, each about half the icon tall.
        canvas.drawText(hh, size / 2f, 44f, paint)
        canvas.drawText(mm, size / 2f, 92f, paint)
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
