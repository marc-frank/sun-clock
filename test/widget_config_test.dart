import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sun_clock/home_widget.dart';
import 'package:sun_clock/l10n/l10n.dart';
import 'package:sun_clock/location_model.dart';
import 'package:sun_clock/widget_editor.dart';
import 'package:sun_clock/zone.dart';

void main() {
  setUpAll(initZones);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('WidgetConfig', () {
    test('round-trips through its map', () {
      const c = WidgetConfig(
        clocks: WidgetClocks.both,
        layout: WidgetLayout.side,
        first: WidgetFirst.local,
        labels: true,
        offset: true,
        progress: true,
        background: 0x80FFFFFF,
        corners: 28,
        autoColors: false,
        timeColor: 0xFF000000,
      );
      expect(WidgetConfig.fromMap(c.toMap()), c);
    });

    test('reads colours sent back as negative ints and ignores junk', () {
      final c = WidgetConfig.fromMap({
        'background': 0x801C1B17 - 0x100000000, // as Android's Int
        'clocks': 'all',
        'corners': 5,
        'labels': 'yes',
      });
      expect(c.background, 0x801C1B17);
      expect(c.clocks, WidgetClocks.sun);
      expect(c.corners, 16);
      expect(c.labels, isFalse);
    });

    test('opacity keeps the colour', () {
      final c = const WidgetConfig(background: 0xFF123456).withOpacity(0.5);
      expect(c.background & 0xFFFFFF, 0x123456);
      expect(c.opacity, closeTo(0.5, 0.01));
    });

    test('primary and secondary clocks', () {
      expect(const WidgetConfig(clocks: WidgetClocks.local).primary,
          WidgetFirst.local);
      expect(const WidgetConfig(clocks: WidgetClocks.local).secondary, isNull);
      const both =
          WidgetConfig(clocks: WidgetClocks.both, first: WidgetFirst.local);
      expect(both.primary, WidgetFirst.local);
      expect(both.secondary, WidgetFirst.sun);
    });
  });

  test('day progress', () {
    expect(dayProgress(const Duration(hours: 6)), 0);
    expect(dayProgress(const Duration(hours: 12)), 0.5);
    expect(dayProgress(const Duration(hours: 0)), 0.5);
    expect(dayProgress(const Duration(hours: 3)), 0.75);
  });

  testWidgets('preview shows both clocks side by side without overflow',
      (tester) async {
    final model = LocationModel()..setFromMap(52.52, 13.405);
    for (final c in const [
      WidgetConfig(),
      WidgetConfig(
          clocks: WidgetClocks.both,
          layout: WidgetLayout.side,
          labels: true,
          offset: true,
          hourLength: true,
          place: true,
          progress: true),
      WidgetConfig(clocks: WidgetClocks.both, labels: true),
      WidgetConfig(clocks: WidgetClocks.local),
    ]) {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(
          child: SizedBox(
              width: 280,
              height: 130,
              child: WidgetPreview(config: c, model: model)),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      if (c.showsSun) {
        expect(texts.any((t) => RegExp(r'^\d\d:\d\d$').hasMatch(t)), isTrue,
            reason: 'sun time in $texts');
      }
      if (c.offset) {
        expect(texts.any((t) => t.contains('sun time')), isTrue);
      }
      await tester.pumpWidget(const SizedBox());
    }
    await tester.pump(const Duration(seconds: 1)); // let the save timer run
  });
}
