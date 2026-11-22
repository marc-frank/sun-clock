// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get sourceGpsApprox => 'GPS, приблизно';

  @override
  String get sourceGps => 'GPS';

  @override
  String get sourceMap => 'вибрано на карті';

  @override
  String get aboutTooltip => 'Про час сонця';

  @override
  String get statusBarHide => 'Прибрати час сонця з рядка стану';

  @override
  String get statusBarShow => 'Показувати час сонця в рядку стану';

  @override
  String get settings => 'Налаштування';

  @override
  String get pickOnMapTooltip => 'Вибрати місце на карті';

  @override
  String get theYear => 'Рік';

  @override
  String get findingPosition => 'Визначаємо місцезнаходження…';

  @override
  String get needsPosition =>
      'Sun Clock потрібне місцезнаходження, щоб знати, коли сонце сходить і заходить.';

  @override
  String get retry => 'Повторити';

  @override
  String get pickPlaceOnMap => 'Вибрати місце на карті';

  @override
  String version(String build, String version) {
    return 'Версія $version ($build)';
  }

  @override
  String get sunTime => 'Час сонця';

  @override
  String get aboutBody =>
      'Sun Clock ділить добу на 24 години, які слідують за сонцем. Схід завжди о 06:00, а захід завжди о 18:00. 12 денних годин порівну ділять справжній світлий день, а 12 нічних годин — ніч.\n\nВзимку денні години короткі, а нічні довгі; влітку навпаки. У дні рівнодення кожна година близька до 60 хвилин.\n\nСхід і захід розраховуються за сонячними формулами NOAA (верхній край сонця торкається горизонту, зі стандартною рефракцією). Коли сонце зовсім не сходить або не заходить, годинник показує істинний сонячний час, де 12:00 — сонячний полудень.';

  @override
  String get mapCredit => 'Дані карти: Natural Earth (суспільне надбання).';

  @override
  String get licences => 'Ліцензії відкритого ПЗ';

  @override
  String get gpsServicesOff => 'Служби геолокації вимкнено.';

  @override
  String get gpsPermissionDenied => 'Доступ до місцезнаходження не надано.';

  @override
  String get gpsNoFix => 'Не вдалося визначити місцезнаходження за GPS.';

  @override
  String dialDay(String time) {
    return 'Час сонця $time, день';
  }

  @override
  String dialNight(String time) {
    return 'Час сонця $time, ніч';
  }

  @override
  String get dialSolarSuffix => ', сонячний час';

  @override
  String get sunTimeDay => 'Час сонця · день';

  @override
  String get sunTimeNight => 'Час сонця · ніч';

  @override
  String get convertTime => 'Перевести час';

  @override
  String get locationHint => 'Відкриває карту для вибору місця';

  @override
  String get noSunset =>
      'Сьогодні тут сонце не заходить.\nПоказано сонячний час (12:00 = сонячний полудень).';

  @override
  String get noSunrise =>
      'Сьогодні тут сонце не сходить.\nПоказано сонячний час (12:00 = сонячний полудень).';

  @override
  String get sunrise => 'Схід';

  @override
  String get sunset => 'Захід';

  @override
  String sunriseAt(String time) {
    return 'Схід $time';
  }

  @override
  String sunsetAt(String time) {
    return 'Захід $time';
  }

  @override
  String get local => 'Місцевий';

  @override
  String get localTime => 'Місцевий час';

  @override
  String resultSunDay(String time) {
    return '$time за часом сонця · день';
  }

  @override
  String resultSunNight(String time) {
    return '$time за часом сонця · ніч';
  }

  @override
  String get solarParen => '(сонячний час)';

  @override
  String get notToday => 'Не сьогодні';

  @override
  String get andWord => 'і';

  @override
  String resultLocal(String times) {
    return '$times за місцевим часом';
  }

  @override
  String dayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String todayLine(String date, String zone) {
    return 'Сьогодні, $date · $zone';
  }

  @override
  String get monthsShort =>
      'січ,лют,бер,квіт,трав,черв,лип,серп,вер,жовт,лист,груд';

  @override
  String get fromLocalToSun => 'З місцевого часу в час сонця';

  @override
  String get pickLocal => 'Вибрати місцевий час';

  @override
  String get fromSunToLocal => 'З часу сонця в місцевий час';

  @override
  String get pickSun => 'Вибрати час сонця';

  @override
  String get converterNote =>
      'Час сонця тут слідує за сьогоднішнім сходом і заходом: 06:00 — схід, 18:00 — захід.';

  @override
  String get locationAccuracy => 'Точність місцезнаходження';

  @override
  String get approximate => 'Приблизно';

  @override
  String get precise => 'Точно';

  @override
  String get approximateHelp =>
      'Використовує приблизне місцезнаходження, округлене приблизно до 1 км. Час сонця зміщується лише на кілька секунд на кілометр, тож цієї точності достатньо, а заряду витрачається менше.';

  @override
  String get preciseHelp =>
      'Використовує GPS для точного місцезнаходження. Час сонця стає точним до секунди; заряду витрачається трохи більше.';

  @override
  String get privacyNote =>
      'В обох випадках час сонця розраховується на цьому телефоні, а ваше місцезнаходження нікуди не надсилається. Карта зберігається в застосунку; Sun Clock виходить в інтернет лише для перевірки оновлень, якщо ви її ввімкнете.';

  @override
  String get preciseDenied =>
      'Система дозволяє Sun Clock лише приблизне місцезнаходження. Увімкніть «Точне місцезнаходження» в дозволі застосунку на доступ до геоданих.';

  @override
  String get openSettings => 'Відкрити налаштування';

  @override
  String get mapPlaceNote =>
      'Зараз використовується місце, вибране на карті; це налаштування набуде чинності, коли ви знову перейдете на GPS.';

  @override
  String get statusBarTitle => 'Час сонця в рядку стану';

  @override
  String get statusBarHelp =>
      'Показує час сонця значком у рядку стану та на панелі сповіщень. Працює і стежить за вашим місцезнаходженням, поки застосунок закрито.';

  @override
  String get chipTitle => 'Показувати текстом у рядку стану';

  @override
  String get chipHelp =>
      'Показує час сонця у вигляді чипа Live Update, наприклад «14:27», замість маленького значка з двох рядків.';

  @override
  String get chipOff =>
      'Live Updates для Sun Clock вимкнено, тому показано значок із двох рядків.';

  @override
  String get followAfterRestart => 'Стежити за місцезнаходженням у фоні';

  @override
  String get followAfterRestartHelp =>
      'Віджет на головному екрані та годинник у рядку стану стежать за телефоном, поки застосунок закрито, а також після перезавантаження. Потрібен доступ до місцезнаходження «Дозволити завжди». Якщо вимкнено, вони зберігають останнє місцезнаходження, доки ви не відкриєте застосунок.';

  @override
  String get backgroundOff =>
      'Доступ «Дозволити завжди» вимкнено, тому віджет і годинник у рядку стану зберігають останнє місцезнаходження, доки ви не відкриєте застосунок.';

  @override
  String get backgroundTitle => 'Використовувати місцезнаходження у фоні?';

  @override
  String get backgroundDisclosure =>
      'Sun Clock отримує ваше місцезнаходження у фоновому режимі, зокрема коли застосунок закрито або він не використовується, щоб час сонця у віджеті на головному екрані та в рядку стану залишався правильним у поїздках і після перезавантаження телефона.\n\nВаше місцезнаходження використовується лише на цьому телефоні для розрахунку часу сонця. Воно ніколи не залишає телефон і нікому не передається.\n\nНа наступному екрані виберіть «Дозволити завжди».';

  @override
  String get noThanks => 'Ні, дякую';

  @override
  String get continueLabel => 'Продовжити';

  @override
  String get backgroundSnack =>
      'Виберіть «Дозволити завжди» в дозволі Sun Clock на доступ до геоданих, щоб стежити за телефоном, поки застосунок закрито.';

  @override
  String get notificationsSnack =>
      'Дозвольте сповіщення для Sun Clock, щоб показувати час сонця в рядку стану.';

  @override
  String get myLocation => 'Моє місцезнаходження';

  @override
  String get location => 'Місцезнаходження';

  @override
  String get dragMapToPick => 'Перетягніть карту, щоб вибрати місце';

  @override
  String get fullScreenMap => 'Карта на весь екран';

  @override
  String get back => 'Назад';

  @override
  String get done => 'Готово';

  @override
  String get tapOrDragMap =>
      'Торкніться карти або перетягніть її, щоб вибрати місце.';

  @override
  String sunriseSunsetLine(String rise, String set) {
    return 'Схід $rise · захід $set';
  }

  @override
  String get polarDay => 'Полярний день';

  @override
  String get polarNight => 'Полярна ніч';

  @override
  String hourLine(String day, String night) {
    return 'Година: день $day · ніч $night';
  }

  @override
  String minutesShort(String n) {
    return '$n хв';
  }

  @override
  String get sunriseAndSunset => 'Схід і захід сонця';

  @override
  String chartLocalTime(String year, String zone) {
    return '$year · місцевий час, $zone';
  }

  @override
  String get sunHourLengthTitle => 'Тривалість денних і нічних годин';

  @override
  String get sunHourLengthSubtitle =>
      'Справжніх хвилин в одній денній та одній нічній годині';

  @override
  String get dayHour => 'Денна година';

  @override
  String get nightHour => 'Нічна година';

  @override
  String get polarGapsNote =>
      'Пропуски — це полярний день або полярна ніч, коли сонце не сходить або не заходить і годинник показує сонячний час.';

  @override
  String get today => 'сьогодні';

  @override
  String dayHourValue(String minutes) {
    return 'Денна година $minutes хв';
  }

  @override
  String nightHourValue(String minutes) {
    return 'Нічна година $minutes хв';
  }

  @override
  String get offsetTitle => 'Час сонця і місцевий час';

  @override
  String offsetSubtitle(String day, String zone) {
    return '$day · попереду (+) або позаду (−) місцевого годинника, $zone';
  }

  @override
  String get offsetToday => 'Сьогодні';

  @override
  String offsetAhead(String duration) {
    return 'попереду на $duration';
  }

  @override
  String offsetBehind(String duration) {
    return 'позаду на $duration';
  }

  @override
  String get offsetInStep => 'збігається';

  @override
  String offsetNow(String value) {
    return 'Зараз: $value';
  }

  @override
  String get legendAhead => 'Час сонця попереду';

  @override
  String get legendBehind => 'Час сонця позаду';

  @override
  String get nowLabel => 'зараз';

  @override
  String hoursMinutes(String h, String m) {
    return '$h год $m хв';
  }

  @override
  String get language => 'Мова';

  @override
  String get phoneLanguage => 'Мова телефона';

  @override
  String get widgetsTitle => 'Віджет на головному екрані';

  @override
  String get widgetsTileHelp => 'Годинники, відомості та кольори';

  @override
  String get widgetsHelp =>
      'Торкніться віджета, щоб змінити його. Також можна довго натиснути на нього на головному екрані.';

  @override
  String get noWidgets => 'На головному екрані ще немає віджета Sun Clock.';

  @override
  String get addWidget => 'Додати на головний екран';

  @override
  String get addWidgetManual =>
      'Довго натисніть на головний екран, виберіть «Віджети» і перетягніть на нього Sun Clock.';

  @override
  String widgetN(String n) {
    return 'Віджет $n';
  }

  @override
  String get sectionClocks => 'Годинники';

  @override
  String get clockBoth => 'Обидва';

  @override
  String get clockLayout => 'Розташування';

  @override
  String get layoutStacked => 'Великий і малий';

  @override
  String get layoutSide => 'Поруч';

  @override
  String get largeClock => 'Великий годинник';

  @override
  String get leftClock => 'Лівий годинник';

  @override
  String get clockNames => 'Показувати назви годинників';

  @override
  String get sectionInfo => 'Відомості';

  @override
  String get infoDayNight => 'День чи ніч';

  @override
  String get infoNext => 'Наступний схід або захід';

  @override
  String get infoHourLength => 'Тривалість денної або нічної години';

  @override
  String get infoOffset => 'Час сонця попереду чи позаду місцевого';

  @override
  String get infoPlace => 'Назва місця';

  @override
  String get infoProgress => 'Перебіг дня або ночі';

  @override
  String get sectionLook => 'Вигляд';

  @override
  String get background => 'Фон';

  @override
  String opacity(String percent) {
    return 'Непрозорість $percent %';
  }

  @override
  String get corners => 'Кути';

  @override
  String get cornersNone => 'Прямі';

  @override
  String get cornersSmall => 'Малі';

  @override
  String get cornersMedium => 'Середні';

  @override
  String get cornersLarge => 'Великі';

  @override
  String get autoColors => 'Годинники бурштинові вдень і сині вночі';

  @override
  String get clockColor => 'Колір годинників';

  @override
  String get textColor => 'Колір тексту';

  @override
  String get dayWord => 'День';

  @override
  String get nightWord => 'Ніч';

  @override
  String widgetSunriseAt(String time) {
    return 'схід $time';
  }

  @override
  String widgetSunsetAt(String time) {
    return 'захід $time';
  }

  @override
  String get widgetSolar => 'істинний сонячний час';

  @override
  String widgetOffset(String offset) {
    return 'час сонця $offset';
  }

  @override
  String get widgetNoPosition => 'Відкрийте Sun Clock, щоб вибрати місце';

  @override
  String dayHourLength(String minutes) {
    return '1 денна година = $minutes справжніх хвилин';
  }

  @override
  String nightHourLength(String minutes) {
    return '1 нічна година = $minutes справжніх хвилин';
  }

  @override
  String dayHourEquals(String n) {
    return 'денна година = $n хв';
  }

  @override
  String nightHourEquals(String n) {
    return 'нічна година = $n хв';
  }

  @override
  String get updateCheckTitle => 'Перевіряти оновлення';

  @override
  String get updateCheckHelp =>
      'Приблизно раз на тиждень запитує GitHub, чи є новіша версія Sun Clock. В інтернет іде лише цей запит; ваше місцезнаходження ніколи не залишає телефон.';

  @override
  String updateAvailable(String version) {
    return 'Доступна Sun Clock $version.';
  }

  @override
  String get upToDate => 'У вас остання версія Sun Clock.';

  @override
  String get updateFailed => 'Не вдалося зв’язатися з GitHub.';

  @override
  String get checkNow => 'Перевірити';

  @override
  String get download => 'Завантажити';

  @override
  String get later => 'Пізніше';

  @override
  String goldenHourLine(String times) {
    return 'Золота година $times';
  }

  @override
  String blueHourLine(String times) {
    return 'Синя година $times';
  }

  @override
  String get addWidgetManualIos =>
      'Натисніть і утримуйте початковий екран або екран блокування, торкніться + або «Змінити» → «Додати віджет» і виберіть Sun Clock.';

  @override
  String get widgetsHelpIos =>
      'Ці налаштування діють для всіх віджетів Sun Clock на початковому екрані. Віджети на екрані блокування показують час сонця в стилі системи.';
}
