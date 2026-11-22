// Screens for the Android home-screen widgets: a list of the placed widgets
// and an editor with a live preview. The editor also opens on its own when
// the launcher asks to set up a new widget (WidgetConfigActivity.kt).

import 'dart:async';

import 'package:flutter/material.dart';

import 'clock_view.dart';
import 'day_offset.dart';
import 'day_offset_chart.dart';
import 'home_widget.dart';
import 'l10n/l10n.dart';
import 'location_model.dart';
import 'sun_clock.dart';
import 'zone.dart';

/// The placed widgets, each with a preview; tap one to change it.
class WidgetsPage extends StatefulWidget {
  final LocationModel model;
  const WidgetsPage({super.key, required this.model});

  @override
  State<WidgetsPage> createState() => _WidgetsPageState();
}

class _WidgetsPageState extends State<WidgetsPage> {
  List<int>? _ids;
  final _configs = <int, WidgetConfig>{};
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // A widget added from the launcher shows up when the app comes back.
    _lifecycle = AppLifecycleListener(onResume: _reload);
    _reload();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final ids = await HomeWidgets.ids();
    for (final id in ids) {
      _configs[id] = await HomeWidgets.load(id);
    }
    if (mounted) setState(() => _ids = ids);
  }

  Future<void> _add() async {
    final ok = await HomeWidgets.pin();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(HomeWidgets.isIOS
              ? context.l10n.addWidgetManualIos
              : context.l10n.addWidgetManual)));
    }
  }

  Future<void> _edit(int id) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => WidgetEditorPage(id: id, model: widget.model)));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final ids = _ids;
    return Scaffold(
      appBar: AppBar(title: Text(l.widgetsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_to_home_screen),
        label: Text(l.addWidget),
      ),
      body: ids == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Text(
                    ids.isEmpty
                        ? l.noWidgets
                        : (HomeWidgets.isIOS
                            ? l.widgetsHelpIos
                            : l.widgetsHelp),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                for (final (i, id) in ids.indexed) ...[
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _edit(id),
                      child: Column(children: [
                        _Wallpaper(
                          child: WidgetPreview(
                              config: _configs[id] ?? const WidgetConfig(),
                              model: widget.model),
                        ),
                        ListTile(
                          title: Text(l.widgetN('${i + 1}')),
                          trailing: const Icon(Icons.edit_outlined),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

/// Changes one widget. Every change is applied to the widget at once.
class WidgetEditorPage extends StatefulWidget {
  final int id;
  final LocationModel model;

  /// Opened by the launcher to set up a new widget: Done closes the app's
  /// configuration screen instead of going back.
  final bool configuring;

  const WidgetEditorPage(
      {super.key,
      required this.id,
      required this.model,
      this.configuring = false});

  @override
  State<WidgetEditorPage> createState() => _WidgetEditorPageState();
}

class _WidgetEditorPageState extends State<WidgetEditorPage> {
  WidgetConfig? _config;
  Timer? _save;

  @override
  void initState() {
    super.initState();
    HomeWidgets.load(widget.id).then((c) {
      if (mounted) setState(() => _config = c);
    });
  }

  @override
  void dispose() {
    if (_save?.isActive ?? false) {
      _save!.cancel();
      HomeWidgets.save(widget.id, _config!);
    }
    super.dispose();
  }

  void _set(WidgetConfig c) {
    setState(() => _config = c);
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 250),
        () => HomeWidgets.save(widget.id, c));
  }

  Future<void> _done() async {
    _save?.cancel();
    if (_config != null) await HomeWidgets.save(widget.id, _config!);
    if (widget.configuring) {
      await HomeWidgets.finishConfig();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = _config;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.widgetsTitle),
        actions: [
          TextButton(onPressed: _done, child: Text(l.done)),
        ],
      ),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              _Wallpaper(child: WidgetPreview(config: c, model: widget.model)),
              Expanded(child: _Options(config: c, onChanged: _set)),
            ]),
    );
  }
}

class _Options extends StatelessWidget {
  final WidgetConfig config;
  final ValueChanged<WidgetConfig> onChanged;
  const _Options({required this.config, required this.onChanged});

  static const _backgrounds = [
    0x1C1B17, 0x000000, 0x263238, 0x1A237E, 0x004D40, 0x3E2723, //
    0x5D4037, 0x37474F, 0xFFFFFF, 0xFFF8E1, 0xFFB300, 0x90CAF9,
  ];

