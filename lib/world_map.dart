import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// The offline world map: Natural Earth 1:50m land, lakes and country
/// borders plus labelled cities, bundled as `assets/map/world.bin` (built by
/// `tool/make_map.py`). Tiles are drawn on the device; there is no network.

const worldMapAsset = 'assets/map/world.bin';

/// Zoom range the data supports (1:50m is detailed to about country scale;
/// closer in, the coasts would show their corners).
/// Keep in step with `tool/make_map.py`, which places the labels for it.
const worldMinZoom = 2.0;
const worldMaxZoom = 6.0;

// Dark style, matching the app (background #1C1B17, amber accents).
const sea = Color(0xFF121416);
const _land = Color(0xFF2B2922);
const _coast = Color(0xFF4A4537);
const _border = Color(0xFF6B6350);
const _grid = Color(0x14FFFFFF);
const _amber = Color(0xFFFFB300);

/// Latitudes of the circles that matter for the sun (obliquity 23.44°).
const _tropic = 23.4363;
const _polarCircle = 90 - _tropic;

/// Polygons or lines in world coordinates: x, y in 0..1 (Web Mercator, x
/// east from 180° W, y south from 85.05° N).
class Shapes {
  /// x, y pairs of all shapes, one after the other.
  final Float32List xy;

  /// Start of each shape in points; one more entry than there are shapes.
  final Uint32List starts;

  /// Bounding box of each shape: x0, y0, x1, y1.
  final Float32List boxes;

  /// Bounding box of each run of [chunk] points (counted over [xy], so a
  /// run may span two shapes), to skip runs that are out of view quickly.
  final Float32List chunkBoxes;

  static const chunkBits = 4, chunk = 1 << chunkBits;

  Shapes(this.xy, this.starts)
      : boxes = _boxes(xy, [for (var i = 0; i < starts.length; i++) starts[i]]),
        chunkBoxes = _boxes(xy, [
          for (var k = 0; k < xy.length ~/ 2; k += chunk) k,
          xy.length ~/ 2
        ]);

  int get length => starts.length - 1;

  static Float32List _boxes(Float32List xy, List<int> starts) {
    final boxes = Float32List(4 * (starts.length - 1));
    for (var i = 0; i < starts.length - 1; i++) {
      var x0 = 1.0, y0 = 1.0, x1 = 0.0, y1 = 0.0;
      for (var k = starts[i]; k < starts[i + 1]; k++) {
        final x = xy[2 * k], y = xy[2 * k + 1];
        if (x < x0) x0 = x;
        if (x > x1) x1 = x;
        if (y < y0) y0 = y;
        if (y > y1) y1 = y;
      }
      boxes
        ..[4 * i] = x0
        ..[4 * i + 1] = y0
        ..[4 * i + 2] = x1
        ..[4 * i + 3] = y1;
    }
    return boxes;
  }

  /// A lighter copy for zoomed-out views: drops points closer than
  /// [tolerance] (world units) to the last one kept; shapes that shrink
  /// below [minPoints] are left out.
  Shapes simplified(double tolerance, int minPoints) {
    final xy = <double>[];
    final starts = <int>[0];
    final t2 = tolerance * tolerance;
    for (var i = 0; i < length; i++) {
      final from = xy.length;
      final end = this.starts[i + 1];
      for (var k = this.starts[i]; k < end; k++) {
        final x = this.xy[2 * k], y = this.xy[2 * k + 1];
        if (xy.length > from && k < end - 1) {
          final dx = x - xy[xy.length - 2], dy = y - xy[xy.length - 1];
          if (dx * dx + dy * dy < t2) continue;
        }
        xy
          ..add(x)
          ..add(y);
      }
      if ((xy.length - from) ~/ 2 < minPoints) {
        xy.length = from;
      } else {
        starts.add(xy.length ~/ 2);
      }
    }
    return Shapes(Float32List.fromList(xy), Uint32List.fromList(starts));
  }
}

class City {
  final String name;
  final LatLng point;
  final int minZoom;
  final bool capital;
  const City(this.name, this.point, this.minZoom, this.capital);
}

class WorldMapData {
  final Shapes land, lakes, borders;
  final List<City> cities;

