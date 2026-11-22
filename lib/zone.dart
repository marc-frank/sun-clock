// Time zone of a coordinate, offline: polygon lookup (lat_lng_to_timezone)
// plus the IANA rules bundled with the `timezone` package.

import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
// latest_all, not latest: the map's polygons use many alias and older
// names (Europe/Amsterdam, Europe/Kiev, ...) that only the full database
// has; with the smaller one those places fell back to a fixed offset
// without summer time.
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

/// Zones the map data still calls by an old name, shown by today's name.
const _renamed = {
  'Europe/Kiev': 'Europe/Kyiv',
  'Europe/Uzhgorod': 'Europe/Kyiv',
  'Europe/Zaporozhye': 'Europe/Kyiv',
  'America/Godthab': 'America/Nuuk',
  'Pacific/Enderbury': 'Pacific/Kanton',
};

void initZones() {
  if (_initialized) return;
  tzdata.initializeTimeZones();
  _initialized = true;
}

/// IANA zone for a position. Over the open sea (no polygon) this falls back
/// to the nautical zone Etc/GMT±N derived from the longitude.
tz.Location zoneAt(double lat, double lon) {
  initZones();
  try {
    final name = tzmap.latLngToTimezoneString(lat, lon);
    return tz.getLocation(_renamed[name] ?? name);
  } catch (_) {
    final h = (lon / 15).round().clamp(-12, 12);
    // Etc/GMT names have the sign inverted: Etc/GMT-1 is UTC+1.
    final name = h == 0 ? 'Etc/GMT' : 'Etc/GMT${h > 0 ? '-' : '+'}${h.abs()}';
    return tz.getLocation(name);
  }
}

/// Wall-clock time in [zone].
tz.TZDateTime inZone(DateTime t, tz.Location zone) =>
    tz.TZDateTime.from(t, zone);

/// "UTC+1", "UTC−3:30", "UTC" for the zone's offset at [t].
String utcOffsetLabel(DateTime t, tz.Location zone) {
  final off = inZone(t, zone).timeZoneOffset;
  if (off == Duration.zero) return 'UTC';
  final sign = off.isNegative ? '−' : '+';
  final m = off.inMinutes.abs();
  final mm = m % 60;
  return 'UTC$sign${m ~/ 60}${mm == 0 ? '' : ':${mm.toString().padLeft(2, '0')}'}';
}

/// Human name of a zone: "Europe/Berlin" → "Berlin".
String zoneCity(tz.Location zone) {
  final n = zone.name;
  if (n.startsWith('Etc/')) return 'Sea';
  return n.split('/').last.replaceAll('_', ' ');
}
