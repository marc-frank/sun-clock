// Dart side of the Android status-bar sun clock. The native service
// (SunClockService.kt) computes sun times itself with a Kotlin port of the
// NOAA formulas (SolarCalc.kt), so it only needs the position and settings.
// When the app uses GPS, the service also follows the phone's location while
// the app is closed.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'location_model.dart';
import 'zone.dart';

class StatusBarClock extends ChangeNotifier {
  static const _channel = MethodChannel('sun_clock/status_bar');

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
    try {
      await _channel.invokeMethod<void>('start', {
        'lat': model.latitude!,
        'lon': model.longitude!,
        'label': zoneCity(model.zone!),
        'followLocation': model.source == LocationSource.gps,
        'precise': model.precision == LocationPrecision.precise,
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