  /// Lighter copies for the zoomed-out tiles, by zoom up to
  /// [_detailZoom]: points less than half a pixel apart at that zoom are
  /// dropped.
  final Map<int, (Shapes, Shapes, Shapes)> _lighter;

  /// From this zoom on, tiles use all of the data.
  static const _detailZoom = 5;

  static double _tolerance(int z) => 0.5 / (256 << z);

  /// Land, lakes and borders at the detail that suits zoom [z].
  (Shapes, Shapes, Shapes) atZoom(int z) =>
      _lighter[z] ?? (land, lakes, borders);

  WorldMapData._(this.land, this.lakes, this.borders, this.cities)
      : _lighter = {
          for (var z = worldMinZoom.toInt(); z < _detailZoom; z++)
            z: (
              land.simplified(_tolerance(z), 3),
              lakes.simplified(_tolerance(z), 3),
              borders.simplified(_tolerance(z), 2),
            )
        };

  static WorldMapData? _loaded;
  static Future<WorldMapData>? _loading;

  /// The parsed map, once [load] has completed.
  static WorldMapData? get loaded => _loaded;

  /// Loads and parses the asset once (parsing off the UI thread: it takes
  /// some 50 ms).
  static Future<WorldMapData> load() => _loading ??= () async {
        final bytes = await rootBundle.load(worldMapAsset);
        final data = await compute(parse, bytes);
        return _loaded = data;
      }();

  /// Parses the asset; [load] is the normal way in.
  static WorldMapData parse(ByteData bytes) {
    final r = _Reader(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    if (String.fromCharCodes(r.bytes(4)) != 'SCM1') {
      throw const FormatException('not a Sun Clock map');
    }
    final land = r.shapes(), lakes = r.shapes(), borders = r.shapes();
    final cities = List.generate(r.uint(), (_) {
      final lon = r.sint() / 100, lat = r.sint() / 100;
      final minZoom = r.byte(), flags = r.byte();
      final name = utf8.decode(r.bytes(r.uint()));
      return City(name, LatLng(lat, lon), minZoom, flags & 1 != 0);
    });
    return WorldMapData._(land, lakes, borders, cities);
  }

  /// Whether the point is on land (not in the sea or a lake on the map).
  bool isLand(double lat, double lon) {
    final x = _mercX(lon), y = _mercY(lat);
    return _inside(land, x, y) && !_inside(lakes, x, y);
  }

  /// Even-odd point-in-polygon test over all shapes.
  static bool _inside(Shapes s, double x, double y) {
    var inside = false;
    for (var i = 0; i < s.length; i++) {
      final b = i * 4;
      if (x < s.boxes[b] ||
          y < s.boxes[b + 1] ||
          x > s.boxes[b + 2] ||
          y > s.boxes[b + 3]) {
        continue;
      }
      final start = s.starts[i], end = s.starts[i + 1];
      var j = end - 1;
      for (var k = start; k < end; j = k++) {
        final xk = s.xy[2 * k], yk = s.xy[2 * k + 1];
        final xj = s.xy[2 * j], yj = s.xy[2 * j + 1];
        if ((yk > y) != (yj > y) && x < (xj - xk) * (y - yk) / (yj - yk) + xk) {
          inside = !inside;
        }
      }
    }
    return inside;
  }
}

double _mercX(double lon) => (lon + 180) / 360;

double _mercY(double lat) {
  final s = math.sin(lat.clamp(-85.0511, 85.0511) * math.pi / 180);
  return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
}

class _Reader {
  final Uint8List data;
  int pos = 0;
  _Reader(this.data);

  int byte() => data[pos++];

  Uint8List bytes(int n) => Uint8List.sublistView(data, pos, pos += n);

  int uint() {
    var n = 0, shift = 0;
    while (true) {
      final b = data[pos++];
      n |= (b & 0x7F) << shift;
      if (b < 0x80) return n;
      shift += 7;
    }
  }

  int sint() {
    final n = uint();
    return n.isEven ? n >> 1 : -((n + 1) >> 1);
  }

