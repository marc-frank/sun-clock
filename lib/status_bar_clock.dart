// Dart side of the Android status-bar sun clock. The native service
// (SunClockService.kt) cannot run the NOAA code, so this computes the next
// two months of sunrises, sunsets and solar noons and hands them over; the
// service interpolates sun time between them every sun-minute.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'location_model.dart';
import 'solar.dart';
import 'zone.dart';

class StatusBarClock extends ChangeNotifier {
  static const _channel = MethodChannel('sun_clock/status_bar');

  /// Days of sun events sent to the service. The service keeps working this
  /// long without the app being opened.
  static const horizonDays = 60;

  final LocationModel model;
  bool _enabled = false;
  Timer? _debounce;

  StatusBarClock(this.model) {
    model.addListener(_onLocationChanged);
  }

  bool get supported => !kIsWeb && Platform.isAndroid;
  bool get enabled => _enabled;

  Future<void> load() async {
    if (!supported) return;
    try {
      _enabled = await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } catch (_) {
      _enabled = false;
    }
    notifyListeners();
    if (_enabled) await _sync(); // refresh the event horizon on every launch
  }

  /// Returns false when notifications were not allowed.
  Future<bool> setEnabled(bool on) async {
    if (!supported) return false;
    if (on) {
      final allowed =
          await _channel.invokeMethod<bool>('requestNotificationPermission') ??
              false;
      if (!allowed) return false;
      _enabled = true;
      notifyListeners();
      await _sync();
    } else {
      _enabled = false;
      notifyListeners();
      await _channel.invokeMethod<void>('stop');
    }
    return true;
  }

  void _onLocationChanged() {
    if (!_enabled) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _sync);
  }

  Future<void> _sync() async {
    if (!_enabled || !model.hasPosition) return;
    final lat = model.latitude!, lon = model.longitude!;
    final now = DateTime.now().toUtc();

    final events = <int>[]; // flat: [utcMillis, 1 = sunrise / 0 = sunset, ...]
    final noons = <int>[];
    for (var d = -1; d <= horizonDays; d++) {
      final day = now.add(Duration(days: d));
      final rise = sunEvent(day, lat, lon, rising: true);
      final set = sunEvent(day, lat, lon, rising: false);
      if (rise != null) events.addAll([rise.millisecondsSinceEpoch, 1]);
      if (set != null) events.addAll([set.millisecondsSinceEpoch, 0]);
      noons.add(solarNoon(day, lon).millisecondsSinceEpoch);
    }

    try {
      await _channel.invokeMethod<void>('start', {
        'events': events,
        'noons': noons,
        'label': zoneCity(model.zone!),
      });
    } catch (e) {
      debugPrint('status bar clock: $e');
    }
  }

  @override
  void dispose() {
    model.removeListener(_onLocationChanged);
    _debounce?.cancel();
    super.dispose();
  }
}
