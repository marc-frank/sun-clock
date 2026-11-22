import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'converter.dart';
import 'light_hours.dart';
import 'l10n/l10n.dart';
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

/// Dial diameter for a screen of [screen] logical pixels: as large as fits
/// beside the text of the first screen (which grows with [textScale]),
/// between 120 and 300, and never wider than [maxWidth].
double dialSize(Size screen, double maxWidth, double textScale) {
  // What the top bar, the times, the event lines and the gaps need, measured
  // on a phone at text scale 1: about 200 px of padding and icons and 365 px
  // of text (with the golden and blue hour lines).
  final byHeight = screen.height - 200 - 365 * textScale;
  return byHeight.clamp(120.0, 300.0).clamp(0.0, maxWidth);
}

/// "Sun time 14:32, day": what a screen reader says for the dial.
String dialLabel(AppLocalizations l, SunClockReading r) {
  final t = r.sunTime;
  final time = '${two(t.inHours % 24)}:${two(t.inMinutes % 60)}';
  return '${r.isDay ? l.dialDay(time) : l.dialNight(time)}'
      '${r.mode == SunClockMode.solarTimeFallback ? l.dialSolarSuffix : ''}';
}

/// The main clock: dial, sun time, local time and UTC, surrounding sun
/// events.
class ClockView extends StatefulWidget {
  final double lat;
  final double lon;
  final tz.Location zone;
  final String sourceLabel;
  final bool approximate;
  final VoidCallback? onLocationTap;

  /// Landscape or tablet: the dial and sun time on the left, the other
  /// times and the place on the right. The caller scales it to fit.
  final bool wide;

  const ClockView({
    super.key,
    required this.lat,
    required this.lon,
    required this.zone,
    required this.sourceLabel,
    this.approximate = false,
    this.onLocationTap,
    this.wide = false,
    this.wideDial = 300,
  });

  /// Dial diameter in the wide layout; the caller fits it to the height.
  final double wideDial;

  /// Width of the right-hand column in the wide layout.
  static const wideInfoWidth = 420.0;

  @override
  State<ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<ClockView> {
  // The clock is read four times a second; the sun events behind it change
  // only a few times a day.
  final _sun = SunClockCache();

  // Golden and blue hours change with the local day and the place.
  final _light = LightHoursCache();

  // The dial's screen-reader label, renewed at most once a minute (or when
  // the place changes) so the reader is not flooded with changes.
  String? _label;
  DateTime? _labelTime;
  double? _labelLat, _labelLon;

  String _labelFor(DateTime now, SunClockReading r) {
    final stale = _labelTime == null ||
        now.difference(_labelTime!).abs() >= const Duration(minutes: 1) ||
        _labelLat != widget.lat ||
        _labelLon != widget.lon;
    if (stale) {
      _label = dialLabel(context.l10n, r);
      _labelTime = now;
      _labelLat = widget.lat;
      _labelLon = widget.lon;
    }
    return _label!;
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.lat, lon = widget.lon, zone = widget.zone;
    return Ticker(builder: (context, now) {
      final theme = Theme.of(context);
      final r = _sun.read(now, lat, lon);
      final (light, bands) = _light.get(now, lat, lon, zone);
      final muted = theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

      final mq = MediaQuery.of(context);
      final screen = mq.padding.deflateSize(mq.size);
      final textScale = mq.textScaler.scale(16) / 16;

      // Dial, sun time and day/night read as one label, renewed once a
      // minute instead of with every tick.
      final dialGroup = Semantics(
        container: true,
        label: _labelFor(now, r),
        child: ExcludeSemantics(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (widget.wide)
              SizedBox.square(
                dimension: widget.wideDial,
                child: CustomPaint(
                    painter: DialPainter(r.sunTime, theme, bands: bands)),
              )
            else
              LayoutBuilder(builder: (context, box) {
                final d = dialSize(screen, box.maxWidth, textScale);
                return SizedBox(
                  width: d,
                  height: d,
                  child: CustomPaint(
                      painter: DialPainter(r.sunTime, theme, bands: bands)),
                );
              }),
            const SizedBox(height: 24),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(hms(r.sunTime),
                  style: theme.textTheme.displayLarge
                      ?.copyWith(fontFeatures: tabular)),
            ),
            Text(r.isDay ? context.l10n.sunTimeDay : context.l10n.sunTimeNight,
                style: muted),
          ]),
        ),
      );

      final info = <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: TimeLines(now: now, zone: zone),
        ),
        TextButton.icon(
          onPressed: () =>
              showConverter(context, lat: lat, lon: lon, zone: zone),
          icon: const Icon(Icons.swap_horiz),
          label: Text(context.l10n.convertTime),
        ),
        const SizedBox(height: 16),
        ..._eventLines(context.l10n, r, zone, muted),
        ..._lightLines(context.l10n, light, zone, muted),
        const SizedBox(height: 4),
        Semantics(
          button: widget.onLocationTap != null,
          hint: widget.onLocationTap == null ? null : context.l10n.locationHint,
          child: InkWell(
            onTap: widget.onLocationTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '${coords(lat, lon, approximate: widget.approximate)}\n'
                '${zone.name} (${utcOffsetLabel(now, zone)}) · '
                '${widget.sourceLabel}',
                textAlign: TextAlign.center,
                style: muted,
              ),
            ),
          ),
        ),
      ];

      if (widget.wide) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          dialGroup,
          const SizedBox(width: 48),
          SizedBox(
            width: ClockView.wideInfoWidth,
            child: Column(mainAxisSize: MainAxisSize.min, children: info),
          ),
        ]);
      }
      return Column(mainAxisSize: MainAxisSize.min, children: [
        dialGroup,
        const SizedBox(height: 24),
        ...info,
      ]);
    });
  }

  /// "Golden hour 07:05–08:10 · 15:22–16:40" and the blue hour, each with
  /// a dot in its colour on the dial.
  List<Widget> _lightLines(
      AppLocalizations l, LightHours h, tz.Location zone, TextStyle? muted) {
    String times(List<LightPeriod> ps) => ps
        .map((p) => '${hm(inZone(p.start, zone))}–${hm(inZone(p.end, zone))}')
        .join(' · ');
    Widget line(Color color, String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
                child: Text(text, textAlign: TextAlign.center, style: muted)),
          ]),
        );
    return [
      if (h.golden.isNotEmpty)
        line(goldenColor, l.goldenHourLine(times(h.golden))),
      if (h.blue.isNotEmpty) line(blueHourColor, l.blueHourLine(times(h.blue))),
    ];
  }

  List<Widget> _eventLines(AppLocalizations l, SunClockReading r,
      tz.Location zone, TextStyle? muted) {
    if (r.mode != SunClockMode.normal) {
      return [
        Text(r.isDay ? l.noSunset : l.noSunrise,
            textAlign: TextAlign.center, style: muted),
      ];
    }
    String ev(SunEvent e) => e.isSunrise
        ? l.sunriseAt(hm(inZone(e.time, zone)))
        : l.sunsetAt(hm(inZone(e.time, zone)));
    return [
      // An icon instead of a "→" character, which sits off-centre in the font.
      // A Wrap, so large text breaks the line instead of overflowing.
      Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
          (r.isDay
              ? l.dayHourLength
              : l.nightHourLength)(r.realMinutesPerSunHour.toStringAsFixed(1)),
          style: muted),
    ];
  }
}