  Shapes shapes() {
    final count = uint();
    final starts = Uint32List(count + 1);
    final xy = <double>[];
    for (var i = 0; i < count; i++) {
      starts[i] = xy.length ~/ 2;
      final n = uint();
      var lon = 0, lat = 0;
      for (var k = 0; k < n; k++) {
        lon += sint();
        lat += sint();
        xy
          ..add(_mercX(lon / 100))
          ..add(_mercY(lat / 100));
      }
    }
    starts[count] = xy.length ~/ 2;
    return Shapes(Float32List.fromList(xy), starts);
  }
}

/// Draws map tiles from [WorldMapData] on the device.
class WorldTileProvider extends TileProvider {
  final WorldMapData data;

  /// Pixels per logical pixel the tiles are drawn at.
  final double scale;

  WorldTileProvider(this.data, this.scale);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _WorldTile(data, coordinates.z, coordinates.x, coordinates.y,
          (options.tileDimension * scale).round());
}

@immutable
class _WorldTile extends ImageProvider<_WorldTile> {
  final WorldMapData data;
  final int z, x, y, size;
  const _WorldTile(this.data, this.z, this.x, this.y, this.size);

  @override
  Future<_WorldTile> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_WorldTile key, ImageDecoderCallback decode) =>
      // Recording a tile takes well under a millisecond; the picture is
      // rasterized later, on the raster thread.
      OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(
          image: paintTile(data, z, x, y, size), debugLabel: '$z/$x/$y')));

  @override
  bool operator ==(Object other) =>
      other is _WorldTile &&
      identical(other.data, data) &&
      other.z == z &&
      other.x == x &&
      other.y == y &&
      other.size == size;

  @override
  int get hashCode => Object.hash(z, x, y, size);
}

/// Draws tile [x], [y] at zoom [z] as a [size]×[size] image.
ui.Image paintTile(WorldMapData data, int z, int x, int y, int size) =>
    recordTile(data, z, x, y, size).toImageSync(size, size);

/// The drawing of a tile, see [paintTile].
@visibleForTesting
ui.Picture recordTile(WorldMapData data, int z, int x, int y, int size) {
  final recorder = ui.PictureRecorder();
  _TilePainter(data, z, x, y, size.toDouble()).paint(Canvas(recorder));
  return recorder.endRecording();
}

class _TilePainter {
  final WorldMapData data;
  final int z;
  final double size;

  /// Pixels per world unit, and the tile's origin in world pixels.
  final double world, ox, oy;

  /// Device pixels per logical pixel (tiles are 256 logical pixels).
  final double px;

  _TilePainter(this.data, this.z, int x, int y, this.size)
      : world = size * (1 << z),
        ox = x * size,
        oy = y * size,
        px = size / 256;

  /// Drawing area with a margin, so clipped edges and strokes stay outside.
  late final double lo = -4 * px, hi = size + 4 * px;

