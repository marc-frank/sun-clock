import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/light_hours.dart';
import 'package:sun_clock/year_data.dart';
import 'package:sun_clock/zone.dart';

void main() {
  setUpAll(initZones);

  test('Berlin in June: blue, then golden around sunrise and sunset', () {
    const lat = 52.52, lon = 13.405;
    final zone = zoneAt(lat, lon);
    final date = DateTime.utc(2026, 6, 21);
    final h = lightHours(date, lat, lon, zone);
    final day = daySun(date, lat, lon, zone);
    expect(h.golden, hasLength(2));
    expect(h.blue, hasLength(2));

    double local(DateTime t) {
      final l = inZone(t, zone);
      return l.hour + l.minute / 60 + l.second / 3600;
    }

    final [mBlue, eBlue] = h.blue;
    final [mGold, eGold] = h.golden;
    // Morning: blue hour runs into golden hour, which spans sunrise.
    expect(mBlue.end, mGold.start);
    expect(local(mGold.start), lessThan(day.sunrise!));
    expect(local(mGold.end), greaterThan(day.sunrise!));
    // Evening: golden hour spans sunset and runs into blue hour.
    expect(local(eGold.start), lessThan(day.sunset!));
    expect(local(eGold.end), greaterThan(day.sunset!));
    expect(eGold.end, eBlue.start);
    // Plausible lengths for Berlin in June.
    expect(
        mBlue.end.difference(mBlue.start).inMinutes, inInclusiveRange(10, 40));
    expect(
        mGold.end.difference(mGold.start).inMinutes, inInclusiveRange(60, 120));
  });

  test('on the dial the morning golden band contains 06:00', () {
    const lat = 52.52, lon = 13.405;
    final zone = zoneAt(lat, lon);
    final h = lightHours(DateTime.utc(2026, 3, 20), lat, lon, zone);
    final bands = dialBands(h, lat, lon);
    final morningGold =
        bands.firstWhere((b) => b.color == goldenColor && b.start < 12);
    expect(morningGold.start, lessThan(6));
    expect(morningGold.end, greaterThan(6));
    final eveningBlue =
        bands.lastWhere((b) => b.color == blueHourColor && b.start > 12);
    expect(eveningBlue.start, greaterThan(18));
  });

  test('Tromsø in December: one long golden twilight or none, no crash', () {
    const lat = 69.65, lon = 18.96;
    final h =
        lightHours(DateTime.utc(2026, 12, 21), lat, lon, zoneAt(lat, lon));
    expect(h.golden.length, lessThanOrEqualTo(1));
  });

  test('Tromsø at midsummer: no golden or blue hour (polar day)', () {
    const lat = 69.65, lon = 18.96;
    final h = lightHours(DateTime.utc(2026, 6, 21), lat, lon, zoneAt(lat, lon));
    expect(h.blue, isEmpty);
  });
}
