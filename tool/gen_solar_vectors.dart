// Regenerates test/solar_vectors.json from the Dart implementation.
//
//   dart run tool/gen_solar_vectors.dart
//
// The vectors are read by test/solar_vectors_test.dart and by the Kotlin
// port's SolarVectorsTest, so the two implementations cannot drift apart.
// Only regenerate after a deliberate change to the formulas, and check the
// diff: the Boulder 2010-06-21 case must still match the NOAA spreadsheet
// (test/sun_clock_test.dart).
//
// For every case, sunrise, sunset and solar noon are those of the UTC date of
// `instant`; declination and equation of time are evaluated at `instant`;
// the sun-clock reading is taken at `instant`.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:sun_clock/solar.dart';
import 'package:sun_clock/sun_clock.dart';

/// (name, instant, lat, lon)
const cases = <(String, String, double, double)>[
  // NOAA spreadsheet sanity row: Boulder, first row of the day sheet.
  ('boulder-noaa-row', '2010-06-21T06:06:00Z', 40.0, -105.0),
  ('boulder-solstice-day', '2010-06-21T18:00:00Z', 40.0, -105.0),
  // Equator.
  ('equator-equinox-day', '2026-03-20T17:00:00Z', 0.0, -78.5),
  ('equator-equinox-night', '2026-09-23T00:00:00Z', 0.0, 0.0),
  // Mid-latitudes north.
  ('berlin-november-day', '2026-11-08T12:00:00Z', 52.52, 13.405),
  ('berlin-november-night', '2026-11-08T20:00:00Z', 52.52, 13.405),
  ('berlin-summer-morning', '2026-06-21T03:00:00Z', 52.52, 13.405),
  // Mid-latitudes south.
  ('sydney-january-day', '2026-01-15T03:00:00Z', -33.87, 151.21),
  ('sydney-july-night', '2026-07-15T12:00:00Z', -33.87, 151.21),
  ('buenos-aires-june-day', '2026-06-21T15:00:00Z', -34.6, -58.4),
  // Near the Arctic circle and around the days the sun stops rising/setting.
  ('rovaniemi-june-solstice', '2026-06-21T10:00:00Z', 66.5, 25.7),
  ('rovaniemi-december-solstice', '2026-12-21T10:00:00Z', 66.5, 25.7),
  ('tromso-before-polar-night', '2026-11-25T10:30:00Z', 69.65, 18.96),
  ('tromso-polar-night-start', '2026-11-28T10:30:00Z', 69.65, 18.96),
  ('tromso-polar-night-solar-noon', '2026-12-21T10:45:00Z', 69.65, 18.96),
  ('tromso-after-polar-night', '2027-01-15T10:45:00Z', 69.65, 18.96),
  ('tromso-before-midnight-sun', '2026-05-17T21:30:00Z', 69.65, 18.96),
  ('tromso-midnight-sun', '2026-05-23T21:30:00Z', 69.65, 18.96),
  // Near the Antarctic circle.
  ('antarctic-circle-june', '2026-06-21T03:00:00Z', -66.6, 140.0),
  ('antarctic-circle-december', '2026-12-21T12:00:00Z', -66.6, 140.0),
  // Polar day and night.
  ('svalbard-polar-day', '2026-06-21T12:00:00Z', 78.22, 15.65),
  ('svalbard-polar-day-late', '2026-06-21T22:00:00Z', 78.22, 15.65),
  ('svalbard-polar-night', '2026-12-21T12:00:00Z', 78.22, 15.65),
  ('mcmurdo-polar-day', '2026-12-21T00:30:00Z', -77.85, 166.67),
  ('mcmurdo-polar-night', '2026-06-21T01:00:00Z', -77.85, 166.67),
  // Longitudes near +-180.
  ('fiji-morning', '2026-02-10T22:00:00Z', -18.0, 178.4),
  ('samoa-noon', '2026-02-10T23:00:00Z', -13.8, -171.8),
  ('dateline-east-noon', '2026-08-01T00:10:00Z', 10.0, 179.9),
  ('dateline-west-day', '2026-08-01T23:50:00Z', 10.0, -179.9),
  ('dateline-west-polar-night', '2026-12-21T23:00:00Z', 72.0, -179.5),
  ('dateline-east-polar-day', '2026-06-21T00:30:00Z', 71.0, 179.5),
];

String? _iso(DateTime? t) => t?.toUtc().toIso8601String();

void main() {
  final out = <Map<String, Object?>>[];
  for (final (name, iso, lat, lon) in cases) {
    final instant = DateTime.parse(iso).toUtc();
    final jd = julianDay(instant);
    final p = solarParams(jd);
    final noon = solarNoon(instant, lon);
    final r = sunClock(instant, lat, lon);
    // In the fallback the Kotlin service uses the nearest solar noon, the
    // Dart app the noon of the instant's UTC date. They agree (to the ms)
    // only within 12 h of that noon, so keep fallback cases there.
    if (r.mode == SunClockMode.solarTimeFallback &&
        instant.difference(noon).abs() >= const Duration(hours: 12)) {
      throw StateError('$name: fallback instant 12 h or more from solar noon');
    }
    out.add({
      'name': name,
      'instant': _iso(instant),
      'lat': lat,
      'lon': lon,
      'julianDay': jd,
      'declination': p.declination,
      'equationOfTime': p.equationOfTime,
      'sunrise': _iso(sunEvent(instant, lat, lon, rising: true)),
      'sunset': _iso(sunEvent(instant, lat, lon, rising: false)),
      'solarNoon': _iso(noon),
      'sunClock': {
        'sunTimeMs': r.sunTime.inMicroseconds / 1000,
        'isDay': r.isDay,
        'mode': r.mode == SunClockMode.normal ? 'normal' : 'fallback',
        'realMinutesPerSunHour': r.realMinutesPerSunHour,
        'next': _iso(r.next?.time),
        'nextIsSunrise': r.next?.isSunrise,
      },
    });
  }
  final json = const JsonEncoder.withIndent('  ').convert({
    'generator': 'tool/gen_solar_vectors.dart',
    'cases': out,
  });
  File('test/solar_vectors.json').writeAsStringSync('$json\n');
  print('Wrote ${out.length} cases to test/solar_vectors.json');
}
