// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get sourceGpsApprox => 'GPS, aproximada';

  @override
  String get sourceGps => 'GPS';

  @override
  String get sourceMap => 'elegida en el mapa';

  @override
  String get aboutTooltip => 'Acerca de la hora del sol';

  @override
  String get statusBarHide => 'Ocultar la hora del sol de la barra de estado';

  @override
  String get statusBarShow => 'Mostrar la hora del sol en la barra de estado';

  @override
  String get settings => 'Ajustes';

  @override
  String get pickOnMapTooltip => 'Elegir un lugar en el mapa';

  @override
  String get theYear => 'El año';

  @override
  String get findingPosition => 'Buscando tu ubicación…';

  @override
  String get needsPosition =>
      'Sun Clock necesita una ubicación para saber cuándo sale y se pone el sol.';

  @override
  String get retry => 'Reintentar';

  @override
  String get pickPlaceOnMap => 'Elegir un lugar en el mapa';

  @override
  String version(String build, String version) {
    return 'Versión $version ($build)';
  }

  @override
  String get sunTime => 'Hora del sol';

  @override
  String get aboutBody =>
      'Sun Clock divide el día en 24 horas que siguen al sol. La salida del sol es siempre a las 06:00 y la puesta siempre a las 18:00. Las 12 horas de día se reparten por igual la luz real del día, y las 12 horas de noche se reparten la noche.\n\nEn invierno, las horas de día son cortas y las de noche largas; en verano es al revés. En los equinoccios cada hora dura unos 60 minutos.\n\nLa salida y la puesta del sol se calculan con las fórmulas solares de la NOAA (el borde superior del sol toca el horizonte, con refracción estándar). Cuando el sol no sale o no se pone en absoluto, el reloj muestra la hora solar verdadera, con las 12:00 en el mediodía solar.';

  @override
  String get mapCredit => 'Datos del mapa: Natural Earth (dominio público).';

  @override
  String get licences => 'Licencias de código abierto';

  @override
  String get gpsServicesOff => 'Los servicios de ubicación están desactivados.';

  @override
  String get gpsPermissionDenied => 'No se concedió el permiso de ubicación.';

  @override
  String get gpsNoFix => 'No se pudo obtener una posición GPS.';

  @override
  String dialDay(String time) {
    return 'Hora del sol $time, día';
  }

  @override
  String dialNight(String time) {
    return 'Hora del sol $time, noche';
  }

  @override
  String get dialSolarSuffix => ', hora solar verdadera';

  @override
  String get sunTimeDay => 'Hora del sol · día';

  @override
  String get sunTimeNight => 'Hora del sol · noche';

  @override
  String get convertTime => 'Convertir una hora';

  @override
  String get locationHint => 'Abre el mapa para elegir un lugar';

  @override
  String get noSunset =>
      'Hoy el sol no se pone aquí.\nSe muestra la hora solar verdadera (12:00 = mediodía solar).';

  @override
  String get noSunrise =>
      'Hoy el sol no sale aquí.\nSe muestra la hora solar verdadera (12:00 = mediodía solar).';

  @override
  String get sunrise => 'Salida del sol';

  @override
  String get sunset => 'Puesta del sol';

  @override
  String sunriseAt(String time) {
    return 'Salida $time';
  }

  @override
  String sunsetAt(String time) {
    return 'Puesta $time';
  }

  @override
  String get local => 'Local';

  @override
  String get localTime => 'Hora local';

  @override
  String resultSunDay(String time) {
    return '$time hora del sol · día';
  }

  @override
  String resultSunNight(String time) {
    return '$time hora del sol · noche';
  }

  @override
  String get solarParen => '(hora solar verdadera)';

  @override
  String get notToday => 'Hoy no';

  @override
  String get andWord => 'y';

  @override
  String resultLocal(String times) {
    return '$times hora local';
  }

  @override
  String dayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String todayLine(String date, String zone) {
    return 'Hoy, $date · $zone';
  }

  @override
  String get monthsShort => 'ene,feb,mar,abr,may,jun,jul,ago,sep,oct,nov,dic';

  @override
  String get fromLocalToSun => 'De hora local a hora del sol';

  @override
  String get pickLocal => 'Elegir una hora local';

  @override
  String get fromSunToLocal => 'De hora del sol a hora local';

  @override
  String get pickSun => 'Elegir una hora del sol';

  @override
  String get converterNote =>
      'La hora del sol sigue la salida y la puesta del sol de hoy en este lugar: las 06:00 son la salida y las 18:00 la puesta.';

  @override
  String get locationAccuracy => 'Precisión de la ubicación';

  @override
  String get approximate => 'Aproximada';

  @override
  String get precise => 'Precisa';

  @override
  String get approximateHelp =>
      'Usa una ubicación aproximada, redondeada a 1 km más o menos. Las horas del sol solo cambian unos segundos por kilómetro, así que es suficiente y gasta menos batería.';

  @override
  String get preciseHelp =>
      'Usa el GPS para tu ubicación exacta. Las horas del sol son exactas al segundo; gasta algo más de batería.';

  @override
  String get privacyNote =>
      'En ambos casos, las horas del sol se calculan en este teléfono y tu ubicación no se envía a ningún sitio. El mapa está guardado en la aplicación, así que Sun Clock no usa internet en absoluto.';

  @override
  String get preciseDenied =>
      'El sistema solo permite la ubicación aproximada para Sun Clock. Activa «Ubicación precisa» en el permiso de ubicación de la aplicación.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get mapPlaceNote =>
      'Estás usando un lugar elegido en el mapa; esto se aplica cuando vuelvas al GPS.';

  @override
  String get statusBarTitle => 'Hora del sol en la barra de estado';

  @override
  String get statusBarHelp =>
      'Muestra la hora del sol como icono en la barra de estado y en el panel de notificaciones. Sigue funcionando y sigue tu ubicación con la aplicación cerrada.';

  @override
  String get chipTitle => 'Mostrar como texto en la barra de estado';

  @override
  String get chipHelp =>
      'Muestra la hora del sol como un chip de actualización en directo, por ejemplo «14:27», en lugar del pequeño icono de dos líneas.';

  @override
  String get chipOff =>
      'Las actualizaciones en directo están desactivadas para Sun Clock, así que se muestra el icono de dos líneas.';

  @override
  String get followAfterRestart => 'Seguir la ubicación tras un reinicio';

  @override
  String get followAfterRestartHelp =>
      'Usa tu ubicación en segundo plano para que el reloj de la barra de estado siga al teléfono tras un reinicio sin abrir la aplicación. Si está desactivado, se usa la última ubicación conocida hasta que abras la aplicación.';

  @override
  String get backgroundOff =>
      'El permiso de ubicación «Permitir siempre» está desactivado, así que tras un reinicio se usa la última ubicación conocida.';

  @override
  String get backgroundTitle => '¿Usar la ubicación en segundo plano?';

  @override
  String get backgroundDisclosure =>
      'Sun Clock recopila tu ubicación en segundo plano, también cuando la aplicación está cerrada o no se usa, para que la hora del sol de la barra de estado sea correcta tras reiniciar el teléfono y mientras viajas.\n\nTu ubicación solo se usa en este teléfono para calcular las horas del sol. Nunca sale del teléfono y no se comparte con nadie.\n\nEn la pantalla siguiente, elige «Permitir siempre».';

  @override
  String get noThanks => 'No, gracias';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get backgroundSnack =>
      'Elige «Permitir siempre» en el permiso de ubicación de Sun Clock para seguir al teléfono tras un reinicio.';

  @override
  String get notificationsSnack =>
      'Permite las notificaciones de Sun Clock para mostrar la hora del sol en la barra de estado.';

  @override
  String get myLocation => 'Mi ubicación';

  @override
  String get location => 'Lugar';

  @override
  String get dragMapToPick => 'Arrastra el mapa para elegir un lugar';

  @override
  String get fullScreenMap => 'Mapa a pantalla completa';

  @override
  String get back => 'Atrás';

  @override
  String get done => 'Listo';

  @override
  String get tapOrDragMap => 'Toca o arrastra el mapa para elegir un lugar.';

  @override
  String sunriseSunsetLine(String rise, String set) {
    return 'Salida $rise · puesta $set';
  }

  @override
  String get polarDay => 'Día polar';

  @override
  String get polarNight => 'Noche polar';

  @override
  String hourLine(String day, String night) {
    return 'Hora: día $day · noche $night';
  }

  @override
  String minutesShort(String n) {
    return '$n min';
  }

  @override
  String get sunriseAndSunset => 'Salida y puesta del sol';

  @override
  String chartLocalTime(String year, String zone) {
    return '$year · hora local, $zone';
  }

  @override
  String get sunHourLengthTitle => 'Duración de las horas de día y de noche';

  @override
  String get sunHourLengthSubtitle =>
      'Minutos reales por hora de día y por hora de noche';

  @override
  String get dayHour => 'Hora de día';

  @override
  String get nightHour => 'Hora de noche';

  @override
  String get polarGapsNote =>
      'Los huecos son el día polar o la noche polar, cuando el sol no sale o no se pone y el reloj muestra la hora solar verdadera.';

  @override
  String get today => 'hoy';

  @override
  String dayHourValue(String minutes) {
    return 'Hora de día $minutes min';
  }

  @override
  String nightHourValue(String minutes) {
    return 'Hora de noche $minutes min';
  }

  @override
  String get offsetTitle => 'Hora del sol frente a hora local';

  @override
  String offsetSubtitle(String day, String zone) {
    return '$day · adelantada (+) o atrasada (−) respecto a la hora local, $zone';
  }

  @override
  String get offsetToday => 'Hoy';

  @override
  String offsetAhead(String duration) {
    return '$duration adelantada';
  }

  @override
  String offsetBehind(String duration) {
    return '$duration atrasada';
  }

  @override
  String get offsetInStep => 'igual';

  @override
  String offsetNow(String value) {
    return 'Ahora: $value';
  }

  @override
  String get legendAhead => 'Hora del sol adelantada';

  @override
  String get legendBehind => 'Hora del sol atrasada';

  @override
  String get nowLabel => 'ahora';

  @override
  String hoursMinutes(String h, String m) {
    return '$h h $m min';
  }

  @override
  String get language => 'Idioma';

  @override
  String get phoneLanguage => 'Idioma del teléfono';

  @override
  String get widgetsTitle => 'Widget de pantalla de inicio';

  @override
  String get widgetsTileHelp => 'Relojes, información y colores';

  @override
  String get widgetsHelp =>
      'Toca un widget para cambiarlo. También puedes mantenerlo pulsado en la pantalla de inicio.';

  @override
  String get noWidgets =>
      'Todavía no hay ningún widget de Sun Clock en la pantalla de inicio.';

  @override
  String get addWidget => 'Añadir a inicio';

  @override
  String get addWidgetManual =>
      'Mantén pulsada la pantalla de inicio, elige Widgets y arrastra Sun Clock.';

  @override
  String widgetN(String n) {
    return 'Widget $n';
  }

  @override
  String get sectionClocks => 'Relojes';

  @override
  String get clockBoth => 'Ambas';

  @override
  String get clockLayout => 'Disposición';

  @override
  String get layoutStacked => 'Grande y pequeña';

  @override
  String get layoutSide => 'Lado a lado';

  @override
  String get largeClock => 'Reloj grande';

  @override
  String get leftClock => 'Reloj izquierdo';

  @override
  String get clockNames => 'Mostrar el nombre de los relojes';

  @override
  String get sectionInfo => 'Información';

  @override
  String get infoDayNight => 'Día o noche';

  @override
  String get infoNext => 'Próxima salida o puesta del sol';

  @override
  String get infoHourLength => 'Duración de una hora de día o de noche';

  @override
  String get infoOffset => 'Adelanto o retraso respecto a la hora local';

  @override
  String get infoPlace => 'Nombre del lugar';

  @override
  String get infoProgress => 'Avance del día o de la noche';

  @override
  String get sectionLook => 'Aspecto';

  @override
  String get background => 'Fondo';

  @override
  String opacity(String percent) {
    return 'Opacidad $percent %';
  }

  @override
  String get corners => 'Esquinas';

  @override
  String get cornersNone => 'Rectas';

  @override
  String get cornersSmall => 'Pequeñas';

  @override
  String get cornersMedium => 'Medianas';

  @override
  String get cornersLarge => 'Grandes';

  @override
  String get autoColors => 'Relojes ámbar de día, azules de noche';

  @override
  String get clockColor => 'Color de los relojes';

  @override
  String get textColor => 'Color del texto';

  @override
  String get dayWord => 'Día';

  @override
  String get nightWord => 'Noche';

  @override
  String widgetSunriseAt(String time) {
    return 'salida $time';
  }

  @override
  String widgetSunsetAt(String time) {
    return 'puesta $time';
  }

  @override
  String get widgetSolar => 'hora solar verdadera';

  @override
  String widgetOffset(String offset) {
    return 'hora del sol $offset';
  }

  @override
  String get widgetNoPosition => 'Abre Sun Clock para elegir un lugar';

  @override
  String dayHourLength(String minutes) {
    return '1 hora de día = $minutes minutos reales';
  }

  @override
  String nightHourLength(String minutes) {
    return '1 hora de noche = $minutes minutos reales';
  }

  @override
  String dayHourEquals(String n) {
    return 'hora de día = $n min';
  }

  @override
  String nightHourEquals(String n) {
    return 'hora de noche = $n min';
  }
}
