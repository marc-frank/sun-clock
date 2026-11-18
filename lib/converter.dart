// Converter between local wall-clock time and sun time, for today at the
// current position: "when is sun 12:00 here?" and "what sun time is 15:30?".

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'clock_view.dart';
import 'l10n/l10n.dart';
import 'sun_clock.dart';
import 'zone.dart';

void showConverter(BuildContext context,
    {required double lat, required double lon, required tz.Location zone}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ConverterPanel(lat: lat, lon: lon, zone: zone),
      ),
    ),
  );
}

String _hmOf(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}';

/// The converter itself; [now] is replaceable in tests.
class ConverterPanel extends StatefulWidget {
  final double lat;
  final double lon;
  final tz.Location zone;
  final DateTime Function() now;

  const ConverterPanel(
      {super.key,
      required this.lat,
      required this.lon,
      required this.zone,
      this.now = DateTime.now});

  @override
  State<ConverterPanel> createState() => _ConverterPanelState();
}

class _ConverterPanelState extends State<ConverterPanel> {
  late final tz.TZDateTime _today = inZone(widget.now(), widget.zone);
  late TimeOfDay _local = TimeOfDay(hour: _today.hour, minute: _today.minute);
  late TimeOfDay _sun = _sunNow();

  TimeOfDay _sunNow() {
    final s = sunClock(_today, widget.lat, widget.lon).sunTime;
    return TimeOfDay(hour: s.inHours % 24, minute: s.inMinutes % 60);
  }

  Future<void> _pick(bool sun) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: sun ? _sun : _local,
      helpText: sun ? context.l10n.sunTime : context.l10n.localTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => sun ? _sun = picked : _local = picked);
  }

  /// Sun time at the picked local time today.
  String _localToSun(AppLocalizations l) {
    final z = widget.zone;
    final t = tz.TZDateTime(
        z, _today.year, _today.month, _today.day, _local.hour, _local.minute);
    final r = sunClock(t, widget.lat, widget.lon);
    final s = r.sunTime;
    final time = '${two(s.inHours % 24)}:${two(s.inMinutes % 60)}';
    return '${r.isDay ? l.resultSunDay(time) : l.resultSunNight(time)}'
        '${r.mode == SunClockMode.solarTimeFallback ? ' ${l.solarParen}' : ''}';
  }

  /// Local times today at which the clock shows the picked sun time.
  String _sunToLocal(AppLocalizations l) {
    final z = widget.zone;
    final found = instantsForSunTime(
      Duration(hours: _sun.hour, minutes: _sun.minute),
      tz.TZDateTime(z, _today.year, _today.month, _today.day),
      tz.TZDateTime(z, _today.year, _today.month, _today.day + 1),
      widget.lat,
      widget.lon,
    );
    if (found.isEmpty) return l.notToday;
    final times = found.map((t) => hm(inZone(t, z))).join(' ${l.andWord} ');
    final solar = found.any((t) =>
        sunClock(t, widget.lat, widget.lon).mode ==
        SunClockMode.solarTimeFallback);
    return '${l.resultLocal(times)}${solar ? ' ${l.solarParen}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.convertTime, style: theme.textTheme.headlineSmall),
      Text(
          l.todayLine(dayMonthLabel(l, _today), widget.zone.name),
          style: muted),
      const SizedBox(height: 20),
      _Row(
        title: l.fromLocalToSun,
        value: _hmOf(_local),
        pickLabel: l.pickLocal,
        onPick: () => _pick(false),
        result: _localToSun(l),
      ),
      const SizedBox(height: 20),
      _Row(
        title: l.fromSunToLocal,
        value: _hmOf(_sun),
        pickLabel: l.pickSun,
        onPick: () => _pick(true),
        result: _sunToLocal(l),
      ),
      const SizedBox(height: 16),
      Text(l.converterNote,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String value;
  final String pickLabel;
  final VoidCallback onPick;
  final String result;

  const _Row(
      {required this.title,
      required this.value,
      required this.pickLabel,
      required this.onPick,
      required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Tooltip(
            message: pickLabel,
            child: OutlinedButton(
              onPressed: onPick,
              child: Text(value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontFeatures: tabular)),
            ),
          ),
          Icon(Icons.arrow_forward,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          Text(result,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontFeatures: tabular)),
        ],
      ),
    ]);
  }
}
