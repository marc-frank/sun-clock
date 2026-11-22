// The widget's views and its information line; the same rules as
// SunWidget.kt and the app's preview (lib/widget_editor.dart). Plain
// SwiftUI, so tool/ios/render_widget.swift can render them on CI.

import SwiftUI
import WidgetKit

/// Texts in the app's language, sent by the app (SharedStore.texts), with
/// English fallbacks for a widget placed before the app was opened.
struct WidgetTexts {
    let t: [String: String]

    func s(_ key: String, _ fallback: String, _ slots: [String: String] = [:]) -> String {
        var r = t[key] ?? fallback
        for (k, v) in slots { r = r.replacingOccurrences(of: "{\(k)}", with: v) }
        return r
    }
}

/// One widget's settings; keys and defaults as lib/home_widget.dart.
struct WidgetSettings {
    var clocks = "sun"
    var layout = "stacked"
    var first = "sun"
    var labels = false
    var dayNight = true
    var next = true
    var hourLength = false
    var offset = false
    var place = false
    var progress = false
    var background: UInt32 = 0xFF1C_1B17
    var autoColors = true
    var timeColor: UInt32 = 0xFFFF_FFFF
    var textColor: UInt32 = 0xB3FF_FFFF

    init() {}

    init(_ d: [String: Any]) {
        func s(_ k: String, _ allowed: Set<String>, _ def: String) -> String {
            if let v = d[k] as? String, allowed.contains(v) { return v }
            return def
        }
        func b(_ k: String, _ def: Bool) -> Bool { d[k] as? Bool ?? def }
        func c(_ k: String, _ def: UInt32) -> UInt32 {
            if let n = d[k] as? NSNumber { return UInt32(truncatingIfNeeded: n.int64Value) }
            return def
        }
        clocks = s("clocks", ["sun", "local", "both"], clocks)
        layout = s("layout", ["stacked", "side"], layout)
        first = s("first", ["sun", "local"], first)
        labels = b("labels", labels)
        dayNight = b("dayNight", dayNight)
        next = b("next", next)
        hourLength = b("hourLength", hourLength)
        offset = b("offset", offset)
        place = b("place", place)
        progress = b("progress", progress)
        background = c("background", background)
        autoColors = b("autoColors", autoColors)
        timeColor = c("timeColor", timeColor)
        textColor = c("textColor", textColor)
    }

    var both: Bool { clocks == "both" }
    var side: Bool { both && layout == "side" }
    var primaryIsSun: Bool { both ? first != "local" : clocks != "local" }
    var showsSun: Bool { clocks != "local" }
}

func argb(_ v: UInt32) -> Color {
    Color(.sRGB,
          red: Double((v >> 16) & 0xFF) / 255,
          green: Double((v >> 8) & 0xFF) / 255,
          blue: Double(v & 0xFF) / 255,
          opacity: Double(v >> 24) / 255)
}

let dayColor = argb(0xFFFF_B300)
let nightColor = argb(0xFF9F_A8DA)

struct SunEntry: TimelineEntry {
    let date: Date
    let reading: SunReading?
    let settings: WidgetSettings
    let texts: WidgetTexts
    let place: String
    let hasPosition: Bool
}

