// The position everything is computed for: either live GPS or a point the
// user picked on the map. Picked points are remembered across launches.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'zone.dart';

enum LocationSource { gps, map }

class LocationModel extends ChangeNotifier {
  LocationSource _source = LocationSource.gps;
  double? _lat;
  double? _lon;
  tz.Location? _zone;
  String? _gpsError;

  StreamSubscription<Position>? _gpsSub;
  Timer? _saveTimer;

  LocationSource get source => _source;
  double? get latitude => _lat;
  double? get longitude => _lon;
  tz.Location? get zone => _zone;
  bool get hasPosition => _lat != null && _lon != null;

  /// Set when GPS is the source and no fix can be obtained.
  String? get gpsError => _gpsError;

  static const _kSource = 'source';
  static const _kLat = 'lat';
  static const _kLon = 'lon';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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

  Future<void> useGps() async {
    _source = LocationSource.gps;
    _gpsError = null;
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
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && _source == LocationSource.gps) {
        _set(last.latitude, last.longitude);
      }
      _stopGps();
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // ~1 km is plenty for sun times
          distanceFilter: 1000,
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
    _lat = lat;
    _lon = ((lon + 180) % 360 + 360) % 360 - 180; // map can wrap past ±180
    _zone = zoneAt(lat, _lon!);
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
