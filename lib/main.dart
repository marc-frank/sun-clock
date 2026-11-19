import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'clock_view.dart';
import 'home_widget.dart';
import 'l10n/l10n.dart';
import 'language.dart';
import 'location_model.dart';
import 'map_picker.dart';
import 'settings_sheet.dart';
import 'status_bar_clock.dart';
import 'widget_editor.dart';
import 'year_charts.dart';
import 'zone.dart';

const appBackground = Color(0xFF1C1B17);

Future<void> main() async {
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
  final language = LanguageSetting();
  // Before the first frame, so the app never flashes in the wrong language
  // or shows the home page when the launcher asked to set up a widget.
  await language.load();
  final configuring = await HomeWidgets.configLaunchId();
  runApp(SunClockApp(
      model: model,
      statusBar: statusBar,
      language: language,
      configureWidget: configuring));
}

class SunClockApp extends StatelessWidget {
  final LocationModel model;
  final StatusBarClock statusBar;
  final LanguageSetting language;

  /// The widget to set up when the launcher opened the app for that.
  final int? configureWidget;

  const SunClockApp(
      {super.key,
      required this.model,
      required this.statusBar,
      required this.language,
      this.configureWidget});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)
        .copyWith(surface: appBackground);
    return ListenableBuilder(
      listenable: language,
      builder: (context, _) => MaterialApp(
      title: 'Sun Clock',
      locale: language.locale,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: appBackground,
        useMaterial3: true,
      ),
      home: configureWidget != null
          ? WidgetEditorPage(
              id: configureWidget!, model: model, configuring: true)
          : HomePage(model: model, statusBar: statusBar, language: language),
    ));
  }
}

class HomePage extends StatelessWidget {
  final LocationModel model;
  final StatusBarClock statusBar;
  final LanguageSetting language;
  const HomePage(
      {super.key,
      required this.model,
      required this.statusBar,
      required this.language});

  void _openMap(BuildContext context) => openMapPicker(context, model);

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
                        language: language,
                      ),
                      model.hasPosition
                          ? ClockView(
                              lat: model.latitude!,
                              lon: model.longitude!,
                              zone: model.zone!,
                              sourceLabel: model.source == LocationSource.gps
                                  ? (model.isApproximate
                                      ? context.l10n.sourceGpsApprox
                                      : context.l10n.sourceGps)
                                  : context.l10n.sourceMap,
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
                  const SizedBox(height: 16),
                  // Under the charts, so they can be watched while picking.
                  MapPanel(
                    model: model,
                    height: (box.maxHeight * 0.42).clamp(220, 420),
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
  final LanguageSetting language;
  const _TopBar(
      {required this.onMap,
      required this.model,
      required this.statusBar,
      required this.language});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        IconButton(
          tooltip: context.l10n.aboutTooltip,
          icon: const Icon(Icons.info_outline),
          onPressed: () => showAbout(context),
        ),
        const Spacer(),
        if (statusBar.supported)
          ListenableBuilder(
            listenable: statusBar,
            builder: (context, _) => IconButton(
              tooltip: statusBar.enabled
                  ? context.l10n.statusBarHide
                  : context.l10n.statusBarShow,
              isSelected: statusBar.enabled,
              icon: const Icon(Icons.notifications_none),
              selectedIcon: const Icon(Icons.notifications_active),
              onPressed: () =>
                  toggleStatusBar(context, statusBar, !statusBar.enabled),
            ),
          ),
        IconButton(
          tooltip: context.l10n.settings,
          icon: const Icon(Icons.tune),
          onPressed: () => showSettings(context, model, statusBar, language),
        ),
        IconButton(
          tooltip: context.l10n.pickOnMapTooltip,
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
          Text(context.l10n.theYear, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c)),
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
    final l = context.l10n;
    final error = model.gpsError;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (error == null) ...[
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(l.findingPosition),
      ] else ...[
        Icon(Icons.location_off, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          '${gpsErrorText(l, error)}\n${l.needsPosition}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
          FilledButton(onPressed: model.useGps, child: Text(l.retry)),
          OutlinedButton(
              onPressed: Geolocator.openAppSettings,
              child: Text(l.settings)),
        ]),
      ],
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: onMap,
        icon: const Icon(Icons.map_outlined),
        label: Text(l.pickPlaceOnMap),
      ),
      const SizedBox(height: 32),
      Ticker(builder: (context, now) => UtcLine(now: now)),
    ]);
  }
}

String gpsErrorText(AppLocalizations l, GpsError e) => switch (e) {
      GpsError.servicesOff => l.gpsServicesOff,
      GpsError.permissionDenied => l.gpsPermissionDenied,
      GpsError.noFix => l.gpsNoFix,
    };

/// "Version 1.3.0 (4)", read from the installed app (set in pubspec.yaml).
Future<String> appVersion(AppLocalizations l) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return l.version(info.version, info.buildNumber);
  } catch (_) {
    return '';
  }
}

void showAbout(BuildContext context) {
  final theme = Theme.of(context);
  final l = context.l10n;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.sunTime, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(l.aboutBody),
          const SizedBox(height: 12),
          Text(l.mapCredit,
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: appVersion(l),
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
                child: Text(l.licences),
              ),
            ]),
          ),
        ]),
      ),
    ),
  );
}