  void paint(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), Paint()..color = sea);

    final (landShapes, lakeShapes, borderShapes) = data.atZoom(z);
    final land = _polygons(landShapes), lakes = _polygons(lakeShapes);
    canvas
      ..drawPath(land, Paint()..color = _land)
      ..drawPath(lakes, Paint()..color = sea);

    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(
          _lines(landShapes, closed: true),
          Paint.from(thin)
            ..color = _coast
            ..strokeWidth = 0.8 * px)
      ..drawPath(
          _lines(lakeShapes, closed: true),
          Paint.from(thin)
            ..color = _coast
            ..strokeWidth = 0.6 * px)
      ..drawPath(
          _lines(borderShapes, closed: false),
          Paint.from(thin)
            ..color = _border
            ..strokeWidth = 0.7 * px);

    _graticule(canvas);
  }

  double _x(double wx) => wx * world - ox;
  double _y(double wy) => wy * world - oy;

  bool _visible(Shapes s, int i) {
    final b = i * 4;
    return _x(s.boxes[b + 2]) >= lo &&
        _x(s.boxes[b]) <= hi &&
        _y(s.boxes[b + 3]) >= lo &&
        _y(s.boxes[b + 1]) <= hi;
  }

  /// The shape's points in tile pixels, dropping points that are less than
  /// half a pixel from the previous one. A run of points that all lie beyond
  /// the same edge of the drawing area is cut to its first and last point:
  /// clipping gives the same polygon, and its strokes are out of view.
  List<double> _points(Shapes s, int i) {
    final start = s.starts[i], end = s.starts[i + 1];
    final out = Float64List(2 * (end - start));
    var n = 0;
    final min2 = 0.25 * px * px;
    final xy = s.xy, chunks = s.chunkBoxes;
    void add(int k) {
      out[n++] = xy[2 * k] * world - ox;
      out[n++] = xy[2 * k + 1] * world - oy;
    }

    var k = start;
    while (k < end) {
      if (k & (Shapes.chunk - 1) == 0) {
        final c = 4 * (k >> Shapes.chunkBits);
        final runEnd = math.min(k + Shapes.chunk, end);
        if (runEnd - k > 2 &&
            (_x(chunks[c + 2]) < lo ||
                _x(chunks[c]) > hi ||
                _y(chunks[c + 3]) < lo ||
                _y(chunks[c + 1]) > hi)) {
          add(k);
          add(runEnd - 1);
          k = runEnd;
          continue;
        }
      }
      final x = xy[2 * k] * world - ox, y = xy[2 * k + 1] * world - oy;
      if (n > 0 && k < end - 1) {
        final dx = x - out[n - 2], dy = y - out[n - 1];
        if (dx * dx + dy * dy < min2) {
          k++;
          continue;
        }
      }
      out[n++] = x;
      out[n++] = y;
      k++;
    }
    return Float64List.sublistView(out, 0, n);
  }

  /// Visible polygons, each clipped to the tile so a continent costs only
  /// the part of it that is in view.
  Path _polygons(Shapes s) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (var i = 0; i < s.length; i++) {
      if (!_visible(s, i)) continue;
      var p = _points(s, i);
      for (var edge = 0; edge < 4 && p.length >= 6; edge++) {
        p = _clip(p, edge);
      }
      if (p.length < 6) continue;
      path.moveTo(p[0], p[1]);
      for (var k = 2; k < p.length; k += 2) {
        path.lineTo(p[k], p[k + 1]);
      }
      path.close();
    }
    return path;
  }

  /// Sutherland–Hodgman against one edge of the drawing area
  /// (0 left, 1 right, 2 top, 3 bottom).
  List<double> _clip(List<double> p, int edge) {
    final axis = edge < 2 ? 0 : 1;
    final limit = edge.isEven ? lo : hi;
    bool inside(double v) => edge.isEven ? v >= limit : v <= limit;
    final out = <double>[];
    final n = p.length ~/ 2;
    var px0 = p[2 * n - 2], py0 = p[2 * n - 1];
    var in0 = inside(axis == 0 ? px0 : py0);
    for (var k = 0; k < n; k++) {
      final x = p[2 * k], y = p[2 * k + 1];
      final in1 = inside(axis == 0 ? x : y);
      if (in1 != in0) {
        final t =
            axis == 0 ? (limit - px0) / (x - px0) : (limit - py0) / (y - py0);
        out
          ..add(axis == 0 ? limit : px0 + t * (x - px0))
          ..add(axis == 0 ? py0 + t * (y - py0) : limit);
      }
      if (in1) {
        out
          ..add(x)
          ..add(y);
      }
      px0 = x;
      py0 = y;
      in0 = in1;
    }
    return out;
  }

  /// Outlines of the visible shapes, leaving out segments outside the tile
  /// and the cuts the data has along 180° and the south edge of Antarctica.
  Path _lines(Shapes s, {required bool closed}) {
    final path = Path();
    final east = world - ox, west = -ox, bottom = world - oy;
    bool cut(double x0, double y0, double x1, double y1) =>
        ((x0 - west).abs() < 0.01 && (x1 - west).abs() < 0.01) ||
        ((x0 - east).abs() < 0.01 && (x1 - east).abs() < 0.01) ||
        (y0 >= bottom - 0.01 && y1 >= bottom - 0.01);
    for (var i = 0; i < s.length; i++) {
      if (!_visible(s, i)) continue;
      final p = closed ? [..._points(s, i)] : _points(s, i);
      if (closed && p.length >= 2) {
        p
          ..add(p[0])
          ..add(p[1]);
      }
      var pen = false;
      for (var k = 2; k < p.length; k += 2) {
        final x0 = p[k - 2], y0 = p[k - 1], x1 = p[k], y1 = p[k + 1];
        final off = (x0 < lo && x1 < lo) ||
            (x0 > hi && x1 > hi) ||
            (y0 < lo && y1 < lo) ||
            (y0 > hi && y1 > hi);
        if (off || cut(x0, y0, x1, y1)) {
          pen = false;
          continue;
        }
        if (!pen) path.moveTo(x0, y0);
        path.lineTo(x1, y1);
        pen = true;
      }
    }
    return path;
  }

  /// Meridians and parallels, denser as the map zooms in, with the equator,
  /// the tropics and the polar circles marked in amber.
  void _graticule(Canvas canvas) {
    final step = switch (z) { <= 3 => 30, 4 => 15, 5 => 10, _ => 5 };
    final grid = Paint()
      ..color = _grid
      ..strokeWidth = 0.8 * px;
    for (var lon = -180; lon <= 180; lon += step) {
      final x = _x(_mercX(lon.toDouble()));
      if (x < lo || x > hi) continue;
      canvas.drawLine(Offset(x, lo), Offset(x, hi), grid);
    }
    for (var lat = -80; lat <= 80; lat += step == 15 ? 15 : step) {
      if (lat == 0) continue;
      final y = _y(_mercY(lat.toDouble()));
      if (y < lo || y > hi) continue;
      canvas.drawLine(Offset(lo, y), Offset(hi, y), grid);
    }

    final equator = _y(_mercY(0));
    if (equator >= lo && equator <= hi) {
      canvas.drawLine(
          Offset(lo, equator),
          Offset(hi, equator),
          Paint()
            ..color = _amber.withValues(alpha: 0.6)
            ..strokeWidth = 1.4 * px);
    }
    final dashed = Paint()
      ..color = _amber.withValues(alpha: 0.35)
      ..strokeWidth = 1 * px;
    // Dashes are laid out from the world's west edge, so they continue
    // across tiles.
    final dash = 6 * px, gap = 4 * px;
    for (final lat in [_tropic, -_tropic, _polarCircle, -_polarCircle]) {
      final y = _y(_mercY(lat));
      if (y < lo || y > hi) continue;
      var x = -((ox % (dash + gap)));
      for (; x < size; x += dash + gap) {
        canvas.drawLine(Offset(x, y), Offset(x + dash, y), dashed);
      }
    }
  }
}

