// NOAA sunrise/sunset and sun time for the iOS widget: a line-by-line port
// of android/.../SolarCalc.kt and SunTime.kt (themselves ports of
// lib/solar.dart and lib/sun_clock.dart). Checked against
// test/solar_vectors.json on CI (tool/ios/vectors_test.swift). Plain
// Foundation, so it also compiles outside the widget.

import Foundation

enum SolarCalc {
    static let dayMs: Int64 = 86_400_000

    static func rad(_ d: Double) -> Double { d * .pi / 180 }
    static func deg(_ r: Double) -> Double { r * 180 / .pi }

    static func julianDay(_ utcMillis: Int64) -> Double {
        Double(utcMillis) / 86_400_000.0 + 2_440_587.5
    }

    static func fromJulianDay(_ jd: Double) -> Int64 {
        Int64(((jd - 2_440_587.5) * 86_400_000.0).rounded())
    }

    /// (declination deg, equation of time minutes), spreadsheet columns T and V.
    static func solarParams(_ jd: Double) -> (Double, Double) {
        let t = (jd - 2451545) / 36525
        let l0 = (280.46646 + t * (36000.76983 + t * 0.0003032))
            .truncatingRemainder(dividingBy: 360)
        let l0p = l0 < 0 ? l0 + 360 : l0
        let m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let c = sin(rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
            sin(rad(2 * m)) * (0.019993 - 0.000101 * t) +
            sin(rad(3 * m)) * 0.000289
        let trueLong = l0p + c
        let appLong = trueLong - 0.00569 - 0.00478 * sin(rad(125.04 - 1934.136 * t))
        let meanObliq = 23 + (26 + ((21.448 - t * (46.815 + t * (0.00059 - t * 0.001813)))) / 60) / 60
        let obliqCorr = meanObliq + 0.00256 * cos(rad(125.04 - 1934.136 * t))
        let decl = deg(asin(sin(rad(obliqCorr)) * sin(rad(appLong))))
        let y = pow(tan(rad(obliqCorr / 2)), 2)
        let eqTime = 4 * deg(
            y * sin(2 * rad(l0p)) -
                2 * e * sin(rad(m)) +
                4 * e * y * sin(rad(m)) * cos(2 * rad(l0p)) -
                0.5 * y * y * sin(4 * rad(l0p)) -
                1.25 * e * e * sin(2 * rad(m))
        )
        return (decl, eqTime)
    }

    static func hourAngle(lat: Double, decl: Double, zenith: Double = 90.833) -> Double? {
        let c = cos(rad(zenith)) / (cos(rad(lat)) * cos(rad(decl))) - tan(rad(lat)) * tan(rad(decl))
        if c < -1 || c > 1 { return nil }
        return deg(acos(c))
    }

    static func dayStart(_ utcMillis: Int64) -> Int64 {
        let q = utcMillis / dayMs
        return (utcMillis % dayMs < 0 ? q - 1 : q) * dayMs
    }

    /// Sunrise or sunset (UTC millis) of the solar day of [utcMillis]'s UTC date.
    static func sunEvent(_ utcMillis: Int64, lat: Double, lon: Double, rising: Bool) -> Int64? {
        let dayJd = julianDay(dayStart(utcMillis))
        var minutes = 720 - 4 * lon
        for _ in 0..<4 {
            let (decl, eqTime) = solarParams(dayJd + minutes / 1440)
            guard let ha = hourAngle(lat: lat, decl: decl) else { return nil }
            minutes = 720 - 4 * (lon + (rising ? ha : -ha)) - eqTime
        }
        return fromJulianDay(dayJd + minutes / 1440)
    }

    static func solarNoon(_ utcMillis: Int64, lon: Double) -> Int64 {
        let dayJd = julianDay(dayStart(utcMillis))
        var minutes = 720 - 4 * lon
        for _ in 0..<3 {
            minutes = 720 - 4 * lon - solarParams(dayJd + minutes / 1440).1
        }
        return fromJulianDay(dayJd + minutes / 1440)
    }

    /// Sun events and noons from yesterday to [days] days ahead.
    static func build(lat: Double, lon: Double, now: Int64, days: Int = 3) -> SunData {
        var events: [(Int64, Bool)] = []
        var noons: [Int64] = []
        for d in -1...days {
            let day = now + Int64(d) * dayMs
            if let r = sunEvent(day, lat: lat, lon: lon, rising: true) { events.append((r, true)) }
            if let s = sunEvent(day, lat: lat, lon: lon, rising: false) { events.append((s, false)) }
            noons.append(solarNoon(day, lon: lon))
        }
        events.sort { $0.0 < $1.0 }
        return SunData(events: events, noons: noons, lat: lat)
    }
}

/// Sun events computed for one position.
struct SunData {
    /// (utcMillis, isSunrise), sorted by time.
    let events: [(Int64, Bool)]
    let noons: [Int64]
    let lat: Double
}

struct SunReading {
    /// Sun time in minutes since sun-midnight, in [0, 1440).
    let sunMinutes: Double
    let isDay: Bool
    /// Real milliseconds per sun-minute right now.
    let msPerSunMinute: Double
    /// Next sunrise/sunset, nil in the polar fallback.
    let next: (Int64, Bool)?
    /// Real minutes per sun-hour, nil in the fallback.
    let realMinutesPerHour: Double?
}

enum SunTime {
    /// Same rule as lib/sun_clock.dart: sunrise → sunset spreads 06:00–18:00
    /// evenly, sunset → sunrise 18:00–06:00; without such a pair (polar day
    /// or night) apparent solar time, 12:00 at solar noon.
    static func read(_ now: Int64, _ data: SunData) -> SunReading? {
        var prev: (Int64, Bool)?
        var next: (Int64, Bool)?
        for e in data.events {
            if e.0 <= now { prev = e } else { next = e; break }
        }
        if let p = prev, let n = next, p.1 != n.1, n.0 - p.0 < SolarCalc.dayMs {
            let span = Double(n.0 - p.0)
            let frac = Double(now - p.0) / span
            let start = p.1 ? 360.0 : 1080.0
            return SunReading(
                sunMinutes: (start + 720.0 * frac).truncatingRemainder(dividingBy: 1440),
                isDay: p.1,
                msPerSunMinute: span / 720.0,
                next: n,
                realMinutesPerHour: span / 12.0 / 60000.0)
        }
        guard let noon = data.noons.min(by: { abs($0 - now) < abs($1 - now) }) else { return nil }
        var m = (720.0 + Double(now - noon) / 60000.0).truncatingRemainder(dividingBy: 1440)
        if m < 0 { m += 1440 }
        return SunReading(
            sunMinutes: m,
            isDay: data.lat * SolarCalc.solarParams(SolarCalc.julianDay(now)).0 > 0,
            msPerSunMinute: 60000.0,
            next: nil,
            realMinutesPerHour: nil)
    }

    /// The real instant (millis) at which the sun-minute after [r] begins,
    /// for the widget's timeline.
    static func nextMinute(after now: Int64, _ r: SunReading) -> Int64 {
        let toNext = (1.0 - (r.sunMinutes - r.sunMinutes.rounded(.down))) * r.msPerSunMinute
        return now + Int64(toNext.rounded(.up)) + 50
    }
}
