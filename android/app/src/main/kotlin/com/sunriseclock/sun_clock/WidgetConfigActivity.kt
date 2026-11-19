package com.sunriseclock.sun_clock

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle

/**
 * Opened by the launcher to set up a new widget (before Android 12) or to
 * change one (long-press → reconfigure on Android 12+). It runs the same
 * Flutter app, which asks for [configWidgetId] at start and then shows only
 * the widget editor; Done there calls finish().
 *
 * The result is OK from the start, so backing out still keeps the widget,
 * with the settings saved last.
 */
class WidgetConfigActivity : MainActivity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override val configWidgetId: Int?
        get() = widgetId.takeIf { it != AppWidgetManager.INVALID_APPWIDGET_ID }

    override fun onCreate(savedInstanceState: Bundle?) {
        widgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        super.onCreate(savedInstanceState)
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        setResult(
            RESULT_OK,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId),
        )
        // Draw the new widget with the template settings right away.
        SunWidget.updateAll(this)
    }
}
