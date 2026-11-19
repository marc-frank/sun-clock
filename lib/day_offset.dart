// How far sun time runs ahead of (+) or behind (−) the local clock over one
// local calendar day. At sunrise the gap is 06:00 minus the local sunrise
// time, at sunset 18:00 minus the local sunset time, and in between it
// changes steadily because sun hours are longer or shorter than real ones.

import 'package:timezone/timezone.dart' as tz;

import 'sun_clock.dart';
import 'zone.dart';

class OffsetPoint {
  /// Local wall-clock hour, 0–24.
  final double hour;

  /// Sun time minus local time, in minutes, in [−720, 720).
  final double minutes;

  const OffsetPoint(this.hour, this.minutes);
}

/// Wraps a difference of two times of day into [−720, 720) minutes.
double wrapMinutes(double m) => ((m + 720) % 1440 + 1440) % 1440 - 720;

/// Sun time minus local time, sampled every [stepMinutes] over the local
/// calendar day [date] (year/month/day only) in [zone]. A null entry marks a
/// break in the line: the wall clock jumped (a DST change) or the
/// difference wrapped around half a day.
List<OffsetPoint?> dayOffsets(
    DateTime date, double lat, double lon, tz.Location zone,
    {int stepMinutes = 10}) {
  final start = tz.TZDateTime(zone, date.year, date.month, date.day);
  final end = tz.TZDateTime(zone, date.year, date.month, date.day + 1);
  final startUtc = start.toUtc(), endUtc = end.toUtc();
  final events = sunEventsAround(
      startUtc.add(endUtc.difference(startUtc) ~/ 2), lat, lon,
      days: 2);
  final step = Duration(minutes: stepMinutes);

  final out = <OffsetPoint?>[];
  OffsetPoint? last;
  for (var t = startUtc; !t.isAfter(endUtc); t = t.add(step)) {
    final local = inZone(t, zone);
    final hour = t.isAtSameMomentAs(endUtc)
        ? 24.0
        : local.hour + local.minute / 60 + local.second / 3600;
    final sun = sunClockWithEvents(t, events, lat, lon).sunTime;
    final minutes = wrapMinutes(
        sun.inMicroseconds / Duration.microsecondsPerMinute - hour * 60);
    final p = OffsetPoint(hour, minutes);
    if (last != null &&
        (hour < last.hour ||
            hour - last.hour > stepMinutes / 60 + 1e-6 ||
            (minutes - last.minutes).abs() > 360)) {
      out.add(null);
    }
    out.add(p);
    last = p;
  }
  return out;
}

/// Sun time minus local time at [now], in minutes.
double offsetAt(DateTime now, double lat, double lon, tz.Location zone) {
  final local = inZone(now, zone);
  final sun = sunClock(now, lat, lon).sunTime;
  return wrapMinutes(sun.inMicroseconds / Duration.microsecondsPerMinute -
      (local.hour * 60 + local.minute + local.second / 60));
}

/// Cache for [dayOffsets], keyed by day and place.
class DayOffsetCache {
  String? _key;
  List<OffsetPoint?>? _data;

  List<OffsetPoint?> get(
      DateTime date, double lat, double lon, tz.Location zone) {
    final key = '${date.year}-${date.month}-${date.day} '
        '${lat.toStringAsFixed(4)} ${lon.toStringAsFixed(4)} ${zone.name}';
    if (key != _key) {
      _data = dayOffsets(date, lat, lon, zone);
      _key = key;
    }
    return _data!;
  }
}
