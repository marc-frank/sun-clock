// "Sun time": a 24-hour clock whose hours are stretched so that sunrise is
// always 06:00 and sunset always 18:00. The 12 day hours divide the real
// daylight span evenly and the 12 night hours divide the real night evenly.

import 'solar.dart';

enum SunClockMode {
  /// Normal case: time lies between a sunrise and a sunset (or vice versa).
  normal,

  /// Polar day/night (or a sun event more than a day away): the clock falls
  /// back to apparent solar time, 12:00 = solar noon, with equal hours.
  solarTimeFallback,
}

class SunEvent {
  final DateTime time; // UTC
  final bool isSunrise;
  const SunEvent(this.time, this.isSunrise);
}

class SunClockReading {
  /// Sun time since sun-midnight, in [0, 24h).
  final Duration sunTime;

  /// True between sunrise and sunset.
  final bool isDay;

  /// How many real minutes one sun-hour currently lasts.
  final double realMinutesPerSunHour;

  /// The bracketing sun events (null in fallback mode).
  final SunEvent? previous;
  final SunEvent? next;

  final SunClockMode mode;

  const SunClockReading({
    required this.sunTime,
    required this.isDay,
    required this.realMinutesPerSunHour,
    required this.previous,
    required this.next,
    required this.mode,
  });
}

/// All sunrises and sunsets for the solar days around [nowUtc], sorted.
List<SunEvent> sunEventsAround(DateTime nowUtc, double lat, double lon,
    {int days = 2}) {
  final events = <SunEvent>[];
  final base = nowUtc.toUtc();
  for (var d = -days; d <= days; d++) {
    final day = base.add(Duration(days: d));
    final rise = sunEvent(day, lat, lon, rising: true);
    final set = sunEvent(day, lat, lon, rising: false);
    if (rise != null) events.add(SunEvent(rise, true));
    if (set != null) events.add(SunEvent(set, false));
  }
  events.sort((a, b) => a.time.compareTo(b.time));
  return events;
}

const _sunHour = Duration.microsecondsPerHour;

SunClockReading sunClock(DateTime now, double lat, double lon) {
  final nowUtc = now.toUtc();
  final (prev, next) = _bracket(sunEventsAround(nowUtc, lat, lon), nowUtc);
  return _reading(nowUtc, prev, next, lat, lon);
}

/// [sunClock] with the sun events already computed (by [sunEventsAround]
/// for a time near [now]), for reading the clock at many instants.
SunClockReading sunClockWithEvents(
    DateTime now, List<SunEvent> events, double lat, double lon) {
  final nowUtc = now.toUtc();
  final (prev, next) = _bracket(events, nowUtc);
  return _reading(nowUtc, prev, next, lat, lon);
}

/// The last event at or before [nowUtc] and the first one after it.
(SunEvent?, SunEvent?) _bracket(List<SunEvent> events, DateTime nowUtc) {
  SunEvent? prev;
  for (final e in events) {
    if (e.time.isAfter(nowUtc)) return (prev, e);
    prev = e;
  }
  return (prev, null);
}

/// Sun time at [nowUtc] between the bracketing events [prev] and [next].
SunClockReading _reading(DateTime nowUtc, SunEvent? prev, SunEvent? next,
    double lat, double lon) {
  if (prev != null &&
      next != null &&
      prev.isSunrise != next.isSunrise &&
      next.time.difference(prev.time) < const Duration(hours: 24)) {
    final span = next.time.difference(prev.time).inMicroseconds;
    final elapsed = nowUtc.difference(prev.time).inMicroseconds;
    final startHour = prev.isSunrise ? 6 : 18;
    // Fraction first: 12h * elapsed in microseconds would overflow 64 bits.
    final fraction = elapsed / span;
    final micros = (startHour * _sunHour + fraction * 12 * _sunHour).round() %
        (24 * _sunHour);
    return SunClockReading(
      sunTime: Duration(microseconds: micros),
      isDay: prev.isSunrise,
      realMinutesPerSunHour: span / 12 / Duration.microsecondsPerMinute,
      previous: prev,
      next: next,
      mode: SunClockMode.normal,
    );
  }

  // Fallback: apparent solar time, 12:00 at solar noon.
  final noon = solarNoon(nowUtc, lon);
  final micros = (12 * _sunHour + nowUtc.difference(noon).inMicroseconds) %
      (24 * _sunHour);
  return SunClockReading(
    sunTime: Duration(microseconds: micros),
    isDay: lat * _declinationSign(nowUtc) > 0,
    realMinutesPerSunHour: 60,
    previous: null,
    next: null,
    mode: SunClockMode.solarTimeFallback,
  );
}

