// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get sourceGpsApprox => 'GPS, ungefähr';

  @override
  String get sourceGps => 'GPS';

  @override
  String get sourceMap => 'auf der Karte gewählt';

  @override
  String get aboutTooltip => 'Über die Sonnenzeit';

  @override
  String get statusBarHide => 'Sonnenzeit in der Statusleiste ausblenden';

  @override
  String get statusBarShow => 'Sonnenzeit in der Statusleiste anzeigen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get pickOnMapTooltip => 'Ort auf der Karte wählen';

  @override
  String get theYear => 'Das Jahr';

  @override
  String get findingPosition => 'Standort wird ermittelt …';

  @override
  String get needsPosition =>
      'Sun Clock braucht einen Standort, um zu wissen, wann die Sonne auf- und untergeht.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get pickPlaceOnMap => 'Ort auf der Karte wählen';

  @override
  String version(String build, String version) {
    return 'Version $version ($build)';
  }

  @override
  String get sunTime => 'Sonnenzeit';

  @override
  String get aboutBody =>
      'Sun Clock teilt den Tag in 24 Stunden, die der Sonne folgen. Sonnenaufgang ist immer um 06:00 und Sonnenuntergang immer um 18:00. Die 12 Tagstunden teilen das echte Tageslicht gleichmäßig auf, die 12 Nachtstunden die Nacht.\n\nIm Winter sind die Tagstunden kurz und die Nachtstunden lang, im Sommer ist es umgekehrt. Zur Tagundnachtgleiche dauert jede Stunde etwa 60 Minuten.\n\nSonnenaufgang und Sonnenuntergang werden mit den Sonnenformeln der NOAA berechnet (der obere Sonnenrand berührt den Horizont, mit Standardrefraktion). Wenn die Sonne gar nicht auf- oder untergeht, zeigt die Uhr die wahre Sonnenzeit, mit 12:00 beim Sonnenhöchststand.';

  @override
  String get mapCredit => 'Kartendaten: Natural Earth (gemeinfrei).';

  @override
  String get licences => 'Open-Source-Lizenzen';

  @override
  String get gpsServicesOff => 'Die Standortdienste sind ausgeschaltet.';

  @override
  String get gpsPermissionDenied =>
      'Die Standortberechtigung wurde nicht erteilt.';

  @override
  String get gpsNoFix => 'Es konnte kein GPS-Standort ermittelt werden.';

  @override
  String dialDay(String time) {
    return 'Sonnenzeit $time, Tag';
  }

  @override
  String dialNight(String time) {
    return 'Sonnenzeit $time, Nacht';
  }

  @override
  String get dialSolarSuffix => ', wahre Sonnenzeit';

  @override
  String get sunTimeDay => 'Sonnenzeit · Tag';

  @override
  String get sunTimeNight => 'Sonnenzeit · Nacht';

  @override
  String get convertTime => 'Zeit umrechnen';

  @override
  String get locationHint => 'Öffnet die Karte zur Ortswahl';

  @override
  String get noSunset =>
      'Die Sonne geht hier heute nicht unter.\nAngezeigt wird die wahre Sonnenzeit (12:00 = Sonnenhöchststand).';

  @override
  String get noSunrise =>
      'Die Sonne geht hier heute nicht auf.\nAngezeigt wird die wahre Sonnenzeit (12:00 = Sonnenhöchststand).';

  @override
  String get sunrise => 'Sonnenaufgang';

  @override
  String get sunset => 'Sonnenuntergang';

  @override
  String sunriseAt(String time) {
    return 'Sonnenaufgang $time';
  }

  @override
  String sunsetAt(String time) {
    return 'Sonnenuntergang $time';
  }

  @override
  String get local => 'Ortszeit';

  @override
  String get localTime => 'Ortszeit';

  @override
  String resultSunDay(String time) {
    return '$time Sonnenzeit · Tag';
  }

  @override
  String resultSunNight(String time) {
    return '$time Sonnenzeit · Nacht';
  }

  @override
  String get solarParen => '(wahre Sonnenzeit)';

  @override
  String get notToday => 'Heute nicht';

  @override
  String get andWord => 'und';

  @override
  String resultLocal(String times) {
    return '$times Ortszeit';
  }

  @override
  String dayMonth(String day, String month) {
    return '$day. $month';
  }

  @override
  String todayLine(String date, String zone) {
    return 'Heute, $date · $zone';
  }

  @override
  String get monthsShort => 'Jan,Feb,Mär,Apr,Mai,Jun,Jul,Aug,Sep,Okt,Nov,Dez';

  @override
  String get fromLocalToSun => 'Von Ortszeit zu Sonnenzeit';

  @override
  String get pickLocal => 'Ortszeit wählen';

  @override
  String get fromSunToLocal => 'Von Sonnenzeit zu Ortszeit';

  @override
  String get pickSun => 'Sonnenzeit wählen';

  @override
  String get converterNote =>
      'Die Sonnenzeit richtet sich nach dem heutigen Sonnenauf- und -untergang an diesem Ort: 06:00 ist Sonnenaufgang, 18:00 Sonnenuntergang.';

  @override
  String get locationAccuracy => 'Standortgenauigkeit';

  @override
  String get approximate => 'Ungefähr';

  @override
  String get precise => 'Genau';

  @override
  String get approximateHelp =>
      'Nutzt einen groben Standort, auf etwa 1 km gerundet. Die Sonnenzeiten ändern sich nur um wenige Sekunden pro Kilometer; das ist genau genug und schont den Akku.';

  @override
  String get preciseHelp =>
      'Nutzt GPS für den genauen Standort. Die Sonnenzeiten werden sekundengenau; braucht etwas mehr Akku.';

  @override
  String get privacyNote =>
      'In beiden Fällen werden die Sonnenzeiten auf diesem Gerät berechnet und der Standort wird nirgendwohin gesendet. Die Karte ist in der App gespeichert; Sun Clock geht nur für die Update-Suche ins Internet, wenn du sie einschaltest.';

  @override
  String get preciseDenied =>
      'Das System erlaubt Sun Clock nur den ungefähren Standort. Schalte in der Standortberechtigung der App „Genauer Standort“ ein.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get mapPlaceNote =>
      'Du nutzt einen auf der Karte gewählten Ort; dies gilt, sobald du wieder auf GPS wechselst.';

  @override
  String get statusBarTitle => 'Sonnenzeit in der Statusleiste';

  @override
  String get statusBarHelp =>
      'Zeigt die Sonnenzeit als Symbol in der Statusleiste und in den Benachrichtigungen. Läuft weiter und folgt deinem Standort, auch wenn die App geschlossen ist.';

  @override
  String get chipTitle => 'Als Text in der Statusleiste anzeigen';

  @override
  String get chipHelp =>
      'Zeigt die Sonnenzeit als Live-Update-Chip, z. B. „14:27“, statt des kleinen gestapelten Symbols.';

  @override
  String get chipOff =>
      'Live-Updates sind für Sun Clock ausgeschaltet, daher wird das gestapelte Symbol angezeigt.';

  @override
  String get followAfterRestart => 'Standort im Hintergrund folgen';

  @override
  String get followAfterRestartHelp =>
      'Damit folgen das Startbildschirm-Widget und die Uhr in der Statusleiste dem Telefon, auch wenn die App geschlossen ist und nach einem Neustart. Braucht den Standortzugriff „Immer zulassen“. Ohne bleibt der letzte Standort, bis du die App öffnest.';

  @override
  String get backgroundOff =>
      'Der Standortzugriff „Immer zulassen“ ist aus, daher behalten Widget und Statusleisten-Uhr den letzten Standort, bis du die App öffnest.';

  @override
  String get backgroundTitle => 'Standort im Hintergrund verwenden?';

  @override
  String get backgroundDisclosure =>
      'Sun Clock erfasst deinen Standort im Hintergrund, auch wenn die App geschlossen ist oder nicht verwendet wird, damit die Sonnenzeit im Startbildschirm-Widget und in der Statusleiste auf Reisen und nach einem Neustart stimmt.\n\nDein Standort wird nur auf diesem Telefon zur Berechnung der Sonnenzeiten verwendet. Er verlässt das Telefon nie und wird mit niemandem geteilt.\n\nWähle auf dem nächsten Bildschirm „Immer zulassen“.';

  @override
  String get noThanks => 'Nein danke';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get backgroundSnack =>
      'Wähle „Immer zulassen“ in der Standortberechtigung von Sun Clock, damit es dem Telefon auch bei geschlossener App folgt.';

  @override
  String get notificationsSnack =>
      'Erlaube Benachrichtigungen für Sun Clock, um die Sonnenzeit in der Statusleiste anzuzeigen.';

  @override
  String get myLocation => 'Mein Standort';

  @override
  String get location => 'Ort';

  @override
  String get dragMapToPick => 'Karte verschieben, um einen Ort zu wählen';

  @override
  String get fullScreenMap => 'Karte im Vollbild';

  @override
  String get back => 'Zurück';

  @override
  String get done => 'Fertig';

  @override
  String get tapOrDragMap =>
      'Tippe auf die Karte oder verschiebe sie, um einen Ort zu wählen.';

  @override
  String sunriseSunsetLine(String rise, String set) {
    return 'Aufgang $rise · Untergang $set';
  }

  @override
  String get polarDay => 'Polartag';

  @override
  String get polarNight => 'Polarnacht';

  @override
  String hourLine(String day, String night) {
    return 'Stunde: Tag $day · Nacht $night';
  }

  @override
  String minutesShort(String n) {
    return '$n min';
  }

  @override
  String get sunriseAndSunset => 'Sonnenaufgang und Sonnenuntergang';

  @override
  String chartLocalTime(String year, String zone) {
    return '$year · Ortszeit, $zone';
  }

  @override
  String get sunHourLengthTitle => 'Länge der Tag- und Nachtstunden';

  @override
  String get sunHourLengthSubtitle =>
      'Echte Minuten pro Tagstunde und pro Nachtstunde';

  @override
  String get dayHour => 'Tagstunde';

  @override
  String get nightHour => 'Nachtstunde';

  @override
  String get polarGapsNote =>
      'Lücken sind Polartag oder Polarnacht: Die Sonne geht dann nicht auf oder unter, und die Uhr zeigt die wahre Sonnenzeit.';

  @override
  String get today => 'heute';

  @override
  String dayHourValue(String minutes) {
    return 'Tagstunde $minutes min';
  }

  @override
  String nightHourValue(String minutes) {
    return 'Nachtstunde $minutes min';
  }

  @override
  String get offsetTitle => 'Sonnenzeit gegenüber Ortszeit';

  @override
  String offsetSubtitle(String day, String zone) {
    return '$day · vor (+) oder hinter (−) der Ortszeit, $zone';
  }

  @override
  String get offsetToday => 'Heute';

  @override
  String offsetAhead(String duration) {
    return '$duration vor';
  }

  @override
  String offsetBehind(String duration) {
    return '$duration nach';
  }

  @override
  String get offsetInStep => 'gleichauf';

  @override
  String offsetNow(String value) {
    return 'Jetzt: $value';
  }

  @override
  String get legendAhead => 'Sonnenzeit vor';

  @override
  String get legendBehind => 'Sonnenzeit nach';

  @override
  String get nowLabel => 'jetzt';

  @override
  String hoursMinutes(String h, String m) {
    return '$h h $m min';
  }

  @override
  String get language => 'Sprache';

  @override
  String get phoneLanguage => 'Sprache des Telefons';

  @override
  String get widgetsTitle => 'Startbildschirm-Widget';

  @override
  String get widgetsTileHelp => 'Uhren, Angaben und Farben';

  @override
  String get widgetsHelp =>
      'Tippe auf ein Widget, um es zu ändern. Das geht auch durch langes Drücken auf dem Startbildschirm.';

  @override
  String get noWidgets =>
      'Auf dem Startbildschirm ist noch kein Sun-Clock-Widget.';

  @override
  String get addWidget => 'Zum Startbildschirm';

  @override
  String get addWidgetManual =>
      'Halte den Startbildschirm gedrückt, wähle Widgets und ziehe Sun Clock darauf.';

  @override
  String widgetN(String n) {
    return 'Widget $n';
  }

  @override
  String get sectionClocks => 'Uhren';

  @override
  String get clockBoth => 'Beide';

  @override
  String get clockLayout => 'Anordnung';

  @override
  String get layoutStacked => 'Groß und klein';

  @override
  String get layoutSide => 'Nebeneinander';

  @override
  String get largeClock => 'Große Uhr';

  @override
  String get leftClock => 'Linke Uhr';

  @override
  String get clockNames => 'Namen der Uhren zeigen';

  @override
  String get sectionInfo => 'Angaben';

  @override
  String get infoDayNight => 'Tag oder Nacht';

  @override
  String get infoNext => 'Nächster Sonnenauf- oder -untergang';

  @override
  String get infoHourLength => 'Länge einer Tag- oder Nachtstunde';

  @override
  String get infoOffset => 'Sonnenzeit vor oder nach der Ortszeit';

  @override
  String get infoPlace => 'Ortsname';

  @override
  String get infoProgress => 'Fortschritt von Tag oder Nacht';

  @override
  String get sectionLook => 'Aussehen';

  @override
  String get background => 'Hintergrund';

  @override
  String opacity(String percent) {
    return 'Deckkraft $percent %';
  }

  @override
  String get corners => 'Ecken';

  @override
  String get cornersNone => 'Eckig';

  @override
  String get cornersSmall => 'Klein';

  @override
  String get cornersMedium => 'Mittel';

  @override
  String get cornersLarge => 'Groß';

  @override
  String get autoColors => 'Uhren tagsüber bernstein, nachts blau';

  @override
  String get clockColor => 'Farbe der Uhren';

  @override
  String get textColor => 'Textfarbe';

  @override
  String get dayWord => 'Tag';

  @override
  String get nightWord => 'Nacht';

  @override
  String widgetSunriseAt(String time) {
    return 'Aufgang $time';
  }

  @override
  String widgetSunsetAt(String time) {
    return 'Untergang $time';
  }

  @override
  String get widgetSolar => 'wahre Sonnenzeit';

  @override
  String widgetOffset(String offset) {
    return 'Sonnenzeit $offset';
  }

  @override
  String get widgetNoPosition => 'Sun Clock öffnen, um einen Ort festzulegen';

  @override
  String dayHourLength(String minutes) {
    return '1 Tagstunde = $minutes echte Minuten';
  }

  @override
  String nightHourLength(String minutes) {
    return '1 Nachtstunde = $minutes echte Minuten';
  }

  @override
  String dayHourEquals(String n) {
    return 'Tagstunde = $n min';
  }

  @override
  String nightHourEquals(String n) {
    return 'Nachtstunde = $n min';
  }

  @override
  String get updateCheckTitle => 'Nach Updates suchen';

  @override
  String get updateCheckHelp =>
      'Fragt etwa einmal pro Woche bei GitHub, ob es eine neuere Version von Sun Clock gibt. Nur diese Anfrage geht ins Internet; dein Standort verlässt nie das Telefon.';

  @override
  String updateAvailable(String version) {
    return 'Sun Clock $version ist verfügbar.';
  }

  @override
  String get upToDate => 'Sun Clock ist aktuell.';

  @override
  String get updateFailed => 'GitHub ist nicht erreichbar.';

  @override
  String get checkNow => 'Jetzt prüfen';

  @override
  String get download => 'Herunterladen';

  @override
  String get later => 'Später';

  @override
  String goldenHourLine(String times) {
    return 'Goldene Stunde $times';
  }

  @override
  String blueHourLine(String times) {
    return 'Blaue Stunde $times';
  }

  @override
  String get addWidgetManualIos =>
      'Halte den Home- oder Sperrbildschirm gedrückt, tippe auf + oder Bearbeiten → Widget hinzufügen und wähle Sun Clock.';

  @override
  String get widgetsHelpIos =>
      'Diese Einstellungen gelten für alle Sun-Clock-Widgets auf dem Home-Bildschirm. Widgets auf dem Sperrbildschirm zeigen die Sonnenzeit im Stil des Systems.';
}
