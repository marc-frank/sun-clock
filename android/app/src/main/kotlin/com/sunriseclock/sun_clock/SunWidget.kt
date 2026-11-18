package com.sunriseclock.sun_clock

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.os.SystemClock
import android.text.format.DateFormat
import android.widget.RemoteViews
import java.util.Date
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.floor

/**
 * Home-screen widget: the current sun time, day or night, and the next
 * sunrise or sunset in local time. It uses the position the app stores in
 * [SunClockStore], so it works without the status-bar clock.
 *
 * Updates: while the status-bar service runs, it pushes every sun-minute
 * (see [SunClockService.update]). Otherwise the widget sets a non-wakeup
 * alarm for the next sun-minute, so it costs nothing while the phone sleeps
 * and catches up as soon as it wakes. Without SCHEDULE_EXACT_ALARM the alarm
 * is inexact: Android may deliver it up to 3/4 of its lead time late, except
 * for alarms less than 10 s ahead, which it delivers on time. So the widget
 * hops: an alarm that lands at least 6 s before the sun-minute changes, then
 * one at the change itself. With the screen on that keeps the minute right to
 * about a second for 2–4 alarms per sun-minute; with the screen off it sets a
 * single alarm, which may show the old minute briefly after the screen
 * comes back on.
 */
class SunWidget : AppWidgetProvider() {

    companion object {
        private const val ACTION_TICK = "com.sunriseclock.sun_clock.WIDGET_TICK"
        private const val DAY_COLOR = 0xFFFFB300.toInt()
        private const val NIGHT_COLOR = 0xFF9FA8DA.toInt()
        /** Below this lead time Android delivers inexact alarms on time. */
        private const val UNFUZZED_MS = 9_500L
        /** Hops land at least this long before the next sun-minute. */
        private const val LAND_BEFORE_MS = 6_000L

        private var cache: SunData? = null
        private var cacheKey: ClockParams? = null

        private fun ids(c: Context): IntArray =
            AppWidgetManager.getInstance(c)
                .getAppWidgetIds(ComponentName(c, SunWidget::class.java))

        /**
         * Redraws all widgets. [schedule] sets the next alarm; the running
         * status-bar service passes false because it ticks anyway.
         */
        fun updateAll(c: Context, schedule: Boolean = !SunClockService.running) {
            val ids = ids(c)
            if (ids.isEmpty()) {
                cancel(c)
                return
            }
            val now = System.currentTimeMillis()
            val reading = data(c, now)?.let { SunTime.read(now, it) }
            val views = render(c, now, reading)
            AppWidgetManager.getInstance(c).updateAppWidget(ids, views)
            if (schedule && reading != null) scheduleNext(c, now, reading) else cancel(c)
        }

        /** Sun events for the stored position, rebuilt every few hours. */
        private fun data(c: Context, now: Long): SunData? {
            val p = SunClockStore.load(c) ?: return null
            val d = cache
            if (d != null && cacheKey == p && abs(now - d.computedAt) < 6 * 3_600_000L) return d
            return SolarCalc.build(p.lat, p.lon, now, p.label).also {
                cache = it
                cacheKey = p
            }
        }

        private fun render(c: Context, now: Long, r: SunReading?): RemoteViews {
            val v = RemoteViews(c.packageName, R.layout.sun_widget)
            val launch = c.packageManager.getLaunchIntentForPackage(c.packageName)
            if (launch != null) {
                v.setOnClickPendingIntent(
                    R.id.widget_root,
                    PendingIntent.getActivity(
                        c, 0, launch,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    ),
                )
            }
            if (r == null) {
                v.setTextViewText(R.id.widget_time, "--:--")
                v.setTextColor(R.id.widget_time, NIGHT_COLOR)
                v.setTextViewText(R.id.widget_detail, c.getString(R.string.widget_no_position))
                return v
            }
            val total = floor(r.sunMinutes).toInt()
            val hh = (total / 60).toString().padStart(2, '0')
            val mm = (total % 60).toString().padStart(2, '0')
            v.setTextViewText(R.id.widget_time, "$hh:$mm")
            v.setTextColor(R.id.widget_time, if (r.isDay) DAY_COLOR else NIGHT_COLOR)

            val dayNight = c.getString(if (r.isDay) R.string.widget_day else R.string.widget_night)
            val next = r.next
            val nextText = if (next != null) {
                val at = DateFormat.getTimeFormat(c).format(Date(next.first))
                c.getString(
                    if (next.second) R.string.widget_sunrise_at else R.string.widget_sunset_at, at,
                )
            } else {
                c.getString(R.string.widget_solar_time) // polar day or night
            }
            v.setTextViewText(R.id.widget_detail, "$dayNight · $nextText")
            return v
        }

        private fun tickIntent(c: Context): PendingIntent =
            PendingIntent.getBroadcast(
                c, 0,
                Intent(c, SunWidget::class.java).setAction(ACTION_TICK),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )

        private fun scheduleNext(c: Context, now: Long, r: SunReading) {
            // Real time until the shown minute changes; +50 ms so the next
            // reading is safely past the boundary.
            val toNext = ceil((1.0 - (r.sunMinutes - floor(r.sunMinutes))) * r.msPerSunMinute)
                .toLong() + 50L
            val interactive = (c.getSystemService(Context.POWER_SERVICE) as PowerManager).isInteractive
            val delay = if (toNext <= UNFUZZED_MS || !interactive) {
                toNext
            } else {
                // Latest delivery is lead * 1.75; land before the change.
                ((toNext - LAND_BEFORE_MS) / 1.75).toLong().coerceAtLeast(1_000L)
            }
            val am = c.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            // ELAPSED_REALTIME (not RTC) so clock changes don't move it; not
            // a wakeup alarm, so a sleeping phone is never woken for it.
            am.set(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + delay, tickIntent(c))
        }

        private fun cancel(c: Context) {
            val am = c.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(tickIntent(c))
        }
    }

    override fun onUpdate(c: Context, manager: AppWidgetManager, appWidgetIds: IntArray) =
        updateAll(c)

    override fun onDisabled(c: Context) = cancel(c)

    override fun onReceive(c: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TICK,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED -> updateAll(c)
            else -> super.onReceive(c, intent)
        }
    }
}
