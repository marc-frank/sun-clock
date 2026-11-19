package com.sunriseclock.sun_clock

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetConfigTest {
    @Test
    fun emptyMapGivesDefaults() {
        assertEquals(WidgetConfig(), WidgetConfig.from(emptyMap()))
    }

    @Test
    fun roundTripsThroughItsMap() {
        val c = WidgetConfig(
            clocks = "both", layout = "side", first = "local", labels = true,
            dayNight = false, next = false, hourLength = true, offset = true,
            place = true, progress = true, background = 0x80FFFFFF.toInt(),
            corners = 28, autoColors = false, timeColor = 0xFF000000.toInt(),
            textColor = 0xDE000000.toInt(),
        )
        assertEquals(c, WidgetConfig.from(c.toMap()))
    }

    @Test
    fun acceptsDartIntsAsLongAndRejectsJunk() {
        // Dart sends 0xFF1C1B17 as a Long (it does not fit a signed Int).
        val c = WidgetConfig.from(
            mapOf(
                "background" to 0x801C1B17L,
                "clocks" to "everything",
                "corners" to 13,
                "labels" to "yes",
            ),
        )
        assertEquals(0x801C1B17L.toInt(), c.background)
        assertEquals("sun", c.clocks)
        assertEquals(16, c.corners)
        assertFalse(c.labels)
    }

    @Test
    fun clockArrangement() {
        assertTrue(WidgetConfig(clocks = "sun").primaryIsSun)
        assertFalse(WidgetConfig(clocks = "local").primaryIsSun)
        assertFalse(WidgetConfig(clocks = "both", first = "local").primaryIsSun)
        assertTrue(WidgetConfig(clocks = "both", layout = "side").side)
        assertFalse(WidgetConfig(clocks = "sun", layout = "side").side)
    }

    @Test
    fun progressThroughDayAndNight() {
        assertEquals(0.0, SunWidget.progress(360.0), 1e-9) // sunrise
        assertEquals(0.5, SunWidget.progress(720.0), 1e-9) // noon
        assertEquals(0.0, SunWidget.progress(1080.0), 1e-9) // sunset
        assertEquals(0.5, SunWidget.progress(0.0), 1e-9) // sun-midnight
        assertEquals(0.75, SunWidget.progress(180.0), 1e-9)
    }

    @Test
    fun offsetWrapsAroundMidnight() {
        assertEquals(23.0, SunWidget.offsetMinutes(623.0, 600.0), 1e-9)
        assertEquals(-90.0, SunWidget.offsetMinutes(360.0, 450.0), 1e-9)
        // Sun time 23:50, local 00:10 the next day: 20 min behind.
        assertEquals(-20.0, SunWidget.offsetMinutes(1430.0, 10.0), 1e-9)
        assertEquals(20.0, SunWidget.offsetMinutes(10.0, 1430.0), 1e-9)
    }
}
