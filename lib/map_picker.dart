import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'clock_view.dart';
import 'location_model.dart';
import 'sun_clock.dart';
import 'year_data.dart';
import 'zone.dart';

/// Full-screen map. The point under the centre pin is the location; every
/// pan updates the model, so the clock and charts follow live.
class MapPickerPage extends StatefulWidget {
  final LocationModel model;
  const MapPickerPage({super.key, required this.model});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final _map = MapController();
  bool _mapReady = false;

  LocationModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.addListener(_followGps);
  }

  @override
  void dispose() {
    model.removeListener(_followGps);
    super.dispose();
  }

  /// While GPS is the source, keep the map centred on the fix.
  void _followGps() {
    if (!_mapReady || model.source != LocationSource.gps || !model.hasPosition) {
      return;
    }
    final p = LatLng(model.latitude!, model.longitude!);
    if (_map.camera.center != p) _map.move(p, _map.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = model.hasPosition
        ? LatLng(model.latitude!, model.longitude!)
        : const LatLng(20, 0);

    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: start,
            initialZoom: model.hasPosition ? 5 : 2,
            minZoom: 2,
            maxZoom: 16,
            interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            onMapReady: () => _mapReady = true,
            onPositionChanged: (pos, hasGesture) {
              final c = pos.center;
              if (hasGesture && c != null) {
                model.setFromMap(c.latitude, c.longitude);
              }
            },
            onTap: (_, p) {
              _map.move(p, _map.camera.zoom);
              model.setFromMap(p.latitude, p.longitude);
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
                ListenableBuilder(
                  listenable: model,
                  builder: (context, _) => FloatingActionButton.extended(
                    heroTag: 'gps',
                    onPressed: model.useGps,
                    icon: Icon(model.source == LocationSource.gps
                        ? Icons.my_location
                        : Icons.location_searching),
                    label: const Text('My location'),
                  ),
                ),
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
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                        Text('${coords(lat, lon)} · ${zoneCity(zone)}',
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
