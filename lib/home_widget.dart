// Settings of the Android home-screen widgets (SunWidget.kt), one set per
// placed widget, and the channel to read and change them. The keys and
// defaults match WidgetConfig.kt.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Which clocks a widget shows.
enum WidgetClocks { sun, local, both }

/// With both clocks: one large with the other small below it, or both
/// side by side at the same size.
enum WidgetLayout { stacked, side }

/// The large (or left) clock when both are shown.
enum WidgetFirst { sun, local }

@immutable
class WidgetConfig {
  final WidgetClocks clocks;
  final WidgetLayout layout;
  final WidgetFirst first;

  /// "Sun time" / "Local time" under or before each clock.
  final bool labels;

  // The information line.
  final bool dayNight;
  final bool next;
  final bool hourLength;
  final bool offset;
  final bool place;

  /// A bar for how much of the current day or night has passed.
  final bool progress;

  /// ARGB; the alpha is the background's opacity.
  final int background;

  /// Corner radius in dp: one of [cornerChoices].
  final int corners;

  /// Clocks in amber by day and blue by night, else in [timeColor].
  final bool autoColors;
  final int timeColor;

  /// Labels, the information line and the small clock.
  final int textColor;

  static const cornerChoices = [0, 8, 16, 28];

  const WidgetConfig({
    this.clocks = WidgetClocks.sun,
    this.layout = WidgetLayout.stacked,
    this.first = WidgetFirst.sun,
    this.labels = false,
    this.dayNight = true,
    this.next = true,
    this.hourLength = false,
    this.offset = false,
    this.place = false,
    this.progress = false,
    this.background = 0xFF1C1B17,
    this.corners = 16,
    this.autoColors = true,
    this.timeColor = 0xFFFFFFFF,
    this.textColor = 0xB3FFFFFF,
  });

  bool get showsSun => clocks != WidgetClocks.local;
  bool get showsLocal => clocks != WidgetClocks.sun;

  /// The large (stacked) or left (side by side) clock.
  WidgetFirst get primary => switch (clocks) {
        WidgetClocks.sun => WidgetFirst.sun,
        WidgetClocks.local => WidgetFirst.local,
        WidgetClocks.both => first,
      };

  /// The other clock when both are shown.
  WidgetFirst? get secondary => clocks != WidgetClocks.both
      ? null
      : (first == WidgetFirst.sun ? WidgetFirst.local : WidgetFirst.sun);

  WidgetConfig copyWith({
    WidgetClocks? clocks,
    WidgetLayout? layout,
    WidgetFirst? first,
    bool? labels,
    bool? dayNight,
    bool? next,
    bool? hourLength,
    bool? offset,
    bool? place,
    bool? progress,
    int? background,
    int? corners,
    bool? autoColors,
    int? timeColor,
    int? textColor,
  }) =>
      WidgetConfig(
        clocks: clocks ?? this.clocks,
        layout: layout ?? this.layout,
        first: first ?? this.first,
        labels: labels ?? this.labels,
        dayNight: dayNight ?? this.dayNight,
        next: next ?? this.next,
        hourLength: hourLength ?? this.hourLength,
        offset: offset ?? this.offset,
        place: place ?? this.place,
        progress: progress ?? this.progress,
        background: background ?? this.background,
        corners: corners ?? this.corners,
        autoColors: autoColors ?? this.autoColors,
        timeColor: timeColor ?? this.timeColor,
        textColor: textColor ?? this.textColor,
      );

  /// The background colour with a new opacity (0–1).
  WidgetConfig withOpacity(double opacity) => copyWith(
      background: ((opacity * 255).round().clamp(0, 255) << 24) |
          (background & 0xFFFFFF));

  double get opacity => ((background >> 24) & 0xFF) / 255;

  Map<String, Object> toMap() => {
        'clocks': clocks.name,
        'layout': layout.name,
        'first': first.name,
        'labels': labels,
        'dayNight': dayNight,
        'next': next,
        'hourLength': hourLength,
        'offset': offset,
        'place': place,
        'progress': progress,
        'background': background,
        'corners': corners,
        'autoColors': autoColors,
        'timeColor': timeColor,
        'textColor': textColor,
      };

  static T _enum<T extends Enum>(List<T> values, Object? v, T fallback) =>
      values.where((e) => e.name == v).firstOrNull ?? fallback;

  /// Missing or malformed values fall back to the defaults. Colours may come
  /// back from Android as negative 32-bit ints.
  factory WidgetConfig.fromMap(Map<Object?, Object?> m) {
    const d = WidgetConfig();
    bool b(String k, bool fallback) => m[k] is bool ? m[k] as bool : fallback;
    int color(String k, int fallback) =>
        m[k] is int ? (m[k] as int) & 0xFFFFFFFF : fallback;
    final corners = m['corners'];
    return WidgetConfig(
      clocks: _enum(WidgetClocks.values, m['clocks'], d.clocks),
      layout: _enum(WidgetLayout.values, m['layout'], d.layout),
      first: _enum(WidgetFirst.values, m['first'], d.first),
      labels: b('labels', d.labels),
      dayNight: b('dayNight', d.dayNight),
      next: b('next', d.next),
      hourLength: b('hourLength', d.hourLength),
      offset: b('offset', d.offset),
      place: b('place', d.place),
      progress: b('progress', d.progress),
      background: color('background', d.background),
      corners: corners is int && cornerChoices.contains(corners)
          ? corners
          : d.corners,
      autoColors: b('autoColors', d.autoColors),
      timeColor: color('timeColor', d.timeColor),
      textColor: color('textColor', d.textColor),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WidgetConfig && mapEquals(other.toMap(), toMap());

  @override
  int get hashCode => Object.hashAll(toMap().values);
}

/// The Android side of the widgets (MainActivity.kt, "sun_clock/widgets").
class HomeWidgets {
  static const _channel = MethodChannel('sun_clock/widgets');

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// Ids of the widgets on the home screen.
  static Future<List<int>> ids() async {
    if (!supported) return const [];
    try {
      final ids = await _channel.invokeListMethod<int>('ids');
      return ids ?? const [];
    } catch (_) {
      return const [];
    }
  }

  static Future<WidgetConfig> load(int id) async {
    try {
      final m = await _channel
          .invokeMapMethod<Object?, Object?>('getConfig', {'id': id});
      return m == null ? const WidgetConfig() : WidgetConfig.fromMap(m);
    } catch (_) {
      return const WidgetConfig();
    }
  }

  /// Stores the settings and redraws the widget. New widgets start with the
  /// settings saved last.
  static Future<void> save(int id, WidgetConfig config) async {
    try {
      await _channel.invokeMethod<void>(
          'setConfig', {'id': id, 'config': config.toMap()});
    } catch (_) {}
  }

  /// Asks the launcher to add a widget (Android 8+); false when it can't.
  static Future<bool> pin() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('pin') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// The widget being set up when the app was opened by the launcher to
  /// configure one, else null.
  static Future<int?> configLaunchId() async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<int>('configLaunchId');
    } catch (_) {
      return null;
    }
  }

  /// Closes the configuration screen opened by the launcher.
  static Future<void> finishConfig() async {
    try {
      await _channel.invokeMethod<void>('finishConfig');
    } catch (_) {}
  }
}
