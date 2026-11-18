import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/solar.dart';
import 'package:sun_clock/sun_clock.dart';
import 'package:sun_clock/zone.dart';
import 'package:timezone/timezone.dart' as tz;

/// instantsForSunTime is the inverse of sunClock within one local day.
void main() {
  setUpAll(initZones);

  const lat = 52.52, lon = 13.405; // Berlin
  late tz.Location berlin;
  setUpAll(() => berlin = zoneAt(lat, lon));

  List<DateTime> onLocalDay(Duration sun, int y, int m, int d,
      {double la = lat, double lo = lon, tz.Location? zone}) {
    zone ??= berlin;
    return instantsForSunTime(sun, tz.TZDateTime(zone, y, m, d),
        tz.TZDateTime(zone, y, m, d + 1), la, lo);
  }

  // Sun time difference in seconds, across midnight.
  int offBy(Duration a, Duration b) {
    final d = (a - b).inSeconds % 86400;
    return d > 43200 ? 86400 - d : d;
  }

  test('round-trips every ten minutes of a day', () {
    for (var min = 0; min < 24 * 60; min += 10) {
      final t = tz.TZDateTime(berlin, 2026, 11, 18, 0, min);
      final sun = sunClock(t, lat, lon).sunTime;
      final back = onLocalDay(sun, 2026, 11, 18);
      expect(back.where((b) => b.difference(t).inSeconds.abs() <= 1),
          hasLength(1),
          reason: 'local ${t.hour}:${t.minute}, got $back');
    }
  });

  test('a night sun time can fall after local midnight', () {
    // November: night from about 16:15 to 07:30, so sun 03:00 is ~03:40.
    final r = onLocalDay(const Duration(hours: 3), 2026, 11, 18);
    expect(r, hasLength(1));
    final local = inZone(r.single, berlin);
    expect(local.day, 18);
    expect(local.hour, inInclusiveRange(2, 4));
    expect(offBy(sunClock(r.single, lat, lon).sunTime,
            const Duration(hours: 3)), lessThanOrEqualTo(1));
    // Sun 22:00 the same night belongs to the evening before midnight.
    final evening = inZone(
        onLocalDay(const Duration(hours: 22), 2026, 11, 18).single, berlin);
    expect(evening.hour, inInclusiveRange(20, 23));
  });

  Map<int, int> occurrences(int y, int m, int d) => {
        for (var min = 0; min < 24 * 60; min += 5)
          min: onLocalDay(Duration(minutes: min), y, m, d).length,
      };

  test('spring DST day (23 h) skips some sun times, never doubles', () {
    final n = occurrences(2026, 3, 29);
    expect(n.values.where((c) => c == 0), isNotEmpty);
    expect(n.values.where((c) => c > 1), isEmpty);
    // Sun noon is still found once, an hour later on the clock than in winter.
    final noon = onLocalDay(const Duration(hours: 12), 2026, 3, 29).single;
    expect(inZone(noon, berlin).hour, 13);
  });

  test('autumn DST day (25 h) repeats some sun times, never skips', () {
    final n = occurrences(2026, 10, 25);
    expect(n.values.where((c) => c == 2), isNotEmpty);
    expect(n.values.where((c) => c == 0), isEmpty);
    for (final e in n.entries) {
      for (final t in onLocalDay(Duration(minutes: e.key), 2026, 10, 25)) {
        expect(offBy(sunClock(t, lat, lon).sunTime, Duration(minutes: e.key)),
            lessThanOrEqualTo(1));
      }
    }
  });

  test('polar day uses solar time', () {
    const sLat = 78.22, sLon = 15.65; // Longyearbyen
    final zone = zoneAt(sLat, sLon);
    final r = onLocalDay(const Duration(hours: 12), 2026, 6, 21,
        la: sLat, lo: sLon, zone: zone);
    expect(r, hasLength(1));
    final reading = sunClock(r.single, sLat, sLon);
    expect(reading.mode, SunClockMode.solarTimeFallback);
    expect(offBy(reading.sunTime, const Duration(hours: 12)),
        lessThanOrEqualTo(1));
    expect(r.single.difference(solarNoon(DateTime.utc(2026, 6, 21), sLon))
        .inSeconds
        .abs(), lessThan(2));
    // Every hour of a polar day is found exactly once.
    for (var h = 0; h < 24; h++) {
      final t = onLocalDay(Duration(hours: h), 2026, 6, 21,
          la: sLat, lo: sLon, zone: zone);
      expect(t, hasLength(1), reason: 'sun $h:00');
      expect(offBy(sunClock(t.single, sLat, sLon).sunTime, Duration(hours: h)),
          lessThanOrEqualTo(1));
    }
  });
}
