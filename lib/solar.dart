// NOAA solar calculations, ported from NOAA_Solar_Calculations_day.xls /
// NOAA_Solar_Calculations_year.xls (columns F..Z of the "Calculations" sheet).
//
// All angles are in degrees unless noted. Longitude is + to the East.

import 'dart:math' as math;

double _rad(double deg) => deg * math.pi / 180.0;
double _deg(double rad) => rad * 180.0 / math.pi;

/// Julian Day for a UTC instant.
double julianDay(DateTime t) =>
    t.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;

DateTime _fromJulianDay(double jd) => DateTime.fromMillisecondsSinceEpoch(
    ((jd - 2440587.5) * 86400000.0).round(),
    isUtc: true);

/// Intermediate NOAA quantities needed for sunrise / sunset.
class SolarParams {
  /// Sun declination (deg), spreadsheet column T.
  final double declination;

  /// Equation of time (minutes), spreadsheet column V.
  final double equationOfTime;

  const SolarParams(this.declination, this.equationOfTime);
}

/// Spreadsheet columns G..V for a given Julian Day.
SolarParams solarParams(double jd) {
  final t = (jd - 2451545) / 36525; // G: Julian Century
  final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360; // I
  final m = 357.52911 + t * (35999.05029 - 0.0001537 * t); // J
  final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t); // K
  final c = math.sin(_rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
      math.sin(_rad(2 * m)) * (0.019993 - 0.000101 * t) +
      math.sin(_rad(3 * m)) * 0.000289; // L: Eq of Ctr
  final trueLong = l0 + c; // M
  final appLong = trueLong -
      0.00569 -
      0.00478 * math.sin(_rad(125.04 - 1934.136 * t)); // P
  final meanObliq = 23 +
      (26 + ((21.448 - t * (46.815 + t * (0.00059 - t * 0.001813)))) / 60) /
          60; // Q
  final obliqCorr =
      meanObliq + 0.00256 * math.cos(_rad(125.04 - 1934.136 * t)); // R
  final decl = _deg(math.asin(
      math.sin(_rad(obliqCorr)) * math.sin(_rad(appLong)))); // T
  final y = math.pow(math.tan(_rad(obliqCorr / 2)), 2).toDouble(); // U
  final eqTime = 4 *
      _deg(y * math.sin(2 * _rad(l0)) -
          2 * e * math.sin(_rad(m)) +
          4 * e * y * math.sin(_rad(m)) * math.cos(2 * _rad(l0)) -
          0.5 * y * y * math.sin(4 * _rad(l0)) -
          1.25 * e * e * math.sin(2 * _rad(m))); // V
  return SolarParams(decl, eqTime);
}

/// Cosine of the sunrise hour angle (before acos), spreadsheet column W.
/// > 1: sun never rises (polar night); < -1: sun never sets (polar day).
double cosHourAngleSunrise(double latitude, double declination) =>
    math.cos(_rad(90.833)) /
        (math.cos(_rad(latitude)) * math.cos(_rad(declination))) -
    math.tan(_rad(latitude)) * math.tan(_rad(declination));

/// HA Sunrise (deg), spreadsheet column W, or null if there is no
/// sunrise/sunset on that day.
double? hourAngleSunrise(double latitude, double declination) {
  final c = cosHourAngleSunrise(latitude, declination);
  if (c < -1 || c > 1) return null;
  return _deg(math.acos(c));
}

/// Result of the spreadsheet calculation for one row, times as fraction of a
/// day in local standard time (columns X, Y, Z).
class SpreadsheetRow {
  final double solarNoon;
  final double? sunrise;
  final double? sunset;
  const SpreadsheetRow(this.solarNoon, this.sunrise, this.sunset);
}

/// Exactly what one row of the NOAA spreadsheet computes: all parameters are
/// evaluated at the single instant [jd]. Used to validate the port.
SpreadsheetRow spreadsheetRow(
    double jd, double latitude, double longitude, double timeZone) {
  final p = solarParams(jd);
  final noon =
      (720 - 4 * longitude - p.equationOfTime + timeZone * 60) / 1440; // X
  final ha = hourAngleSunrise(latitude, p.declination);
  if (ha == null) return SpreadsheetRow(noon, null, null);
  return SpreadsheetRow(noon, noon - ha * 4 / 1440, noon + ha * 4 / 1440);
}

/// Sunrise (rising == true) or sunset as a UTC instant, for the solar day
/// whose noon falls nearest to [utcDate]'s 12:00 UTC shifted by longitude.
///
/// Unlike the spreadsheet (which evaluates the sun's position once, at the
/// row's time), this re-evaluates the formula at the event itself, which is
/// a few seconds more accurate. Returns null when the sun does not rise/set.
DateTime? sunEvent(DateTime utcDate, double latitude, double longitude,
    {required bool rising}) {
  final day = DateTime.utc(utcDate.year, utcDate.month, utcDate.day);
  final dayJd = julianDay(day);
  // Start from approximate local solar noon.
  double minutes = 720 - 4 * longitude;
  for (var i = 0; i < 4; i++) {
    final p = solarParams(dayJd + minutes / 1440);
    final ha = hourAngleSunrise(latitude, p.declination);
    if (ha == null) return null;
    minutes = 720 -
        4 * (longitude + (rising ? ha : -ha)) -
        p.equationOfTime;
  }
  return _fromJulianDay(dayJd + minutes / 1440);
}

/// Solar noon as a UTC instant for the solar day of [utcDate].
DateTime solarNoon(DateTime utcDate, double longitude) {
  final day = DateTime.utc(utcDate.year, utcDate.month, utcDate.day);
  final dayJd = julianDay(day);
  double minutes = 720 - 4 * longitude;
  for (var i = 0; i < 3; i++) {
    minutes = 720 - 4 * longitude - solarParams(dayJd + minutes / 1440).equationOfTime;
  }
  return _fromJulianDay(dayJd + minutes / 1440);
}
