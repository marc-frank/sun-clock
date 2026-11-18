import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sun_clock/location_model.dart';
import 'package:sun_clock/map_picker.dart';
import 'package:sun_clock/world_map.dart';
import 'package:sun_clock/zone.dart';

/// Set to write preview images of the map to build/map_preview/:
/// `flutter test test/world_map_test.dart --dart-define=MAP_PREVIEW=true`
const _preview = bool.fromEnvironment('MAP_PREVIEW');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WorldMapData map;
  setUpAll(() async {
    initZones();
    map = await WorldMapData.load();
  });

  test('the bundled map loads', () {
    expect(map.land.length, greaterThan(1000));
    expect(map.lakes.length, greaterThan(100));
    expect(map.borders.length, greaterThan(100));
    final berlin = map.cities.singleWhere((c) => c.name == 'Berlin');
    expect(berlin.point.latitude, closeTo(52.52, 0.1));
    expect(berlin.point.longitude, closeTo(13.4, 0.1));
    expect(berlin.capital, isTrue);
    expect(berlin.minZoom, lessThanOrEqualTo(4));
    for (final c in map.cities) {
      expect(c.minZoom, inInclusiveRange(worldMinZoom, worldMaxZoom));
    }
  });

  test('land and water are where they should be', () {
    expect(map.isLand(52.52, 13.405), isTrue, reason: 'Berlin');
    expect(map.isLand(-15.8, -47.9), isTrue, reason: 'Brasília');
    expect(map.isLand(-25, 134), isTrue, reason: 'central Australia');
    expect(map.isLand(66, -168.9), isFalse, reason: 'Bering Strait');
    expect(map.isLand(67, 179.5), isTrue, reason: 'Chukotka, west of 180°');
    expect(map.isLand(67, -179.5), isTrue, reason: 'Chukotka, east of 180°');
    expect(map.isLand(30, -40), isFalse, reason: 'mid-Atlantic');
    expect(map.isLand(-40, -130), isFalse, reason: 'South Pacific');
    expect(map.isLand(42, 51), isFalse, reason: 'Caspian Sea');
    expect(map.isLand(-1, 33), isFalse, reason: 'Lake Victoria');
    expect(map.isLand(-80, 0), isTrue, reason: 'Antarctica');
  });

  group('preview', skip: !_preview, () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    setUpAll(_loadFont);

    for (final (name, lat, lon, zoom) in [
      ('world', 20.0, 0.0, 2.0),
      ('europe', 50.0, 10.0, 4.0),
      ('berlin', 52.52, 13.405, 5.0),
      ('berlin6', 52.52, 13.405, 6.0),
      ('pacific', 0.0, 180.0, 3.0),
      ('arctic', 66.0, 25.0, 4.0),
    ]) {
      testWidgets(name, (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final model = LocationModel()..setFromMap(lat, lon);
        final boundary = GlobalKey();
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              brightness: Brightness.dark,
              colorSchemeSeed: const Color(0xFFFFB300),
              fontFamily: 'Roboto'),
          home: Scaffold(
            body: RepaintBoundary(key: boundary, child: SunMap(model: model)),
          ),
        ));
        await tester.pump();
        MapController.of(tester.element(find.byType(TileLayer)))
            .move(LatLng(lat, lon), zoom);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final png = await tester.runAsync(() async {
          final ro = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await ro.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          return bytes!.buffer.asUint8List();
        });
        File('build/map_preview/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!);
        await tester.pump(const Duration(seconds: 1));
      });
    }
  });
}

/// Real glyphs instead of the test font's boxes.
Future<void> _loadFont() async {
  final fonts =
      Directory('${File(Platform.resolvedExecutable).parent.parent.parent.path}'
          '/material_fonts');
  if (!fonts.existsSync()) return;
  for (final (family, files) in [
    ('Roboto', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']),
    ('MaterialIcons', ['materialicons-regular.otf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('${fonts.path}/$f');
      if (file.existsSync()) {
        loader.addFont(
            Future.value(ByteData.sublistView(file.readAsBytesSync())));
      }
    }
    await loader.load();
  }
}