  static const _textColors = [
    0xFFFFFFFF, 0xB3FFFFFF, 0xFFFFB300, 0xFF9FA8DA, 0xFFFF7043, //
    0xFF80CBC4, 0xDE000000, 0x8A000000, 0xFF1A237E, 0xFF5D4037,
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final c = config;
    void set(WidgetConfig n) => onChanged(n);

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
          child: Text(text,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary)),
        );
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(text, style: theme.textTheme.bodyMedium),
        );
    Widget toggle(String title, bool value, ValueChanged<bool> on) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          value: value,
          onChanged: on,
        );
    Widget full(Widget w) => SizedBox(width: double.infinity, child: w);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        header(l.sectionClocks),
        full(SegmentedButton<WidgetClocks>(
          segments: [
            ButtonSegment(value: WidgetClocks.sun, label: Text(l.sunTime)),
            ButtonSegment(value: WidgetClocks.local, label: Text(l.local)),
            ButtonSegment(value: WidgetClocks.both, label: Text(l.clockBoth)),
          ],
          showSelectedIcon: false,
          selected: {c.clocks},
          onSelectionChanged: (s) => set(c.copyWith(clocks: s.first)),
        )),
        if (c.clocks == WidgetClocks.both) ...[
          label(l.clockLayout),
          full(SegmentedButton<WidgetLayout>(
            segments: [
              ButtonSegment(
                  value: WidgetLayout.stacked, label: Text(l.layoutStacked)),
              ButtonSegment(
                  value: WidgetLayout.side, label: Text(l.layoutSide)),
            ],
            showSelectedIcon: false,
            selected: {c.layout},
            onSelectionChanged: (s) => set(c.copyWith(layout: s.first)),
          )),
          label(c.layout == WidgetLayout.side ? l.leftClock : l.largeClock),
          full(SegmentedButton<WidgetFirst>(
            segments: [
              ButtonSegment(value: WidgetFirst.sun, label: Text(l.sunTime)),
              ButtonSegment(value: WidgetFirst.local, label: Text(l.local)),
            ],
            showSelectedIcon: false,
            selected: {c.first},
            onSelectionChanged: (s) => set(c.copyWith(first: s.first)),
          )),
        ],
        toggle(l.clockNames, c.labels, (v) => set(c.copyWith(labels: v))),
        header(l.sectionInfo),
        toggle(l.infoDayNight, c.dayNight, (v) => set(c.copyWith(dayNight: v))),
        toggle(l.infoNext, c.next, (v) => set(c.copyWith(next: v))),
        toggle(l.infoHourLength, c.hourLength,
            (v) => set(c.copyWith(hourLength: v))),
        toggle(l.infoOffset, c.offset, (v) => set(c.copyWith(offset: v))),
        toggle(l.infoPlace, c.place, (v) => set(c.copyWith(place: v))),
        toggle(l.infoProgress, c.progress, (v) => set(c.copyWith(progress: v))),
        header(l.sectionLook),
        label(l.background),
        _Swatches(
          colors: [for (final rgb in _backgrounds) 0xFF000000 | rgb],
          selected: 0xFF000000 | (c.background & 0xFFFFFF),
          onSelected: (argb) => set(c.copyWith(
              background: (c.background & 0xFF000000) | (argb & 0xFFFFFF))),
        ),
        label(l.opacity('${(c.opacity * 100).round()}')),
        Slider(
          value: c.opacity,
          divisions: 20,
          label: '${(c.opacity * 100).round()} %',
          onChanged: (v) => set(c.withOpacity(v)),
        ),
        if (!HomeWidgets.isIOS) label(l.corners),
        if (!HomeWidgets.isIOS)
          full(SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(l.cornersNone)),
              ButtonSegment(value: 8, label: Text(l.cornersSmall)),
              ButtonSegment(value: 16, label: Text(l.cornersMedium)),
              ButtonSegment(value: 28, label: Text(l.cornersLarge)),
            ],
            showSelectedIcon: false,
            selected: {c.corners},
            onSelectionChanged: (s) => set(c.copyWith(corners: s.first)),
          )),
        const SizedBox(height: 8),
        toggle(
            l.autoColors, c.autoColors, (v) => set(c.copyWith(autoColors: v))),
        if (!c.autoColors) ...[
          label(l.clockColor),
          _Swatches(
            colors: _textColors,
            selected: c.timeColor,
            onSelected: (v) => set(c.copyWith(timeColor: v)),
          ),
        ],
        label(l.textColor),
        _Swatches(
          colors: _textColors,
          selected: c.textColor,
          onSelected: (v) => set(c.copyWith(textColor: v)),
        ),
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  final List<int> colors;
  final int selected;
  final ValueChanged<int> onSelected;
  const _Swatches(
      {required this.colors, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final argb in colors)
        Semantics(
          button: true,
          selected: argb == selected,
          label: '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onSelected(argb),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color(argb),
                shape: BoxShape.circle,
                border: Border.all(
                    color: argb == selected ? Colors.white : outline,
                    width: argb == selected ? 3 : 1),
              ),
              child: argb == selected
                  ? Icon(Icons.check,
                      size: 20,
                      color: Color(argb).computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)
                  : null,
            ),
          ),
        ),
    ]);
  }
}

/// A stand-in home screen, so a see-through background shows.
class _Wallpaper extends StatelessWidget {
  final Widget child;
  const _Wallpaper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3F6E8C), Color(0xFF8C5A7A), Color(0xFFE0A15E)],
        ),
      ),
      child: Center(
        child: SizedBox(width: 280, height: 130, child: child),
      ),
    );
  }
}

