import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'clock_view.dart';
import 'location_model.dart';
import 'map_picker.dart';
import 'settings_sheet.dart';
import 'status_bar_clock.dart';
import 'year_charts.dart';
import 'zone.dart';

const appBackground = Color(0xFF1C1B17);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initZones();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark, // iOS: light status bar text
    systemNavigationBarColor: appBackground,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final model = LocationModel()..load();
  final statusBar = StatusBarClock(model)..load();
  runApp(SunClockApp(model: model, statusBar: statusBar));
}

class SunClockApp extends StatelessWidget {
  final LocationModel model;
  final StatusBarClock statusBar;
  const SunClockApp({super.key, required this.model, required this.statusBar});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)
        .copyWith(surface: appBackground);
    return MaterialApp(
      title: 'Sun Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: appBackground,
        useMaterial3: true,
      ),
      home: HomePage(model: model, statusBar: statusBar),
    );
  }
}

class HomePage extends StatelessWidget {
  final LocationModel model;
  final StatusBarClock statusBar;
  const HomePage({super.key, required this.model, required this.statusBar});

  void _openMap(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MapPickerPage(model: model)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: model,
          builder: (context, _) => LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                // First screen: the clock, exactly one viewport tall.
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopBar(
                        onMap: () => _openMap(context),
                        model: model,
                        statusBar: statusBar,
                      ),
                      model.hasPosition
                          ? ClockView(
                              lat: model.latitude!,
                              lon: model.longitude!,
                              zone: model.zone!,
                              sourceLabel: model.source == LocationSource.gps
                                  ? (model.isApproximate
                                      ? 'GPS, approximate'
                                      : 'GPS')
                                  : 'picked on map',
                              approximate: model.isApproximate,
                              onLocationTap: () => _openMap(context),
                            )
                          : _NoPosition(
                              model: model, onMap: () => _openMap(context)),
                      _ScrollHint(visible: model.hasPosition),
                    ],
                  ),
                ),
                if (model.hasPosition) ...[
                  YearCharts(
                    lat: model.latitude!,
                    lon: model.longitude!,
                    zone: model.zone!,
                  ),
                  const SizedBox(height: 32),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onMap;
  final LocationModel model;
  final StatusBarClock statusBar;
  const _TopBar(
      {required this.onMap, required this.model, required this.statusBar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        IconButton(
          tooltip: 'About sun time',
          icon: const Icon(Icons.info_outline),
          onPressed: () => showAbout(context),
        ),
        const Spacer(),
        if (statusBar.supported)
          ListenableBuilder(
            listenable: statusBar,
            builder: (context, _) => IconButton(
              tooltip: statusBar.enabled
                  ? 'Hide sun time from status bar'
                  : 'Show sun time in status bar',
              isSelected: statusBar.enabled,
              icon: const Icon(Icons.notifications_none),
              selectedIcon: const Icon(Icons.notifications_active),
              onPressed: () =>
                  toggleStatusBar(context, statusBar, !statusBar.enabled),
            ),
          ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.tune),
          onPressed: () => showSettings(context, model, statusBar),
        ),
        IconButton(
          tooltip: 'Pick location on map',
          icon: const Icon(Icons.map_outlined),
          onPressed: onMap,
        ),
      ]),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  final bool visible;
  const _ScrollHint({required this.visible});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurfaceVariant;
    return Opacity(
      opacity: visible ? 1 : 0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Column(children: [
          Text('The year', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c)),
          Icon(Icons.keyboard_arrow_down, color: c),
        ]),
      ),
    );
  }
}

class _NoPosition extends StatelessWidget {
  final LocationModel model;
  final VoidCallback onMap;
  const _NoPosition({required this.model, required this.onMap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = model.gpsError;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (error == null) ...[
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text('Finding your position…'),
      ] else ...[
        Icon(Icons.location_off, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          '$error\nSun Clock needs a position to know when the sun rises '
          'and sets.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
          FilledButton(onPressed: model.useGps, child: const Text('Retry')),
          const OutlinedButton(
              onPressed: Geolocator.openAppSettings,
              child: Text('Settings')),
        ]),
      ],
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: onMap,
        icon: const Icon(Icons.map_outlined),
        label: const Text('Pick a place on the map'),
      ),
      const SizedBox(height: 32),
      Ticker(builder: (context, now) => UtcLine(now: now)),
    ]);
  }
}

/// "Version 1.1.0 (2)", read from the installed app (set in pubspec.yaml).
Future<String> appVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return 'Version ${info.version} (${info.buildNumber})';
  } catch (_) {
    return '';
  }
}

void showAbout(BuildContext context) {
  final theme = Theme.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sun time', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'Sun Clock divides the day into 24 hours that follow the sun. '
            'Sunrise is always 06:00 and sunset always 18:00. The 12 day '
            'hours share the real daylight evenly, and the 12 night hours '
            'share the night.\n\n'
            'In winter, day hours are short and night hours long; in summer '
            'it is the other way round. At the equinoxes every hour is '
            'close to 60 minutes.\n\n'
            'Sunrise and sunset are calculated with the NOAA solar formulas '
            '(the upper edge of the sun touching the horizon, with standard '
            'refraction). When the sun does not rise or set at all, the '
            'clock shows apparent solar time, with 12:00 at solar noon.',
          ),
          const SizedBox(height: 12),
          Text('Map data © OpenStreetMap contributors.',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: appVersion(),
            builder: (context, snap) => Row(children: [
              Text(snap.data ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              TextButton(
                onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'Sun Clock',
                    applicationVersion: snap.data),
                child: const Text('Open-source licences'),
              ),
            ]),
          ),
        ]),
      ),
    ),
  );
}
