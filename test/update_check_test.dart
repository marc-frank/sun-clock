import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sun_clock/language.dart';
import 'package:sun_clock/location_model.dart';
import 'package:sun_clock/main.dart';
import 'package:sun_clock/status_bar_clock.dart';
import 'package:sun_clock/update_check.dart';
import 'package:sun_clock/zone.dart';

Map<String, Object?> latest(String tag) => {
      'tag_name': tag,
      'html_url': 'https://github.com/marc-frank/sun-clock/releases/tag/$tag',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initZones);

  test('versions compare by number', () {
    expect(isNewer('1.4.0', '1.3.0'), isTrue);
    expect(isNewer('1.10.0', '1.9.3'), isTrue);
    expect(isNewer('2.0.0', '1.99.99'), isTrue);
    expect(isNewer('1.4.0', '1.4.0'), isFalse);
    expect(isNewer('1.3.9', '1.4.0'), isFalse);
    expect(isNewer('garbage', '1.0.0'), isFalse);
  });

  test('a release is read from GitHub JSON, only for this repository', () {
    final r = Release.fromJson(latest('v1.5.0'))!;
    expect(r.version, '1.5.0');
    expect(r.url, endsWith('/releases/tag/v1.5.0'));
    expect(
        Release.fromJson({
          'tag_name': 'v9.9.9',
          'html_url': 'https://example.com/evil',
        }),
        isNull);
    expect(Release.fromJson({'message': 'Not Found'}), isNull);
    expect(Release.fromJson('nonsense'), isNull);
  });

  group('UpdateChecker', () {
    var fetches = 0;
    var now = DateTime(2026, 11, 21, 12);
    late Object? response;

    UpdateChecker checker() => UpdateChecker(
          fetchLatest: () async {
            fetches++;
            return response;
          },
          currentVersion: () async => '1.4.0',
          clock: () => now,
        );

    setUp(() {
      fetches = 0;
      now = DateTime(2026, 11, 21, 12);
      response = latest('v1.5.0');
    });

    test('off by default: never goes online', () async {
      SharedPreferences.setMockInitialValues({});
      final c = checker();
      await c.load();
      expect(c.enabled, isFalse);
      expect(fetches, 0);
      expect(c.showBanner, isFalse);
    });

    test('turning it on checks and finds the newer release', () async {
      SharedPreferences.setMockInitialValues({});
      final c = checker();
      await c.load();
      await c.setEnabled(true);
      expect(fetches, 1);
      expect(c.available?.version, '1.5.0');
      expect(c.showBanner, isTrue);
    });

    test('checks at most once a week on start', () async {
      SharedPreferences.setMockInitialValues({'updateCheck': true});
      await checker().load();
      expect(fetches, 1);

      now = now.add(const Duration(days: 3));
      await checker().load();
      expect(fetches, 1, reason: 'too soon');

      now = now.add(const Duration(days: 5));
      await checker().load();
      expect(fetches, 2, reason: 'a week has passed');
    });

    test('up to date: no banner', () async {
      SharedPreferences.setMockInitialValues({'updateCheck': true});
      response = latest('v1.4.0');
      final c = checker();
      await c.load();
      expect(c.available, isNull);
      expect(c.showBanner, isFalse);
      expect(await c.check(), CheckResult.upToDate);
    });

    test('"Later" hides the banner for that version only', () async {
      SharedPreferences.setMockInitialValues({'updateCheck': true});
      final c = checker();
      await c.load();
      await c.dismiss();
      expect(c.showBanner, isFalse);

      // A later release shows again.
      now = now.add(const Duration(days: 8));
      response = latest('v1.6.0');
      final c2 = checker();
      await c2.load();
      expect(c2.available?.version, '1.6.0');
      expect(c2.showBanner, isTrue);
    });

    test('a failed request reports failure and shows nothing', () async {
      SharedPreferences.setMockInitialValues({'updateCheck': true});
      response = null;
      final c = checker();
      await c.load();
      expect(c.showBanner, isFalse);
      expect(await c.check(), CheckResult.failed);
      expect(c.lastResult, CheckResult.failed);
    });
  });

  testWidgets('the home page shows a banner for a newer release',
      (tester) async {
    SharedPreferences.setMockInitialValues({'updateCheck': true});
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final updates = UpdateChecker(
        fetchLatest: () async => latest('v9.0.0'),
        currentVersion: () async => '1.4.0');
    final model = LocationModel()..setFromMap(52.52, 13.405);
    await tester.pumpWidget(SunClockApp(
        model: model,
        statusBar: StatusBarClock(model),
        language: LanguageSetting(),
        updates: updates));
    await tester.runAsync(updates.load);
    await tester.pump();
    expect(find.text('Sun Clock 9.0.0 is available.'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('Sun Clock 9.0.0 is available.'), findsNothing);
    await tester.pump(const Duration(seconds: 1)); // let the save timer run
  });
}
