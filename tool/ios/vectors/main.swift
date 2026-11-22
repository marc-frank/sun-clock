// Checks ios/SunClockWidget/SunCalc.swift against test/solar_vectors.json,
// the vectors the Dart and Kotlin versions are checked against. Run on CI:
//   swiftc ios/SunClockWidget/SunCalc.swift tool/ios/vectors/main.swift -o vt
//   ./vt test/solar_vectors.json

import Foundation

func ms(_ iso: String) -> Int64 {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return Int64((f.date(from: iso)!.timeIntervalSince1970 * 1000).rounded())
}

var failures = 0
func check(_ what: String, _ ok: Bool) {
    if !ok { failures += 1; print("FAIL \(what)") }
}
func near(_ a: Double, _ b: Double, _ tol: Double) -> Bool { abs(a - b) <= tol }

func checkTime(_ what: String, _ expected: Any?, _ actual: Int64?) {
    if expected == nil || expected is NSNull {
        check("\(what) should be nil", actual == nil)
        return
    }
    guard let a = actual else { check("\(what) missing", false); return }
    check("\(what) \(a) vs \(expected!)", near(Double(ms(expected as! String)), Double(a), 5))
}

let path = CommandLine.arguments[1]
let root = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as! [String: Any]
let cases = root["cases"] as! [[String: Any]]
var modes = Set<String>()
for c in cases {
    let name = c["name"] as! String
    let now = ms(c["instant"] as! String)
    let lat = c["lat"] as! Double, lon = c["lon"] as! Double

    let jd = SolarCalc.julianDay(now)
    check("\(name) julianDay", near(jd, c["julianDay"] as! Double, 1e-9))
    let (decl, eq) = SolarCalc.solarParams(jd)
    check("\(name) declination", near(decl, c["declination"] as! Double, 1e-9))
    check("\(name) equationOfTime", near(eq, c["equationOfTime"] as! Double, 1e-9))
    checkTime("\(name) sunrise", c["sunrise"], SolarCalc.sunEvent(now, lat: lat, lon: lon, rising: true))
    checkTime("\(name) sunset", c["sunset"], SolarCalc.sunEvent(now, lat: lat, lon: lon, rising: false))
    checkTime("\(name) solarNoon", c["solarNoon"], SolarCalc.solarNoon(now, lon: lon))

    let s = c["sunClock"] as! [String: Any]
    let mode = s["mode"] as! String
    modes.insert(mode)
    guard let r = SunTime.read(now, SolarCalc.build(lat: lat, lon: lon, now: now, days: 14)) else {
        check("\(name) reading", false); continue
    }
    let fallback = mode == "fallback"
    check("\(name) mode", fallback == (r.realMinutesPerHour == nil))
    check("\(name) isDay", (s["isDay"] as! Bool) == r.isDay)
    check("\(name) sunTime", near(s["sunTimeMs"] as! Double, r.sunMinutes * 60_000, 5))
    if !fallback {
        check("\(name) realMinutesPerSunHour",
              near(s["realMinutesPerSunHour"] as! Double, r.realMinutesPerHour!, 1e-4))
    }
    checkTime("\(name) next", s["next"], r.next?.0)
    if let ns = s["nextIsSunrise"] as? Bool { check("\(name) nextIsSunrise", ns == r.next?.1) }
}
check("covers both modes", modes == ["normal", "fallback"])
print("\(cases.count) cases, \(failures) failures")
exit(failures == 0 ? 0 : 1)
