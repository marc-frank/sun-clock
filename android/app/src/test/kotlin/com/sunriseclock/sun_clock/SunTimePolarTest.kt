package com.sunriseclock.sun_clock

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

/**
 * In the polar fallback the day/night flag follows lib/sun_clock.dart:
 * day when the sun is over the observer's hemisphere (lat * declination > 0),
 * not when the solar clock reads 06:00–18:00.
 */
class SunTimePolarTest {
    private fun ms(iso: String) = Instant.parse(iso).toEpochMilli()

    private fun readAtSolarNoonAndMidnight(lat: Double, lon: Double, day: String): Pair<SunReading, SunReading> {
        val start = ms(day)
        val data = SolarCalc.build(lat, lon, start, "")
        val noon = SolarCalc.solarNoon(start, lon)
        val atNoon = SunTime.read(noon, data)
        val atMidnight = SunTime.read(noon + 12 * 3_600_000L, data)
        assertNotNull(atNoon)
        assertNotNull(atMidnight)
        return Pair(atNoon!!, atMidnight!!)
    }

    @Test
    fun polarNightIsNightEvenAtSolarNoon() {
        // Tromsø in December: the sun does not rise.
        val (noon, midnight) = readAtSolarNoonAndMidnight(69.65, 18.96, "2026-12-21T00:00:00Z")
        assertNull(noon.next)
        assertEquals(720.0, noon.sunMinutes, 0.01)
        assertFalse(noon.isDay)
        assertFalse(midnight.isDay)
    }

    @Test
    fun polarDayIsDayEvenAtSolarMidnight() {
        // Tromsø in June: the sun does not set.
        val (noon, midnight) = readAtSolarNoonAndMidnight(69.65, 18.96, "2026-06-21T00:00:00Z")
        assertNull(midnight.next)
        assertEquals(0.0, midnight.sunMinutes % 1440.0, 0.5)
        assertTrue(noon.isDay)
        assertTrue(midnight.isDay)
    }

    @Test
    fun southernPolarNightAndDay() {
        // McMurdo: polar day in December, polar night in June.
        val (decNoon, decMidnight) = readAtSolarNoonAndMidnight(-77.85, 166.67, "2026-12-21T00:00:00Z")
        assertTrue(decNoon.isDay)
        assertTrue(decMidnight.isDay)
        val (junNoon, junMidnight) = readAtSolarNoonAndMidnight(-77.85, 166.67, "2026-06-21T00:00:00Z")
        assertFalse(junNoon.isDay)
        assertFalse(junMidnight.isDay)
    }
}
