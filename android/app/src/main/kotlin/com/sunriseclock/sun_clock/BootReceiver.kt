package com.sunriseclock.sun_clock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restarts the status-bar clock after a reboot or an app update. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
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
