import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'sun_clock.dart';
import 'zone.dart';

const dayColor = Color(0xFFFFB300);
const nightColor = Color(0xFF9FA8DA);
const tabular = [FontFeature.tabularFigures()];

String two(int n) => n.toString().padLeft(2, '0');

String hms(Duration d) =>
    '${two(d.inHours % 24)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';

String hm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

/// Fractional hours → "HH:MM".
String hoursToHm(double h) {
  final m = (h * 60).round();
  return '${two((m ~/ 60) % 24)}:${two(m % 60)}';
}

String coord(double v, String pos, String neg, {int decimals = 3}) =>
    '${v.abs().toStringAsFixed(decimals)}° ${v >= 0 ? pos : neg}';

/// Approximate positions are rounded to 0.01°, so show two decimals and "≈".
String coords(double lat, double lon, {bool approximate = false}) {
  final d = approximate ? 2 : 3;
  return '${approximate ? '≈ ' : ''}${coord(lat, 'N', 'S', decimals: d)}  '
      '${coord(lon, 'E', 'W', decimals: d)}';
}

/// Rebuilds its child four times a second with the current time, while the
/// app is in the foreground.
class Ticker extends StatefulWidget {
  final Widget Function(BuildContext context, DateTime now) builder;
  const Ticker({super.key, required this.builder});

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    _start();
  }

  void _start() {
    _timer ??= Timer.periodic(
        const Duration(milliseconds: 250), (_) => setState(() {}));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  // Inactive still means visible (e.g. a system dialog on top); hidden and
  // paused mean nobody sees the clock.
  void _onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      if (_timer == null) {
        _start();
        setState(() {}); // show the right time at once
      }
    } else {
      _stop();
    }
  }

  @override
  void dispose() {
    _stop();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

/// The main clock: dial, sun time, UTC, surrounding sun events.
class ClockView extends StatefulWidget {
  final double lat;
  final double lon;
  final tz.Location zone;
  final String sourceLabel;
  final bool approximate;
  final VoidCallback? onLocationTap;

  const ClockView({
    super.key,
    required this.lat,
    required this.lon,
    required this.zone,
    required this.sourceLabel,
    this.approximate = false,
    this.onLocationTap,
  });

  @override
  State<ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<ClockView> {
  // The clock is read four times a second; the sun events behind it change
  // only a few times a day.
  final _sun = SunClockCache();

  @override
  Widget build(BuildContext context) {
    final lat = widget.lat, lon = widget.lon, zone = widget.zone;
    return Ticker(builder: (context, now) {
      final theme = Theme.of(context);
      final r = _sun.read(now, lat, lon);
      final muted = theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

      return Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 280,
          height: 280,
          child: CustomPaint(painter: DialPainter(r.sunTime, theme)),
        ),
        const SizedBox(height: 24),
        Text(hms(r.sunTime),
            style: theme.textTheme.displayLarge
                ?.copyWith(fontFeatures: tabular)),
        Text(r.isDay ? 'Sun time · day' : 'Sun time · night', style: muted),
        const SizedBox(height: 24),
        UtcLine(now: now),
        const SizedBox(height: 24),
        ..._eventLines(r, zone, muted),
        const SizedBox(height: 4),
        InkWell(
          onTap: widget.onLocationTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '${coords(lat, lon, approximate: widget.approximate)}\n'
              '${zone.name} (${utcOffsetLabel(now, zone)}) · ${widget.sourceLabel}',
              textAlign: TextAlign.center,
              style: muted,
            ),
          ),
        ),
      ]);
    });
  }

  List<Widget> _eventLines(
      SunClockReading r, tz.Location zone, TextStyle? muted) {
    if (r.mode != SunClockMode.normal) {
      return [
        Text(
            'The sun does not ${r.isDay ? 'set' : 'rise'} here today.\n'
            'Showing solar time (12:00 = solar noon).',
            textAlign: TextAlign.center,
            style: muted),
      ];
    }
    String ev(SunEvent e) =>
        '${e.isSunrise ? 'Sunrise' : 'Sunset'} ${hm(inZone(e.time, zone))}';
    return [
      // An icon instead of a "→" character, which sits off-centre in the font.
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(ev(r.previous!), style: muted),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.arrow_forward,
              size: (muted?.fontSize ?? 14) + 2, color: muted?.color),
        ),
        Text(ev(r.next!), style: muted),
      ]),
      const SizedBox(height: 4),
      Text(
          '1 sun hour = ${r.realMinutesPerSunHour.toStringAsFixed(1)} '
          'real minutes',
          style: muted),
    ];
  }
}

class UtcLine extends StatelessWidget {
  final DateTime now;
  const UtcLine({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final utc = now.toUtc();
    return Text(
      'UTC  ${hms(Duration(hours: utc.hour, minutes: utc.minute, seconds: utc.second))}',
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontFeatures: tabular),
    );
  }
}

/// 24-hour dial: midnight at the bottom, noon at the top. Because sunrise is
/// always 06:00 and sunset 18:00, the upper half is always day.
class DialPainter extends CustomPainter {
  final Duration sunTime;
  final ThemeData theme;
  final bool labels;
  DialPainter(this.sunTime, this.theme, {this.labels = true});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: radius);
    final scale = radius / 140;

    canvas.drawArc(rect, math.pi, math.pi, true,
        Paint()..color = const Color(0xFFFFC94D).withValues(alpha: 0.25));
    canvas.drawArc(rect, 0, math.pi, true,
        Paint()..color = const Color(0xFF3A4A8C).withValues(alpha: 0.35));
    canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale
          ..color = theme.colorScheme.outline);

    // Angle for hour h: 0h at bottom, clockwise, 12h at top.
    double angle(double h) => math.pi / 2 + h / 24 * 2 * math.pi;

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var h = 0; h < 24; h++) {
      final a = angle(h.toDouble());
      final dir = Offset(math.cos(a), math.sin(a));
      final major = h % 6 == 0;
      canvas.drawLine(
          c + dir * (radius - (major ? 14 : 7) * scale),
          c + dir * radius,
          Paint()
            ..strokeWidth = (major ? 3 : 1.5) * scale
            ..color = theme.colorScheme.onSurface);
      if (major && labels) {
        tp.text = TextSpan(
            text: '$h',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600));
        tp.layout();
        tp.paint(canvas,
            c + dir * (radius - 30 * scale) - Offset(tp.width / 2, tp.height / 2));
      }
    }

    final hours = sunTime.inMicroseconds / Duration.microsecondsPerHour;
    final a = angle(hours);
    final dir = Offset(math.cos(a), math.sin(a));
    final handColor = hours >= 6 && hours < 18 ? dayColor : nightColor;
    canvas.drawLine(
        c,
        c + dir * (radius - 22 * scale),
        Paint()
          ..strokeWidth = 4 * scale
          ..strokeCap = StrokeCap.round
          ..color = handColor);
    canvas.drawCircle(
        c + dir * (radius - 22 * scale), 10 * scale, Paint()..color = handColor);
    canvas.drawCircle(c, 5 * scale, Paint()..color = theme.colorScheme.onSurface);
  }

  @override
  bool shouldRepaint(DialPainter old) => old.sunTime != sunTime;
}
