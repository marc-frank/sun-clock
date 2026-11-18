// Dart side of the Android status-bar sun clock. The native service
// (SunClockService.kt) computes sun times itself with a Kotlin port of the
// NOAA formulas (SolarCalc.kt), so it only needs the position and settings.
// When the app uses GPS, the service also follows the phone's location while
// the app is closed. The position is stored natively whenever it changes,
// also with the status-bar clock off, for the home-screen widget
// (SunWidget.kt).

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'location_model.dart';
import 'zone.dart';

class StatusBarClock extends ChangeNotifier with WidgetsBindingObserver {
  static const _channel = MethodChannel('sun_clock/status_bar');

  final LocationModel model;
  bool _enabled = false;
  bool _backgroundOptIn = false;
  bool _backgroundGranted = false;
  bool _chipSupported = false;
  bool _chipOn = false;
  bool _chipAllowed = false;
  Timer? _debounce;

  StatusBarClock(this.model) {
    model.addListener(_onLocationChanged);
  }

  bool get supported => !kIsWeb && Platform.isAndroid;
  bool get enabled => _enabled;

  /// The user turned on "Follow location after a restart".
  bool get backgroundOptIn => _backgroundOptIn;

  /// Android grants "Allow all the time"; when this turns false after an
  /// opt-in, the service silently falls back to the stored position.
  bool get backgroundGranted => _backgroundGranted;

  /// Android 16+: the status bar can show the sun time as a text chip.
  bool get chipSupported => _chipSupported;
  bool get chipOn => _chipOn;

  /// Live Updates are allowed for the app in system settings.
  bool get chipAllowed => _chipAllowed;

  Future<void> load() async {
    if (!supported) return;
    WidgetsBinding.instance.addObserver(this);
    try {
      _enabled = await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } catch (_) {
      _enabled = false;
    }
    await refreshBackground();
    notifyListeners();
    // Refresh the service's event horizon (or the widget's position).
    await _sync();
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

  /// Re-reads the background-location state; the permission can be changed
  /// in system settings at any time.
  Future<void> refreshBackground() async {
    if (!supported) return;
    try {
      final c =
          await _channel.invokeMapMethod<String, bool>('textChipStatus');
      _chipSupported = c?['supported'] ?? false;
      _chipOn = c?['on'] ?? false;
      _chipAllowed = c?['allowed'] ?? false;
    } catch (_) {}
    try {
      final s = await _channel
          .invokeMapMethod<String, bool>('backgroundLocationStatus');
      _backgroundOptIn = s?['optedIn'] ?? false;
      _backgroundGranted = s?['granted'] ?? false;
    } catch (_) {
      return;
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshBackground();
  }

  /// Turning on asks for "Allow all the time" (the caller shows the
  /// disclosure first). Returns false when Android did not grant it.
  Future<bool> setBackgroundLocation(bool on) async {
    if (!supported) return false;
    if (on) {
      final granted = await _channel.invokeMethod<bool>(
              'requestBackgroundLocation', {
            'precise': model.precision == LocationPrecision.precise,
          }) ??
          false;
      if (!granted) {
        await refreshBackground();
        return false;
      }
    }
    await _channel.invokeMethod<void>('setBackgroundLocation', {'on': on});
    await refreshBackground();
    return true;
  }

  Future<void> setTextChip(bool on) async {
    if (!supported) return;
    await _channel.invokeMethod<void>('setTextChip', {'on': on});
    await refreshBackground();
  }

  Future<void> openPromotionSettings() =>
      _channel.invokeMethod<void>('openPromotionSettings');

  void _onLocationChanged() {
    if (!supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _sync);
  }

  /// Sends the position: 'start' (re)starts the status-bar service,
  /// 'setPosition' only stores it for the home-screen widget.
  Future<void> _sync() async {
    if (!supported || !model.hasPosition) return;
    try {
      await _channel.invokeMethod<void>(_enabled ? 'start' : 'setPosition', {
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
    WidgetsBinding.instance.removeObserver(this);
    model.removeListener(_onLocationChanged);
    _debounce?.cancel();
    super.dispose();
  }
}
