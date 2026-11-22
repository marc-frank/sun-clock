import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sun_clock/language.dart';
import 'package:sun_clock/location_model.dart';
import 'package:sun_clock/main.dart';
import 'package:sun_clock/status_bar_clock.dart';
import 'package:sun_clock/zone.dart';

/// Russian and Ukrainian texts are longer than English: the home page, the
/// chart grid and the settings sheet must still fit.
void main() {
  setUpAll(initZones);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final lang in ['ru', 'uk']) {
    for (final (size, scale) in const [
      (Size(360, 640), 1.3),
      (Size(800, 360), 1.0),
      (Size(1280, 800), 1.0),
    ]) {
      testWidgets('$lang at ${size.width}x${size.height}, text x$scale',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final language = LanguageSetting();
        await language.set(lang);
        final model = LocationModel()..setFromMap(52.52, 13.405);
        await tester.pumpWidget(SunClockApp(
            model: model,
            statusBar: StatusBarClock(model),
            language: language));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'home');
        expect(find.textContaining(lang == 'ru' ? 'Время солнца' : 'Час сонця'),
            findsWidgets,
            reason: 'shown in $lang');

        // The settings sheet.
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: 'settings');
        expect(find.text(lang == 'ru' ? 'Настройки' : 'Налаштування'),
            findsOneWidget);
        await tester.pump(const Duration(seconds: 1)); // let the save timer run
      });
    }
  }
}
