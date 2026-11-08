// Per-day sunrise/sunset and sun-hour lengths for a whole year, used by the
// charts below the clock.

import 'package:timezone/timezone.dart' as tz;

import 'solar.dart';
import 'zone.dart';

enum PolarState { none, polarDay, polarNight }

class DaySun {
  final DateTime date; // calendar date (UTC-midnight DateTime used as a key)

  /// Wall-clock hours in the location's zone (may exceed 24 or go below 0
  /// in unusual zones); null when the sun does not rise/set that day.
  final double? sunrise;
  final double? sunset;

  /// Real minutes per sun-hour during the day and the following night.
  final double? dayHourMinutes;
  final double? nightHourMinutes;

  final PolarState polar;

  const DaySun(this.date, this.sunrise, this.sunset, this.dayHourMinutes,
      this.nightHourMinutes, this.polar);
}

double _wallHours(DateTime utc, DateTime date, tz.Location zone) {
  final l = inZone(utc, zone);
  final dayShift =
      DateTime.utc(l.year, l.month, l.day).difference(date).inDays;
  return dayShift * 24 + l.hour + l.minute / 60 + l.second / 3600;
}

/// Sun data for one calendar [date] (only year/month/day are used).
DaySun daySun(DateTime date, double lat, double lon, tz.Location zone) {
  date = DateTime.utc(date.year, date.month, date.day);
  final next = date.add(const Duration(days: 1));
  final rise = sunEvent(date, lat, lon, rising: true);
  final set = sunEvent(date, lat, lon, rising: false);
  final nextRise = sunEvent(next, lat, lon, rising: true);

  double? dayHour;
  double? nightHour;
  if (rise != null && set != null) {
    final span = set.difference(rise);
    if (!span.isNegative && span < const Duration(hours: 24)) {
      dayHour = span.inSeconds / 60 / 12;
    }
  }
  if (set != null && nextRise != null) {
    final span = nextRise.difference(set);
    if (!span.isNegative && span < const Duration(hours: 24)) {
      nightHour = span.inSeconds / 60 / 12;
    }
  }

  var polar = PolarState.none;
  if (rise == null || set == null) {
    final noon = date.add(Duration(minutes: (720 - 4 * lon).round()));
    final decl = solarParams(julianDay(noon)).declination;
    polar = cosHourAngleSunrise(lat, decl) < -1
        ? PolarState.polarDay
        : PolarState.polarNight;
  }

  return DaySun(
    date,
    rise == null ? null : _wallHours(rise, date, zone),
    set == null ? null : _wallHours(set, date, zone),
    dayHour,
    nightHour,
    polar,
  );
}

List<DaySun> yearData(int year, double lat, double lon, tz.Location zone) {
  final out = <DaySun>[];
  for (var d = DateTime.utc(year);
      d.year == year;
      d = d.add(const Duration(days: 1))) {
    out.add(daySun(d, lat, lon, zone));
  }
  return out;
}

/// Small cache so the charts don't recompute on every rebuild.
class YearDataCache {
  String? _key;
  List<DaySun>? _data;

  List<DaySun> get(int year, double lat, double lon, tz.Location zone) {
    final key = '$year ${lat.toStringAsFixed(4)} ${lon.toStringAsFixed(4)} '
        '${zone.name}';
    if (key != _key) {
      _data = yearData(year, lat, lon, zone);
      _key = key;
    }
    return _data!;
  }
}
