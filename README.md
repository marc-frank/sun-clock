# Sun Clock

A Flutter app (Android, iOS) that shows **sun time**: a 24-hour clock whose
hours are stretched so that sunrise is always 06:00 and sunset always 18:00.
The 12 day hours split the real daylight evenly, and the 12 night hours split
the real night evenly. The current UTC time is shown alongside.

Scroll down for charts of the year: sunrise and sunset times, and how long
one day hour and one night hour last. The map button lets you pick any place
on an OpenStreetMap map. The clock and charts follow the pin live, and the
picked place is remembered.

## Code

| File | What it does |
| --- | --- |
| `lib/solar.dart` | NOAA sunrise/sunset formula, ported column by column from `NOAA_Solar_Calculations_*.xls` |
| `lib/sun_clock.dart` | UTC instant + position → sun time (solar-time fallback in polar day/night) |
| `lib/year_data.dart` | Per-day sunrise, sunset and hour lengths for a year |
| `lib/zone.dart` | Offline time zone for a coordinate (`lat_lng_to_timezone` + `timezone`) |
| `lib/location_model.dart` | GPS or map-picked position, saved with `shared_preferences` |
| `lib/clock_view.dart` | Dial, sun time, UTC |
| `lib/year_charts.dart` | Year charts (`fl_chart`) |
| `lib/map_picker.dart` | Map picker with a live preview (`flutter_map`) |

## Develop

```bash
flutter test
flutter run
```

## Release

The Android release signing key is read from `android/key.properties`,
which is not in git. Without that file, release builds are signed with the
debug key.

```bash
flutter build apk --release        # sideloadable APK
flutter build appbundle --release  # for Google Play
```

App icons: `python tool/make_icon.py` draws the images in `assets/icon/`,
then `dart run flutter_launcher_icons` generates the platform icons. The
themed (monochrome) Android icon layer in `res/drawable-*` is added by hand.

Map data © OpenStreetMap contributors.
