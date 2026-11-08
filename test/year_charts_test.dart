import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/year_charts.dart';
import 'package:sun_clock/zone.dart';

/// Touch behaviour of the year charts inside the scrolling home page.
void main() {
  final scroll = ScrollController();

  Future<void> pumpCharts(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: scroll,
          child: Column(children: [
            YearCharts(lat: 52.52, lon: 13.405, zone: zoneAt(52.52, 13.405)),
            const SizedBox(height: 1500),
          ]),
        ),
      ),
    ));
  }

  bool tooltipShown(WidgetTester tester) => tester
      .widgetList<LineChart>(find.byType(LineChart))
      .any((c) => c.data.showingTooltipIndicators.isNotEmpty);

  testWidgets('a sideways swipe keeps the infobox even when it drifts vertically',
      (tester) async {
    await pumpCharts(tester);
    final chart = tester.getCenter(find.byType(LineChart).first);

    final g = await tester.startGesture(chart);
    await tester.pump();
    expect(tooltipShown(tester), isTrue, reason: 'shows on touch down');

    await g.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(tooltipShown(tester), isTrue);

    // Finger drifts up and down while scrubbing: the page must not take over.
    for (final step in const [Offset(10, 30), Offset(-20, -45), Offset(30, 25)]) {
      await g.moveBy(step);
      await tester.pump();
      expect(tooltipShown(tester), isTrue, reason: 'after moving by $step');
    }
    expect(scroll.offset, 0);

    await g.up();
    await tester.pump();
    expect(tooltipShown(tester), isFalse, reason: 'hides on release');
  });

  testWidgets('a vertical swipe on a chart scrolls the page', (tester) async {
    await pumpCharts(tester);
    final chart = tester.getCenter(find.byType(LineChart).first);
    await tester.dragFrom(chart, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    expect(tooltipShown(tester), isFalse);
  });

  testWidgets('a tap pins the infobox', (tester) async {
    await pumpCharts(tester);
    await tester.tap(find.byType(LineChart).first);
    await tester.pump();
    expect(tooltipShown(tester), isTrue);
  });
}
