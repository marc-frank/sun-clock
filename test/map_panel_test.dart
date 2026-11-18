import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sun_clock/location_model.dart';
import 'package:sun_clock/map_picker.dart';
import 'package:sun_clock/world_map.dart';
import 'package:sun_clock/zone.dart';

/// The map panel sits in the scrolling home page under the charts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    initZones();
    await WorldMapData.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(LocationModel, ScrollController)> pumpPanel(
      WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final model = LocationModel()..setFromMap(52.52, 13.405);
    final scroll = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: scroll,
          child: Column(children: [
            MapPanel(model: model, height: 300),
            const SizedBox(height: 1500),
          ]),
        ),
      ),
    ));
    await tester.pump();
    return (model, scroll);
  }

  testWidgets('the map is drawn from the bundled data, not the network',
      (tester) async {
    await pumpPanel(tester);
    final tiles = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(tiles.tileProvider, isA<WorldTileProvider>());
    expect(tiles.urlTemplate, isNull);
    expect(find.text('Natural Earth'), findsOneWidget);
    expect(find.text('Berlin'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // let the save timer run
  });

  testWidgets('dragging the panel map moves the location, not the page',
      (tester) async {
    final (model, scroll) = await pumpPanel(tester);
    final map = tester.getCenter(find.byType(FlutterMap));

    // Drag down: the map shows what is further north.
    await tester.dragFrom(map, const Offset(0, 120));
    await tester.pump(const Duration(seconds: 1));
    expect(model.latitude!, greaterThan(52.52));
    expect(scroll.offset, 0);

    // Drag sideways: further west.
    final lat = model.latitude!;
    await tester.dragFrom(map, const Offset(150, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(model.longitude!, lessThan(13.405));
    expect(model.latitude!, closeTo(lat, 0.5));
    expect(scroll.offset, 0);
  });

  testWidgets('the panel map follows a location set elsewhere', (tester) async {
    final (model, _) = await pumpPanel(tester);
    model.setFromMap(-33.87, 151.21);
    await tester.pump();
    final camera = MapCamera.of(tester.element(find.byType(TileLayer)));
    expect(camera.center.latitude, closeTo(-33.87, 1e-6));
    expect(camera.center.longitude, closeTo(151.21, 1e-6));
    await tester.pump(const Duration(seconds: 1)); // let the save timer run
  });
}
