package com.sunriseclock.sun_clock

import android.Manifest
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import kotlin.math.abs

/**
 * Follows the phone's location while the app is closed, independent of the
 * status-bar clock, so the home-screen widget (and the status-bar clock after
 * a restart) use where the phone is now. Android delivers low-power updates
 * to [LocationReceiver] even when no part of the app is running.
 *
 * Only when the user opted in to background location ("Follow my location
 * in the background" in Settings, after the in-app disclosure), Android
 * still grants "Allow all the time", the app uses GPS rather than a place
 * picked on the map, and there is a widget or the status-bar clock to keep
 * up to date.
 */
object LocationFollower {
    private const val ACTION = "com.sunriseclock.sun_clock.LOCATION"

    private fun granted(c: Context, p: String) =
        c.checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED

    /** Opted in, and "Allow all the time" is (still) granted. */
    fun backgroundAllowed(c: Context): Boolean {
        if (!SunClockStore.backgroundLocation(c)) return false
        if (!granted(c, Manifest.permission.ACCESS_COARSE_LOCATION)) return false
        // Before Android 10 any location permission includes the background.
        return Build.VERSION.SDK_INT < 29 ||
            granted(c, Manifest.permission.ACCESS_BACKGROUND_LOCATION)
    }

    private fun hasWidgets(c: Context) =
        AppWidgetManager.getInstance(c)
            .getAppWidgetIds(ComponentName(c, SunWidget::class.java)).isNotEmpty()

    private fun wanted(c: Context): Boolean {
        val p = SunClockStore.load(c) ?: return false
        return p.followLocation && backgroundAllowed(c) &&
            (hasWidgets(c) || SunClockStore.isEnabled(c))
    }

    private fun pendingIntent(c: Context): PendingIntent =
        PendingIntent.getBroadcast(
            c, 0,
            Intent(c, LocationReceiver::class.java).setAction(ACTION),
            // Mutable: Android adds the location to the intent.
            PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0),
        )

    /** Starts or stops following to match the settings; safe to call often. */
    fun sync(c: Context) {
        val lm = c.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val pi = pendingIntent(c)
        try {
            lm.removeUpdates(pi)
        } catch (_: Exception) {
        }
        if (!wanted(c)) return
        val precise = SunClockStore.load(c)?.precise == true &&
            granted(c, Manifest.permission.ACCESS_FINE_LOCATION)
        for ((provider, minTime, minDistance) in requests(lm, precise)) {
            try {
                if (!lm.allProviders.contains(provider)) continue
                lm.requestLocationUpdates(provider, minTime, minDistance, pi)
            } catch (_: SecurityException) {
            } catch (_: IllegalArgumentException) {
            }
        }
    }

    /**
     * Low-power updates, as in the status-bar service: approximate uses the
     * network provider every 15 min or 1 km; precise the fused/GPS provider
     * every 5 min or 250 m. The passive provider adds fixes other apps
     * request anyway.
     */
    fun requests(lm: LocationManager, precise: Boolean): List<Triple<String, Long, Float>> {
        val list = mutableListOf<Triple<String, Long, Float>>()
        if (precise) {
            val provider = if (Build.VERSION.SDK_INT >= 31 &&
                lm.allProviders.contains(LocationManager.FUSED_PROVIDER)
            ) LocationManager.FUSED_PROVIDER else LocationManager.GPS_PROVIDER
            list.add(Triple(provider, 5 * 60_000L, 250f))
        } else {
            list.add(Triple(LocationManager.NETWORK_PROVIDER, 15 * 60_000L, 1000f))
        }
        list.add(Triple(LocationManager.PASSIVE_PROVIDER, 60_000L, if (precise) 100f else 1000f))
        return list
    }

    /**
     * The stored position moved to [location], or null when it hasn't moved
     * enough (or the fix is stale, or the app uses a place from the map).
     */
    fun moved(p: ClockParams, location: Location, now: Long = System.currentTimeMillis()): ClockParams? {
        if (location.time < now - 6 * 3_600_000L) return null // stale fix
        return moved(p, location.latitude, location.longitude)
    }

    /** As above, for a position in degrees; testable without Android. */
    fun moved(p: ClockParams, latitude: Double, longitude: Double): ClockParams? {
        if (!p.followLocation) return null // a place picked on the map stays
        var lat = latitude
        var lon = longitude
        if (!p.precise) { // same rounding as the app: about 1 km
            lat = Math.round(lat * 100) / 100.0
            lon = Math.round(lon * 100) / 100.0
        }
        val threshold = if (p.precise) 0.002 else 0.01 // degrees, ~200 m / ~1 km
        if (abs(lat - p.lat) < threshold && abs(lon - p.lon) < threshold) return null

        // The place name came from the app's time-zone lookup; drop it once
        // the phone is more than ~25 km away and show coordinates instead.
        val far = abs(lat - p.lat) > 0.25 || abs(lon - p.lon) > 0.25
        val label = if (far || p.label.isEmpty()) coordLabel(lat, lon, p.precise) else p.label
        return p.copy(lat = lat, lon = lon, label = label)
    }

    fun coordLabel(lat: Double, lon: Double, precise: Boolean): String {
        val f = if (precise) "%.3f" else "%.2f"
        val ns = if (lat >= 0) "N" else "S"
        val ew = if (lon >= 0) "E" else "W"
        return "${String.format(java.util.Locale.ROOT, f, abs(lat))}° $ns " +
            "${String.format(java.util.Locale.ROOT, f, abs(lon))}° $ew"
    }
}

/** Receives [LocationFollower]'s updates, stores the position, redraws widgets. */
class LocationReceiver : BroadcastReceiver() {
    override fun onReceive(c: Context, intent: Intent) {
        @Suppress("DEPRECATION")
        val location = intent.getParcelableExtra<Location>(LocationManager.KEY_LOCATION_CHANGED)
            ?: return
        val p = SunClockStore.load(c) ?: return
        val next = LocationFollower.moved(p, location) ?: return
        SunClockStore.save(c, next)
        SunWidget.updateAll(c)
    }
}
