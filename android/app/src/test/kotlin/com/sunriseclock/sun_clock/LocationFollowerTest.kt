package com.sunriseclock.sun_clock

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class LocationFollowerTest {
    private val berlin = ClockParams(52.52, 13.41, "Berlin", followLocation = true, precise = false)

    @Test
    fun smallMovesAreIgnored() {
        // Under ~1 km (approximate): no change, so no redraw.
        assertNull(LocationFollower.moved(berlin, 52.523, 13.412))
    }

    @Test
    fun approximateIsRoundedAndKeepsNearbyName() {
        val m = LocationFollower.moved(berlin, 52.5612, 13.4398)
        assertNotNull(m)
        assertEquals(52.56, m!!.lat, 1e-9)
        assertEquals(13.44, m.lon, 1e-9)
        assertEquals("Berlin", m.label) // within ~25 km
    }

    @Test
    fun farAwayShowsCoordinates() {
        val m = LocationFollower.moved(berlin, 48.137, 11.575)!! // Munich
        assertEquals("48.14° N 11.58° E", m.label)
    }

    @Test
    fun preciseFollowsSmallerMoves() {
        val p = berlin.copy(precise = true)
        val m = LocationFollower.moved(p, 52.5235, 13.41)
        assertNotNull(m)
        assertEquals(52.5235, m!!.lat, 1e-9)
    }

    @Test
    fun mapPlaceIsNeverMoved() {
        assertNull(LocationFollower.moved(berlin.copy(followLocation = false), 48.0, 11.0))
    }
}
