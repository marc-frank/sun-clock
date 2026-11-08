package com.sunriseclock.sun_clock

import kotlin.math.abs

/**
 * Same rule as lib/sun_clock.dart: between a sunrise and the following sunset
 * the 12 hours 06:00–18:00 are spread evenly, between a sunset and the next
 * sunrise the hours 18:00–06:00. Without such a pair (polar day/night) it
 * falls back to apparent solar time, 12:00 at solar noon.
 */
data class SunReading(
    /** Sun time in minutes since sun-midnight, in [0, 1440). */
    val sunMinutes: Double,
    val isDay: Boolean,
    /** Real milliseconds per sun-minute right now. */
    val msPerSunMinute: Double,
    /** Next sunrise/sunset, null in the fallback or when the data ran out. */
    val next: Pair<Long, Boolean>?,
    /** Real minutes per sun-hour, null in the fallback. */
    val realMinutesPerHour: Double?,
    /** The handed-over data no longer covers [now]; the app should refresh it. */
    val stale: Boolean,
)

object SunTime {
    private const val DAY_MS = 24 * 60 * 60 * 1000L

    fun read(now: Long, data: SunData): SunReading? {
        var prev: Pair<Long, Boolean>? = null
        var next: Pair<Long, Boolean>? = null
        for (e in data.events) {
            if (e.first <= now) prev = e else { next = e; break }
        }
        if (prev != null && next != null && prev.second != next.second &&
            next.first - prev.first < DAY_MS
        ) {
            val span = (next.first - prev.first).toDouble()
            val frac = (now - prev.first) / span
            val start = if (prev.second) 360.0 else 1080.0
            return SunReading(
                sunMinutes = (start + 720.0 * frac) % 1440.0,
                isDay = prev.second,
                msPerSunMinute = span / 720.0,
                next = next,
                realMinutesPerHour = span / 12.0 / 60000.0,
                stale = false,
            )
        }
        val noon = data.noons.minByOrNull { abs(it - now) } ?: return null
        val m = ((720.0 + (now - noon) / 60000.0) % 1440.0 + 1440.0) % 1440.0
        return SunReading(
            sunMinutes = m,
            isDay = m in 360.0..1080.0,
            msPerSunMinute = 60000.0,
            next = null,
            realMinutesPerHour = null,
            stale = abs(noon - now) > DAY_MS, // past the end of the data
        )
    }
}