/// City names that appear as the map zooms in.
class CityLabels extends StatelessWidget {
  final WorldMapData data;
  const CityLabels({super.key, required this.data});

  static final _byZoom = <int, List<Marker>>{};

  @override
  Widget build(BuildContext context) {
    final zoom = MapCamera.of(context).zoom.floor();
    final markers = _byZoom[zoom] ??= [
      for (final c in data.cities)
        if (c.minZoom <= zoom)
          Marker(
            point: c.point,
            width: 160,
            height: 16,
            // The dot's centre (3 px in) sits on the point.
            alignment: const Alignment(1 - 6 / 160, 0),
            child: _Label(c),
          ),
    ];
    return MarkerLayer(markers: markers, rotate: false);
  }
}

class _Label extends StatelessWidget {
  final City city;
  const _Label(this.city);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(children: [
        Container(
          width: city.capital ? 6 : 4,
          height: city.capital ? 6 : 4,
          margin: EdgeInsets.only(
              right: city.capital ? 3 : 4, left: city.capital ? 0 : 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: city.capital
                ? const Color(0xFFE0C890)
                : const Color(0xFFB8B0A0),
          ),
        ),
        Flexible(
          child: Text(
            city.name,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              color: city.capital
                  ? const Color(0xFFE8E0CC)
                  : const Color(0xFFC4BCA8),
              fontWeight: city.capital ? FontWeight.w600 : FontWeight.w400,
              shadows: const [
                Shadow(color: Color(0xE6000000), blurRadius: 3),
                Shadow(color: Color(0xCC000000), blurRadius: 1),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

/// The credit for the map data, in the corner of the map.
class NaturalEarthCredit extends StatelessWidget {
  const NaturalEarthCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0x99000000),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('Natural Earth',
              style: TextStyle(fontSize: 10, color: Color(0xFFA8A090))),
        ),
      ),
    );
  }
}
