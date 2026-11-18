package com.sunriseclock.sun_clock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restarts the status-bar clock and the widget after a reboot or an app update. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                // Alarms don't survive a reboot or an update: restart the
                // widget's chain (a no-op without widgets).
                SunWidget.updateAll(context)
                if (SunClockStore.isEnabled(context) && SunClockStore.load(context) != null) {
                    try {
                        SunClockService.start(context)
                    } catch (_: Exception) {
                        // Not allowed to start from the background on this
                        // device; it starts again when the app is opened.
                    }
                }
            }
        }
    }
}
