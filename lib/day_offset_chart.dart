import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'clock_view.dart';
import 'day_offset.dart';
import 'l10n/l10n.dart';
import 'year_data.dart';
import 'zone.dart';

/// "+1h", "−30m", "0" for the offset chart's y axis.
String offsetAxisLabel(double v) {
  final m = v.round();
  if (m == 0) return '0';
  final sign = m > 0 ? '+' : '−';
  final a = m.abs();
  if (a < 60) return '$sign${a}m';
  if (a % 60 == 0) return '$sign${a ~/ 60}h';
  return '$sign${a ~/ 60}h${two(a % 60)}';
}

/// "23 min ahead", "1 h 5 min behind" or "in step".
String offsetText(AppLocalizations l, double minutes) {
  final m = minutes.round();
  if (m == 0) return l.offsetInStep;
  final a = m.abs();
  final d =
      a < 60 ? l.minutesShort('$a') : l.hoursMinutes('${a ~/ 60}', '${a % 60}');
  return m > 0 ? l.offsetAhead(d) : l.offsetBehind(d);
}

/// Card with how far sun time is ahead of or behind the local clock through
/// one day: [day] (a date from the year data) or, when null, today with a
/// marker at the current time. [section] lays it out like the year charts.
class DayOffsetSection extends StatefulWidget {
  final double lat;
  final double lon;
  final tz.Location zone;
  final DateTime? day;
  final DateTime Function() clock;
  final Widget Function(
      String title, String subtitle, List<Widget> legend, Widget chart) section;

  const DayOffsetSection(
      {super.key,
      required this.lat,
      required this.lon,
      required this.zone,
      required this.section,
      this.day,
      this.clock = DateTime.now});

  @override
  State<DayOffsetSection> createState() => _DayOffsetSectionState();
}

class _DayOffsetSectionState extends State<DayOffsetSection> {
  final _cache = DayOffsetCache();

  /// Moves the "now" marker along while today is shown.
  Timer? _minute;

  @override
  void initState() {
    super.initState();
    _minute = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && widget.day == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _minute?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = widget.clock();
    final local = inZone(now, widget.zone);
    final today = DateTime.utc(local.year, local.month, local.day);
    final date = widget.day ?? today;
    final isToday = date == today;
    final points = _cache.get(date, widget.lat, widget.lon, widget.zone);
    final sun = daySun(date, widget.lat, widget.lon, widget.zone);
    final style = Theme.of(context).textTheme.bodySmall;

    return widget.section(
      l.offsetTitle,
      l.offsetSubtitle(
          isToday ? l.offsetToday : dayMonthLabel(l, date), widget.zone.name),
      [
        _Swatch(dayColor, l.legendAhead),
        _Swatch(nightColor, l.legendBehind),
        if (isToday)
          Text(
              l.offsetNow(offsetText(
                  l, offsetAt(now, widget.lat, widget.lon, widget.zone))),
              style: style?.copyWith(
                  fontWeight: FontWeight.w600, fontFeatures: tabular)),
      ],
      DayOffsetChart(
        points: points,
        sunrise: sun.sunrise,
        sunset: sun.sunset,
        nowHour: isToday
            ? local.hour + local.minute / 60 + local.second / 3600
            : null,
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  const _Swatch(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 14,
          height: 10,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      // Wraps instead of overflowing with very large text.
      Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
    ]);
  }
}

/// Width of the y-axis labels, as in the year charts.
const double _leftReserved = 40;

class DayOffsetChart extends StatelessWidget {
  final List<OffsetPoint?> points;
  final double? sunrise;
  final double? sunset;
  final double? nowHour;

  const DayOffsetChart(
      {super.key,
      required this.points,
      this.sunrise,
      this.sunset,
      this.nowHour});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final spots = [
      for (final p in points)
        p == null ? FlSpot.nullSpot : FlSpot(p.hour, p.minutes)
    ];
    var lo = 0.0, hi = 0.0;
    for (final p in points) {
      if (p == null) continue;
      if (p.minutes < lo) lo = p.minutes;
      if (p.minutes > hi) hi = p.minutes;
    }
    final span = hi - lo;
    final interval = span <= 90
        ? 15.0
        : span <= 180
            ? 30.0
            : span <= 420
                ? 60.0
                : 120.0;
    final minY = ((lo - interval / 4) / interval).floorToDouble() * interval;
    final maxY = ((hi + interval / 4) / interval).ceilToDouble() * interval;

    final labelStyle = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final grid = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    VerticalLine marker(double x, Color color, String text,
            {Alignment align = Alignment.bottomRight}) =>
        VerticalLine(
          x: x,
          color: color,
          strokeWidth: 1.5,
          dashArray: [4, 4],
          label: VerticalLineLabel(
            show: true,
            alignment: align,
            labelResolver: (_) => text,
            style: labelStyle?.copyWith(color: color),
          ),
        );

    bool inDay(double? h) => h != null && h > 0 && h < 24;

    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minX: 0,
        maxX: 24,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        lineTouchData: const LineTouchData(enabled: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: true,
          horizontalInterval: interval,
          verticalInterval: 3,
          getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1),
          getDrawingVerticalLine: (_) => FlLine(color: grid, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _leftReserved,
              interval: interval,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(offsetAxisLabel(v),
                    style: labelStyle, textAlign: TextAlign.right),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 6,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(two(v.round()), style: labelStyle),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            // Between the line and zero: sun time ahead (line above zero)
            // or behind (below).
            belowBarData: BarAreaData(
                show: true,
                color: dayColor.withValues(alpha: 0.3),
                cutOffY: 0,
                applyCutOffY: true),
            aboveBarData: BarAreaData(
                show: true,
                color: nightColor.withValues(alpha: 0.3),
                cutOffY: 0,
                applyCutOffY: true),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
                y: 0,
                color: theme.colorScheme.outline,
                strokeWidth: 1,
                dashArray: [2, 3]),
          ],
          verticalLines: [
            if (inDay(sunrise)) marker(sunrise!, dayColor, '↑'),
            if (inDay(sunset)) marker(sunset!, const Color(0xFFFF7043), '↓'),
            if (nowHour != null)
              marker(nowHour!, theme.colorScheme.onSurface, l.nowLabel,
                  align: Alignment.topRight),
          ],
        ),
      ),
    );
  }
}
