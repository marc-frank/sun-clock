import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:sun_clock/zone.dart';

/// The map's polygons name some zones by aliases or old names; they must
/// resolve to real zones with their summer time, not a fixed offset.
void main() {
  setUpAll(initZones);

  for (final (lat, lon, name) in const [
    (50.45, 30.52, 'Europe/Kyiv'), // Kyiv; the map says Europe/Kiev
    (49.84, 24.03, 'Europe/Kyiv'), // Lviv
    (46.48, 30.73, 'Europe/Kyiv'), // Odesa
    (52.37, 4.90, 'Europe/Amsterdam'),
    (59.33, 18.07, 'Europe/Stockholm'),
    (55.68, 12.57, 'Europe/Copenhagen'),
    (55.75, 37.62, 'Europe/Moscow'),
    (64.18, -51.72, 'America/Nuuk'),
  ]) {
    test('$lat,$lon is $name', () {
      expect(zoneAt(lat, lon).name, name);
    });
  }

  test('Kyiv has summer time', () {
    final kyiv = zoneAt(50.45, 30.52);
    expect(tz.TZDateTime(kyiv, 2026, 1, 15).timeZoneOffset.inHours, 2);
    expect(tz.TZDateTime(kyiv, 2026, 7, 15).timeZoneOffset.inHours, 3);
  });
}