enum WidgetText {
    static func sun(_ r: SunReading?) -> String {
        guard let r = r else { return "--:--" }
        let total = Int(r.sunMinutes.rounded(.down))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    static var uses24Hour: Bool {
        !(DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "")
            .contains("a")
    }

    /// Large clocks leave out AM/PM (as on Android); the small one keeps it.
    static func local(_ d: Date, large: Bool) -> String {
        let f = DateFormatter()
        if large {
            f.dateFormat = uses24Hour ? "HH:mm" : "h:mm"
        } else {
            f.timeStyle = .short
        }
        return f.string(from: d)
    }

    /// How much of the current day (06:00–18:00 sun time) or night has passed.
    static func progress(_ m: Double) -> Double {
        m >= 360 && m < 1080 ? (m - 360) / 720 : ((m - 1080).truncatingRemainder(dividingBy: 1440) + 1440)
            .truncatingRemainder(dividingBy: 1440) / 720
    }

    /// The information line, as SunWidget.kt builds it.
    static func detail(_ e: SunEntry) -> String {
        let t = e.texts, c = e.settings
        guard e.hasPosition, let r = e.reading else {
            return c.showsSun ? t.s("noPosition", "Open Sun Clock to set a location") : ""
        }
        var parts: [String] = []
        if c.dayNight { parts.append(r.isDay ? t.s("day", "Day") : t.s("night", "Night")) }
        if c.next {
            if let n = r.next {
                let f = DateFormatter()
                f.timeStyle = .short
                let at = f.string(from: Date(timeIntervalSince1970: Double(n.0) / 1000))
                parts.append(n.1 ? t.s("sunriseAt", "sunrise {time}", ["time": at])
                    : t.s("sunsetAt", "sunset {time}", ["time": at]))
            } else {
                parts.append(t.s("solar", "solar time"))
            }
        }
        if c.hourLength, let h = r.realMinutesPerHour {
            let n = "\(Int(h.rounded()))"
            parts.append(r.isDay ? t.s("dayHour", "day hour = {n} min", ["n": n])
                : t.s("nightHour", "night hour = {n} min", ["n": n]))
        }
        if c.offset {
            let cal = Calendar.current.dateComponents([.hour, .minute, .second], from: e.date)
            let local = Double(cal.hour! * 60 + cal.minute!) + Double(cal.second!) / 60
            var d = (r.sunMinutes - local + 720).truncatingRemainder(dividingBy: 1440)
            if d < 0 { d += 1440 }
            let m = Int((d - 720).rounded())
            let a = abs(m)
            let dur = a < 60 ? t.s("minutes", "{n} min", ["n": "\(a)"])
                : t.s("hoursMinutes", "{h} h {m} min", ["h": "\(a / 60)", "m": "\(a % 60)"])
            parts.append(m > 0 ? t.s("offsetAhead", "sun time {d} ahead", ["d": dur])
                : m < 0 ? t.s("offsetBehind", "sun time {d} behind", ["d": dur])
                : t.s("offsetSame", "sun time in step"))
        }
        if c.place && !e.place.isEmpty { parts.append(e.place) }
        return parts.joined(separator: " · ")
    }
}

extension View {
    /// iOS 17 draws the background itself (and leaves it out where the
    /// system wants, e.g. StandBy); before that the view paints it.
    @ViewBuilder func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            containerBackground(color, for: .widget)
        } else {
            padding(8).background(color)
        }
    }
}

struct HomeWidgetView: View {
    let entry: SunEntry

    var body: some View {
        let c = entry.settings, t = entry.texts, r = entry.reading
        let timeColor = c.autoColors ? (r?.isDay == true ? dayColor : nightColor) : argb(c.timeColor)
        let textColor = argb(c.textColor)
        let detail = WidgetText.detail(entry)

        func name(_ sun: Bool) -> String {
            sun ? t.s("nameSun", "Sun time") : t.s("nameLocal", "Local time")
        }
        func clock(_ sun: Bool) -> some View {
            VStack(spacing: 0) {
                Text(sun ? WidgetText.sun(r) : WidgetText.local(entry.date, large: true))
                    .font(.system(size: 64, weight: .medium))
                    .monospacedDigit()
                    .minimumScaleFactor(0.2)
                    .lineLimit(1)
                    .foregroundColor(timeColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if c.labels {
                    Text(name(sun)).font(.system(size: 10)).lineLimit(1).foregroundColor(textColor)
                }
            }
        }

        return VStack(spacing: 2) {
            HStack(spacing: 6) {
                clock(c.primaryIsSun)
                if c.side { clock(!c.primaryIsSun) }
            }
            if c.both && !c.side {
                let sun = !c.primaryIsSun
                HStack(spacing: 6) {
                    if c.labels { Text(name(sun)) }
                    Text(sun ? WidgetText.sun(r) : WidgetText.local(entry.date, large: false))
                        .monospacedDigit()
                }
                .font(.system(size: 14))
                .foregroundColor(textColor)
            }
            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            if c.progress, let r = r {
                ProgressView(value: WidgetText.progress(r.sunMinutes))
                    .tint(timeColor)
            }
        }
        .widgetBackground(argb(c.background))
    }
}

/// Lock Screen: one line next to the date.
struct InlineWidgetView: View {
    let entry: SunEntry
    var body: some View {
        Text("☀︎ \(WidgetText.sun(entry.reading))")
            .widgetBackground(.clear)
    }
}

/// Lock Screen: the sun time inside a ring for the day or night so far.
struct CircularWidgetView: View {
    let entry: SunEntry
    var body: some View {
        ZStack {
            if let r = entry.reading {
                Circle().stroke(lineWidth: 4).opacity(0.25)
                Circle()
                    .trim(from: 0, to: WidgetText.progress(r.sunMinutes))
                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text(WidgetText.sun(entry.reading))
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
        }
        .padding(2)
        .widgetBackground(.clear)
    }
}

/// Lock Screen: sun time large, the information line below.
struct RectangularWidgetView: View {
    let entry: SunEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(WidgetText.sun(entry.reading))
                    .font(.system(size: 30, weight: .semibold))
                    .monospacedDigit()
                Text(entry.texts.s("nameSun", "Sun time"))
                    .font(.caption)
                    .lineLimit(1)
            }
            Text(WidgetText.detail(entry))
                .font(.caption)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetBackground(.clear)
    }
}
