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

  test('Tromsø has polar day and polar night', () {
    final zone = zoneAt(69.65, 18.96);
    final days = yearData(2026, 69.65, 18.96, zone);
    expect(days.any((d) => d.polar == PolarState.polarDay), isTrue);
    expect(days.any((d) => d.polar == PolarState.polarNight), isTrue);
    expect(days[180].sunrise, isNull);
  });
}
