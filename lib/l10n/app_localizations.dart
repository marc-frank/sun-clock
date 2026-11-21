import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @sourceGpsApprox.
  ///
  /// In en, this message translates to:
  /// **'GPS, approximate'**
  String get sourceGpsApprox;

  /// No description provided for @sourceGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get sourceGps;

  /// No description provided for @sourceMap.
  ///
  /// In en, this message translates to:
  /// **'picked on map'**
  String get sourceMap;

  /// No description provided for @aboutTooltip.
  ///
  /// In en, this message translates to:
  /// **'About sun time'**
  String get aboutTooltip;

  /// No description provided for @statusBarHide.
  ///
  /// In en, this message translates to:
  /// **'Hide sun time from status bar'**
  String get statusBarHide;

  /// No description provided for @statusBarShow.
  ///
  /// In en, this message translates to:
  /// **'Show sun time in status bar'**
  String get statusBarShow;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @pickOnMapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pick location on map'**
  String get pickOnMapTooltip;

  /// No description provided for @theYear.
  ///
  /// In en, this message translates to:
  /// **'The year'**
  String get theYear;

  /// No description provided for @findingPosition.
  ///
  /// In en, this message translates to:
  /// **'Finding your position…'**
  String get findingPosition;

  /// No description provided for @needsPosition.
  ///
  /// In en, this message translates to:
  /// **'Sun Clock needs a position to know when the sun rises and sets.'**
  String get needsPosition;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @pickPlaceOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick a place on the map'**
  String get pickPlaceOnMap;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String version(String build, String version);

  /// No description provided for @sunTime.
  ///
  /// In en, this message translates to:
  /// **'Sun time'**
  String get sunTime;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Sun Clock divides the day into 24 hours that follow the sun. Sunrise is always 06:00 and sunset always 18:00. The 12 day hours share the real daylight evenly, and the 12 night hours share the night.\n\nIn winter, day hours are short and night hours long; in summer it is the other way round. At the equinoxes every hour is close to 60 minutes.\n\nSunrise and sunset are calculated with the NOAA solar formulas (the upper edge of the sun touching the horizon, with standard refraction). When the sun does not rise or set at all, the clock shows apparent solar time, with 12:00 at solar noon.'**
  String get aboutBody;

  /// No description provided for @mapCredit.
  ///
  /// In en, this message translates to:
  /// **'Map data: Natural Earth (public domain).'**
  String get mapCredit;

  /// No description provided for @licences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licences;

  /// No description provided for @gpsServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off.'**
  String get gpsServicesOff;

  /// No description provided for @gpsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was not granted.'**
  String get gpsPermissionDenied;

  /// No description provided for @gpsNoFix.
  ///
  /// In en, this message translates to:
  /// **'Could not get a GPS fix.'**
  String get gpsNoFix;

  /// No description provided for @dialDay.
  ///
  /// In en, this message translates to:
  /// **'Sun time {time}, day'**
  String dialDay(String time);

  /// No description provided for @dialNight.
  ///
  /// In en, this message translates to:
  /// **'Sun time {time}, night'**
  String dialNight(String time);

  /// No description provided for @dialSolarSuffix.
  ///
  /// In en, this message translates to:
  /// **', solar time'**
  String get dialSolarSuffix;

  /// No description provided for @sunTimeDay.
  ///
  /// In en, this message translates to:
  /// **'Sun time · day'**
  String get sunTimeDay;

  /// No description provided for @sunTimeNight.
  ///
  /// In en, this message translates to:
  /// **'Sun time · night'**
  String get sunTimeNight;

  /// No description provided for @convertTime.
  ///
  /// In en, this message translates to:
  /// **'Convert a time'**
  String get convertTime;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the map to pick a place'**
  String get locationHint;

  /// No description provided for @noSunset.
  ///
  /// In en, this message translates to:
  /// **'The sun does not set here today.\nShowing solar time (12:00 = solar noon).'**
  String get noSunset;

  /// No description provided for @noSunrise.
  ///
  /// In en, this message translates to:
  /// **'The sun does not rise here today.\nShowing solar time (12:00 = solar noon).'**
  String get noSunrise;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @sunriseAt.
  ///
  /// In en, this message translates to:
  /// **'Sunrise {time}'**
  String sunriseAt(String time);

  /// No description provided for @sunsetAt.
  ///
  /// In en, this message translates to:
  /// **'Sunset {time}'**
  String sunsetAt(String time);

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @localTime.
  ///
  /// In en, this message translates to:
  /// **'Local time'**
  String get localTime;

  /// No description provided for @resultSunDay.
  ///
  /// In en, this message translates to:
  /// **'{time} sun time · day'**
  String resultSunDay(String time);

  /// No description provided for @resultSunNight.
  ///
  /// In en, this message translates to:
  /// **'{time} sun time · night'**
  String resultSunNight(String time);

  /// No description provided for @solarParen.
  ///
  /// In en, this message translates to:
  /// **'(solar time)'**
  String get solarParen;

  /// No description provided for @notToday.
  ///
  /// In en, this message translates to:
  /// **'Not today'**
  String get notToday;

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get andWord;

  /// No description provided for @resultLocal.
  ///
  /// In en, this message translates to:
  /// **'{times} local time'**
  String resultLocal(String times);

  /// No description provided for @dayMonth.
  ///
  /// In en, this message translates to:
  /// **'{day} {month}'**
  String dayMonth(String day, String month);

  /// No description provided for @todayLine.
  ///
  /// In en, this message translates to:
  /// **'Today, {date} · {zone}'**
  String todayLine(String date, String zone);

  /// No description provided for @monthsShort.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get monthsShort;

  /// No description provided for @fromLocalToSun.
  ///
  /// In en, this message translates to:
  /// **'From local time to sun time'**
  String get fromLocalToSun;

  /// No description provided for @pickLocal.
  ///
  /// In en, this message translates to:
  /// **'Pick a local time'**
  String get pickLocal;

  /// No description provided for @fromSunToLocal.
  ///
  /// In en, this message translates to:
  /// **'From sun time to local time'**
  String get fromSunToLocal;

  /// No description provided for @pickSun.
  ///
  /// In en, this message translates to:
  /// **'Pick a sun time'**
  String get pickSun;

  /// No description provided for @converterNote.
  ///
  /// In en, this message translates to:
  /// **'Sun time follows today\'s sunrise and sunset here: 06:00 is sunrise, 18:00 sunset.'**
  String get converterNote;

  /// No description provided for @locationAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Location accuracy'**
  String get locationAccuracy;

  /// No description provided for @approximate.
  ///
  /// In en, this message translates to:
  /// **'Approximate'**
  String get approximate;

  /// No description provided for @precise.
  ///
  /// In en, this message translates to:
  /// **'Precise'**
  String get precise;

  /// No description provided for @approximateHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses a coarse fix, rounded to about 1 km. Sun times shift by only a few seconds per kilometre, so this is accurate enough and uses less battery.'**
  String get approximateHelp;

  /// No description provided for @preciseHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses GPS for your exact position. Sun times become accurate to the second; uses a little more battery.'**
  String get preciseHelp;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Either way, sun times are calculated on this phone and your position is not sent anywhere. The map is stored in the app; Sun Clock only goes online for the update check, if you turn it on.'**
  String get privacyNote;

  /// No description provided for @preciseDenied.
  ///
  /// In en, this message translates to:
  /// **'The system only allows approximate location for Sun Clock. Turn on \"Precise location\" in the app\'s location permission.'**
  String get preciseDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @mapPlaceNote.
  ///
  /// In en, this message translates to:
  /// **'You are using a place picked on the map; this applies when you switch back to GPS.'**
  String get mapPlaceNote;

  /// No description provided for @statusBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Sun time in status bar'**
  String get statusBarTitle;

  /// No description provided for @statusBarHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows the sun time as a status-bar icon and in the notification shade. Keeps running and follows your location while the app is closed.'**
  String get statusBarHelp;

  /// No description provided for @chipTitle.
  ///
  /// In en, this message translates to:
  /// **'Show as text in the status bar'**
  String get chipTitle;

  /// No description provided for @chipHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows the sun time as a Live Update chip, e.g. \"14:27\", instead of the small stacked icon.'**
  String get chipHelp;

  /// No description provided for @chipOff.
  ///
  /// In en, this message translates to:
  /// **'Live Updates are turned off for Sun Clock, so the stacked icon is shown.'**
  String get chipOff;

  /// No description provided for @followAfterRestart.
  ///
  /// In en, this message translates to:
  /// **'Follow my location in the background'**
  String get followAfterRestart;

  /// No description provided for @followAfterRestartHelp.
  ///
  /// In en, this message translates to:
  /// **'Lets the home-screen widget and the status-bar clock follow the phone while the app is closed, also after a restart. Needs location \"Allow all the time\". When off, they keep the last position until you open the app.'**
  String get followAfterRestartHelp;

  /// No description provided for @backgroundOff.
  ///
  /// In en, this message translates to:
  /// **'Location \"Allow all the time\" is off, so the widget and the status-bar clock keep the last position until you open the app.'**
  String get backgroundOff;

  /// No description provided for @backgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Use location in the background?'**
  String get backgroundTitle;

  /// No description provided for @backgroundDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Sun Clock collects your location in the background, also when the app is closed or not in use, so the sun time on the home-screen widget and in the status bar stays right while you travel and after the phone restarts.\n\nYour position is only used on this phone to calculate sun times. It never leaves the phone and is not shared with anyone.\n\nOn the next screen, choose \"Allow all the time\".'**
  String get backgroundDisclosure;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get noThanks;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @backgroundSnack.
  ///
  /// In en, this message translates to:
  /// **'Choose \"Allow all the time\" in Sun Clock\'s location permission to follow the phone while the app is closed.'**
  String get backgroundSnack;

  /// No description provided for @notificationsSnack.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for Sun Clock to show the sun time in the status bar.'**
  String get notificationsSnack;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @dragMapToPick.
  ///
  /// In en, this message translates to:
  /// **'Drag the map to pick a place'**
  String get dragMapToPick;

  /// No description provided for @fullScreenMap.
  ///
  /// In en, this message translates to:
  /// **'Full-screen map'**
  String get fullScreenMap;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @tapOrDragMap.
  ///
  /// In en, this message translates to:
  /// **'Tap or drag the map to pick a place.'**
  String get tapOrDragMap;

  /// No description provided for @sunriseSunsetLine.
  ///
  /// In en, this message translates to:
  /// **'Sunrise {rise} · sunset {set}'**
  String sunriseSunsetLine(String rise, String set);

  /// No description provided for @polarDay.
  ///
  /// In en, this message translates to:
  /// **'Polar day'**
  String get polarDay;

  /// No description provided for @polarNight.
  ///
  /// In en, this message translates to:
  /// **'Polar night'**
  String get polarNight;

  /// No description provided for @hourLine.
  ///
  /// In en, this message translates to:
  /// **'Hour: day {day} · night {night}'**
  String hourLine(String day, String night);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesShort(String n);

  /// No description provided for @sunriseAndSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunrise and sunset'**
  String get sunriseAndSunset;

  /// No description provided for @chartLocalTime.
  ///
  /// In en, this message translates to:
  /// **'{year} · local time, {zone}'**
  String chartLocalTime(String year, String zone);

  /// No description provided for @sunHourLengthTitle.
  ///
  /// In en, this message translates to:
  /// **'Length of day and night hours'**
  String get sunHourLengthTitle;

  /// No description provided for @sunHourLengthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real minutes in one day hour and one night hour'**
  String get sunHourLengthSubtitle;

  /// No description provided for @dayHour.
  ///
  /// In en, this message translates to:
  /// **'Day hour'**
  String get dayHour;

  /// No description provided for @nightHour.
  ///
  /// In en, this message translates to:
  /// **'Night hour'**
  String get nightHour;

  /// No description provided for @polarGapsNote.
  ///
  /// In en, this message translates to:
  /// **'Gaps are polar day or polar night, when the sun does not rise or set and the clock shows solar time.'**
  String get polarGapsNote;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @dayHourValue.
  ///
  /// In en, this message translates to:
  /// **'Day hour {minutes} min'**
  String dayHourValue(String minutes);

  /// No description provided for @nightHourValue.
  ///
  /// In en, this message translates to:
  /// **'Night hour {minutes} min'**
  String nightHourValue(String minutes);

  /// No description provided for @offsetTitle.
  ///
  /// In en, this message translates to:
  /// **'Sun time vs local time'**
  String get offsetTitle;

  /// No description provided for @offsetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{day} · ahead (+) or behind (−) the local clock, {zone}'**
  String offsetSubtitle(String day, String zone);

  /// No description provided for @offsetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get offsetToday;

  /// No description provided for @offsetAhead.
  ///
  /// In en, this message translates to:
  /// **'{duration} ahead'**
  String offsetAhead(String duration);

  /// No description provided for @offsetBehind.
  ///
  /// In en, this message translates to:
  /// **'{duration} behind'**
  String offsetBehind(String duration);

  /// No description provided for @offsetInStep.
  ///
  /// In en, this message translates to:
  /// **'in step'**
  String get offsetInStep;

  /// No description provided for @offsetNow.
  ///
  /// In en, this message translates to:
  /// **'Now: {value}'**
  String offsetNow(String value);

  /// No description provided for @legendAhead.
  ///
  /// In en, this message translates to:
  /// **'Sun time ahead'**
  String get legendAhead;

  /// No description provided for @legendBehind.
  ///
  /// In en, this message translates to:
  /// **'Sun time behind'**
  String get legendBehind;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get nowLabel;

  /// No description provided for @hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String hoursMinutes(String h, String m);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @phoneLanguage.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get phoneLanguage;

  /// No description provided for @widgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Home-screen widget'**
  String get widgetsTitle;

  /// No description provided for @widgetsTileHelp.
  ///
  /// In en, this message translates to:
  /// **'Clocks, information and colours'**
  String get widgetsTileHelp;

  /// No description provided for @widgetsHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap a widget to change it. You can also long-press it on the home screen.'**
  String get widgetsHelp;

  /// No description provided for @noWidgets.
  ///
  /// In en, this message translates to:
  /// **'There is no Sun Clock widget on the home screen yet.'**
  String get noWidgets;

  /// No description provided for @addWidget.
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get addWidget;

  /// No description provided for @addWidgetManual.
  ///
  /// In en, this message translates to:
  /// **'Long-press the home screen, choose Widgets and drag Sun Clock onto it.'**
  String get addWidgetManual;

  /// No description provided for @widgetN.
  ///
  /// In en, this message translates to:
  /// **'Widget {n}'**
  String widgetN(String n);

  /// No description provided for @sectionClocks.
  ///
  /// In en, this message translates to:
  /// **'Clocks'**
  String get sectionClocks;

  /// No description provided for @clockBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get clockBoth;

  /// No description provided for @clockLayout.
  ///
  /// In en, this message translates to:
  /// **'Arrangement'**
  String get clockLayout;

  /// No description provided for @layoutStacked.
  ///
  /// In en, this message translates to:
  /// **'Large and small'**
  String get layoutStacked;

  /// No description provided for @layoutSide.
  ///
  /// In en, this message translates to:
  /// **'Side by side'**
  String get layoutSide;

  /// No description provided for @largeClock.
  ///
  /// In en, this message translates to:
  /// **'Large clock'**
  String get largeClock;

  /// No description provided for @leftClock.
  ///
  /// In en, this message translates to:
  /// **'Left clock'**
  String get leftClock;

  /// No description provided for @clockNames.
  ///
  /// In en, this message translates to:
  /// **'Show clock names'**
  String get clockNames;

  /// No description provided for @sectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get sectionInfo;

  /// No description provided for @infoDayNight.
  ///
  /// In en, this message translates to:
  /// **'Day or night'**
  String get infoDayNight;

  /// No description provided for @infoNext.
  ///
  /// In en, this message translates to:
  /// **'Next sunrise or sunset'**
  String get infoNext;

  /// No description provided for @infoHourLength.
  ///
  /// In en, this message translates to:
  /// **'Length of a day or night hour'**
  String get infoHourLength;

  /// No description provided for @infoOffset.
  ///
  /// In en, this message translates to:
  /// **'Sun time ahead of or behind local time'**
  String get infoOffset;

  /// No description provided for @infoPlace.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get infoPlace;

  /// No description provided for @infoProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress of the day or night'**
  String get infoProgress;

  /// No description provided for @sectionLook.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get sectionLook;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @opacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity {percent} %'**
  String opacity(String percent);

  /// No description provided for @corners.
  ///
  /// In en, this message translates to:
  /// **'Corners'**
  String get corners;

  /// No description provided for @cornersNone.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get cornersNone;

  /// No description provided for @cornersSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get cornersSmall;

  /// No description provided for @cornersMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get cornersMedium;

  /// No description provided for @cornersLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get cornersLarge;

  /// No description provided for @autoColors.
  ///
  /// In en, this message translates to:
  /// **'Clocks amber by day, blue by night'**
  String get autoColors;

  /// No description provided for @clockColor.
  ///
  /// In en, this message translates to:
  /// **'Clock colour'**
  String get clockColor;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text colour'**
  String get textColor;

  /// No description provided for @dayWord.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayWord;

  /// No description provided for @nightWord.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get nightWord;

  /// No description provided for @widgetSunriseAt.
  ///
  /// In en, this message translates to:
  /// **'sunrise {time}'**
  String widgetSunriseAt(String time);

  /// No description provided for @widgetSunsetAt.
  ///
  /// In en, this message translates to:
  /// **'sunset {time}'**
  String widgetSunsetAt(String time);

  /// No description provided for @widgetSolar.
  ///
  /// In en, this message translates to:
  /// **'solar time'**
  String get widgetSolar;

  /// No description provided for @widgetOffset.
  ///
  /// In en, this message translates to:
  /// **'sun time {offset}'**
  String widgetOffset(String offset);

  /// No description provided for @widgetNoPosition.
  ///
  /// In en, this message translates to:
  /// **'Open Sun Clock to set a location'**
  String get widgetNoPosition;

  /// No description provided for @dayHourLength.
  ///
  /// In en, this message translates to:
  /// **'1 day hour = {minutes} real minutes'**
  String dayHourLength(String minutes);

  /// No description provided for @nightHourLength.
  ///
  /// In en, this message translates to:
  /// **'1 night hour = {minutes} real minutes'**
  String nightHourLength(String minutes);

  /// No description provided for @dayHourEquals.
  ///
  /// In en, this message translates to:
  /// **'day hour = {n} min'**
  String dayHourEquals(String n);

  /// No description provided for @nightHourEquals.
  ///
  /// In en, this message translates to:
  /// **'night hour = {n} min'**
  String nightHourEquals(String n);

  /// No description provided for @updateCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheckTitle;

  /// No description provided for @updateCheckHelp.
  ///
  /// In en, this message translates to:
  /// **'About once a week, asks GitHub whether a newer Sun Clock exists. Only that request goes online; your position never leaves the phone.'**
  String get updateCheckHelp;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Sun Clock {version} is available.'**
  String updateAvailable(String version);

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Sun Clock is up to date.'**
  String get upToDate;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach GitHub.'**
  String get updateFailed;

  /// No description provided for @checkNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkNow;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
