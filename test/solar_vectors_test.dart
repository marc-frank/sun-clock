// Checks lib/solar.dart and lib/sun_clock.dart against test/solar_vectors.json.
// The Kotlin port (android/.../SolarVectorsTest.kt) reads the same file, so
// the two implementations cannot drift apart. Regenerate the file with
// `dart run tool/gen_solar_vectors.dart` only after a deliberate change.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/solar.dart';
import 'package:sun_clock/sun_clock.dart';

const _timeToleranceMs = 5;

void _expectTime(DateTime? actual, Object? expected, String what) {
  if (expected == null) {
    expect(actual, isNull, reason: what);
    return;
  }
  expect(actual, isNotNull, reason: what);
  final diff = actual!.difference(DateTime.parse(expected as String));
  expect(diff.inMilliseconds.abs(), lessThanOrEqualTo(_timeToleranceMs),
      reason: '$what: $actual vs $expected');
}

void main() {
  final file = File('test/solar_vectors.json');
  final cases = (jsonDecode(file.readAsStringSync())
          as Map<String, dynamic>)['cases'] as List<dynamic>;

  test('vector file covers polar, equatorial and date-line cases', () {
    expect(cases.length, greaterThanOrEqualTo(20));
    final modes = cases.map((c) => c['sunClock']['mode']).toSet();
    expect(modes, containsAll(['normal', 'fallback']));
  });

  for (final c in cases.cast<Map<String, dynamic>>()) {
    test(c['name'], () {
      final instant = DateTime.parse(c['instant'] as String);
      final lat = (c['lat'] as num).toDouble();
      final lon = (c['lon'] as num).toDouble();

      final jd = julianDay(instant);
      expect(jd, closeTo((c['julianDay'] as num).toDouble(), 1e-9));
      final p = solarParams(jd);
      expect(p.declination, closeTo((c['declination'] as num).toDouble(), 1e-9));
      expect(p.equationOfTime,
          closeTo((c['equationOfTime'] as num).toDouble(), 1e-9));

      _expectTime(sunEvent(instant, lat, lon, rising: true), c['sunrise'],
          'sunrise');
      _expectTime(sunEvent(instant, lat, lon, rising: false), c['sunset'],
          'sunset');
      _expectTime(solarNoon(instant, lon), c['solarNoon'], 'solar noon');

      final s = c['sunClock'] as Map<String, dynamic>;
      final r = sunClock(instant, lat, lon);
      expect(r.mode == SunClockMode.normal ? 'normal' : 'fallback', s['mode']);
      expect(r.isDay, s['isDay']);
      expect(r.sunTime.inMicroseconds / 1000,
          closeTo((s['sunTimeMs'] as num).toDouble(), _timeToleranceMs));
      expect(r.realMinutesPerSunHour,
          closeTo((s['realMinutesPerSunHour'] as num).toDouble(), 1e-4));
      _expectTime(r.next?.time, s['next'], 'next event');
      expect(r.next?.isSunrise, s['nextIsSunrise']);
    });
  }
}
