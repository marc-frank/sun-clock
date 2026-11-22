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
      'Dans les deux cas, les heures du soleil sont calculées sur ce téléphone et votre position n\'est envoyée nulle part. La carte est enregistrée dans l\'application ; Sun Clock ne se connecte à Internet que pour la recherche de mises à jour, si vous l\'activez.';

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
  String get followAfterRestart => 'Suivre ma position en arrière-plan';

  @override
  String get followAfterRestartHelp =>
      'Le widget d\'écran d\'accueil et l\'horloge de la barre d\'état suivent le téléphone quand l\'application est fermée, même après un redémarrage. Nécessite l\'accès à la position « Toujours autoriser ». Sinon, ils gardent la dernière position jusqu\'à ce que vous ouvriez l\'application.';

  @override
  String get backgroundOff =>
      'L\'accès à la position « Toujours autoriser » est désactivé : le widget et l\'horloge de la barre d\'état gardent la dernière position jusqu\'à ce que vous ouvriez l\'application.';

  @override
  String get backgroundTitle => 'Utiliser la position en arrière-plan ?';

  @override
  String get backgroundDisclosure =>
      'Sun Clock collecte votre position en arrière-plan, même lorsque l\'application est fermée ou inutilisée, pour que l\'heure du soleil du widget d\'écran d\'accueil et de la barre d\'état reste juste en voyage et après un redémarrage.\n\nVotre position sert uniquement sur ce téléphone à calculer les heures du soleil. Elle ne quitte jamais le téléphone et n\'est partagée avec personne.\n\nSur l\'écran suivant, choisissez « Toujours autoriser ».';

  @override
  String get noThanks => 'Non merci';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get backgroundSnack =>
      'Choisissez « Toujours autoriser » dans l\'autorisation de position de Sun Clock pour suivre le téléphone quand l\'application est fermée.';

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
  String get sunHourLengthTitle => 'Durée des heures de jour et de nuit';

  @override
  String get sunHourLengthSubtitle =>
      'Minutes réelles par heure de jour et par heure de nuit';

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

  @override
  String get offsetTitle => 'Heure du soleil et heure locale';

  @override
  String offsetSubtitle(String day, String zone) {
    return '$day · en avance (+) ou en retard (−) sur l\'heure locale, $zone';
  }

  @override
  String get offsetToday => 'Aujourd\'hui';

  @override
  String offsetAhead(String duration) {
    return '$duration d\'avance';
  }

  @override
  String offsetBehind(String duration) {
    return '$duration de retard';
  }

  @override
  String get offsetInStep => 'à l\'heure';

  @override
  String offsetNow(String value) {
    return 'Maintenant : $value';
  }

  @override
  String get legendAhead => 'Heure du soleil en avance';

  @override
  String get legendBehind => 'Heure du soleil en retard';

  @override
  String get nowLabel => 'maint.';

  @override
  String hoursMinutes(String h, String m) {
    return '$h h $m min';
  }

  @override
  String get language => 'Langue';

  @override
  String get phoneLanguage => 'Langue du téléphone';

  @override
  String get widgetsTitle => 'Widget d\'écran d\'accueil';

  @override
  String get widgetsTileHelp => 'Horloges, informations et couleurs';

  @override
  String get widgetsHelp =>
      'Touchez un widget pour le modifier. Vous pouvez aussi appuyer longuement dessus sur l\'écran d\'accueil.';

  @override
  String get noWidgets =>
      'Il n\'y a pas encore de widget Sun Clock sur l\'écran d\'accueil.';

  @override
  String get addWidget => 'Ajouter à l\'accueil';

  @override
  String get addWidgetManual =>
      'Appuyez longuement sur l\'écran d\'accueil, choisissez Widgets et faites-y glisser Sun Clock.';

  @override
  String widgetN(String n) {
    return 'Widget $n';
  }

  @override
  String get sectionClocks => 'Horloges';

  @override
  String get clockBoth => 'Les deux';

  @override
  String get clockLayout => 'Disposition';

  @override
  String get layoutStacked => 'Grande et petite';

  @override
  String get layoutSide => 'Côte à côte';

  @override
  String get largeClock => 'Grande horloge';

  @override
  String get leftClock => 'Horloge de gauche';

  @override
  String get clockNames => 'Afficher le nom des horloges';

  @override
  String get sectionInfo => 'Informations';

  @override
  String get infoDayNight => 'Jour ou nuit';

  @override
  String get infoNext => 'Prochain lever ou coucher du soleil';

  @override
  String get infoHourLength => 'Durée d\'une heure de jour ou de nuit';

  @override
  String get infoOffset => 'Avance ou retard sur l\'heure locale';

  @override
  String get infoPlace => 'Nom du lieu';

  @override
  String get infoProgress => 'Avancement du jour ou de la nuit';

  @override
  String get sectionLook => 'Apparence';

  @override
  String get background => 'Arrière-plan';

  @override
  String opacity(String percent) {
    return 'Opacité $percent %';
  }

  @override
  String get corners => 'Coins';

  @override
  String get cornersNone => 'Carrés';

  @override
  String get cornersSmall => 'Petits';

  @override
  String get cornersMedium => 'Moyens';

  @override
  String get cornersLarge => 'Grands';

  @override
  String get autoColors => 'Horloges ambre le jour, bleues la nuit';

  @override
  String get clockColor => 'Couleur des horloges';

  @override
  String get textColor => 'Couleur du texte';

  @override
  String get dayWord => 'Jour';

  @override
  String get nightWord => 'Nuit';

  @override
  String widgetSunriseAt(String time) {
    return 'lever $time';
  }

  @override
  String widgetSunsetAt(String time) {
    return 'coucher $time';
  }

  @override
  String get widgetSolar => 'temps solaire vrai';

  @override
  String widgetOffset(String offset) {
    return 'heure du soleil $offset';
  }

  @override
  String get widgetNoPosition => 'Ouvrez Sun Clock pour définir un lieu';

  @override
  String dayHourLength(String minutes) {
    return '1 heure de jour = $minutes minutes réelles';
  }

  @override
  String nightHourLength(String minutes) {
    return '1 heure de nuit = $minutes minutes réelles';
  }

  @override
  String dayHourEquals(String n) {
    return 'heure de jour = $n min';
  }

  @override
  String nightHourEquals(String n) {
    return 'heure de nuit = $n min';
  }

  @override
  String get updateCheckTitle => 'Rechercher les mises à jour';

  @override
  String get updateCheckHelp =>
      'Environ une fois par semaine, demande à GitHub s\'il existe une version plus récente de Sun Clock. Seule cette requête passe par Internet ; votre position ne quitte jamais le téléphone.';

  @override
  String updateAvailable(String version) {
    return 'Sun Clock $version est disponible.';
  }

  @override
  String get upToDate => 'Sun Clock est à jour.';

  @override
  String get updateFailed => 'Impossible de joindre GitHub.';

  @override
  String get checkNow => 'Vérifier';

  @override
  String get download => 'Télécharger';

  @override
  String get later => 'Plus tard';

  @override
  String goldenHourLine(String times) {
    return 'Heure dorée $times';
  }

  @override
  String blueHourLine(String times) {
    return 'Heure bleue $times';
  }

  @override
  String get addWidgetManualIos =>
      'Maintenez le doigt sur l\'écran d\'accueil ou de verrouillage, touchez + ou Modifier → Ajouter un widget, puis choisissez Sun Clock.';

  @override
  String get widgetsHelpIos =>
      'Ces réglages s\'appliquent à tous les widgets Sun Clock de l\'écran d\'accueil. Les widgets de l\'écran verrouillé affichent l\'heure du soleil dans le style du système.';
}
