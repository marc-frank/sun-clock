// Opt-in update check (Android): when turned on in Settings, the app asks
// GitHub for the latest release about once a week when it starts, and the
// home page shows a banner when that release is newer than this one. It is
// the only time Sun Clock goes online; the request carries nothing about the
// user or their position.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The repository releases are published to.
const releasesApi =
    'https://api.github.com/repos/marc-frank/sun-clock/releases/latest';
const releasesPage = 'https://github.com/marc-frank/sun-clock/releases';

/// A release found on GitHub.
@immutable
class Release {
  /// "1.4.0" (the tag without its "v").
  final String version;

  /// The release's page, with the APK to download.
  final String url;

  const Release(this.version, this.url);

  /// From GitHub's "latest release" JSON; null when it is not usable.
  static Release? fromJson(Object? json) {
    if (json is! Map) return null;
    final tag = json['tag_name'];
    final url = json['html_url'];
    if (tag is! String || url is! String) return null;
    if (!url.startsWith('$releasesPage/')) return null;
    final version = tag.startsWith('v') ? tag.substring(1) : tag;
    if (parseVersion(version) == null) return null;
    return Release(version, url);
  }
}

/// "1.4.0" → [1, 4, 0]; null for anything else.
List<int>? parseVersion(String v) {
  final m = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(v.trim());
  if (m == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(m.group(i)!)];
}

/// True when [candidate] is a later version than [current].
bool isNewer(String candidate, String current) {
  final a = parseVersion(candidate), b = parseVersion(current);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

enum CheckResult { newer, upToDate, failed }

class UpdateChecker extends ChangeNotifier {
  static const _kEnabled = 'updateCheck';
  static const _kLast = 'updateCheckLast';
  static const _kDismissed = 'updateDismissed';
  static const interval = Duration(days: 7);
  static const _channel = MethodChannel('sun_clock/system');

  /// Replaceable in tests.
  final Future<Object?> Function() fetchLatest;
  final Future<String> Function() currentVersion;
  final DateTime Function() clock;

  UpdateChecker({
    Future<Object?> Function()? fetchLatest,
    Future<String> Function()? currentVersion,
    this.clock = DateTime.now,
  })  : fetchLatest = fetchLatest ?? _fetchFromGitHub,
        currentVersion = currentVersion ?? _installedVersion;

  bool _enabled = false;
  Release? _available;
  String? _dismissed;
  bool _checking = false;
  CheckResult? _lastResult;

  /// Only Android builds offer it (and can open the download page).
  static bool get supported => !kIsWeb && Platform.isAndroid;

  bool get enabled => _enabled;
  bool get checking => _checking;

  /// What the last check found, shown next to "Check now".
  CheckResult? get lastResult => _lastResult;

  /// A newer release, once found.
  Release? get available => _available;

  /// Show the home-page banner: a newer release the user hasn't dismissed.
  bool get showBanner =>
      _enabled && _available != null && _available!.version != _dismissed;

  /// Reads the setting and, when it is on and a week has passed, checks.
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _enabled = p.getBool(_kEnabled) ?? false;
      _dismissed = p.getString(_kDismissed);
    } catch (_) {}
    notifyListeners();
    if (_enabled && await _due()) await check();
  }

  Future<bool> _due() async {
    try {
      final p = await SharedPreferences.getInstance();
      final last = p.getInt(_kLast);
      if (last == null) return true;
      return clock()
              .difference(DateTime.fromMillisecondsSinceEpoch(last))
              .abs() >=
          interval;
    } catch (_) {
      return true;
    }
  }

  /// Turning it on checks right away.
  Future<void> setEnabled(bool on) async {
    _enabled = on;
    if (!on) _available = null;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kEnabled, on);
    } catch (_) {}
    if (on) await check();
  }

  /// Asks GitHub now.
  Future<CheckResult> check() async {
    if (_checking) return CheckResult.failed;
    _checking = true;
    notifyListeners();
    final r = await _check();
    _lastResult = r;
    _checking = false;
    notifyListeners();
    return r;
  }

  Future<CheckResult> _check() async {
    try {
      final release = Release.fromJson(await fetchLatest());
      if (release == null) return CheckResult.failed;
      try {
        final p = await SharedPreferences.getInstance();
        await p.setInt(_kLast, clock().millisecondsSinceEpoch);
      } catch (_) {}
      final current = await currentVersion();
      _available = isNewer(release.version, current) ? release : null;
      return _available != null ? CheckResult.newer : CheckResult.upToDate;
    } catch (_) {
      return CheckResult.failed;
    }
  }

  /// "Later": no banner again for this version.
  Future<void> dismiss() async {
    final v = _available?.version;
    if (v == null) return;
    _dismissed = v;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kDismissed, v);
    } catch (_) {}
  }

  /// Opens the release page in the browser.
  Future<void> openDownload() async {
    final url = _available?.url ?? releasesPage;
    try {
      await _channel.invokeMethod<bool>('openUrl', {'url': url});
    } catch (_) {}
  }

  static Future<String> _installedVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  static Future<Object?> _fetchFromGitHub() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse(releasesApi));
      // GitHub requires a User-Agent; nothing else is sent.
      req.headers.set(HttpHeaders.userAgentHeader, 'SunClock-update-check');
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final body = await res
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));
      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }
}
