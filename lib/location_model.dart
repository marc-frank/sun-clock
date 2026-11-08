// The position everything is computed for: either live GPS or a point the
// user picked on the map. Picked points are remembered across launches.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'zone.dart';

enum LocationSource { gps, map }

/// How exactly GPS positions are used. Approximate is the default: it asks the
/// system for a coarse fix only and rounds it to 0.01° (about 1 km), which
/// changes sun times by a few seconds at most.
enum LocationPrecision { approximate, precise }

class LocationModel extends ChangeNotifier {
  LocationSource _source = LocationSource.gps;
  LocationPrecision _precision = LocationPrecision.approximate;
  bool _preciseDenied = false;
  double? _lat;
  double? _lon;
  tz.Location? _zone;
  String? _gpsError;

  StreamSubscription<Position>? _gpsSub;
  Timer? _saveTimer;

  LocationSource get source => _source;
  LocationPrecision get precision => _precision;

  /// Precise was chosen, but the system only granted approximate location.
  bool get preciseDenied => _preciseDenied;

  /// Coordinates are rounded (approximate GPS).
  bool get isApproximate =>
      _source == LocationSource.gps &&
      _precision == LocationPrecision.approximate;
  double? get latitude => _lat;
  double? get longitude => _lon;
  tz.Location? get zone => _zone;
  bool get hasPosition => _lat != null && _lon != null;

  /// Set when GPS is the source and no fix can be obtained.
  String? get gpsError => _gpsError;

  static const _kSource = 'source';
  static const _kLat = 'lat';
  static const _kLon = 'lon';
  static const _kPrecision = 'precision';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_kPrecision) == LocationPrecision.precise.name) {
        _precision = LocationPrecision.precise;
      }
      final lat = prefs.getDouble(_kLat);
      final lon = prefs.getDouble(_kLon);
      if (lat != null && lon != null) _set(lat, lon);
      if (prefs.getString(_kSource) == 'map' && lat != null) {
        _source = LocationSource.map;
        notifyListeners();
        return;
      }
    } catch (_) {
      // Preferences unavailable: start from GPS.
    }
    await useGps();
  }

  /// Point picked on the map. Called continuously while panning.
  void setFromMap(double lat, double lon) {
    _stopGps();
    _source = LocationSource.map;
    _gpsError = null;
    _set(lat, lon);
    _saveSoon();
  }

  Future<void> setPrecision(LocationPrecision p) async {
    if (p == _precision) return;
    _precision = p;
    _preciseDenied = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrecision, p.name);
    } catch (_) {}
    if (_source == LocationSource.gps) {
      await useGps(); // restart the stream with the new accuracy
    } else {
      notifyListeners();
    }
  }

  Future<void> useGps() async {
    _source = LocationSource.gps;
    _gpsError = null;
    _preciseDenied = false;
    notifyListeners();
    _saveSoon();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _fail('Location services are turned off.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fail('Location permission was not granted.');
      }
      if (_source != LocationSource.gps) return; // user picked a point meanwhile
      final precise = _precision == LocationPrecision.precise;
      if (precise) {
        // Android 12+ and iOS 14+ let the user grant only approximate access.
        var status = await Geolocator.getLocationAccuracy();
        if (status == LocationAccuracyStatus.reduced) {
          try {
            // iOS: one-time prompt for full accuracy (no-op on Android).
            status = await Geolocator.requestTemporaryFullAccuracy(
                purposeKey: 'SunTimes');
          } catch (_) {}
        }
        _preciseDenied = status == LocationAccuracyStatus.reduced;
        notifyListeners();
      }
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && _source == LocationSource.gps) {
        _set(last.latitude, last.longitude);
      }
      _stopGps();
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: precise ? LocationAccuracy.high : LocationAccuracy.low,
          distanceFilter: precise ? 50 : 1000,
        ),
      ).listen(
        (p) {
          if (_source != LocationSource.gps) return;
          _gpsError = null;
          _set(p.latitude, p.longitude);
          _saveSoon();
        },
        onError: (Object e) => _fail('Could not get a GPS fix.'),
      );
    } catch (e) {
      _fail('Could not get a GPS fix.');
    }
  }

  void _fail(String message) {
    if (_source != LocationSource.gps) return;
    _gpsError = message;
    notifyListeners();
  }

  void _set(double lat, double lon) {
    lon = ((lon + 180) % 360 + 360) % 360 - 180; // map can wrap past ±180
    if (isApproximate) {
      lat = (lat * 100).roundToDouble() / 100;
      lon = (lon * 100).roundToDouble() / 100;
    }
    _lat = lat;
    _lon = lon;
    _zone = zoneAt(lat, lon);
    notifyListeners();
  }

  void _stopGps() {
    _gpsSub?.cancel();
    _gpsSub = null;
  }

  void _saveSoon() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kSource, _source.name);
        if (_lat != null && _lon != null) {
          await prefs.setDouble(_kLat, _lat!);
          await prefs.setDouble(_kLon, _lon!);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _stopGps();
    _saveTimer?.cancel();
    super.dispose();
  }
}
