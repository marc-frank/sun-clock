# Sun Clock

A Flutter app (Android, iOS) that shows **sun time**: a 24-hour clock whose
hours are stretched so that sunrise is always 06:00 and sunset always 18:00.
The 12 day hours split the real daylight evenly, and the 12 night hours split
the real night evenly. The current UTC time is shown alongside.

- `lib/solar.dart` is the NOAA sunrise/sunset formula, ported column by column
  from `NOAA_Solar_Calculations_*.xls`.
- `lib/sun_clock.dart` converts a UTC instant and a position to sun time.
- `lib/main.dart` contains the UI and reads the position over GPS (`geolocator`).
- `test/sun_clock_test.dart` checks the port against rows sampled from both
  spreadsheets.

When the sun doesn't rise or set (polar day or night), the app falls back to
apparent solar time, where 12:00 is solar noon.

```bash
flutter test
flutter run
```