/// What the widget will look like, drawn by Flutter (the real one is drawn
/// by SunWidget.kt with the same rules).
class WidgetPreview extends StatelessWidget {
  final WidgetConfig config;
  final LocationModel model;
  const WidgetPreview({super.key, required this.config, required this.model});

  @override
  Widget build(BuildContext context) =>
      Ticker(builder: (context, now) => _build(context, now));

  Widget _build(BuildContext context, DateTime now) {
    final l = context.l10n;
    final c = config;
    final hasPos = model.hasPosition;
    final reading =
        hasPos ? sunClock(now, model.latitude!, model.longitude!) : null;
    final isDay = reading?.isDay ?? false;
    final timeColor =
        c.autoColors ? (isDay ? dayColor : nightColor) : Color(c.timeColor);
    final textColor = Color(c.textColor);

    String sunText() {
      if (reading == null) return '--:--';
      final t = reading.sunTime;
      return '${two(t.inHours % 24)}:${two(t.inMinutes % 60)}';
    }

    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final localText = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(now),
        alwaysUse24HourFormat: use24);
    // Large clocks leave out AM/PM, as on the widget.
    final localShort = use24
        ? hm(now)
        : '${TimeOfDay.fromDateTime(now).hourOfPeriod == 0 ? 12 : TimeOfDay.fromDateTime(now).hourOfPeriod}:${two(now.minute)}';
    String text(WidgetFirst w) => w == WidgetFirst.sun ? sunText() : localText;
    String large(WidgetFirst w) =>
        w == WidgetFirst.sun ? sunText() : localShort;
    String name(WidgetFirst w) =>
        w == WidgetFirst.sun ? l.sunTime : l.localTime;

    Widget clockColumn(WidgetFirst w) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(children: [
              Expanded(
                child: FittedBox(
                  child: Text(large(w),
                      style: TextStyle(
                          color: timeColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 48,
                          fontFeatures: tabular)),
                ),
              ),
              if (c.labels)
                Text(name(w),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontSize: 10)),
            ]),
          ),
        );

    final secondary = c.secondary;
    final side = secondary != null && c.layout == WidgetLayout.side;
    final detail = widgetDetail(l, c, reading, now,
        place: hasPos ? zoneCity(model.zone!) : '', hasPosition: hasPos);

    return ClipRRect(
      borderRadius: BorderRadius.circular(c.corners.toDouble()),
      child: Container(
        color: Color(c.background),
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          Expanded(
            child: Row(children: [
              clockColumn(c.primary),
              if (side) clockColumn(secondary),
            ]),
          ),
          if (secondary != null && !side)
            Text(
                c.labels
                    ? '${name(secondary)} ${text(secondary)}'
                    : text(secondary),
                style: TextStyle(
                    color: textColor, fontSize: 14, fontFeatures: tabular)),
          if (detail.isNotEmpty)
            Text(detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 12)),
          if (c.progress && reading != null) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: dayProgress(reading.sunTime),
              color: timeColor,
              backgroundColor: textColor.withValues(alpha: 0.25),
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ]),
      ),
    );
  }
}

/// How much of the current day (06:00–18:00 sun time) or night has passed.
double dayProgress(Duration sunTime) {
  final m = sunTime.inMicroseconds / Duration.microsecondsPerMinute;
  final day = m >= 360 && m < 1080;
  return day ? (m - 360) / 720 : ((m - 1080) % 1440 + 1440) % 1440 / 720;
}

/// The widget's information line, as SunWidget.kt builds it.
String widgetDetail(
    AppLocalizations l, WidgetConfig c, SunClockReading? reading, DateTime now,
    {required String place, required bool hasPosition}) {
  if (!hasPosition) return c.showsSun ? l.widgetNoPosition : '';
  final parts = <String>[];
  final r = reading;
  if (r != null) {
    if (c.dayNight) parts.add(r.isDay ? l.dayWord : l.nightWord);
    if (c.next) {
      final next = r.next;
      if (next != null) {
        final at = hm(next.time.toLocal());
        parts
            .add(next.isSunrise ? l.widgetSunriseAt(at) : l.widgetSunsetAt(at));
      } else {
        parts.add(l.widgetSolar);
      }
    }
    if (c.hourLength && r.mode == SunClockMode.normal) {
      final n = '${r.realMinutesPerSunHour.round()}';
      parts.add(r.isDay ? l.dayHourEquals(n) : l.nightHourEquals(n));
    }
    if (c.offset) {
      final local = now.hour * 60 + now.minute + now.second / 60;
      final m = wrapMinutes(
          r.sunTime.inMicroseconds / Duration.microsecondsPerMinute - local);
      parts.add(l.widgetOffset(offsetText(l, m)));
    }
  }
  if (c.place && place.isNotEmpty) parts.add(place);
  return parts.join(' · ');
}
