package com.sunriseclock.sun_clock

import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.roundToLong
import kotlin.math.sin
import kotlin.math.tan

/**
 * NOAA sunrise/sunset, a line-by-line port of lib/solar.dart so the
 * status-bar service can recompute sun times after the phone has moved
 * without the Flutter app running. Keep the two in sync.
 */
object SolarCalc {
    private const val DAY_MS = 86_400_000L

    private fun rad(d: Double) = Math.toRadians(d)
    private fun deg(r: Double) = Math.toDegrees(r)

    fun julianDay(utcMillis: Long) = utcMillis / 86_400_000.0 + 2_440_587.5
    private fun fromJulianDay(jd: Double) = ((jd - 2_440_587.5) * 86_400_000.0).roundToLong()

    /** (declination deg, equation of time minutes), spreadsheet columns T and V. */
    fun solarParams(jd: Double): Pair<Double, Double> {
        val t = (jd - 2451545) / 36525
        val l0 = ((280.46646 + t * (36000.76983 + t * 0.0003032)) % 360 + 360) % 360
        val m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        val e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        val c = sin(rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
            sin(rad(2 * m)) * (0.019993 - 0.000101 * t) +
            sin(rad(3 * m)) * 0.000289
        val trueLong = l0 + c
        val appLong = trueLong - 0.00569 - 0.00478 * sin(rad(125.04 - 1934.136 * t))
        val meanObliq = 23 + (26 + ((21.448 - t * (46.815 + t * (0.00059 - t * 0.001813)))) / 60) / 60
        val obliqCorr = meanObliq + 0.00256 * cos(rad(125.04 - 1934.136 * t))
        val decl = deg(asin(sin(rad(obliqCorr)) * sin(rad(appLong))))
        val y = tan(rad(obliqCorr / 2)).pow(2)
        val eqTime = 4 * deg(
            y * sin(2 * rad(l0)) -
                2 * e * sin(rad(m)) +
                4 * e * y * sin(rad(m)) * cos(2 * rad(l0)) -
                0.5 * y * y * sin(4 * rad(l0)) -
                1.25 * e * e * sin(2 * rad(m))
        )
        return Pair(decl, eqTime)
    }

    private fun hourAngleSunrise(lat: Double, decl: Double): Double? {
        val c = cos(rad(90.833)) / (cos(rad(lat)) * cos(rad(decl))) - tan(rad(lat)) * tan(rad(decl))
        if (c < -1 || c > 1) return null
        return deg(acos(c))
    }

    private fun dayStart(utcMillis: Long) = Math.floorDiv(utcMillis, DAY_MS) * DAY_MS

    /** Sunrise or sunset (UTC millis) of the solar day of [utcMillis]'s UTC date. */
    fun sunEvent(utcMillis: Long, lat: Double, lon: Double, rising: Boolean): Long? {
        val dayJd = julianDay(dayStart(utcMillis))
        var minutes = 720 - 4 * lon
        repeat(4) {
            val (decl, eqTime) = solarParams(dayJd + minutes / 1440)
            val ha = hourAngleSunrise(lat, decl) ?: return null
            minutes = 720 - 4 * (lon + if (rising) ha else -ha) - eqTime
        }
        return fromJulianDay(dayJd + minutes / 1440)
    }

    fun solarNoon(utcMillis: Long, lon: Double): Long {
        val dayJd = julianDay(dayStart(utcMillis))
        var minutes = 720 - 4 * lon
        repeat(3) {
            minutes = 720 - 4 * lon - solarParams(dayJd + minutes / 1440).second
        }
        return fromJulianDay(dayJd + minutes / 1440)
    }

    /** Sun events and noons from yesterday to [days] days ahead. */
    fun build(lat: Double, lon: Double, now: Long, label: String, days: Int = 14): SunData {
        val events = mutableListOf<Pair<Long, Boolean>>()
        val noons = mutableListOf<Long>()
        for (d in -1..days) {
            val day = now + d * DAY_MS
            sunEvent(day, lat, lon, true)?.let { events.add(Pair(it, true)) }
            sunEvent(day, lat, lon, false)?.let { events.add(Pair(it, false)) }
            noons.add(solarNoon(day, lon))
        }
        events.sortBy { it.first }
        return SunData(events, noons, label, computedAt = now)
    }
}
