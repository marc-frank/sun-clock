import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sun_clock/animated_range.dart';
import 'package:sun_clock/clock_view.dart';
import 'package:sun_clock/language.dart';
import 'package:sun_clock/location_model.dart';
import 'package:sun_clock/main.dart';
import 'package:sun_clock/map_picker.dart';
import 'package:sun_clock/status_bar_clock.dart';
import 'package:sun_clock/zone.dart';

/// Landscape phones and tablets: two columns on the first screen, and the
/// charts and map in a 2×2 grid.
void main() {
  setUpAll(initZones);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpHome(WidgetTester tester, Size size,
      {double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final model = LocationModel()..setFromMap(52.52, 13.405);
    await tester.pumpWidget(SunClockApp(
        model: model,
        statusBar: StatusBarClock(model),
        language: LanguageSetting()));
    await tester.pump();
  }

  final dial = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is DialPainter);

  for (final (name, size, scale) in const [
    ('phone landscape', Size(800, 360), 1.0),
    ('small phone landscape, large text', Size(640, 320), 1.6),
    ('tablet landscape', Size(1280, 800), 1.0),
    ('tablet portrait', Size(800, 1280), 1.0),
  ]) {
    testWidgets('$name: two columns that fit the first screen',
        (tester) async {
      await pumpHome(tester, size, textScale: scale);
      expect(tester.takeException(), isNull);

      final dialRect = tester.getRect(dial);
      final times = tester.getRect(find.byType(TimeLines));
      expect(dialRect.center.dx, lessThan(times.left),
          reason: 'dial left of the times');
      final clock = tester.getRect(find.byType(ClockView));
      expect(clock.top, greaterThanOrEqualTo(0));
      expect(clock.bottom, lessThanOrEqualTo(size.height),
          reason: 'the first screen fits without scrolling');
      expect(clock.right, lessThanOrEqualTo(size.width));
      await tester.pump(const Duration(seconds: 1)); // let the save timer run
    });
  }

  testWidgets('wide: charts and map in two columns and two rows',
      (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    final sunrise = tester.getRect(find.text('Sunrise and sunset'));
    final offset = tester.getRect(find.text('Sun time vs local time'));
    final hours = tester.getRect(find.text('Length of day and night hours'));
    final map = tester.getRect(find.byType(MapPanel));

    expect(offset.left, greaterThan(640), reason: 'right column');
    expect(sunrise.left, lessThan(640), reason: 'left column');
    expect(offset.top, closeTo(sunrise.top, 1), reason: 'same row');
    expect(hours.left, lessThan(640));
    expect(hours.top, greaterThan(sunrise.top + 200), reason: 'second row');
    expect(map.left, greaterThan(640));
    expect(map.top, lessThan(hours.top + 20), reason: 'beside the hours');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('narrow: one column, map last', (tester) async {
    await pumpHome(tester, const Size(400, 800));
    final sunrise = tester.getRect(find.text('Sunrise and sunset'));
    final offset = tester.getRect(find.text('Sun time vs local time'));
    final map = tester.getRect(find.byType(MapPanel));
    expect(offset.left, closeTo(sunrise.left, 1));
    expect(offset.top, greaterThan(sunrise.top));
    expect(map.top, greaterThan(offset.top));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the y-range glides to new limits', (tester) async {
    final seen = <double>[];
    Widget range(double min, double max) => Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedYRange(
            min: min,
            max: max,
            builder: (context, lo, hi) {
              seen.add(lo);
              return const SizedBox();
            },
          ),
        );
    await tester.pumpWidget(range(0, 60));
    expect(seen.last, 0, reason: 'no animation on first show');
    await tester.pumpWidget(range(-120, 60));
    await tester.pump(const Duration(milliseconds: 175));
    expect(seen.last, inExclusiveRange(-120, 0), reason: 'part way');
    await tester.pump(const Duration(milliseconds: 400));
    expect(seen.last, -120);
  });

  test('axis labels only on whole steps', () {
    expect(onInterval(60, 30), isTrue);
    expect(onInterval(-90, 30), isTrue);
    expect(onInterval(37.5, 15), isFalse);
    expect(onInterval(0, 15), isTrue);
  });
}
