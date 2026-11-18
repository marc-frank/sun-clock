import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/year_charts.dart';
import 'package:sun_clock/zone.dart';

/// The "today" marker follows the local date while the app stays open.
void main() {
  setUpAll(initZones);

  double todayX(WidgetTester tester) => tester
      .widget<LineChart>(find.byType(LineChart).first)
      .data
      .extraLinesData
      .verticalLines
      .single
      .x;

  testWidgets('moves at local midnight and into the new year', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // 23:59 on 31 December in Berlin (UTC+1).
    var now = DateTime.utc(2026, 12, 31, 22, 59);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: YearCharts(
              lat: 52.52,
              lon: 13.405,
              zone: zoneAt(52.52, 13.405),
              clock: () => now),
        ),
      ),
    ));
    expect(todayX(tester), 364);
    expect(find.textContaining('2026 ·'), findsOneWidget);

    // Nothing changes before midnight.
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    expect(find.textContaining('2026 ·'), findsOneWidget);

    now = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));
    expect(todayX(tester), 0);
    expect(find.textContaining('2027 ·'), findsOneWidget);

    // And again a day later.
    now = now.add(const Duration(days: 1));
    await tester.pump(const Duration(days: 1));
    expect(todayX(tester), 1);
  });
}
