import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'clock_view.dart';
import 'location_model.dart';
import 'sun_clock.dart';
import 'year_data.dart';
import 'zone.dart';

/// Zoom shared by the panel and the full-screen map, so maximizing and
/// coming back keep the same view.
double _sharedZoom = 5;

/// The map with a centre pin. The point under the pin is the location; every
/// pan updates the model, so the clock and charts follow live. When the
/// location changes elsewhere (GPS, the other map), the map follows it.
class SunMap extends StatefulWidget {
  final LocationModel model;
  const SunMap({super.key, required this.model});

  @override
  State<SunMap> createState() => SunMapState();
}

class SunMapState extends State<SunMap> {
  final _map = MapController();
  bool _ready = false;
  bool _picking = false; // the model change came from this map

  LocationModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.addListener(_follow);
  }

  @override
  void dispose() {
    model.removeListener(_follow);
    _map.dispose();
    super.dispose();
  }

  void _follow() {
    if (_picking || !_ready || !model.hasPosition) return;
    final c = _map.camera.center;
    final p = LatLng(model.latitude!, model.longitude!);
    // The map repeats east–west, so compare longitudes modulo 360°.
    final dLon = (c.longitude - p.longitude + 540) % 360 - 180;
    if ((c.latitude - p.latitude).abs() < 1e-7 && dLon.abs() < 1e-7) return;
    _map.move(p, _map.camera.zoom);
  }

  /// Re-centre on the model and take over the shared zoom.
  void sync() {
    if (!_ready || !model.hasPosition) return;
    _map.move(LatLng(model.latitude!, model.longitude!), _sharedZoom);
  }

  void _pick(double lat, double lon) {
    _picking = true;
    try {
      model.setFromMap(lat, lon);
    } finally {
      _picking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = model.hasPosition
        ? LatLng(model.latitude!, model.longitude!)
        : const LatLng(20, 0);
    return Stack(children: [
      FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: start,
          initialZoom: model.hasPosition ? _sharedZoom : 2,
          minZoom: 2,
          maxZoom: 16,
          interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          onMapReady: () => _ready = true,
          // The map repeats east–west without limit; the model folds the
          // longitude back into ±180°.
          onPositionChanged: (camera, hasGesture) {
            _sharedZoom = camera.zoom;
            if (hasGesture) {
              _pick(camera.center.latitude, camera.center.longitude);
            }
          },
          onTap: (_, p) {
            _map.move(p, _map.camera.zoom);
            _pick(p.latitude, p.longitude);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.sunriseclock.sun_clock',
            maxNativeZoom: 19,
          ),
          const RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
      // Centre pin: the tip of the icon marks the point.
      IgnorePointer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 44),
            child: Icon(Icons.location_on,
                size: 48,
                color: theme.colorScheme.primary,
                shadows: const [Shadow(blurRadius: 6)]),
          ),
        ),
      ),
    ]);
  }
}

/// "My location" button that shows whether GPS is the source.
class _GpsButton extends StatelessWidget {
  final LocationModel model;
  final bool extended;
  const _GpsButton({required this.model, this.extended = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final icon = Icon(model.source == LocationSource.gps
            ? Icons.my_location
            : Icons.location_searching);
        return extended
            ? FloatingActionButton.extended(
                heroTag: 'gps',
                onPressed: model.useGps,
                icon: icon,
                label: const Text('My location'),
              )
            : IconButton(
                tooltip: 'My location',
                onPressed: model.useGps,
                icon: icon,
              );
      },
    );
  }
}

/// The map as a panel on the home page, under the charts, so they can be
/// watched while picking a place. Can be maximized to the full-screen map.
class MapPanel extends StatefulWidget {
  final LocationModel model;
  final double height;
  const MapPanel({super.key, required this.model, required this.height});

  @override
  State<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<MapPanel> {
  final _map = GlobalKey<SunMapState>();

  Future<void> _maximize() async {
    await openMapPicker(context, widget.model);
    _map.currentState?.sync();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = widget.model;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location', style: theme.textTheme.titleMedium),
                    ListenableBuilder(
                      listenable: model,
                      builder: (context, _) => Text(
                        model.hasPosition
                            ? '${coords(model.latitude!, model.longitude!, approximate: model.isApproximate)}'
                                ' · ${zoneCity(model.zone!)}'
                            : 'Drag the map to pick a place',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: tabular),
                      ),
                    ),
                  ]),
            ),
            _GpsButton(model: model),
            IconButton(
              tooltip: 'Full-screen map',
              onPressed: _maximize,
              icon: const Icon(Icons.open_in_full),
            ),
          ]),
        ),
        SizedBox(
            height: widget.height, child: SunMap(key: _map, model: model)),
      ]),
    );
  }
}

Future<void> openMapPicker(BuildContext context, LocationModel model) =>
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MapPickerPage(model: model)));

/// Full-screen map with a live preview of the clock.
class MapPickerPage extends StatelessWidget {
  final LocationModel model;
  const MapPickerPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        SunMap(model: model),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconButton.filledTonal(
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(child: _LivePreview(model: model)),
              ]),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _GpsButton(model: model, extended: true),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'done',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
              ]),
              const SizedBox(height: 24), // keep clear of the attribution
            ]),
          ),
        ),
      ]),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final LocationModel model;
  const _LivePreview({required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        if (!model.hasPosition) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tap or drag the map to pick a place.'),
            ),
          );
        }
        final lat = model.latitude!, lon = model.longitude!;
        final zone = model.zone!;
        return Ticker(builder: (context, now) {
          final r = sunClock(now, lat, lon);
          final today = inZone(now, zone);
          final d = daySun(today, lat, lon, zone);
          final muted = theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
          return Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
              child: Row(children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CustomPaint(
                      painter: DialPainter(r.sunTime, theme, labels: false)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hms(r.sunTime),
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontFeatures: tabular)),
                        Text(
                          d.sunrise != null && d.sunset != null
                              ? 'Sunrise ${hoursToHm(d.sunrise!)} · '
                                  'sunset ${hoursToHm(d.sunset!)}'
                              : d.polar == PolarState.polarDay
                                  ? 'Polar day'
                                  : 'Polar night',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontFeatures: tabular),
                        ),
                        Text(
                          'Hour: day ${_min(d.dayHourMinutes)} · '
                          'night ${_min(d.nightHourMinutes)}',
                          style: muted?.copyWith(fontFeatures: tabular),
                        ),
                        Text('${coords(lat, lon, approximate: model.isApproximate)} · ${zoneCity(zone)}',
                            style: muted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ]),
                ),
              ]),
            ),
          );
        });
      },
    );
  }

  static String _min(double? m) => m == null ? '—' : '${m.toStringAsFixed(0)} min';
}
