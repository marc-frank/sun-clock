// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get sourceGpsApprox => 'GPS, approximatif';

  @override
  String get sourceGps => 'GPS';

  @override
  String get sourceMap => 'choisi sur la carte';

  @override
  String get aboutTooltip => 'À propos de l\'heure du soleil';

  @override
  String get statusBarHide =>
      'Masquer l\'heure du soleil dans la barre d\'état';

  @override
  String get statusBarShow =>
      'Afficher l\'heure du soleil dans la barre d\'état';

  @override
  String get settings => 'Paramètres';

  @override
  String get pickOnMapTooltip => 'Choisir un lieu sur la carte';

  @override
  String get theYear => 'L\'année';

  @override
  String get findingPosition => 'Recherche de votre position…';

  @override
  String get needsPosition =>
      'Sun Clock a besoin d\'une position pour savoir quand le soleil se lève et se couche.';

  @override
  String get retry => 'Réessayer';

  @override
  String get pickPlaceOnMap => 'Choisir un lieu sur la carte';

  @override
  String version(String build, String version) {
    return 'Version $version ($build)';
  }

  @override
  String get sunTime => 'Heure du soleil';

  @override
  String get aboutBody =>
      'Sun Clock divise la journée en 24 heures qui suivent le soleil. Le lever du soleil est toujours à 06:00 et le coucher toujours à 18:00. Les 12 heures de jour se partagent la lumière réelle du jour à parts égales, et les 12 heures de nuit se partagent la nuit.\n\nEn hiver, les heures de jour sont courtes et les heures de nuit longues ; en été, c\'est l\'inverse. Aux équinoxes, chaque heure dure environ 60 minutes.\n\nLe lever et le coucher du soleil sont calculés avec les formules solaires de la NOAA (le bord supérieur du soleil touche l\'horizon, avec la réfraction standard). Quand le soleil ne se lève pas ou ne se couche pas du tout, l\'horloge affiche le temps solaire vrai, avec 12:00 au midi solaire.';

  @override
  String get mapCredit =>
      'Données cartographiques : Natural Earth (domaine public).';

  @override
  String get licences => 'Licences open source';

  @override
  String get gpsServicesOff => 'Les services de localisation sont désactivés.';

  @override
  String get gpsPermissionDenied =>
      'L\'autorisation de localisation n\'a pas été accordée.';

  @override
  String get gpsNoFix => 'Impossible d\'obtenir une position GPS.';

  @override
  String dialDay(String time) {
    return 'Heure du soleil $time, jour';
  }

  @override
  String dialNight(String time) {
    return 'Heure du soleil $time, nuit';
  }

  @override
  String get dialSolarSuffix => ', temps solaire vrai';

  @override
  String get sunTimeDay => 'Heure du soleil · jour';

  @override
  String get sunTimeNight => 'Heure du soleil · nuit';

  @override
  String get convertTime => 'Convertir une heure';

  @override
  String get locationHint => 'Ouvre la carte pour choisir un lieu';

  @override
  String get noSunset =>
      'Le soleil ne se couche pas ici aujourd\'hui.\nAffichage du temps solaire vrai (12:00 = midi solaire).';

  @override
  String get noSunrise =>
      'Le soleil ne se lève pas ici aujourd\'hui.\nAffichage du temps solaire vrai (12:00 = midi solaire).';

  @override
  String get sunrise => 'Lever du soleil';

  @override
  String get sunset => 'Coucher du soleil';

  @override
  String sunriseAt(String time) {
    return 'Lever $time';
  }

  @override
  String sunsetAt(String time) {
    return 'Coucher $time';
  }

  @override
  String sunHourLength(String minutes) {
    return '1 heure du soleil = $minutes minutes réelles';
  }

  @override
  String get local => 'Locale';

  @override
  String get localTime => 'Heure locale';

  @override
  String resultSunDay(String time) {
    return '$time heure du soleil · jour';
  }

  @override
  String resultSunNight(String time) {
    return '$time heure du soleil · nuit';
  }

  @override
  String get solarParen => '(temps solaire vrai)';

  @override
  String get notToday => 'Pas aujourd\'hui';

  @override
  String get andWord => 'et';

  @override
  String resultLocal(String times) {
    return '$times heure locale';
  }

  @override
  String dayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String todayLine(String date, String zone) {
    return 'Aujourd\'hui, $date · $zone';
  }

  @override
  String get monthsShort =>
      'janv.,févr.,mars,avr.,mai,juin,juil.,août,sept.,oct.,nov.,déc.';

  @override
  String get fromLocalToSun => 'De l\'heure locale à l\'heure du soleil';

  @override
  String get pickLocal => 'Choisir une heure locale';

  @override
  String get fromSunToLocal => 'De l\'heure du soleil à l\'heure locale';

  @override
  String get pickSun => 'Choisir une heure du soleil';

  @override
  String get converterNote =>
      'L\'heure du soleil suit le lever et le coucher du soleil d\'aujourd\'hui à cet endroit : 06:00 est le lever, 18:00 le coucher.';

  @override
  String get locationAccuracy => 'Précision de la position';

  @override
  String get approximate => 'Approximative';

  @override
  String get precise => 'Précise';

  @override
  String get approximateHelp =>
      'Utilise une position approximative, arrondie à environ 1 km. Les heures du soleil ne varient que de quelques secondes par kilomètre : c\'est assez précis et cela économise la batterie.';

  @override
  String get preciseHelp =>
      'Utilise le GPS pour votre position exacte. Les heures du soleil sont précises à la seconde ; consomme un peu plus de batterie.';

  @override
  String get privacyNote =>
      'Dans les deux cas, les heures du soleil sont calculées sur ce téléphone et votre position n\'est envoyée nulle part. La carte est enregistrée dans l\'application : Sun Clock n\'utilise pas du tout Internet.';

  @override
  String get preciseDenied =>
      'Le système n\'autorise qu\'une position approximative pour Sun Clock. Activez « Position exacte » dans l\'autorisation de localisation de l\'application.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get mapPlaceNote =>
      'Vous utilisez un lieu choisi sur la carte ; ce réglage s\'applique quand vous revenez au GPS.';

  @override
  String get statusBarTitle => 'Heure du soleil dans la barre d\'état';

  @override
  String get statusBarHelp =>
      'Affiche l\'heure du soleil sous forme d\'icône dans la barre d\'état et dans le volet de notifications. Continue de fonctionner et suit votre position quand l\'application est fermée.';

  @override
  String get chipTitle => 'Afficher sous forme de texte dans la barre d\'état';

  @override
  String get chipHelp =>
      'Affiche l\'heure du soleil dans une pastille d\'actualité en direct, par exemple « 14:27 », au lieu de la petite icône sur deux lignes.';

  @override
  String get chipOff =>
      'Les actualités en direct sont désactivées pour Sun Clock ; l\'icône sur deux lignes est donc affichée.';

  @override
  String get followAfterRestart => 'Suivre la position après un redémarrage';

  @override
  String get followAfterRestartHelp =>
      'Utilise votre position en arrière-plan pour que l\'horloge de la barre d\'état suive le téléphone après un redémarrage sans ouvrir l\'application. Si désactivé, la dernière position connue est utilisée jusqu\'à l\'ouverture de l\'application.';

  @override
  String get backgroundOff =>
      'L\'autorisation de localisation « Toujours autoriser » est désactivée ; après un redémarrage, la dernière position connue est donc utilisée.';

  @override
  String get backgroundTitle => 'Utiliser la position en arrière-plan ?';

  @override
  String get backgroundDisclosure =>
      'Sun Clock collecte votre position en arrière-plan, y compris quand l\'application est fermée ou n\'est pas utilisée, afin que l\'heure du soleil dans la barre d\'état reste juste après un redémarrage du téléphone et pendant vos déplacements.\n\nVotre position sert uniquement, sur ce téléphone, à calculer les heures du soleil. Elle ne quitte jamais le téléphone et n\'est partagée avec personne.\n\nSur l\'écran suivant, choisissez « Toujours autoriser ».';

  @override
  String get noThanks => 'Non merci';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get backgroundSnack =>
      'Choisissez « Toujours autoriser » dans l\'autorisation de localisation de Sun Clock pour suivre le téléphone après un redémarrage.';

  @override
  String get notificationsSnack =>
      'Autorisez les notifications de Sun Clock pour afficher l\'heure du soleil dans la barre d\'état.';

  @override
  String get myLocation => 'Ma position';

  @override
  String get location => 'Lieu';

  @override
  String get dragMapToPick => 'Faites glisser la carte pour choisir un lieu';

  @override
  String get fullScreenMap => 'Carte en plein écran';

  @override
  String get back => 'Retour';

  @override
  String get done => 'Terminé';

  @override
  String get tapOrDragMap =>
      'Touchez ou faites glisser la carte pour choisir un lieu.';

  @override
  String sunriseSunsetLine(String rise, String set) {
    return 'Lever $rise · coucher $set';
  }

  @override
  String get polarDay => 'Jour polaire';

  @override
  String get polarNight => 'Nuit polaire';

  @override
  String hourLine(String day, String night) {
    return 'Heure : jour $day · nuit $night';
  }

  @override
  String minutesShort(String n) {
    return '$n min';
  }

  @override
  String get sunriseAndSunset => 'Lever et coucher du soleil';

  @override
  String chartLocalTime(String year, String zone) {
    return '$year · heure locale, $zone';
  }

  @override
  String get sunHourLengthTitle => 'Durée d\'une heure du soleil';

  @override
  String get sunHourLengthSubtitle => 'Minutes réelles par heure du soleil';

  @override
  String get dayHour => 'Heure de jour';

  @override
  String get nightHour => 'Heure de nuit';

  @override
  String get polarGapsNote =>
      'Les interruptions correspondent au jour polaire ou à la nuit polaire, quand le soleil ne se lève pas ou ne se couche pas et que l\'horloge affiche le temps solaire vrai.';

  @override
  String get today => 'aujourd\'hui';

  @override
  String dayHourValue(String minutes) {
    return 'Heure de jour $minutes min';
  }

  @override
  String nightHourValue(String minutes) {
    return 'Heure de nuit $minutes min';
  }
}
