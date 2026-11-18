import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/sun_clock.dart';

/// The cached clock must read exactly like the pure function.
void main() {
  void sweep(double lat, double lon, DateTime start, Duration step, int n) {
    final cache = SunClockCache();
    var t = start;
    for (var i = 0; i < n; i++) {
      final a = cache.read(t, lat, lon);
      final b = sunClock(t, lat, lon);
      expect(a.sunTime, b.sunTime, reason: 'at $t');
      expect(a.isDay, b.isDay);
      expect(a.mode, b.mode);
      expect(a.previous?.time, b.previous?.time);
      expect(a.next?.time, b.next?.time);
      t = t.add(step);
    }
  }

  test('matches sunClock over three days in Berlin', () {
    sweep(52.52, 13.405, DateTime.utc(2026, 11, 17), const Duration(minutes: 7),
        3 * 24 * 60 ~/ 7);
  });

  test('matches sunClock into and out of polar night', () {
    // Tromsø: the sun stops rising in late November.
    sweep(69.65, 18.96, DateTime.utc(2026, 11, 20), const Duration(minutes: 37),
        8 * 24 * 60 ~/ 37);
  });

  test('follows a new position at once', () {
    final cache = SunClockCache();
    final t = DateTime.utc(2026, 6, 1, 12);
    cache.read(t, 52.52, 13.405);
    expect(cache.read(t, -33.87, 151.21).sunTime,
        sunClock(t, -33.87, 151.21).sunTime);
  });

  test('handles time going backwards', () {
    final cache = SunClockCache();
    final t = DateTime.utc(2026, 6, 1, 12);
    cache.read(t, 52.52, 13.405);
    final earlier = t.subtract(const Duration(hours: 20));
    expect(cache.read(earlier, 52.52, 13.405).sunTime,
        sunClock(earlier, 52.52, 13.405).sunTime);
  });
}
