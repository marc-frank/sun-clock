// Home-screen and Lock Screen widgets (WidgetKit). The app stores the
// position, the settings and the texts in the shared App Group
// (SharedStore); this computes sun time itself (SunCalc.swift) and hands
// WidgetKit a timeline with an entry at every sun-minute and every real
// minute for the next two hours.

import SwiftUI
import WidgetKit

struct SunProvider: TimelineProvider {
    func placeholder(in context: Context) -> SunEntry {
        SunEntry(date: Date(), reading: nil, settings: WidgetSettings(),
                 texts: WidgetTexts(t: [:]), place: "", hasPosition: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SunEntry) -> Void) {
        completion(entries(from: Date(), limit: 1)[0])
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SunEntry>) -> Void) {
        let list = entries(from: Date(), limit: 240)
        completion(Timeline(entries: list, policy: .after(list.last!.date)))
    }

    func entries(from start: Date, limit: Int) -> [SunEntry] {
        let pos = SharedStore.position()
        let settings = WidgetSettings(SharedStore.config())
        let texts = WidgetTexts(t: SharedStore.texts())
        let now = Int64(start.timeIntervalSince1970 * 1000)
        let data = pos.map { SolarCalc.build(lat: $0.lat, lon: $0.lon, now: now) }

        // Every real minute (for the local clock) and every sun-minute.
        let end = now + 2 * 3_600_000
        var times = Set<Int64>([now])
        var m = (now / 60_000 + 1) * 60_000
        while m < end { times.insert(m); m += 60_000 }
        if let data = data {
            var t = now
            while t < end, times.count < 600, let r = SunTime.read(t, data) {
                t = SunTime.nextMinute(after: t, r)
                times.insert(t)
            }
        }
        return times.sorted().prefix(limit).map { ms in
            SunEntry(date: Date(timeIntervalSince1970: Double(ms) / 1000),
                     reading: data.flatMap { SunTime.read(ms, $0) },
                     settings: settings, texts: texts,
                     place: pos?.label ?? "", hasPosition: pos != nil)
        }
    }
}

struct SunClockWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SunEntry

    var body: some View {
        switch family {
        case .accessoryInline: InlineWidgetView(entry: entry)
        case .accessoryCircular: CircularWidgetView(entry: entry)
        case .accessoryRectangular: RectangularWidgetView(entry: entry)
        default: HomeWidgetView(entry: entry)
        }
    }
}

struct SunClockWidget: Widget {
    let kind = "SunClockWidget"

    var body: some WidgetConfiguration {
        let t = WidgetTexts(t: SharedStore.texts())
        return StaticConfiguration(kind: kind, provider: SunProvider()) { entry in
            SunClockWidgetView(entry: entry)
        }
        .configurationDisplayName(t.s("nameSun", "Sun time"))
        .description(t.s("description", "Sun time and local time, with sunrise, sunset and more"))
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct SunClockWidgets: WidgetBundle {
    var body: some Widget {
        SunClockWidget()
    }
}
