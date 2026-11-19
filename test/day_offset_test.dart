import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/day_offset.dart';
import 'package:sun_clock/day_offset_chart.dart';
import 'package:sun_clock/sun_clock.dart';
import 'package:sun_clock/year_data.dart';
import 'package:sun_clock/zone.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(initZones);

  const lat = 52.52, lon = 13.405; // Berlin
  late tz.Location berlin;
  setUp(() => berlin = zoneAt(lat, lon));

  test('wrapMinutes keeps differences within half a day', () {
    expect(wrapMinutes(0), 0);
    expect(wrapMinutes(719), 719);
    expect(wrapMinutes(720), -720);
    expect(wrapMinutes(-1430), 10);
    expect(wrapMinutes(1430), -10);
  });

  test('covers the whole local day, every 10 minutes', () {
    final pts = dayOffsets(DateTime.utc(2026, 6, 21), lat, lon, berlin);
    expect(pts.whereType<OffsetPoint>().length, 24 * 6 + 1);
    expect(pts.first!.hour, 0);
    expect(pts.last!.hour, 24);
    expect(pts.contains(null), isFalse);
  });

  test('matches sunClock at each sample', () {
    final date = DateTime.utc(2026, 3, 10);
    final pts = dayOffsets(date, lat, lon, berlin, stepMinutes: 60);
    for (final p in pts.whereType<OffsetPoint>().take(24)) {
      final t = tz.TZDateTime(berlin, date.year, date.month, date.day,
          p.hour.round());
      final sun = sunClock(t, lat, lon).sunTime.inMicroseconds / 6e7;
      expect(p.minutes, closeTo(wrapMinutes(sun - p.hour * 60), 1e-6));
    }
  });

  test('at sunrise sun time is 06:00 minus the local sunrise time', () {
    final date = DateTime.utc(2026, 12, 21);
    final rise = daySun(date, lat, lon, berlin).sunrise!; // ≈ 8.3 h
    final pts = dayOffsets(date, lat, lon, berlin, stepMinutes: 1);
    final near = pts
        .whereType<OffsetPoint>()
        .reduce((a, b) => (a.hour - rise).abs() < (b.hour - rise).abs() ? a : b);
    expect(near.minutes, closeTo(360 - rise * 60, 1.5));
    expect(near.minutes, lessThan(-100), reason: 'winter: sun time lags');
  });

  test('a DST change breaks the line instead of drawing back', () {
    // Berlin leaves summer time on 25 Oct 2026: 03:00 → 02:00.
    final pts = dayOffsets(DateTime.utc(2026, 10, 25), lat, lon, berlin);
    expect(pts.where((p) => p == null), hasLength(1));
    expect(pts.whereType<OffsetPoint>().length, 25 * 6 + 1);
  });

  test('axis labels', () {
    expect(offsetAxisLabel(0), '0');
    expect(offsetAxisLabel(30), '+30m');
    expect(offsetAxisLabel(-60), '−1h');
    expect(offsetAxisLabel(-90), '−1h30');
  });
}
