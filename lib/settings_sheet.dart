import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'location_model.dart';
import 'status_bar_clock.dart';

/// Bottom sheet with location precision and the status-bar clock switch.
void showSettings(
    BuildContext context, LocationModel model, StatusBarClock statusBar) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([model, statusBar]),
        builder: (context, _) {
          final theme = Theme.of(context);
          final muted = theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Text('Location accuracy', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<LocationPrecision>(
                      segments: const [
                        ButtonSegment(
                          value: LocationPrecision.approximate,
                          icon: Icon(Icons.location_searching),
                          label: Text('Approximate'),
                        ),
                        ButtonSegment(
                          value: LocationPrecision.precise,
                          icon: Icon(Icons.my_location),
                          label: Text('Precise'),
                        ),
                      ],
                      selected: {model.precision},
                      onSelectionChanged: (s) => model.setPrecision(s.first),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    model.precision == LocationPrecision.approximate
                        ? 'Uses a coarse fix, rounded to about 1 km. Sun times '
                            'shift by only a few seconds per kilometre, so this '
                            'is accurate enough and keeps your position private.'
                        : 'Uses GPS for your exact position. Sun times become '
                            'accurate to the second; uses a little more battery.',
                    style: muted,
                  ),
                  if (model.precision == LocationPrecision.precise &&
                      model.preciseDenied) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: theme.colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'The system only allows approximate location '
                                'for Sun Clock. Turn on "Precise location" in '
                                'the app\'s location permission.',
                                style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer),
                              ),
                              const SizedBox(height: 8),
                              const FilledButton.tonal(
                                onPressed: Geolocator.openAppSettings,
                                child: Text('Open settings'),
                              ),
                            ]),
                      ),
                    ),
                  ],
                  if (model.source == LocationSource.map) ...[
                    const SizedBox(height: 8),
                    Text(
                        'You are using a place picked on the map; this applies '
                        'when you switch back to GPS.',
                        style: muted),
                  ],
                  if (statusBar.supported) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sun time in status bar'),
                      subtitle: Text(
                        'Shows the sun time as a status-bar icon and in the '
                        'notification shade. Keeps running when the app is '
                        'closed; it uses the last known location.',
                        style: muted,
                      ),
                      value: statusBar.enabled,
                      onChanged: (on) => toggleStatusBar(context, statusBar, on),
                    ),
                  ],
                ]),
          );
        },
      ),
    ),
  );
}

Future<void> toggleStatusBar(
    BuildContext context, StatusBarClock statusBar, bool on) async {
  final ok = await statusBar.setEnabled(on);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Allow notifications for Sun Clock to show the sun time '
          'in the status bar.'),
      action: SnackBarAction(
          label: 'Settings', onPressed: Geolocator.openAppSettings),
    ));
  }
}
