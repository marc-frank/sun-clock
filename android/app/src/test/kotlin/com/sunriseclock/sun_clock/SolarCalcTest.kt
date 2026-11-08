package com.sunriseclock.sun_clock

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

/** The Kotlin port must match lib/solar.dart (and through it the NOAA sheet). */
class SolarCalcTest {
    private fun ms(iso: String) = Instant.parse(iso).toEpochMilli()

    @Test
    fun matchesNoaaSpreadsheetRow() {
        // NOAA_Solar_Calculations_day.xls, first row.
        val (decl, eqTime) = SolarCalc.solarParams(2455368.754166667)
        assertEquals(23.438312159513938, decl, 1e-9)
        assertEquals(-1.7063078407232208, eqTime, 1e-9)
    }

    @Test
    fun matchesDartSunEvents() {
        // Printed by lib/solar.dart's sunEvent for Berlin, 2026-11-08.
        val day = ms("2026-11-08T00:00:00Z")
        val rise = SolarCalc.sunEvent(day, 52.52, 13.405, rising = true)!!
        val set = SolarCalc.sunEvent(day, 52.52, 13.405, rising = false)!!
        assertEquals(ms("2026-11-08T06:15:18.372Z").toDouble(), rise.toDouble(), 2.0)
        assertEquals(ms("2026-11-08T15:24:09.960Z").toDouble(), set.toDouble(), 2.0)
    }

    @Test
    fun sunTimeIsSixAtSunriseAndEighteenAtSunset() {
        val now = ms("2026-11-08T12:00:00Z")
        val data = SolarCalc.build(52.52, 13.405, now, "Berlin")
        val rise = data.events.first { it.second && it.first > now - 86_400_000L }.first
        val set = data.events.first { !it.second && it.first > rise }.first
        assertEquals(360.0, SunTime.read(rise, data)!!.sunMinutes, 0.01)
        assertEquals(1080.0, SunTime.read(set, data)!!.sunMinutes, 0.01)
        assertEquals(720.0, SunTime.read((rise + set) / 2, data)!!.sunMinutes, 0.01)
    }

    @Test
    fun polarDayHasNoEventsButANoon() {
        val day = ms("2026-06-21T00:00:00Z")
        assertNull(SolarCalc.sunEvent(day, 78.22, 15.65, rising = true))
        val data = SolarCalc.build(78.22, 15.65, day, "")
        val r = SunTime.read(day + 12 * 3_600_000L, data)
        assertNotNull(r)
        assertTrue(r!!.next == null)
    }
}
