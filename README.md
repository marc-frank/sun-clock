# Sun Clock

A Flutter app (Android, iOS) that shows **sun time**: a 24-hour clock whose
hours are stretched so that sunrise is always 06:00 and sunset always 18:00.
The 12 day hours split the real daylight evenly, and the 12 night hours split
the real night evenly. The current UTC time is shown alongside.

Scroll down for charts of the year: sunrise and sunset times, and how long
one day hour and one night hour last. Between them, a day chart shows how far
sun time runs ahead of or behind the local clock through today; while you
drag a finger along a year chart it shows that day instead. Under the charts is a map
panel to pick any place, so the charts can be watched changing while you drag;
it can be maximized to a full-screen map (also behind the map button). The
clock and charts follow the pin live, and the picked place is remembered.

On Android there is also a home-screen widget (`SunWidget.kt`). Each widget
has its own settings (Settings → Home-screen widget, or long-press the widget
on Android 12+): sun time, local time or both (one large and one small, or
side by side), clock names, an information line (day or night, next sunrise
or sunset, length of a sun hour, how far sun time is ahead of local time,
place name), a progress bar for the day or night, and background colour,
opacity, corners and text colours. It uses the last position
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

On Android 16+ the status-bar clock can instead show the sun time as text in
a Live Update chip (opt-in in Settings, `POST_PROMOTED_NOTIFICATIONS`).
Without promotion it keeps the stacked-digit icon.

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
| `lib/day_offset.dart`, `lib/day_offset_chart.dart` | Sun time minus local time through a day, and its chart |
| `lib/home_widget.dart`, `lib/widget_editor.dart` | Home-screen widget settings and their editor with a live preview (Android: `WidgetConfig.kt`, `SunWidget.kt`) |
| `lib/language.dart` | Language: the phone's or one chosen in Settings (also used by the widget and notification) |
| `lib/map_picker.dart` | Map panel under the charts and full-screen map picker (`flutter_map`) |
| `lib/world_map.dart` | Offline world map drawn from the bundled Natural Earth data (`assets/map/world.bin`) |
| `lib/converter.dart` | Converter between local time and sun time |
| `lib/l10n/` | Texts in English, German, French and Spanish (`app_*.arb`; `flutter gen-l10n` writes the Dart files) |

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

The app needs no internet access: the world map is bundled. Map data: Natural
Earth (public domain).

Android texts (notification, widget) are in `android/app/src/main/res/values*/strings.xml`.
