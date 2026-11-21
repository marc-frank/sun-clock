import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'home_widget.dart';
import 'l10n/l10n.dart';
import 'language.dart';
import 'location_model.dart';
import 'status_bar_clock.dart';
import 'update_check.dart';
import 'widget_editor.dart';

/// Bottom sheet with location precision and the status-bar clock switch.
void showSettings(BuildContext context, LocationModel model,
    StatusBarClock statusBar, LanguageSetting language,
    [UpdateChecker? updates]) {
  statusBar.refreshBackground();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge(
            [model, statusBar, language, if (updates != null) updates]),
        builder: (context, _) {
          final theme = Theme.of(context);
          final l = context.l10n;
          final muted = theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.settings, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.translate),
                title: Text(l.language),
                trailing: DropdownButton<String>(
                  value: language.code,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: '', child: Text(l.phoneLanguage)),
                    for (final e in appLanguages.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (c) => language.set(c ?? ''),
                ),
              ),
              if (HomeWidgets.supported)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.widgets_outlined),
                  title: Text(l.widgetsTitle),
                  subtitle: Text(l.widgetsTileHelp, style: muted),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => WidgetsPage(model: model))),
                ),
              if (updates != null && UpdateChecker.supported) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.system_update_outlined),
                  title: Text(l.updateCheckTitle),
                  subtitle: Text(l.updateCheckHelp, style: muted),
                  value: updates.enabled,
                  onChanged: updates.setEnabled,
                ),
                if (updates.enabled)
                  Row(children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        updates.available != null
                            ? l.updateAvailable(updates.available!.version)
                            : switch (updates.lastResult) {
                                CheckResult.upToDate => l.upToDate,
                                CheckResult.failed => l.updateFailed,
                                _ => '',
                              },
                        style: muted,
                      ),
                    ),
                    if (updates.available != null)
                      TextButton(
                          onPressed: updates.openDownload,
                          child: Text(l.download))
                    else
                      TextButton(
                        onPressed: updates.checking ? null : updates.check,
                        child: Text(l.checkNow),
                      ),
                  ]),
              ],
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(l.locationAccuracy, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<LocationPrecision>(
                  segments: [
                    ButtonSegment(
                      value: LocationPrecision.approximate,
                      icon: const Icon(Icons.location_searching),
                      label: Text(l.approximate),
                    ),
                    ButtonSegment(
                      value: LocationPrecision.precise,
                      icon: const Icon(Icons.my_location),
                      label: Text(l.precise),
                    ),
                  ],
                  selected: {model.precision},
                  onSelectionChanged: (s) => model.setPrecision(s.first),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                model.precision == LocationPrecision.approximate
                    ? l.approximateHelp
                    : l.preciseHelp,
                style: muted,
              ),
              const SizedBox(height: 4),
              Text(
                l.privacyNote,
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
                            l.preciseDenied,
                            style: TextStyle(
                                color: theme.colorScheme.onErrorContainer),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: Geolocator.openAppSettings,
                            child: Text(l.openSettings),
                          ),
                        ]),
                  ),
                ),
              ],
              if (model.source == LocationSource.map) ...[
                const SizedBox(height: 8),
                Text(l.mapPlaceNote, style: muted),
              ],
              // Follows the phone while the app is closed, for the
              // widget and the status-bar clock alike.
              if (statusBar.supported &&
                  model.source == LocationSource.gps) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.followAfterRestart),
                  subtitle: Text(
                    l.followAfterRestartHelp,
                    style: muted,
                  ),
                  value: statusBar.backgroundOptIn,
                  onChanged: (on) =>
                      toggleBackgroundLocation(context, statusBar, on),
                ),
                if (statusBar.backgroundOptIn && !statusBar.backgroundGranted)
                  Row(children: [
                    Expanded(
                      child: Text(
                        l.backgroundOff,
                        style: muted,
                      ),
                    ),
                    TextButton(
                      onPressed: Geolocator.openAppSettings,
                      child: Text(l.settings),
                    ),
                  ]),
              ],
              if (statusBar.supported) ...[
                const SizedBox(height: 24),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.statusBarTitle),
                  subtitle: Text(
                    l.statusBarHelp,
                    style: muted,
                  ),
                  value: statusBar.enabled,
                  onChanged: (on) => toggleStatusBar(context, statusBar, on),
                ),
                if (statusBar.enabled && statusBar.chipSupported) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.chipTitle),
                    subtitle: Text(
                      l.chipHelp,
                      style: muted,
                    ),
                    value: statusBar.chipOn,
                    onChanged: statusBar.setTextChip,
                  ),
                  if (statusBar.chipOn && !statusBar.chipAllowed)
                    Row(children: [
                      Expanded(
                        child: Text(
                          l.chipOff,
                          style: muted,
                        ),
                      ),
                      TextButton(
                        onPressed: statusBar.openPromotionSettings,
                        child: Text(l.settings),
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
  final l = context.l10n;
  if (on) {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_on_outlined),
        title: Text(l.backgroundTitle),
        content: Text(l.backgroundDisclosure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.noThanks),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.continueLabel),
          ),
        ],
      ),
    );
    if (accepted != true) return;
  }
  final ok = await statusBar.setBackgroundLocation(on);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.backgroundSnack),
      action: SnackBarAction(
          label: l.settings, onPressed: Geolocator.openAppSettings),
    ));
  }
}

Future<void> toggleStatusBar(
    BuildContext context, StatusBarClock statusBar, bool on) async {
  final l = context.l10n;
  final ok = await statusBar.setEnabled(on);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.notificationsSnack),
      action: SnackBarAction(
          label: l.settings, onPressed: Geolocator.openAppSettings),
    ));
  }
}
