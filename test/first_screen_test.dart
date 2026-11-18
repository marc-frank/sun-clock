import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sun_clock/clock_view.dart';
import 'package:sun_clock/location_model.dart';
import 'package:sun_clock/main.dart';
import 'package:sun_clock/status_bar_clock.dart';
import 'package:sun_clock/zone.dart';

/// The first screen on small phones, in landscape and with large text.
void main() {
  setUpAll(initZones);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpHome(WidgetTester tester, Size size, double textScale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final model = LocationModel()..setFromMap(52.52, 13.405);
    await tester.pumpWidget(SunClockApp(
        model: model, statusBar: StatusBarClock(model)));
    await tester.pump();
  }

  final dialFinder = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is DialPainter);

  // Layout overflows are reported as errors and fail the test by
  // themselves; the explicit check makes the intent visible.
  for (final (size, scale) in const [
    (Size(360, 640), 2.0),
    (Size(360, 640), 1.0),
    (Size(320, 568), 1.3),
    (Size(640, 360), 1.0),
    (Size(640, 360), 2.0),
    (Size(1000, 800), 1.0),
  ]) {
    testWidgets('no overflow at ${size.width}×${size.height}, text ×$scale',
        (tester) async {
      await pumpHome(tester, size, scale);
      expect(tester.takeException(), isNull);
      final dial = tester.getSize(dialFinder);
      expect(dial.width, inInclusiveRange(120, 300));
      expect(dial.width, lessThanOrEqualTo(size.width - 32));
      await tester.pump(const Duration(seconds: 1)); // let the save timer run
    });
  }

  testWidgets('dial is larger on a tall phone', (tester) async {
    await pumpHome(tester, const Size(412, 915), 1.0);
    expect(tester.getSize(dialFinder).width, 300);
    await tester.pump(const Duration(seconds: 1)); // let the save timer run
  });

  testWidgets('screen readers get a dial label, tooltips and hints',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester, const Size(400, 800), 1.0);

    expect(find.bySemanticsLabel(RegExp(r'^Sun time \d\d:\d\d, (day|night)$')),
        findsOneWidget);
    for (final tip in ['About sun time', 'Settings', 'Pick location on map']) {
      expect(find.byTooltip(tip), findsOneWidget);
    }
    final location = find.ancestor(
        of: find.textContaining('Europe/Berlin'),
        matching: find.byType(Semantics));
    expect(
        tester.getSemantics(location.first),
        isSemantics(
          hint: 'Opens the map to pick a place',
          isButton: true,
          hasTapAction: true,
        ));
    await tester.pump(const Duration(seconds: 1)); // let the save timer run
    handle.dispose();
  });
}
