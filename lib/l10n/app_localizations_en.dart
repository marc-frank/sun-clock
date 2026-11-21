// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get sourceGpsApprox => 'GPS, approximate';

  @override
  String get sourceGps => 'GPS';

  @override
  String get sourceMap => 'picked on map';

  @override
  String get aboutTooltip => 'About sun time';

  @override
  String get statusBarHide => 'Hide sun time from status bar';

  @override
  String get statusBarShow => 'Show sun time in status bar';

  @override
  String get settings => 'Settings';

  @override
  String get pickOnMapTooltip => 'Pick location on map';

  @override
  String get theYear => 'The year';

  @override
  String get findingPosition => 'Finding your position…';

  @override
  String get needsPosition =>
      'Sun Clock needs a position to know when the sun rises and sets.';

  @override
  String get retry => 'Retry';

  @override
  String get pickPlaceOnMap => 'Pick a place on the map';

  @override
  String version(String build, String version) {
    return 'Version $version ($build)';
  }

  @override
  String get sunTime => 'Sun time';

  @override
  String get aboutBody =>
      'Sun Clock divides the day into 24 hours that follow the sun. Sunrise is always 06:00 and sunset always 18:00. The 12 day hours share the real daylight evenly, and the 12 night hours share the night.\n\nIn winter, day hours are short and night hours long; in summer it is the other way round. At the equinoxes every hour is close to 60 minutes.\n\nSunrise and sunset are calculated with the NOAA solar formulas (the upper edge of the sun touching the horizon, with standard refraction). When the sun does not rise or set at all, the clock shows apparent solar time, with 12:00 at solar noon.';

  @override
  String get mapCredit => 'Map data: Natural Earth (public domain).';

  @override
  String get licences => 'Open-source licences';

  @override
  String get gpsServicesOff => 'Location services are turned off.';

  @override
  String get gpsPermissionDenied => 'Location permission was not granted.';

  @override
  String get gpsNoFix => 'Could not get a GPS fix.';

  @override
  String dialDay(String time) {
    return 'Sun time $time, day';
  }

  @override
  String dialNight(String time) {
    return 'Sun time $time, night';
  }

  @override
  String get dialSolarSuffix => ', solar time';

  @override
  String get sunTimeDay => 'Sun time · day';

  @override
  String get sunTimeNight => 'Sun time · night';

  @override
  String get convertTime => 'Convert a time';

  @override
  String get locationHint => 'Opens the map to pick a place';

  @override
  String get noSunset =>
      'The sun does not set here today.\nShowing solar time (12:00 = solar noon).';

  @override
  String get noSunrise =>
      'The sun does not rise here today.\nShowing solar time (12:00 = solar noon).';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get sunset => 'Sunset';

  @override
  String sunriseAt(String time) {
    return 'Sunrise $time';
  }

  @override
  String sunsetAt(String time) {
    return 'Sunset $time';
  }

  @override
  String get local => 'Local';

  @override
  String get localTime => 'Local time';

  @override
  String resultSunDay(String time) {
    return '$time sun time · day';
  }

  @override
  String resultSunNight(String time) {
    return '$time sun time · night';
  }

  @override
  String get solarParen => '(solar time)';

  @override
  String get notToday => 'Not today';

  @override
  String get andWord => 'and';

  @override
  String resultLocal(String times) {
    return '$times local time';
  }

  @override
  String dayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String todayLine(String date, String zone) {
    return 'Today, $date · $zone';
  }

  @override
  String get monthsShort => 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

  @override
  String get fromLocalToSun => 'From local time to sun time';

  @override
  String get pickLocal => 'Pick a local time';

  @override
  String get fromSunToLocal => 'From sun time to local time';

  @override
  String get pickSun => 'Pick a sun time';

  @override
  String get converterNote =>
      'Sun time follows today\'s sunrise and sunset here: 06:00 is sunrise, 18:00 sunset.';

  @override
  String get locationAccuracy => 'Location accuracy';

  @override
  String get approximate => 'Approximate';

  @override
  String get precise => 'Precise';

  @override
  String get approximateHelp =>
      'Uses a coarse fix, rounded to about 1 km. Sun times shift by only a few seconds per kilometre, so this is accurate enough and uses less battery.';

  @override
  String get preciseHelp =>
      'Uses GPS for your exact position. Sun times become accurate to the second; uses a little more battery.';

  @override
  String get privacyNote =>
      'Either way, sun times are calculated on this phone and your position is not sent anywhere. The map is stored in the app; Sun Clock only goes online for the update check, if you turn it on.';

  @override
  String get preciseDenied =>
      'The system only allows approximate location for Sun Clock. Turn on \"Precise location\" in the app\'s location permission.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get mapPlaceNote =>
      'You are using a place picked on the map; this applies when you switch back to GPS.';

  @override
  String get statusBarTitle => 'Sun time in status bar';

  @override
  String get statusBarHelp =>
      'Shows the sun time as a status-bar icon and in the notification shade. Keeps running and follows your location while the app is closed.';

  @override
  String get chipTitle => 'Show as text in the status bar';

  @override
  String get chipHelp =>
      'Shows the sun time as a Live Update chip, e.g. \"14:27\", instead of the small stacked icon.';

  @override
  String get chipOff =>
      'Live Updates are turned off for Sun Clock, so the stacked icon is shown.';

  @override
  String get followAfterRestart => 'Follow location after a restart';

  @override
  String get followAfterRestartHelp =>
      'Uses your location in the background, so the status-bar clock follows the phone after a restart without opening the app. When off, it uses the last known position until you open the app.';

  @override
  String get backgroundOff =>
      'Location \"Allow all the time\" is off, so after a restart the last known position is used.';

  @override
  String get backgroundTitle => 'Use location in the background?';

  @override
  String get backgroundDisclosure =>
      'Sun Clock collects your location in the background, also when the app is closed or not in use, to keep the sun time in the status bar right after the phone restarts and while you travel.\n\nYour position is only used on this phone to calculate sun times. It never leaves the phone and is not shared with anyone.\n\nOn the next screen, choose \"Allow all the time\".';

  @override
  String get noThanks => 'No thanks';

  @override
  String get continueLabel => 'Continue';

  @override
  String get backgroundSnack =>
      'Choose \"Allow all the time\" in Sun Clock\'s location permission to follow the phone after a restart.';

  @override
  String get notificationsSnack =>
      'Allow notifications for Sun Clock to show the sun time in the status bar.';

  @override
  String get myLocation => 'My location';

  @override
  String get location => 'Location';

  @override
  String get dragMapToPick => 'Drag the map to pick a place';

  @override
  String get fullScreenMap => 'Full-screen map';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get tapOrDragMap => 'Tap or drag the map to pick a place.';

  @override
  String sunriseSunsetLine(String rise, String set) {
    return 'Sunrise $rise · sunset $set';
  }

  @override
  String get polarDay => 'Polar day';

  @override
  String get polarNight => 'Polar night';

  @override
  String hourLine(String day, String night) {
    return 'Hour: day $day · night $night';
  }

  @override
  String minutesShort(String n) {
    return '$n min';
  }

  @override
  String get sunriseAndSunset => 'Sunrise and sunset';

  @override
  String chartLocalTime(String year, String zone) {
    return '$year · local time, $zone';
  }

  @override
  String get sunHourLengthTitle => 'Length of day and night hours';

  @override
  String get sunHourLengthSubtitle =>
      'Real minutes in one day hour and one night hour';

  @override
  String get dayHour => 'Day hour';

  @override
  String get nightHour => 'Night hour';

  @override
  String get polarGapsNote =>
      'Gaps are polar day or polar night, when the sun does not rise or set and the clock shows solar time.';

  @override
  String get today => 'today';

  @override
  String dayHourValue(String minutes) {
    return 'Day hour $minutes min';
  }

  @override
  String nightHourValue(String minutes) {
    return 'Night hour $minutes min';
  }

  @override
  String get offsetTitle => 'Sun time vs local time';

  @override
  String offsetSubtitle(String day, String zone) {
    return '$day · ahead (+) or behind (−) the local clock, $zone';
  }

  @override
  String get offsetToday => 'Today';

  @override
  String offsetAhead(String duration) {
    return '$duration ahead';
  }

  @override
  String offsetBehind(String duration) {
    return '$duration behind';
  }

  @override
  String get offsetInStep => 'in step';

  @override
  String offsetNow(String value) {
    return 'Now: $value';
  }

  @override
  String get legendAhead => 'Sun time ahead';

  @override
  String get legendBehind => 'Sun time behind';

  @override
  String get nowLabel => 'now';

  @override
  String hoursMinutes(String h, String m) {
    return '$h h $m min';
  }

  @override
  String get language => 'Language';

  @override
  String get phoneLanguage => 'Phone language';

  @override
  String get widgetsTitle => 'Home-screen widget';

  @override
  String get widgetsTileHelp => 'Clocks, information and colours';

  @override
  String get widgetsHelp =>
      'Tap a widget to change it. You can also long-press it on the home screen.';

  @override
  String get noWidgets =>
      'There is no Sun Clock widget on the home screen yet.';

  @override
  String get addWidget => 'Add to home screen';

  @override
  String get addWidgetManual =>
      'Long-press the home screen, choose Widgets and drag Sun Clock onto it.';

  @override
  String widgetN(String n) {
    return 'Widget $n';
  }

  @override
  String get sectionClocks => 'Clocks';

  @override
  String get clockBoth => 'Both';

  @override
  String get clockLayout => 'Arrangement';

  @override
  String get layoutStacked => 'Large and small';

  @override
  String get layoutSide => 'Side by side';

  @override
  String get largeClock => 'Large clock';

  @override
  String get leftClock => 'Left clock';

  @override
  String get clockNames => 'Show clock names';

  @override
  String get sectionInfo => 'Information';

  @override
  String get infoDayNight => 'Day or night';

  @override
  String get infoNext => 'Next sunrise or sunset';

  @override
  String get infoHourLength => 'Length of a day or night hour';

  @override
  String get infoOffset => 'Sun time ahead of or behind local time';

  @override
  String get infoPlace => 'Place name';

  @override
  String get infoProgress => 'Progress of the day or night';

  @override
  String get sectionLook => 'Look';

  @override
  String get background => 'Background';

  @override
  String opacity(String percent) {
    return 'Opacity $percent %';
  }

  @override
  String get corners => 'Corners';

  @override
  String get cornersNone => 'Square';

  @override
  String get cornersSmall => 'Small';

  @override
  String get cornersMedium => 'Medium';

  @override
  String get cornersLarge => 'Large';

  @override
  String get autoColors => 'Clocks amber by day, blue by night';

  @override
  String get clockColor => 'Clock colour';

  @override
  String get textColor => 'Text colour';

  @override
  String get dayWord => 'Day';

  @override
  String get nightWord => 'Night';

  @override
  String widgetSunriseAt(String time) {
    return 'sunrise $time';
  }

  @override
  String widgetSunsetAt(String time) {
    return 'sunset $time';
  }

  @override
  String get widgetSolar => 'solar time';

  @override
  String widgetOffset(String offset) {
    return 'sun time $offset';
  }

  @override
  String get widgetNoPosition => 'Open Sun Clock to set a location';

  @override
  String dayHourLength(String minutes) {
    return '1 day hour = $minutes real minutes';
  }

  @override
  String nightHourLength(String minutes) {
    return '1 night hour = $minutes real minutes';
  }

  @override
  String dayHourEquals(String n) {
    return 'day hour = $n min';
  }

  @override
  String nightHourEquals(String n) {
    return 'night hour = $n min';
  }

  @override
  String get updateCheckTitle => 'Check for updates';

  @override
  String get updateCheckHelp =>
      'About once a week, asks GitHub whether a newer Sun Clock exists. Only that request goes online; your position never leaves the phone.';

  @override
  String updateAvailable(String version) {
    return 'Sun Clock $version is available.';
  }

  @override
  String get upToDate => 'Sun Clock is up to date.';

  @override
  String get updateFailed => 'Couldn\'t reach GitHub.';

  @override
  String get checkNow => 'Check now';

  @override
  String get download => 'Download';

  @override
  String get later => 'Later';
}
