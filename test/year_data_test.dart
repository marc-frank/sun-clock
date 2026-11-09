import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/year_data.dart';
import 'package:sun_clock/zone.dart';

void main() {
  test('time zone lookup and DST', () {
    final berlin = zoneAt(52.52, 13.405);
    expect(berlin.name, 'Europe/Berlin');
    expect(inZone(DateTime.utc(2026, 7, 1), berlin).timeZoneOffset.inHours, 2);
    expect(inZone(DateTime.utc(2026, 1, 1), berlin).timeZoneOffset.inHours, 1);
    expect(zoneAt(40.7128, -74.006).name, 'America/New_York');
    // Open ocean still resolves to some zone (the lookup picks the nearest).
    expect(zoneAt(-40, -130).name, isNotEmpty);
  });

  test('Berlin year: plausible sunrise, sunset and hour lengths', () {
    final zone = zoneAt(52.52, 13.405);
    final days = yearData(2026, 52.52, 13.405, zone);
    expect(days.length, 365);
    final dec21 = days[DateTime.utc(2026, 12, 21).difference(DateTime.utc(2026)).inDays];
    expect(dec21.sunrise!, closeTo(8 + 15 / 60, 0.1)); // ~08:15 CET
    expect(dec21.sunset!, closeTo(15 + 54 / 60, 0.1)); // ~15:54 CET
    expect(dec21.dayHourMinutes!, closeTo(38.3, 1));
    expect(dec21.dayHourMinutes! + dec21.nightHourMinutes!, closeTo(120, 1));
    final jun21 = days[DateTime.utc(2026, 6, 21).difference(DateTime.utc(2026)).inDays];
    expect(jun21.sunrise!, closeTo(4 + 43 / 60, 0.1)); // ~04:43 CEST
    expect(jun21.dayHourMinutes!, greaterThan(80));
    expect(days.every((d) => d.polar == PolarState.none), isTrue);
  });

  // Kiritimati (157° W) uses UTC+14, a day ahead of the sun; the year's
  // sunrises used to land on the next local day (30:00 and later) and fell
  // off the chart.
  test('a zone across the date line keeps times on the local day', () {
    for (final (lat, lon) in const [(1.87, -157.4), (0.0, -170.0), (-50.0, -160.0)]) {
      final zone = zoneAt(lat, lon);
      final days = yearData(2026, lat, lon, zone);
      for (final d in days) {
        expect(d.sunrise!, inInclusiveRange(0, 24), reason: '$lat $lon ${d.date}');
        expect(d.sunset!, inInclusiveRange(0, 24), reason: '$lat $lon ${d.date}');
        expect(d.dayHourMinutes, isNotNull);
        expect(d.nightHourMinutes, isNotNull);
      }
    }
    // Kiritimati itself: sunrise around 06:20, sunset around 18:30.
    final k = yearData(2026, 1.87, -157.4, zoneAt(1.87, -157.4));
    expect(zoneAt(1.87, -157.4).name, 'Pacific/Kiritimati');
    expect(k[170].sunrise!, closeTo(6.4, 0.5));
    expect(k[170].sunset!, closeTo(18.5, 0.5));
  });

  test('Tromsø has polar day and polar night', () {
    final zone = zoneAt(69.65, 18.96);
    final days = yearData(2026, 69.65, 18.96, zone);
    expect(days.any((d) => d.polar == PolarState.polarDay), isTrue);
    expect(days.any((d) => d.polar == PolarState.polarNight), isTrue);
    expect(days[180].sunrise, isNull);
  });
}
