import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'sun_clock.dart';

void main() => runApp(const SunClockApp());

class SunClockApp extends StatelessWidget {
  const SunClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sun Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const ClockPage(),
    );
  }
}

class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  Position? _position;
  String? _error;
  Timer? _ticker;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
        const Duration(milliseconds: 250), (_) => setState(() {}));
    _startLocation();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _startLocation() async {
    setState(() => _error = null);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _error = 'Location services are turned off.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission is needed to know '
            'when the sun rises and sets where you are.');
        return;
      }
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && _position == null) setState(() => _position = last);

      _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // ~1 km is plenty for sun times
          distanceFilter: 1000,
        ),
      ).listen(
        (p) => setState(() => _position = p),
        onError: (Object e) => setState(() => _error = '$e'),
      );
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pos = _position;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: pos == null
                ? _waiting(context, now)
                : _clock(context, now, pos.latitude, pos.longitude),
          ),
        ),
      ),
    );
  }

  Widget _waiting(BuildContext context, DateTime now) {
    final theme = Theme.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (_error == null) ...[
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text('Finding your position…'),
      ] else ...[
        Icon(Icons.location_off, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: _startLocation, child: const Text('Retry')),
        TextButton(
            onPressed: Geolocator.openAppSettings,
            child: const Text('Open settings')),
      ],
      const SizedBox(height: 32),
      _utcLine(context, now),
    ]);
  }

  Widget _clock(BuildContext context, DateTime now, double lat, double lon) {
    final theme = Theme.of(context);
    final r = sunClock(now, lat, lon);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 280,
        height: 280,
        child: CustomPaint(painter: _DialPainter(r.sunTime, theme)),
      ),
      const SizedBox(height: 24),
      Text(_hms(r.sunTime),
          style: theme.textTheme.displayLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()])),
      Text(r.isDay ? 'Sun time · day' : 'Sun time · night', style: muted),
      const SizedBox(height: 24),
      _utcLine(context, now),
      const SizedBox(height: 24),
      if (r.mode == SunClockMode.normal) ...[
        Text(
            '${r.previous!.isSunrise ? 'Sunrise' : 'Sunset'} '
            '${_hm(r.previous!.time.toLocal())}   →   '
            '${r.next!.isSunrise ? 'Sunrise' : 'Sunset'} '
            '${_hm(r.next!.time.toLocal())}',
            style: muted),
        const SizedBox(height: 4),
        Text(
            '1 sun hour = ${r.realMinutesPerSunHour.toStringAsFixed(1)} '
            'real minutes',
            style: muted),
      ] else
        Text(
            'The sun does not ${r.isDay ? 'set' : 'rise'} here today.\n'
            'Showing solar time (12:00 = solar noon).',
            textAlign: TextAlign.center,
            style: muted),
      const SizedBox(height: 4),
      Text('${_coord(lat, 'N', 'S')}  ${_coord(lon, 'E', 'W')}', style: muted),
    ]);
  }

  Widget _utcLine(BuildContext context, DateTime now) {
    final theme = Theme.of(context);
    final utc = now.toUtc();
    return Text(
      'UTC  ${_hms(Duration(hours: utc.hour, minutes: utc.minute, seconds: utc.second))}',
      style: theme.textTheme.headlineSmall
          ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

String _hms(Duration d) =>
    '${_two(d.inHours % 24)}:${_two(d.inMinutes % 60)}:${_two(d.inSeconds % 60)}';

String _hm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String _coord(double v, String pos, String neg) =>
    '${v.abs().toStringAsFixed(3)}° ${v >= 0 ? pos : neg}';

/// 24-hour dial: midnight at the bottom, noon at the top. Because sunrise is
/// always 06:00 and sunset 18:00, the upper half is always day.
class _DialPainter extends CustomPainter {
  final Duration sunTime;
  final ThemeData theme;
  _DialPainter(this.sunTime, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: radius);

    // Day (upper) and night (lower) halves.
    canvas.drawArc(rect, math.pi, math.pi, true,
        Paint()..color = const Color(0xFFFFC94D).withOpacity(0.25));
    canvas.drawArc(rect, 0, math.pi, true,
        Paint()..color = const Color(0xFF3A4A8C).withOpacity(0.35));
    canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = theme.colorScheme.outline);

    // Angle for hour h: 0h at bottom, clockwise, 12h at top.
    double angle(double h) => math.pi / 2 + h / 24 * 2 * math.pi;

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var h = 0; h < 24; h++) {
      final a = angle(h.toDouble());
      final dir = Offset(math.cos(a), math.sin(a));
      final major = h % 6 == 0;
      canvas.drawLine(
          c + dir * (radius - (major ? 14 : 7)),
          c + dir * radius,
          Paint()
            ..strokeWidth = major ? 3 : 1.5
            ..color = theme.colorScheme.onSurface);
      if (major) {
        tp.text = TextSpan(
            text: '$h',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600));
        tp.layout();
        tp.paint(canvas,
            c + dir * (radius - 30) - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Hand.
    final hours = sunTime.inMicroseconds / Duration.microsecondsPerHour;
    final a = angle(hours);
    final dir = Offset(math.cos(a), math.sin(a));
    final isDay = hours >= 6 && hours < 18;
    final handColor = isDay ? const Color(0xFFFFB300) : const Color(0xFF9FA8DA);
    canvas.drawLine(
        c,
        c + dir * (radius - 22),
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = handColor);
    canvas.drawCircle(c + dir * (radius - 22), 10, Paint()..color = handColor);
    canvas.drawCircle(c, 5, Paint()..color = theme.colorScheme.onSurface);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.sunTime != sunTime;
}
