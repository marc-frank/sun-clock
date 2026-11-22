// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get sourceGpsApprox => 'GPS, приблизительно';

  @override
  String get sourceGps => 'GPS';

  @override
  String get sourceMap => 'выбрано на карте';

  @override
  String get aboutTooltip => 'О времени солнца';

  @override
  String get statusBarHide => 'Убрать время солнца из строки состояния';

  @override
  String get statusBarShow => 'Показывать время солнца в строке состояния';

  @override
  String get settings => 'Настройки';

  @override
  String get pickOnMapTooltip => 'Выбрать место на карте';

  @override
  String get theYear => 'Год';

  @override
  String get findingPosition => 'Определяем местоположение…';

  @override
  String get needsPosition =>
      'Sun Clock нужно местоположение, чтобы знать, когда восходит и заходит солнце.';

  @override
  String get retry => 'Повторить';

  @override
  String get pickPlaceOnMap => 'Выбрать место на карте';

  @override
  String version(String build, String version) {
    return 'Версия $version ($build)';
  }

  @override
  String get sunTime => 'Время солнца';

  @override
  String get aboutBody =>
      'Sun Clock делит сутки на 24 часа, которые следуют за солнцем. Восход всегда в 06:00, а закат всегда в 18:00. 12 дневных часов поровну делят настоящий светлый день, а 12 ночных часов — ночь.\n\nЗимой дневные часы короткие, а ночные длинные; летом наоборот. В дни равноденствия каждый час близок к 60 минутам.\n\nВосход и закат рассчитываются по солнечным формулам NOAA (верхний край солнца касается горизонта, со стандартной рефракцией). Когда солнце вовсе не восходит или не заходит, часы показывают истинное солнечное время, где 12:00 — солнечный полдень.';

  @override
  String get mapCredit =>
      'Данные карты: Natural Earth (общественное достояние).';

  @override
  String get licences => 'Лицензии открытого ПО';

  @override
  String get gpsServicesOff => 'Службы геолокации выключены.';

  @override
  String get gpsPermissionDenied => 'Доступ к местоположению не предоставлен.';

  @override
  String get gpsNoFix => 'Не удалось определить местоположение по GPS.';

  @override
  String dialDay(String time) {
    return 'Время солнца $time, день';
  }

  @override
  String dialNight(String time) {
    return 'Время солнца $time, ночь';
  }

  @override
  String get dialSolarSuffix => ', солнечное время';

  @override
  String get sunTimeDay => 'Время солнца · день';

  @override
  String get sunTimeNight => 'Время солнца · ночь';

  @override
  String get convertTime => 'Перевести время';

  @override
  String get locationHint => 'Открывает карту для выбора места';

  @override
  String get noSunset =>
      'Сегодня здесь солнце не заходит.\nПоказано солнечное время (12:00 = солнечный полдень).';

  @override
  String get noSunrise =>
      'Сегодня здесь солнце не восходит.\nПоказано солнечное время (12:00 = солнечный полдень).';

  @override
  String get sunrise => 'Восход';

  @override
  String get sunset => 'Закат';

  @override
  String sunriseAt(String time) {
    return 'Восход $time';
  }

  @override
  String sunsetAt(String time) {
    return 'Закат $time';
  }

  @override
  String get local => 'Местное';

  @override
  String get localTime => 'Местное время';

  @override
  String resultSunDay(String time) {
    return '$time по времени солнца · день';
  }

  @override
  String resultSunNight(String time) {
    return '$time по времени солнца · ночь';
  }

  @override
  String get solarParen => '(солнечное время)';

  @override
  String get notToday => 'Не сегодня';

  @override
  String get andWord => 'и';

  @override
  String resultLocal(String times) {
    return '$times по местному времени';
  }

  @override
  String dayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String todayLine(String date, String zone) {
    return 'Сегодня, $date · $zone';
  }

  @override
  String get monthsShort => 'янв,фев,мар,апр,мая,июн,июл,авг,сен,окт,ноя,дек';

  @override
  String get fromLocalToSun => 'Из местного времени во время солнца';

  @override
  String get pickLocal => 'Выбрать местное время';

  @override
  String get fromSunToLocal => 'Из времени солнца в местное время';

  @override
  String get pickSun => 'Выбрать время солнца';

  @override
  String get converterNote =>
      'Время солнца здесь следует за сегодняшним восходом и закатом: 06:00 — восход, 18:00 — закат.';

  @override
  String get locationAccuracy => 'Точность местоположения';

  @override
  String get approximate => 'Приблизительно';

  @override
  String get precise => 'Точно';

  @override
  String get approximateHelp =>
      'Использует приблизительное местоположение, округлённое примерно до 1 км. Время солнца смещается лишь на несколько секунд на километр, так что этой точности достаточно, а заряд расходуется меньше.';

  @override
  String get preciseHelp =>
      'Использует GPS для точного местоположения. Время солнца становится точным до секунды; заряд расходуется немного больше.';

  @override
  String get privacyNote =>
      'В обоих случаях время солнца рассчитывается на этом телефоне, и ваше местоположение никуда не отправляется. Карта хранится в приложении; Sun Clock выходит в интернет только для проверки обновлений, если вы её включите.';

  @override
  String get preciseDenied =>
      'Система разрешает Sun Clock только приблизительное местоположение. Включите «Точное местоположение» в разрешении приложения на доступ к геоданным.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get mapPlaceNote =>
      'Сейчас используется место, выбранное на карте; эта настройка вступит в силу, когда вы снова переключитесь на GPS.';

  @override
  String get statusBarTitle => 'Время солнца в строке состояния';

  @override
  String get statusBarHelp =>
      'Показывает время солнца значком в строке состояния и в панели уведомлений. Работает и следует за вашим местоположением, пока приложение закрыто.';

  @override
  String get chipTitle => 'Показывать текстом в строке состояния';

  @override
  String get chipHelp =>
      'Показывает время солнца в виде чипа Live Update, например «14:27», вместо маленького значка из двух строк.';

  @override
  String get chipOff =>
      'Live Updates для Sun Clock выключены, поэтому показан значок из двух строк.';

  @override
  String get followAfterRestart => 'Следовать за местоположением в фоне';

  @override
  String get followAfterRestartHelp =>
      'Виджет на главном экране и часы в строке состояния следуют за телефоном, пока приложение закрыто, а также после перезагрузки. Нужен доступ к местоположению «Разрешить в любом режиме». Если выключено, они сохраняют последнее местоположение, пока вы не откроете приложение.';

  @override
  String get backgroundOff =>
      'Доступ «Разрешить в любом режиме» выключен, поэтому виджет и часы в строке состояния сохраняют последнее местоположение, пока вы не откроете приложение.';

  @override
  String get backgroundTitle => 'Использовать местоположение в фоне?';

  @override
  String get backgroundDisclosure =>
      'Sun Clock получает ваше местоположение в фоновом режиме, в том числе когда приложение закрыто или не используется, чтобы время солнца в виджете на главном экране и в строке состояния оставалось верным в поездках и после перезагрузки телефона.\n\nВаше местоположение используется только на этом телефоне для расчёта времени солнца. Оно никогда не покидает телефон и никому не передаётся.\n\nНа следующем экране выберите «Разрешить в любом режиме».';

  @override
  String get noThanks => 'Нет, спасибо';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get backgroundSnack =>
      'Выберите «Разрешить в любом режиме» в разрешении Sun Clock на доступ к геоданным, чтобы следовать за телефоном, пока приложение закрыто.';

  @override
  String get notificationsSnack =>
      'Разрешите уведомления для Sun Clock, чтобы показывать время солнца в строке состояния.';

  @override
  String get myLocation => 'Моё местоположение';

  @override
  String get location => 'Местоположение';

  @override
  String get dragMapToPick => 'Перетащите карту, чтобы выбрать место';

  @override
  String get fullScreenMap => 'Карта во весь экран';

  @override
  String get back => 'Назад';

  @override
  String get done => 'Готово';

  @override
  String get tapOrDragMap =>
      'Нажмите на карту или перетащите её, чтобы выбрать место.';

  @override
  String sunriseSunsetLine(String rise, String set) {
    return 'Восход $rise · закат $set';
  }

  @override
  String get polarDay => 'Полярный день';

  @override
  String get polarNight => 'Полярная ночь';

  @override
  String hourLine(String day, String night) {
    return 'Час: день $day · ночь $night';
  }

  @override
  String minutesShort(String n) {
    return '$n мин';
  }

  @override
  String get sunriseAndSunset => 'Восход и закат';

  @override
  String chartLocalTime(String year, String zone) {
    return '$year · местное время, $zone';
  }

  @override
  String get sunHourLengthTitle => 'Длительность дневных и ночных часов';

  @override
  String get sunHourLengthSubtitle =>
      'Настоящих минут в одном дневном и одном ночном часе';

  @override
  String get dayHour => 'Дневной час';

  @override
  String get nightHour => 'Ночной час';

  @override
  String get polarGapsNote =>
      'Пропуски — это полярный день или полярная ночь, когда солнце не восходит или не заходит и часы показывают солнечное время.';

  @override
  String get today => 'сегодня';

  @override
  String dayHourValue(String minutes) {
    return 'Дневной час $minutes мин';
  }

  @override
  String nightHourValue(String minutes) {
    return 'Ночной час $minutes мин';
  }

  @override
  String get offsetTitle => 'Время солнца и местное время';

  @override
  String offsetSubtitle(String day, String zone) {
    return '$day · впереди (+) или позади (−) местных часов, $zone';
  }

  @override
  String get offsetToday => 'Сегодня';

  @override
  String offsetAhead(String duration) {
    return 'впереди на $duration';
  }

  @override
  String offsetBehind(String duration) {
    return 'позади на $duration';
  }

  @override
  String get offsetInStep => 'совпадает';

  @override
  String offsetNow(String value) {
    return 'Сейчас: $value';
  }

  @override
  String get legendAhead => 'Время солнца впереди';

  @override
  String get legendBehind => 'Время солнца позади';

  @override
  String get nowLabel => 'сейчас';

  @override
  String hoursMinutes(String h, String m) {
    return '$h ч $m мин';
  }

  @override
  String get language => 'Язык';

  @override
  String get phoneLanguage => 'Язык телефона';

  @override
  String get widgetsTitle => 'Виджет на главном экране';

  @override
  String get widgetsTileHelp => 'Часы, сведения и цвета';

  @override
  String get widgetsHelp =>
      'Нажмите на виджет, чтобы изменить его. Можно также долго нажать на него на главном экране.';

  @override
  String get noWidgets => 'На главном экране пока нет виджета Sun Clock.';

  @override
  String get addWidget => 'Добавить на главный экран';

  @override
  String get addWidgetManual =>
      'Долго нажмите на главный экран, выберите «Виджеты» и перетащите на него Sun Clock.';

  @override
  String widgetN(String n) {
    return 'Виджет $n';
  }

  @override
  String get sectionClocks => 'Часы';

  @override
  String get clockBoth => 'Оба';

  @override
  String get clockLayout => 'Расположение';

  @override
  String get layoutStacked => 'Большие и маленькие';

  @override
  String get layoutSide => 'Рядом';

  @override
  String get largeClock => 'Большие часы';

  @override
  String get leftClock => 'Левые часы';

  @override
  String get clockNames => 'Показывать названия часов';

  @override
  String get sectionInfo => 'Сведения';

  @override
  String get infoDayNight => 'День или ночь';

  @override
  String get infoNext => 'Следующий восход или закат';

  @override
  String get infoHourLength => 'Длительность дневного или ночного часа';

  @override
  String get infoOffset => 'Время солнца впереди или позади местного';

  @override
  String get infoPlace => 'Название места';

  @override
  String get infoProgress => 'Ход дня или ночи';

  @override
  String get sectionLook => 'Внешний вид';

  @override
  String get background => 'Фон';

  @override
  String opacity(String percent) {
    return 'Непрозрачность $percent %';
  }

  @override
  String get corners => 'Углы';

  @override
  String get cornersNone => 'Прямые';

  @override
  String get cornersSmall => 'Малые';

  @override
  String get cornersMedium => 'Средние';

  @override
  String get cornersLarge => 'Большие';

  @override
  String get autoColors => 'Часы янтарные днём и синие ночью';

  @override
  String get clockColor => 'Цвет часов';

  @override
  String get textColor => 'Цвет текста';

  @override
  String get dayWord => 'День';

  @override
  String get nightWord => 'Ночь';

  @override
  String widgetSunriseAt(String time) {
    return 'восход $time';
  }

  @override
  String widgetSunsetAt(String time) {
    return 'закат $time';
  }

  @override
  String get widgetSolar => 'истинное солнечное время';

  @override
  String widgetOffset(String offset) {
    return 'время солнца $offset';
  }

  @override
  String get widgetNoPosition => 'Откройте Sun Clock, чтобы выбрать место';

  @override
  String dayHourLength(String minutes) {
    return '1 дневной час = $minutes настоящих минут';
  }

  @override
  String nightHourLength(String minutes) {
    return '1 ночной час = $minutes настоящих минут';
  }

  @override
  String dayHourEquals(String n) {
    return 'дневной час = $n мин';
  }

  @override
  String nightHourEquals(String n) {
    return 'ночной час = $n мин';
  }

  @override
  String get updateCheckTitle => 'Проверять обновления';

  @override
  String get updateCheckHelp =>
      'Примерно раз в неделю спрашивает GitHub, есть ли новая версия Sun Clock. В интернет уходит только этот запрос; ваше местоположение никогда не покидает телефон.';

  @override
  String updateAvailable(String version) {
    return 'Доступна Sun Clock $version.';
  }

  @override
  String get upToDate => 'У вас последняя версия Sun Clock.';

  @override
  String get updateFailed => 'Не удалось связаться с GitHub.';

  @override
  String get checkNow => 'Проверить';

  @override
  String get download => 'Скачать';

  @override
  String get later => 'Позже';
}
