package com.sunriseclock.sun_clock

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import android.text.format.DateFormat
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar
import java.util.Date
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.floor

/**
 * Home-screen widget: the sun time and/or the local time, with a line of
 * information (day or night, the next sunrise or sunset, the length of a
 * sun hour, how far sun time is ahead of local time, the place) and a bar
 * for the day or night. Each widget has its own choice of these and of
 * colours ([WidgetConfig], edited in the app). It uses the position the app
 * stores in [SunClockStore], so it works without the status-bar clock.
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
            val place = SunClockStore.load(c)?.label ?: ""
            val lc = SunClockStore.localized(c)
            val manager = AppWidgetManager.getInstance(c)
            for (id in ids) {
                manager.updateAppWidget(id, render(c, lc, WidgetStore.load(c, id), now, reading, place))
            }
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

        private val CORNERS = mapOf(
            0 to R.drawable.widget_bg_0,
            8 to R.drawable.widget_bg_8,
            16 to R.drawable.widget_bg_16,
            28 to R.drawable.widget_bg_28,
        )

        private fun shown(on: Boolean) = if (on) View.VISIBLE else View.GONE

        /**
         * One widget. [lc] is the context in the app's language (for the
         * texts), [c] the plain one (for the package and the launch intent).
         */
        private fun render(
            c: Context, lc: Context, cfg: WidgetConfig, now: Long, r: SunReading?, place: String,
        ): RemoteViews {
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

            // A white rounded shape, tinted to the colour and faded to its alpha.
            v.setImageViewResource(R.id.widget_bg, CORNERS[cfg.corners] ?: R.drawable.widget_bg_16)
            v.setInt(R.id.widget_bg, "setColorFilter", cfg.background or 0xFF000000.toInt())
            v.setInt(R.id.widget_bg, "setImageAlpha", cfg.background ushr 24)

            val timeColor = when {
                !cfg.autoColors -> cfg.timeColor
                r?.isDay == true -> DAY_COLOR
                else -> NIGHT_COLOR
            }
            val sunText = r?.let { hhmm(it.sunMinutes) } ?: "--:--"
            val sunName = lc.getString(R.string.widget_name_sun)
            val localName = lc.getString(R.string.widget_name_local)

            fun clock(sunId: Int, localId: Int, labelId: Int, isSun: Boolean) {
                v.setViewVisibility(sunId, shown(isSun))
                v.setViewVisibility(localId, shown(!isSun))
                // Large clocks leave out AM/PM: auto-size does not shrink a
                // TextClock's text, so "8:05 PM" would be cut off.
                v.setCharSequence(localId, "setFormat12Hour", "h:mm")
                v.setCharSequence(localId, "setFormat24Hour", "HH:mm")
                v.setTextViewText(sunId, sunText)
                v.setTextColor(sunId, timeColor)
                v.setTextColor(localId, timeColor)
                v.setViewVisibility(labelId, shown(cfg.labels))
                v.setTextViewText(labelId, if (isSun) sunName else localName)
                v.setTextColor(labelId, cfg.textColor)
            }
            clock(R.id.widget_sun_1, R.id.widget_local_1, R.id.widget_label_1, cfg.primaryIsSun)
            v.setViewVisibility(R.id.widget_col_2, shown(cfg.side))
            if (cfg.side) {
                clock(R.id.widget_sun_2, R.id.widget_local_2, R.id.widget_label_2, !cfg.primaryIsSun)
            }

            val small = cfg.both && !cfg.side
            v.setViewVisibility(R.id.widget_small_row, shown(small))
            if (small) {
                val sun = !cfg.primaryIsSun
                v.setViewVisibility(R.id.widget_small_sun, shown(sun))
                v.setViewVisibility(R.id.widget_small_local, shown(!sun))
                v.setTextViewText(R.id.widget_small_sun, sunText)
                v.setViewVisibility(R.id.widget_small_label, shown(cfg.labels))
                v.setTextViewText(R.id.widget_small_label, if (sun) sunName else localName)
                for (id in intArrayOf(
                    R.id.widget_small_label, R.id.widget_small_sun, R.id.widget_small_local,
                )) {
                    v.setTextColor(id, cfg.textColor)
                }
            }

            val detail = detail(lc, cfg, now, r, place)
            v.setTextViewText(R.id.widget_detail, detail)
            v.setViewVisibility(R.id.widget_detail, shown(detail.isNotEmpty()))
            v.setTextColor(R.id.widget_detail, cfg.textColor)

            val bar = cfg.progress && r != null
            v.setViewVisibility(R.id.widget_progress, shown(bar))
            if (bar && r != null) {
                v.setProgressBar(
                    R.id.widget_progress, 1000, (progress(r.sunMinutes) * 1000).toInt(), false,
                )
                if (Build.VERSION.SDK_INT >= 31) {
                    v.setColorStateList(
                        R.id.widget_progress, "setProgressTintList",
                        ColorStateList.valueOf(timeColor),
                    )
                    v.setColorStateList(
                        R.id.widget_progress, "setProgressBackgroundTintList",
                        ColorStateList.valueOf(cfg.textColor),
                    )
                }
            }
            return v
        }

        private fun hhmm(sunMinutes: Double): String {
            val total = floor(sunMinutes).toInt()
            return (total / 60).toString().padStart(2, '0') + ":" +
                (total % 60).toString().padStart(2, '0')
        }

        /** How much of the current day (06:00–18:00 sun time) or night has passed. */
        internal fun progress(sunMinutes: Double): Double =
            if (sunMinutes >= 360 && sunMinutes < 1080) {
                (sunMinutes - 360) / 720
            } else {
                ((sunMinutes - 1080) % 1440 + 1440) % 1440 / 720
            }

        /** Sun time minus local time in minutes, wrapped into [-720, 720). */
        internal fun offsetMinutes(sunMinutes: Double, localMinutes: Double): Double =
            ((sunMinutes - localMinutes + 720) % 1440 + 1440) % 1440 - 720

        /** The information line, as lib/widget_editor.dart previews it. */
        private fun detail(
            lc: Context, cfg: WidgetConfig, now: Long, r: SunReading?, place: String,
        ): String {
            if (r == null) {
                return if (cfg.showsSun) lc.getString(R.string.widget_no_position) else ""
            }
            val parts = mutableListOf<String>()
            if (cfg.dayNight) {
                parts += lc.getString(if (r.isDay) R.string.widget_day else R.string.widget_night)
            }
            if (cfg.next) {
                val next = r.next
                parts += if (next != null) {
                    val at = DateFormat.getTimeFormat(lc).format(Date(next.first))
                    lc.getString(
                        if (next.second) R.string.widget_sunrise_at else R.string.widget_sunset_at, at,
                    )
                } else {
                    lc.getString(R.string.widget_solar_time) // polar day or night
                }
            }
            if (cfg.hourLength) {
                r.realMinutesPerHour?.let {
                    parts += lc.getString(R.string.notif_hour_length, Math.round(it).toInt())
                }
            }
            if (cfg.offset) {
                val cal = Calendar.getInstance().apply { timeInMillis = now }
                val local = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE) +
                    cal.get(Calendar.SECOND) / 60.0
                val m = Math.round(offsetMinutes(r.sunMinutes, local)).toInt()
                val a = abs(m)
                val d = if (a < 60) {
                    lc.getString(R.string.duration_min, a)
                } else {
                    lc.getString(R.string.duration_h_min, a / 60, a % 60)
                }
                parts += when {
                    m > 0 -> lc.getString(R.string.widget_offset_ahead, d)
                    m < 0 -> lc.getString(R.string.widget_offset_behind, d)
                    else -> lc.getString(R.string.widget_offset_same)
                }
            }
            if (cfg.place && place.isNotEmpty()) parts += place
            return parts.joinToString(" · ")
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

    override fun onDeleted(c: Context, appWidgetIds: IntArray) =
        WidgetStore.delete(c, appWidgetIds)

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
