import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'location_model.dart';
import 'status_bar_clock.dart';

/// Bottom sheet with location precision and the status-bar clock switch.
void showSettings(
    BuildContext context, LocationModel model, StatusBarClock statusBar) {
  statusBar.refreshBackground();
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
                            'is accurate enough and uses less battery.'
                        : 'Uses GPS for your exact position. Sun times become '
                            'accurate to the second; uses a little more battery.',
                    style: muted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Either way, sun times are calculated on this phone and '
                    'your position is not sent anywhere. Only the map screen '
                    'loads map images from OpenStreetMap for the area shown.',
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
                        'notification shade. Keeps running and follows your '
                        'location while the app is closed.',
                        style: muted,
                      ),
                      value: statusBar.enabled,
                      onChanged: (on) => toggleStatusBar(context, statusBar, on),
                    ),
                    if (statusBar.enabled && statusBar.chipSupported) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show as text in the status bar'),
                        subtitle: Text(
                          'Shows the sun time as a Live Update chip, e.g. '
                          '"14:27", instead of the small stacked icon.',
                          style: muted,
                        ),
                        value: statusBar.chipOn,
                        onChanged: statusBar.setTextChip,
                      ),
                      if (statusBar.chipOn && !statusBar.chipAllowed)
                        Row(children: [
                          Expanded(
                            child: Text(
                              'Live Updates are turned off for Sun Clock, so '
                              'the stacked icon is shown.',
                              style: muted,
                            ),
                          ),
                          TextButton(
                            onPressed: statusBar.openPromotionSettings,
                            child: const Text('Settings'),
                          ),
                        ]),
                    ],
                    if (statusBar.enabled &&
                        model.source == LocationSource.gps) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Follow location after a restart'),
                        subtitle: Text(
                          'Uses your location in the background, so the '
                          'status-bar clock follows the phone after a restart '
                          'without opening the app. When off, it uses the '
                          'last known position until you open the app.',
                          style: muted,
                        ),
                        value: statusBar.backgroundOptIn,
                        onChanged: (on) =>
                            toggleBackgroundLocation(context, statusBar, on),
                      ),
                      if (statusBar.backgroundOptIn &&
                          !statusBar.backgroundGranted)
                        Row(children: [
                          Expanded(
                            child: Text(
                              'Location "Allow all the time" is off, so after '
                              'a restart the last known position is used.',
                              style: muted,
                            ),
                          ),
                          const TextButton(
                            onPressed: Geolocator.openAppSettings,
                            child: Text('Settings'),
                          ),
                        ]),
                    ],
                  ],
                ]),
          );
        },
      ),
    ),
  );
}

/// Google Play's prominent disclosure, shown before Android's own prompt.
Future<void> toggleBackgroundLocation(
    BuildContext context, StatusBarClock statusBar, bool on) async {
  if (on) {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_on_outlined),
        title: const Text('Use location in the background?'),
        content: const Text(
          'Sun Clock collects your location in the background, also when the '
          'app is closed or not in use, to keep the sun time in the status '
          'bar right after the phone restarts and while you travel.\n\n'
          'Your position is only used on this phone to calculate sun times. '
          'It never leaves the phone and is not shared with anyone.\n\n'
          'On the next screen, choose "Allow all the time".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No thanks'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
  }
  final ok = await statusBar.setBackgroundLocation(on);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Choose "Allow all the time" in Sun Clock\'s location '
          'permission to follow the phone after a restart.'),
      action: SnackBarAction(
          label: 'Settings', onPressed: Geolocator.openAppSettings),
    ));
  }
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
