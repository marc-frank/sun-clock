# Sun Clock

A Flutter app (Android, iOS) that shows **sun time**: a 24-hour clock whose
hours are stretched so that sunrise is always 06:00 and sunset always 18:00.
The 12 day hours split the real daylight evenly, and the 12 night hours split
the real night evenly. The current UTC time is shown alongside.

Scroll down for charts of the year: sunrise and sunset times, and how long
one day hour and one night hour last. Under the charts is an OpenStreetMap
panel to pick any place, so the charts can be watched changing while you drag;
it can be maximized to a full-screen map (also behind the map button). The
clock and charts follow the pin live, and the picked place is remembered.

On Android there is also a home-screen widget (`SunWidget.kt`) with the sun
time, day or night, and the next sunrise or sunset. It uses the last position
the app stored, so open the app once after installing. It updates with
non-wakeup alarms at each sun-minute while the screen is on (no exact-alarm
permission; to about a second), and from the status-bar service when that
is on.

The status-bar clock follows the phone's location with the while-in-use
permission. After a reboot Android does not give that to a service started
in the background, so it uses the last position until the app is opened,
unless "Follow location after a restart" is on in Settings: that asks for
background location ("Allow all the time", `ACCESS_BACKGROUND_LOCATION`)
after an in-app disclosure. Google Play requires a matching declaration in
the Play Console (App content → Location permissions) with a short video of
the feature.

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
| `lib/map_picker.dart` | Map panel under the charts and full-screen map picker (`flutter_map`) |

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
bash tool/build_release.sh
```

This builds the signed APK (to install directly) and the app bundle (for
Google Play), and copies them to `dist/SunClock-<version>.apk` / `.aab`.
`dist/` is not in git.

App icons: `python tool/make_icon.py` draws the images in `assets/icon/`,
then `dart run flutter_launcher_icons` generates the platform icons. The
themed (monochrome) Android icon layer in `res/drawable-*` is added by hand.

Map data © OpenStreetMap contributors.
