package com.sunriseclock.sun_clock

import android.content.Context

/** Sun events handed over from Dart, persisted so the service survives reboots. */
data class SunData(
    /** (utcMillis, isSunrise), sorted by time. */
    val events: List<Pair<Long, Boolean>>,
    /** Solar noons (utcMillis), for the polar-day/night fallback. */
    val noons: List<Long>,
    val label: String,
)

object SunClockStore {
    private const val PREFS = "sun_clock_status_bar"
    private const val K_ENABLED = "enabled"
    private const val K_EVENTS = "events"
    private const val K_NOONS = "noons"
    private const val K_LABEL = "label"

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun isEnabled(c: Context) = prefs(c).getBoolean(K_ENABLED, false)

    fun setEnabled(c: Context, on: Boolean) =
        prefs(c).edit().putBoolean(K_ENABLED, on).apply()

    /** [flatEvents] is [millis, 1|0, millis, 1|0, ...] as sent by Dart. */
    fun save(c: Context, flatEvents: List<Long>, noons: List<Long>, label: String) {
        prefs(c).edit()
            .putString(K_EVENTS, flatEvents.joinToString(","))
            .putString(K_NOONS, noons.joinToString(","))
            .putString(K_LABEL, label)
            .putBoolean(K_ENABLED, true)
            .apply()
    }

    fun load(c: Context): SunData? {
        val p = prefs(c)
        val flat = p.getString(K_EVENTS, null)?.split(",")?.mapNotNull { it.toLongOrNull() }
            ?: return null
        val events = flat.chunked(2).filter { it.size == 2 }
            .map { Pair(it[0], it[1] == 1L) }
            .sortedBy { it.first }
        val noons = p.getString(K_NOONS, "")!!.split(",").mapNotNull { it.toLongOrNull() }
        if (events.isEmpty() && noons.isEmpty()) return null
        return SunData(events, noons, p.getString(K_LABEL, "") ?: "")
    }
}
