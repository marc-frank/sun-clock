// What the app hands to the widget, in the shared App Group: the position,
// the widget settings (same keys as lib/home_widget.dart and
// WidgetConfig.kt) and the widget's texts in the app's language. Used by
// both the app (Runner) and the widget extension.

import Foundation

enum SharedStore {
    static let defaultGroup = "group.com.sunriseclock.sunClock"

    /// Sideloading tools (AltStore, SideStore) re-sign the app under the
    /// installer's team and rename its app groups; they list the real ones
    /// in the Info.plist key ALTAppGroups. The extension looks in its own
    /// Info.plist and in the containing app's.
    static let groupId: String = {
        if let g = (Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String])?.first {
            return g
        }
        let appInfo = Bundle.main.bundleURL
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Info.plist")
        if let d = NSDictionary(contentsOf: appInfo),
           let g = (d["ALTAppGroups"] as? [String])?.first {
            return g
        }
        return defaultGroup
    }()

    static var defaults: UserDefaults { UserDefaults(suiteName: groupId) ?? .standard }

    struct Position: Equatable {
        var lat: Double
        var lon: Double
        /// Place name from the app's time-zone lookup; coordinates once the
        /// phone moved far.
        var label: String
        /// The app uses GPS (not a place picked on the map).
        var follow: Bool
        var precise: Bool
    }

    static func position() -> Position? {
        let d = defaults
        guard d.object(forKey: "lat") != nil, d.object(forKey: "lon") != nil else { return nil }
        return Position(
            lat: d.double(forKey: "lat"), lon: d.double(forKey: "lon"),
            label: d.string(forKey: "label") ?? "",
            follow: d.bool(forKey: "follow"), precise: d.bool(forKey: "precise"))
    }

    static func save(_ p: Position) {
        let d = defaults
        d.set(p.lat, forKey: "lat")
        d.set(p.lon, forKey: "lon")
        d.set(p.label, forKey: "label")
        d.set(p.follow, forKey: "follow")
        d.set(p.precise, forKey: "precise")
    }

    /// Widget settings; one set for all widgets on iOS.
    static func config() -> [String: Any] {
        defaults.dictionary(forKey: "widgetConfig") ?? [:]
    }

    static func saveConfig(_ c: [String: Any]) {
        defaults.set(c, forKey: "widgetConfig")
    }

    /// Texts in the app's language, with {time}, {d}, {n}, {h}, {m} slots.
    static func texts() -> [String: String] {
        (defaults.dictionary(forKey: "widgetTexts") as? [String: String]) ?? [:]
    }

    static func saveTexts(_ t: [String: String]) {
        defaults.set(t, forKey: "widgetTexts")
    }

    /// The user opted in to following the location in the background.
    static var backgroundOptIn: Bool {
        get { defaults.bool(forKey: "backgroundLocation") }
        set { defaults.set(newValue, forKey: "backgroundLocation") }
    }

    /// The stored position moved to (lat, lon), or nil when it hasn't moved
    /// enough or the app uses a place picked on the map. Same rule as
    /// LocationFollower.kt.
    static func moved(_ p: Position, lat latitude: Double, lon longitude: Double) -> Position? {
        if !p.follow { return nil }
        var lat = latitude, lon = longitude
        if !p.precise { // same rounding as the app: about 1 km
            lat = (lat * 100).rounded() / 100
            lon = (lon * 100).rounded() / 100
        }
        let threshold = p.precise ? 0.002 : 0.01
        if abs(lat - p.lat) < threshold && abs(lon - p.lon) < threshold { return nil }
        let far = abs(lat - p.lat) > 0.25 || abs(lon - p.lon) > 0.25
        let label = (far || p.label.isEmpty) ? coordLabel(lat, lon, precise: p.precise) : p.label
        return Position(lat: lat, lon: lon, label: label, follow: p.follow, precise: p.precise)
    }

    static func coordLabel(_ lat: Double, _ lon: Double, precise: Bool) -> String {
        let f = precise ? "%.3f" : "%.2f"
        let ns = lat >= 0 ? "N" : "S", ew = lon >= 0 ? "E" : "W"
        return "\(String(format: f, abs(lat)))° \(ns) \(String(format: f, abs(lon)))° \(ew)"
    }
}
