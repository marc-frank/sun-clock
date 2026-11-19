// The app's language: the phone's language (the default) or one chosen in
// Settings. The choice is also handed to the Android side, so the
// status-bar notification and the home-screen widget use it too.

import 'dart:io' show Platform;
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language codes the app is translated into, with each language's own
/// name. The empty code means "follow the phone".
const appLanguages = <String, String>{
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
};

class LanguageSetting extends ChangeNotifier {
  static const _key = 'language';
  static const _channel = MethodChannel('sun_clock/status_bar');

  String _code = '';

  /// '' for the phone's language, else a key of [appLanguages].
  String get code => _code;

  /// For MaterialApp.locale: null follows the phone.
  Locale? get locale => _code.isEmpty ? null : Locale(_code);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final c = prefs.getString(_key) ?? '';
      _code = appLanguages.containsKey(c) ? c : '';
    } catch (_) {
      _code = '';
    }
    notifyListeners();
    await _syncNative();
  }

  Future<void> set(String code) async {
    if (!appLanguages.containsKey(code)) code = '';
    if (code == _code) return;
    _code = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {}
    await _syncNative();
  }

  Future<void> _syncNative() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setLanguage', {'code': _code});
    } catch (_) {}
  }
}
