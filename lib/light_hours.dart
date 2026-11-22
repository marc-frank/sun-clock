// Golden hour and blue hour, as photographers use them: golden hour while
// the sun's centre is between 6° above and 4° below the horizon, blue hour
// while it is between 4° and 6° below. Each happens in the morning and in
// the evening of a local day.

import 'dart:ui' show Color;

import 'package:timezone/timezone.dart' as tz;

import 'solar.dart';
import 'sun_clock.dart';
import 'year_data.dart';
import 'zone.dart';

const goldenColor = Color(0xFFFFB74D);
const blueHourColor = Color(0xFF5C7CFA);

/// One golden or blue period, as UTC instants.
class LightPeriod {
  final DateTime start;
  final DateTime end;
  const LightPeriod(this.start, this.end);
}

class LightHours {
  /// Morning first; empty where the sun doesn't cross the angles (polar
  /// day or night). When the sun stays below 6° all day (high latitudes in
  /// winter) the golden hour is one period from morning to evening.
  final List<LightPeriod> golden;
  final List<LightPeriod> blue;
  const LightHours(this.golden, this.blue);
}

/// Golden and blue hours of the local calendar day [date] in [zone].
LightHours lightHours(DateTime date, double lat, double lon, tz.Location zone) {
  final d =
      sunDateFor(DateTime.utc(date.year, date.month, date.day), lon, zone);
  DateTime? at(double elevation, bool rising) =>
      sunAtElevation(d, lat, lon, elevation, rising: rising);

  LightPeriod? span(DateTime? a, DateTime? b) =>
      a != null && b != null && b.isAfter(a) ? LightPeriod(a, b) : null;

  final blueUp = at(-6, true), lowUp = at(-4, true), highUp = at(6, true);
  final highDown = at(6, false),
      lowDown = at(-4, false),
      blueDown = at(-6, false);

  final golden = <LightPeriod?>[
    if (highUp == null && highDown == null)
      span(lowUp, lowDown) // the sun never climbs past 6°
    else ...[
      span(lowUp, highUp),
      span(highDown, lowDown),
    ],
  ].whereType<LightPeriod>().toList();
  final blue = [span(blueUp, lowUp), span(lowDown, blueDown)]
      .whereType<LightPeriod>()
      .toList();
  return LightHours(golden, blue);
}

/// A band on the dial: from [start] to [end] in sun-time hours (0–24; the
/// band may run past midnight, then [end] < [start]).
class DialBand {
  final double start;
  final double end;
  final Color color;
  const DialBand(this.start, this.end, this.color);
}

double _sunHours(DateTime t, double lat, double lon) =>
    sunClock(t, lat, lon).sunTime.inMicroseconds / Duration.microsecondsPerHour;

/// The periods as bands on the sun-time dial.
List<DialBand> dialBands(LightHours h, double lat, double lon) => [
      for (final p in h.blue)
        DialBand(_sunHours(p.start, lat, lon), _sunHours(p.end, lat, lon),
            blueHourColor),
      for (final p in h.golden)
        DialBand(_sunHours(p.start, lat, lon), _sunHours(p.end, lat, lon),
            goldenColor),
    ];

/// Caches [lightHours] and [dialBands] for the clock, which reads them four
/// times a second; they change with the local day and the place.
class LightHoursCache {
  String? _key;
  LightHours? _hours;
  List<DialBand>? _bands;

  (LightHours, List<DialBand>) get(
      DateTime now, double lat, double lon, tz.Location zone) {
    final local = inZone(now, zone);
    final key = '${local.year}-${local.month}-${local.day} '
        '${lat.toStringAsFixed(4)} ${lon.toStringAsFixed(4)} ${zone.name}';
    if (key != _key) {
      _hours = lightHours(local, lat, lon, zone);
      _bands = dialBands(_hours!, lat, lon);
      _key = key;
    }
    return (_hours!, _bands!);
  }
}