/// [sunClock] for a clock that is read several times a second: the sun
/// events are computed once and reused until the position changes or the
/// time passes the next event (or leaves the bracketing pair otherwise).
class SunClockCache {
  double? _lat;
  double? _lon;
  SunEvent? _prev;
  SunEvent? _next;
  DateTime? _validFrom;
  DateTime? _validUntil;

  /// How often the events are recomputed when there is no next event
  /// (polar day or night).
  static const polarRecheck = Duration(hours: 1);

  SunClockReading read(DateTime now, double lat, double lon) {
    final nowUtc = now.toUtc();
    if (lat != _lat ||
        lon != _lon ||
        nowUtc.isBefore(_validFrom!) ||
        !nowUtc.isBefore(_validUntil!)) {
      final (prev, next) =
          _bracket(sunEventsAround(nowUtc, lat, lon), nowUtc);
      _prev = prev;
      _next = next;
      _lat = lat;
      _lon = lon;
      _validFrom = _prev?.time ?? nowUtc;
      _validUntil = _next?.time ?? nowUtc.add(polarRecheck);
    }
    return _reading(nowUtc, _prev, _next, lat, lon);
  }
}

double _declinationSign(DateTime utc) =>
    solarParams(julianDay(utc)).declination;

/// The instants in [from, to) at which the clock reads [sunTime]: the
/// inverse of [sunClock]. Usually one per day, but a local day that is
/// shorter or longer than a sun day (DST changes, or days and nights
/// changing length) can hold none or two. Where the clock falls back to
/// solar time (polar day or night), the inverse uses solar time too.
List<DateTime> instantsForSunTime(
    Duration sunTime, DateTime from, DateTime to, double lat, double lon) {
  final fromUtc = from.toUtc(), toUtc = to.toUtc();
  final target = sunTime.inMicroseconds % (24 * _sunHour);
  bool inRange(DateTime t) => !t.isBefore(fromUtc) && t.isBefore(toUtc);
  final out = <DateTime>[];

  // Normal segments: sunrise → sunset covers 06:00–18:00, sunset → sunrise
  // 18:00–06:00 (across sun-midnight), each stretched over its real span.
  final mid = fromUtc.add(toUtc.difference(fromUtc) ~/ 2);
  final days = toUtc.difference(fromUtc).inDays + 2;
  final events = sunEventsAround(mid, lat, lon, days: days);
  for (var i = 0; i + 1 < events.length; i++) {
    final a = events[i], b = events[i + 1];
    final span = b.time.difference(a.time);
    if (a.isSunrise == b.isSunrise || span >= const Duration(hours: 24)) {
      continue;
    }
    final start = (a.isSunrise ? 6 : 18) * _sunHour;
    final offset = (target - start) % (24 * _sunHour);
    if (offset >= 12 * _sunHour) continue;
    final t = a.time.add(Duration(
        microseconds: (span.inMicroseconds * (offset / (12 * _sunHour)))
            .round()));
    if (inRange(t)) out.add(t);
  }

  // Solar-time fallback: the clock measures from the solar noon of the UTC
  // date it is read on, so each UTC date has exactly one candidate. Keep it
  // only where the clock really is in fallback mode.
  for (var d = DateTime.utc(fromUtc.year, fromUtc.month, fromUtc.day - 1);
      d.isBefore(toUtc);
      d = d.add(const Duration(days: 1))) {
    final noon = solarNoon(d, lon).difference(d).inMicroseconds;
    final t = d.add(Duration(
        microseconds: (noon - 12 * _sunHour + target) % (24 * _sunHour)));
    if (inRange(t) &&
        sunClock(t, lat, lon).mode == SunClockMode.solarTimeFallback) {
      out.add(t);
    }
  }
  out.sort();
  return out;
}
