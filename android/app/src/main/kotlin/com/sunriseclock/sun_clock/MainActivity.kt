package com.sunriseclock.sun_clock

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "sun_clock/status_bar"
        const val REQUEST_NOTIFICATIONS = 41
        const val REQUEST_LOCATION = 42
    }

    private var pendingPermission: MethodChannel.Result? = null
    private var pendingLocation: MethodChannel.Result? = null

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isEnabled" -> result.success(SunClockStore.isEnabled(this))
                    "requestNotificationPermission" -> requestNotifications(result)
                    // The position changed: store it for the home-screen
                    // widget even while the status-bar clock is off.
                    "setPosition" -> {
                        SunClockStore.save(this, params(call))
                        SunWidget.updateAll(this)
                        result.success(null)
                    }
                    "start" -> {
                        SunClockStore.save(this, params(call))
                        SunClockStore.setEnabled(this, true)
                        SunClockService.start(this)
                        result.success(null)
                    }
                    "stop" -> {
                        SunClockStore.setEnabled(this, false)
                        SunClockService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
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
        if (requestCode == REQUEST_LOCATION) {
            pendingLocation?.success(
                grantResults.any { it == PackageManager.PERMISSION_GRANTED },
            )
            pendingLocation = null
        }
    }
}
