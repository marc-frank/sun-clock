package com.sunriseclock.sun_clock

import android.content.Context

/**
 * One home-screen widget's settings, edited in the app (lib/widget_editor.dart).
 * Keys and defaults match lib/home_widget.dart. Colours are ARGB; the
 * background's alpha is its opacity.
 */
data class WidgetConfig(
    /** "sun", "local" or "both". */
    val clocks: String = "sun",
    /** With both clocks: "stacked" (one large, one small) or "side". */
    val layout: String = "stacked",
    /** With both clocks: the large or left one, "sun" or "local". */
    val first: String = "sun",
    val labels: Boolean = false,
    val dayNight: Boolean = true,
    val next: Boolean = true,
    val hourLength: Boolean = false,
    val offset: Boolean = false,
    val place: Boolean = false,
    val progress: Boolean = false,
    val background: Int = 0xFF1C1B17.toInt(),
    /** Corner radius in dp: 0, 8, 16 or 28. */
    val corners: Int = 16,
    val autoColors: Boolean = true,
    val timeColor: Int = 0xFFFFFFFF.toInt(),
    val textColor: Int = 0xB3FFFFFF.toInt(),
) {
    val showsSun get() = clocks != "local"
    val both get() = clocks == "both"
    val side get() = both && layout == "side"

    /** The large (or left) clock: true for sun time. */
    val primaryIsSun get() = if (both) first != "local" else clocks != "local"

    fun toMap(): Map<String, Any> = mapOf(
        "clocks" to clocks, "layout" to layout, "first" to first,
        "labels" to labels, "dayNight" to dayNight, "next" to next,
        "hourLength" to hourLength, "offset" to offset, "place" to place,
        "progress" to progress, "background" to background, "corners" to corners,
        "autoColors" to autoColors, "timeColor" to timeColor, "textColor" to textColor,
    )

    companion object {
        private val CORNERS = setOf(0, 8, 16, 28)

        /** Unknown or malformed values fall back to the defaults. */
        fun from(m: Map<String, Any?>): WidgetConfig {
            val d = WidgetConfig()
            fun s(k: String, allowed: Set<String>, def: String) =
                (m[k] as? String)?.takeIf { it in allowed } ?: def
            fun b(k: String, def: Boolean) = m[k] as? Boolean ?: def
            // Dart sends colours above 2^31 as Long.
            fun i(k: String, def: Int) = (m[k] as? Number)?.toLong()?.toInt() ?: def
            return WidgetConfig(
                clocks = s("clocks", setOf("sun", "local", "both"), d.clocks),
                layout = s("layout", setOf("stacked", "side"), d.layout),
                first = s("first", setOf("sun", "local"), d.first),
                labels = b("labels", d.labels),
                dayNight = b("dayNight", d.dayNight),
                next = b("next", d.next),
                hourLength = b("hourLength", d.hourLength),
                offset = b("offset", d.offset),
                place = b("place", d.place),
                progress = b("progress", d.progress),
                background = i("background", d.background),
                corners = i("corners", d.corners).takeIf { it in CORNERS } ?: d.corners,
                autoColors = b("autoColors", d.autoColors),
                timeColor = i("timeColor", d.timeColor),
                textColor = i("textColor", d.textColor),
            )
        }
    }
}

/** The settings of each placed widget, plus the last saved ones for new widgets. */
object WidgetStore {
    private const val PREFS = "sun_clock_widgets"
    private const val TEMPLATE = "template"

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun read(c: Context, key: String): WidgetConfig? {
        val prefix = "$key."
        val all = prefs(c).all.filterKeys { it.startsWith(prefix) }
        if (all.isEmpty()) return null
        return WidgetConfig.from(all.mapKeys { it.key.removePrefix(prefix) })
    }

    private fun write(c: Context, key: String, cfg: WidgetConfig) {
        val e = prefs(c).edit()
        for ((k, v) in cfg.toMap()) {
            when (v) {
                is Boolean -> e.putBoolean("$key.$k", v)
                is Int -> e.putInt("$key.$k", v)
                is String -> e.putString("$key.$k", v)
            }
        }
        e.apply()
    }

    /**
     * A widget without saved settings starts with the ones saved last and
     * keeps that copy, so editing another widget later doesn't change it.
     */
    fun load(c: Context, id: Int): WidgetConfig {
        read(c, "$id")?.let { return it }
        val start = read(c, TEMPLATE) ?: WidgetConfig()
        write(c, "$id", start)
        return start
    }

    fun save(c: Context, id: Int, cfg: WidgetConfig) {
        write(c, "$id", cfg)
        write(c, TEMPLATE, cfg)
    }

    fun delete(c: Context, ids: IntArray) {
        val e = prefs(c).edit()
        val keys = prefs(c).all.keys
        for (id in ids) keys.filter { it.startsWith("$id.") }.forEach(e::remove)
        e.apply()
    }
}
