// Renders the widget views to PNG files on CI (macOS), since there is no
// iPhone or simulator home screen to look at them on:
//   swiftc -parse-as-library ios/SunClockWidget/SunCalc.swift \
//     ios/SunClockWidget/SharedStore.swift ios/SunClockWidget/WidgetViews.swift \
//     tool/ios/render_widget.swift -o render && ./render out/

import AppKit
import SwiftUI
import WidgetKit

@main
struct Render {
    @MainActor static func main() {
        let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
        try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

        // Berlin, 21 Nov 2026 15:30 UTC (16:30 local): just after sunset.
        let now = Int64(1_795_275_000_000)
        let data = SolarCalc.build(lat: 52.52, lon: 13.405, now: now)
        let reading = SunTime.read(now, data)
        let date = Date(timeIntervalSince1970: Double(now) / 1000)
        let texts = WidgetTexts(t: [:])

        func entry(_ s: WidgetSettings) -> SunEntry {
            SunEntry(date: date, reading: reading, settings: s, texts: texts,
                     place: "Berlin", hasPosition: true)
        }

        var both = WidgetSettings()
        both.clocks = "both"
        both.layout = "side"
        both.labels = true
        both.progress = true
        both.offset = true
        var stacked = WidgetSettings()
        stacked.clocks = "both"
        stacked.labels = true
        stacked.place = true
        stacked.background = 0xFFFF_F8E1
        stacked.textColor = 0xDE00_0000

        // Outside a widget, containerBackground and the system's 16 pt content
        // margins don't apply: add both by hand for the home-screen sizes.
        func home(_ s: WidgetSettings) -> AnyView {
            AnyView(HomeWidgetView(entry: entry(s)).padding(16).background(argb(s.background)))
        }
        let views: [(String, AnyView, CGSize)] = [
            ("small-default", home(WidgetSettings()), CGSize(width: 170, height: 170)),
            ("medium-side", home(both), CGSize(width: 364, height: 170)),
            ("small-stacked-light", home(stacked), CGSize(width: 170, height: 170)),
            ("lock-rectangular", AnyView(RectangularWidgetView(entry: entry(WidgetSettings()))), CGSize(width: 172, height: 76)),
            ("lock-circular", AnyView(CircularWidgetView(entry: entry(WidgetSettings()))), CGSize(width: 76, height: 76)),
            ("lock-inline", AnyView(InlineWidgetView(entry: entry(WidgetSettings()))), CGSize(width: 200, height: 24)),
        ]
        for (name, view, size) in views {
            let framed = view
                .frame(width: size.width, height: size.height)
                .background(Color(white: 0.35))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .environment(\.colorScheme, .dark)
            let r = ImageRenderer(content: framed)
            r.scale = 3
            guard let img = r.nsImage, let tiff = img.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:])
            else { print("could not render \(name)"); exit(1) }
            try! png.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
            print("rendered \(name)")
        }
        print("sun time \(WidgetText.sun(reading)), detail: \(WidgetText.detail(entry(both)))")
    }
}
