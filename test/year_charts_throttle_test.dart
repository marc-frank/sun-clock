import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/year_charts.dart';
import 'package:sun_clock/year_data.dart';
import 'package:sun_clock/zone.dart';

/// While the map is dragged the charts follow at most ten times a second,
/// and always end on the final position.
void main() {
  setUpAll(initZones);

  final zone = zoneAt(52.52, 13.405);
  final now = DateTime.utc(2026, 6, 1, 12);

  // Sunrise on 1 January as drawn by the first chart.
  double shownSunrise(WidgetTester tester) => tester
      .widget<LineChart>(find.byType(LineChart).first)
      .data
      .lineBarsData
      .first
      .spots
      .first
      .y;

  double sunriseAt(double lon) =>
      daySun(DateTime.utc(2026), 52.52, lon, zone).sunrise!;

  testWidgets('throttles updates with a trailing one', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final lon = ValueNotifier(13.0);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ValueListenableBuilder<double>(
            valueListenable: lon,
            builder: (context, v, _) =>
                YearCharts(lat: 52.52, lon: v, zone: zone, clock: () => now),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(shownSunrise(tester), sunriseAt(13.0));

    // The first move after a pause shows at once.
    lon.value = 13.1;
    await tester.pump();
    expect(shownSunrise(tester), sunriseAt(13.1));

    // Frame-by-frame drag: held back, then updated about every 100 ms.
    final shown = <double>{};
    for (var i = 1; i <= 30; i++) {
      lon.value = 13.1 + i * 0.1;
      await tester.pump(const Duration(milliseconds: 16));
      shown.add(shownSunrise(tester));
    }
    // 30 frames ≈ 480 ms: about five updates, far fewer than 30.
    expect(shown.length, inInclusiveRange(3, 7));

    // The drag stops: the final position appears without further input.
    await tester.pump(const Duration(milliseconds: 150));
    expect(shownSunrise(tester), sunriseAt(16.1));
  });
}
