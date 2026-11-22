import CoreLocation
import Flutter
import UIKit
import WidgetKit

/// The iOS side of the app's channels (the Android side is MainActivity.kt):
/// - sun_clock/status_bar: stores the position for the widget and follows
///   the location in the background when the user opted in. There is no
///   status-bar clock on iOS, so its switches report "off".
/// - sun_clock/widgets: the widget settings and texts (one set for all
///   widgets), read by the widget extension from the shared App Group.
/// - sun_clock/system: opens the release page for the update check.
@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    private let location = CLLocationManager()
    private var pendingAlways: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        if let registrar = registrar(forPlugin: "SunClockNative") {
            let m = registrar.messenger()
            FlutterMethodChannel(name: "sun_clock/status_bar", binaryMessenger: m)
                .setMethodCallHandler { [weak self] call, result in self?.statusBar(call, result) }
            FlutterMethodChannel(name: "sun_clock/widgets", binaryMessenger: m)
                .setMethodCallHandler { [weak self] call, result in self?.widgets(call, result) }
            FlutterMethodChannel(name: "sun_clock/system", binaryMessenger: m)
                .setMethodCallHandler { call, result in Self.system(call, result) }
        }
        // Also when iOS relaunches the app in the background for a
        // significant location change.
        location.delegate = self
        syncLocation()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: Channels

    private func args(_ call: FlutterMethodCall) -> [String: Any] {
        call.arguments as? [String: Any] ?? [:]
    }

    private func statusBar(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case "isEnabled", "requestNotificationPermission":
            result(false)
        case "setPosition", "start":
            let a = args(call)
            if let lat = a["lat"] as? Double, let lon = a["lon"] as? Double {
                SharedStore.save(.init(
                    lat: lat, lon: lon, label: a["label"] as? String ?? "",
                    follow: a["followLocation"] as? Bool ?? false,
                    precise: a["precise"] as? Bool ?? false))
                reloadWidgets()
                syncLocation()
            }
            result(nil)
        case "stop", "setTextChip", "openPromotionSettings", "setLanguage":
            result(nil)
        case "textChipStatus":
            result(["supported": false, "on": false, "allowed": false])
        case "backgroundLocationStatus":
            result(["optedIn": SharedStore.backgroundOptIn, "granted": alwaysGranted])
        case "requestBackgroundLocation":
            if alwaysGranted {
                result(true)
                return
            }
            pendingAlways?(false)
            pendingAlways = result
            location.requestAlwaysAuthorization()
            // iOS shows no prompt when the user already decided; then the
            // delegate isn't called and this answers instead.
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
                guard let self = self, let r = self.pendingAlways else { return }
                self.pendingAlways = nil
                r(self.alwaysGranted)
            }
        case "setBackgroundLocation":
            SharedStore.backgroundOptIn = args(call)["on"] as? Bool == true
            syncLocation()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func widgets(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case "ids":
            // One set of settings for all widgets; [0] once one is placed.
            WidgetCenter.shared.getCurrentConfigurations { r in
                var placed = false
                if case .success(let infos) = r {
                    placed = infos.contains { $0.kind == "SunClockWidget" }
                }
                DispatchQueue.main.async { result(placed ? [0] : [Int]()) }
            }
        case "getConfig":
            result(SharedStore.config())
        case "setConfig":
            if let c = args(call)["config"] as? [String: Any] { SharedStore.saveConfig(c) }
            reloadWidgets()
            result(nil)
        case "setTexts":
            if let t = args(call)["texts"] as? [String: String] { SharedStore.saveTexts(t) }
            reloadWidgets()
            result(nil)
        case "pin":
            result(false) // iOS has no API to add a widget for the user
        case "configLaunchId", "finishConfig":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func system(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let url = (call.arguments as? [String: Any])?["url"] as? String ?? ""
        guard call.method == "openUrl",
              url.hasPrefix("https://github.com/marc-frank/sun-clock/"),
              let u = URL(string: url)
        else {
            result(FlutterMethodNotImplemented)
            return
        }
        UIApplication.shared.open(u) { ok in result(ok) }
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Background location

    private var alwaysGranted: Bool {
        location.authorizationStatus == .authorizedAlways
    }

    /// Significant-change monitoring: low power, about every 500 m or more,
    /// and iOS relaunches the app for it. Only when opted in, "Always" is
    /// granted and the app uses GPS rather than a place from the map.
    private func syncLocation() {
        let want = SharedStore.backgroundOptIn && alwaysGranted &&
            (SharedStore.position()?.follow ?? false) &&
            CLLocationManager.significantLocationChangeMonitoringAvailable()
        if want {
            location.startMonitoringSignificantLocationChanges()
        } else {
            location.stopMonitoringSignificantLocationChanges()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if let r = pendingAlways, manager.authorizationStatus != .notDetermined {
            pendingAlways = nil
            r(alwaysGranted)
        }
        syncLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last,
              l.timestamp.timeIntervalSinceNow > -6 * 3600,
              let p = SharedStore.position(),
              let moved = SharedStore.moved(p, lat: l.coordinate.latitude, lon: l.coordinate.longitude)
        else { return }
        SharedStore.save(moved)
        reloadWidgets()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
