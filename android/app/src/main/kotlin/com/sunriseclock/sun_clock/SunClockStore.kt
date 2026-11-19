package com.sunriseclock.sun_clock

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

/** Sun events computed for one position, used to interpolate sun time. */
data class SunData(
    /** (utcMillis, isSunrise), sorted by time. */
    val events: List<Pair<Long, Boolean>>,
    /** Solar noons (utcMillis), for the polar-day/night fallback. */
    val noons: List<Long>,
    /** Latitude, for the polar-day/night fallback's day/night flag. */
    val lat: Double,
    val label: String,
    val computedAt: Long,
)

/**
 * What the service and the home-screen widget need, persisted so it survives
 * reboots. The app stores it whenever its position changes, whether or not
 * the status-bar clock is on ([SunClockStore.isEnabled] is a separate flag).
 */
data class ClockParams(
    val lat: Double,
    val lon: Double,
    /** Place name from the app's time-zone lookup; empty once the phone moved. */
    val label: String,
    /** Follow the device location (the app uses GPS, not a point picked on the map). */
    val followLocation: Boolean,
    /** The user chose precise location in the app's settings. */
    val precise: Boolean,
)

object SunClockStore {
    private const val PREFS = "sun_clock_status_bar"
    private const val K_ENABLED = "enabled"
    private const val K_LAT = "lat"
    private const val K_LON = "lon"
    private const val K_LABEL = "label"
    private const val K_FOLLOW = "follow"
    private const val K_PRECISE = "precise"
    private const val K_BACKGROUND = "background_location"
    private const val K_CHIP = "text_chip"
    private const val K_LANGUAGE = "language"

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun isEnabled(c: Context) = prefs(c).getBoolean(K_ENABLED, false)

    fun setEnabled(c: Context, on: Boolean) =
        prefs(c).edit().putBoolean(K_ENABLED, on).apply()

    /**
     * The user opted in to background location ("Allow all the time") so
     * the service can follow the phone when started without the app, e.g.
     * after a reboot. Whether Android still grants it is checked separately.
     */
    fun backgroundLocation(c: Context) = prefs(c).getBoolean(K_BACKGROUND, false)

    fun setBackgroundLocation(c: Context, on: Boolean) =
        prefs(c).edit().putBoolean(K_BACKGROUND, on).apply()

    /** Android 16+: show the sun time as a Live Update chip (text). */
    fun textChip(c: Context) = prefs(c).getBoolean(K_CHIP, false)

    fun setTextChip(c: Context, on: Boolean) =
        prefs(c).edit().putBoolean(K_CHIP, on).apply()

    /** The language chosen in the app ("" follows the phone). */
    fun language(c: Context): String = prefs(c).getString(K_LANGUAGE, "") ?: ""

    fun setLanguage(c: Context, code: String) =
        prefs(c).edit().putString(K_LANGUAGE, code).apply()

    private var localizedFor: Pair<String, Context>? = null

    /**
     * [c] with the app's language for string lookups, so the notification
     * and the widget follow the language chosen in the app.
     */
    fun localized(c: Context): Context {
        val lang = language(c)
        if (lang.isEmpty()) return c
        localizedFor?.let { (l, ctx) -> if (l == lang) return ctx }
        val conf = Configuration(c.resources.configuration)
        conf.setLocale(Locale.forLanguageTag(lang))
        return c.applicationContext.createConfigurationContext(conf).also {
            localizedFor = lang to it
        }
    }

    fun save(c: Context, p: ClockParams) {
        prefs(c).edit()
            // Doubles as raw bits: SharedPreferences has no putDouble.
            .putLong(K_LAT, p.lat.toRawBits())
            .putLong(K_LON, p.lon.toRawBits())
            .putString(K_LABEL, p.label)
            .putBoolean(K_FOLLOW, p.followLocation)
            .putBoolean(K_PRECISE, p.precise)
            .apply()
    }

    fun load(c: Context): ClockParams? {
        val p = prefs(c)
        if (!p.contains(K_LAT) || !p.contains(K_LON)) return null
        return ClockParams(
            lat = Double.fromBits(p.getLong(K_LAT, 0)),
            lon = Double.fromBits(p.getLong(K_LON, 0)),
            label = p.getString(K_LABEL, "") ?: "",
            followLocation = p.getBoolean(K_FOLLOW, false),
            precise = p.getBoolean(K_PRECISE, false),
        )
    }
}
