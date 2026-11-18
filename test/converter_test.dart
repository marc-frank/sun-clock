import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sun_clock/converter.dart';
import 'package:sun_clock/zone.dart';

/// The converter sheet shows both directions for today.
void main() {
  setUpAll(initZones);

  testWidgets('shows sun time for a local time and back', (tester) async {
    final zone = zoneAt(52.52, 13.405);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConverterPanel(
          lat: 52.52,
          lon: 13.405,
          zone: zone,
          // 12:00 in Berlin on 18 Nov 2026.
          now: () => DateTime.utc(2026, 11, 18, 11),
        ),
      ),
    ));
    expect(find.text('Today, 18 Nov · Europe/Berlin'), findsOneWidget);
    // Local 12:00 is a little after sun noon in November (short day hours).
    expect(find.textContaining('sun time · day'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d\d:\d\d local time$')),
        findsOneWidget);

    // Picking a sun time opens a 24-hour picker.
    await tester.tap(find.byTooltip('Pick a sun time'));
    await tester.pumpAndSettle();
    expect(find.text('Sun time'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
