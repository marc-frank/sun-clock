package com.sunriseclock.sun_clock

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

open class MainActivity : FlutterActivity() {
    /** The widget the launcher asked to set up ([WidgetConfigActivity]). */
    protected open val configWidgetId: Int? = null

    private companion object {
        const val CHANNEL = "sun_clock/status_bar"
        const val REQUEST_NOTIFICATIONS = 41
        const val REQUEST_LOCATION = 42
        const val REQUEST_FOREGROUND_FOR_BACKGROUND = 43
        const val REQUEST_BACKGROUND = 44
    }

    private var pendingPermission: MethodChannel.Result? = null
    private var pendingLocation: MethodChannel.Result? = null
    private var pendingBackground: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Location permission with the user's precision choice: approximate
        // asks for coarse location only, so the system dialog never offers
        // precise. (The geolocator plugin would always ask for both.)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sun_clock/location")
            .setMethodCallHandler { call, result ->
                if (call.method == "requestLocation") {
                    requestLocation(call.argument<Boolean>("precise") == true, result)
                } else {
                    result.notImplemented()
                }
            }
        // The opt-in update check opens the release page in the browser.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sun_clock/system")
            .setMethodCallHandler { call, result ->
                val url = call.argument<String>("url") ?: ""
                if (call.method != "openUrl" ||
                    !url.startsWith("https://github.com/marc-frank/sun-clock/")
                ) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)))
                    result.success(true)
                } catch (_: ActivityNotFoundException) {
                    result.success(false)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sun_clock/widgets")
            .setMethodCallHandler { call, result -> widgets(call, result) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setLanguage" -> {
                        val code = call.argument<String>("code") ?: ""
                        if (code != SunClockStore.language(this)) {
                            SunClockStore.setLanguage(this, code)
                            SunWidget.updateAll(this)
                            if (SunClockStore.isEnabled(this)) SunClockService.start(this)
                        }
                        result.success(null)
                    }
                    "isEnabled" -> result.success(SunClockStore.isEnabled(this))
                    "requestNotificationPermission" -> requestNotifications(result)
                    // The position changed: store it for the home-screen
                    // widget even while the status-bar clock is off.
                    "setPosition" -> {
                        SunClockStore.save(this, params(call))
                        SunWidget.updateAll(this)
                        LocationFollower.sync(this)
                        result.success(null)
                    }
                    "start" -> {
                        SunClockStore.save(this, params(call))
                        SunClockStore.setEnabled(this, true)
                        SunClockService.start(this)
                        LocationFollower.sync(this)
                        result.success(null)
                    }
                    "backgroundLocationStatus" -> result.success(
                        mapOf(
                            "optedIn" to SunClockStore.backgroundLocation(this),
                            "granted" to hasBackgroundLocation(),
                        ),
                    )
                    "requestBackgroundLocation" ->
                        requestBackgroundLocation(call.argument<Boolean>("precise") == true, result)
                    "setBackgroundLocation" -> {
                        SunClockStore.setBackgroundLocation(this, call.argument<Boolean>("on") == true)
                        LocationFollower.sync(this)
                        result.success(null)
                    }
                    // Live Update chip (Android 16+).
                    "textChipStatus" -> result.success(
                        mapOf(
                            "supported" to (Build.VERSION.SDK_INT >= 36),
                            "on" to SunClockStore.textChip(this),
                            "allowed" to promotionAllowed(),
                        ),
                    )
                    "setTextChip" -> {
                        SunClockStore.setTextChip(this, call.argument<Boolean>("on") == true)
                        if (SunClockStore.isEnabled(this)) SunClockService.start(this)
                        result.success(null)
                    }
                    "openPromotionSettings" -> {
                        openPromotionSettings()
                        result.success(null)
                    }
                    "stop" -> {
                        SunClockStore.setEnabled(this, false)
                        SunClockService.stop(this)
                        LocationFollower.sync(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** The home-screen widgets' settings (lib/home_widget.dart). */
    private fun widgets(call: MethodCall, result: MethodChannel.Result) {
        val manager = AppWidgetManager.getInstance(this)
        when (call.method) {
            "ids" -> result.success(
                manager.getAppWidgetIds(ComponentName(this, SunWidget::class.java)).toList(),
            )
            "getConfig" -> result.success(
                WidgetStore.load(this, call.argument<Int>("id")!!).toMap(),
            )
            "setConfig" -> {
                val map = call.argument<Map<String, Any?>>("config") ?: emptyMap()
                WidgetStore.save(this, call.argument<Int>("id")!!, WidgetConfig.from(map))
                SunWidget.updateAll(this)
                result.success(null)
            }
            "pin" -> result.success(
                Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported &&
                    manager.requestPinAppWidget(
                        ComponentName(this, SunWidget::class.java), null, null,
                    ),
            )
            "configLaunchId" -> result.success(configWidgetId)
            "finishConfig" -> {
                result.success(null)
                finish()
            }
            else -> result.notImplemented()
        }
    }

    private fun params(call: MethodCall) = ClockParams(
        lat = call.argument<Double>("lat")!!,
        lon = call.argument<Double>("lon")!!,
        label = call.argument<String>("label") ?: "",
        followLocation = call.argument<Boolean>("followLocation") == true,
        precise = call.argument<Boolean>("precise") == true,
    )

    private fun requestNotifications(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingPermission?.success(false)
        pendingPermission = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
    }

    private fun granted(p: String) =
        checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED

    private fun requestLocation(precise: Boolean, result: MethodChannel.Result) {
        val coarse = Manifest.permission.ACCESS_COARSE_LOCATION
        val fine = Manifest.permission.ACCESS_FINE_LOCATION
        if (if (precise) granted(fine) else granted(coarse)) {
            result.success(true)
            return
        }
        pendingLocation?.success(granted(coarse))
        pendingLocation = result
        val perms = if (precise) arrayOf(fine, coarse) else arrayOf(coarse)
        requestPermissions(perms, REQUEST_LOCATION)
    }

    private fun promotionAllowed(): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        val nm = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
        return nm.canPostPromotedNotifications()
    }

    /** The app's Live Updates switch in system settings, else its notification page. */
    private fun openPromotionSettings() {
        val action = if (Build.VERSION.SDK_INT >= 36) {
            Settings.ACTION_APP_NOTIFICATION_PROMOTION_SETTINGS
        } else {
            Settings.ACTION_APP_NOTIFICATION_SETTINGS
        }
        try {
            startActivity(Intent(action).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
        } catch (_: ActivityNotFoundException) {
            startActivity(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
            )
        }
    }

    private fun hasBackgroundLocation(): Boolean {
        val foreground = granted(Manifest.permission.ACCESS_COARSE_LOCATION)
        // Before Android 10 the foreground permission covers the background.
        return foreground && (Build.VERSION.SDK_INT < 29 ||
            granted(Manifest.permission.ACCESS_BACKGROUND_LOCATION))
    }

    /**
     * "Allow all the time", the way Android 11+ requires: the while-in-use
     * permission first, then the background one in a separate request, which
     * opens the app's location page in system settings. Android 10 offers
     * both in one dialog. The Dart side shows the prominent disclosure before
     * calling this.
     */
    private fun requestBackgroundLocation(precise: Boolean, result: MethodChannel.Result) {
        pendingBackground?.success(false)
        pendingBackground = result
        val coarse = Manifest.permission.ACCESS_COARSE_LOCATION
        val fine = Manifest.permission.ACCESS_FINE_LOCATION
        if (!granted(coarse)) {
            val perms = if (precise) arrayOf(fine, coarse) else arrayOf(coarse)
            if (Build.VERSION.SDK_INT == 29) {
                requestPermissions(
                    perms + Manifest.permission.ACCESS_BACKGROUND_LOCATION, REQUEST_BACKGROUND,
                )
            } else {
                requestPermissions(perms, REQUEST_FOREGROUND_FOR_BACKGROUND)
            }
            return
        }
        requestBackgroundStep()
    }

    private fun requestBackgroundStep() {
        if (hasBackgroundLocation()) {
            finishBackground()
            return
        }
        requestPermissions(arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION), REQUEST_BACKGROUND)
    }

    private fun finishBackground() {
        pendingBackground?.success(hasBackgroundLocation())
        pendingBackground = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_NOTIFICATIONS) {
            pendingPermission?.success(
                grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
            )
            pendingPermission = null
        }
        if (requestCode == REQUEST_FOREGROUND_FOR_BACKGROUND) {
            if (granted(Manifest.permission.ACCESS_COARSE_LOCATION)) {
                requestBackgroundStep()
            } else {
                finishBackground()
            }
        }
        if (requestCode == REQUEST_BACKGROUND) finishBackground()
        if (requestCode == REQUEST_LOCATION) {
            pendingLocation?.success(
                grantResults.any { it == PackageManager.PERMISSION_GRANTED },
            )
            pendingLocation = null
        }
    }
}