/// Local wall-clock time of [zone] and UTC, one line each.
class TimeLines extends StatelessWidget {
  final DateTime now;
  final tz.Location zone;
  const TimeLines({super.key, required this.now, required this.zone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        theme.textTheme.headlineSmall?.copyWith(fontFeatures: tabular);
    final label = style?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final local = inZone(now, zone);
    final utc = now.toUtc();
    TableRow row(String name, DateTime t) => TableRow(children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(name, style: label),
          ),
          Text(
              hms(Duration(
                  hours: t.hour, minutes: t.minute, seconds: t.second)),
              style: style),
        ]);
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [row(context.l10n.local, local), row('UTC', utc)],
    );
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

  /// Minute and second hands of sun time, like a wall clock's: once round
  /// per sun hour and per sun minute, 0 at the top.
  final bool minuteHands;

  /// Golden and blue hours, drawn as bands along the rim.
  final List<DialBand> bands;
  DialPainter(this.sunTime, this.theme,
      {this.labels = true, this.minuteHands = true, this.bands = const []});

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

    // Golden and blue hours along the rim, under the hour ticks.
    final bandRect = Rect.fromCircle(center: c, radius: radius - 5 * scale);
    for (final b in bands) {
      var hours = b.end - b.start;
      if (hours < 0) hours += 24;
      canvas.drawArc(
          bandRect,
          angle(b.start),
          hours / 24 * 2 * math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8 * scale
            ..color = b.color.withValues(alpha: 0.85));
    }

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
        tp.paint(
            canvas,
            c +
                dir * (radius - 30 * scale) -
                Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Angle for a fraction of a turn, 0 at the top, clockwise.
    double turn(double f) => -math.pi / 2 + f * 2 * math.pi;
    Offset at(double angle, double length) =>
        c + Offset(math.cos(angle), math.sin(angle)) * length;
    final micros = sunTime.inMicroseconds;

    if (minuteHands) {
      final minutes =
          micros % Duration.microsecondsPerHour / Duration.microsecondsPerHour;
      final m = turn(minutes);
      canvas.drawLine(
          at(m, -10 * scale),
          at(m, radius - 36 * scale),
          Paint()
            ..strokeWidth = 3 * scale
            ..strokeCap = StrokeCap.round
            ..color = theme.colorScheme.onSurface.withValues(alpha: 0.85));
    }

    final hours = micros / Duration.microsecondsPerHour;
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
    canvas.drawCircle(c + dir * (radius - 22 * scale), 10 * scale,
        Paint()..color = handColor);

    if (minuteHands) {
      // Ticks once per sun second, together with the digital time below
      // (a sun second lasts longer or shorter than a real one).
      final seconds = (micros % Duration.microsecondsPerMinute) ~/
          Duration.microsecondsPerSecond /
          60;
      final s = turn(seconds);
      canvas.drawLine(
          at(s, -18 * scale),
          at(s, radius - 12 * scale),
          Paint()
            ..strokeWidth = 1.5 * scale
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFFF7043));
    }
    canvas.drawCircle(
        c, 5 * scale, Paint()..color = theme.colorScheme.onSurface);
  }

  @override
  bool shouldRepaint(DialPainter old) =>
      old.sunTime != sunTime || !identical(old.bands, bands);
}
