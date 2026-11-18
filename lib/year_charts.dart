import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'clock_view.dart';
import 'year_data.dart';
import 'zone.dart';

const _monthLetters = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _dateLabel(DateTime d) => '${d.day} ${_monthNames[d.month - 1]}';

/// The two year charts shown below the clock.
class YearCharts extends StatefulWidget {
  final double lat;
  final double lon;
  final tz.Location zone;

  /// The current time; replaceable in tests.
  final DateTime Function() clock;

  const YearCharts(
      {super.key,
      required this.lat,
      required this.lon,
      required this.zone,
      this.clock = DateTime.now});

  @override
  State<YearCharts> createState() => _YearChartsState();
}

class _YearChartsState extends State<YearCharts> {
  final _cache = YearDataCache();

  /// At most this many chart updates per second while the map is dragged.
  static const _minInterval = Duration(milliseconds: 100);

  // The position the charts show. While the map is dragged the location
  // changes every frame, and each change recomputes the whole year, so the
  // charts follow at most every [_minInterval], with a trailing update for
  // the final position.
  late double _lat = widget.lat;
  late double _lon = widget.lon;
  late tz.Location _zone = widget.zone;

  /// Runs for [_minInterval] after each update; changes meanwhile wait.
  Timer? _cooldown;

  // The "today" marker (and after New Year the whole year) moves at local
  // midnight in the location's zone. A timer set for that moment rebuilds
  // the charts once a day instead of with every clock tick.
  Timer? _midnight;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _newDay);
    _scheduleMidnight();
  }

  @override
  void didUpdateWidget(YearCharts old) {
    super.didUpdateWidget(old);
    // The first change after a pause shows at once (build follows this);
    // later ones wait for the cooldown to end.
    if (_cooldown == null && _behind) _follow();
  }

  bool get _behind =>
      widget.lat != _lat || widget.lon != _lon || widget.zone != _zone;

  void _follow() {
    final zoneChanged = widget.zone != _zone;
    _lat = widget.lat;
    _lon = widget.lon;
    _zone = widget.zone;
    if (zoneChanged) _scheduleMidnight();
    _cooldown = Timer(_minInterval, _cooldownEnded);
  }

  void _cooldownEnded() {
    _cooldown = null;
    if (mounted && _behind) setState(_follow); // the trailing update
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = inZone(widget.clock(), _zone);
    // Midnight is skipped on a few DST days; TZDateTime then moves it on.
    final next = tz.TZDateTime(_zone, now.year, now.month, now.day + 1);
    final wait = next.difference(now) + const Duration(seconds: 1);
    _midnight = Timer(wait.isNegative ? const Duration(seconds: 1) : wait,
        _newDay);
  }

  // Also called on resume: timers can run late while the phone sleeps.
  void _newDay() {
    if (!mounted) return;
    setState(() {});
    _scheduleMidnight();
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _cooldown?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = inZone(widget.clock(), _zone);
    final days = _cache.get(today.year, _lat, _lon, _zone);
    final todayIndex = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(today.year))
        .inDays
        .toDouble();
    final hasPolar = days.any((d) => d.polar != PolarState.none);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Section(
        title: 'Sunrise and sunset',
        subtitle: '${today.year} · local time, ${_zone.name}',
        legend: const [
          _LegendItem(dayColor, 'Sunrise'),
          _LegendItem(Color(0xFFFF7043), 'Sunset'),
        ],
        chart: _SunTimesChart(days: days, todayIndex: todayIndex),
      ),
      const SizedBox(height: 16),
      _Section(
        title: 'Length of one sun hour',
        subtitle: 'Real minutes per hour of sun time',
        legend: const [
          _LegendItem(dayColor, 'Day hour'),
          _LegendItem(nightColor, 'Night hour'),
        ],
        chart: _HourLengthChart(days: days, todayIndex: todayIndex),
      ),
      if (hasPolar)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Text(
            'Gaps are polar day or polar night, when the sun does not rise '
            'or set and the clock shows solar time.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
    ]);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_LegendItem> legend;
  final Widget chart;

  const _Section(
      {required this.title,
      required this.subtitle,
      required this.legend,
      required this.chart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.titleMedium),
          Text(subtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 16, children: legend),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: chart),
        ]),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

// ---------------------------------------------------------------------------

FlTitlesData _titles(BuildContext context,
    {required double yInterval,
    required String Function(double) yLabel,
    required int dayCount}) {
  final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant);
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: _leftReserved,
        interval: yInterval,
        getTitlesWidget: (v, meta) {
          if (v == meta.min || v == meta.max) {
            // Edge labels are fine but avoid half-clipped extra ones.
            if (v % yInterval != 0) return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(yLabel(v), style: style, textAlign: TextAlign.right),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 22,
        interval: dayCount / 12,
        getTitlesWidget: (v, meta) {
          final m = (v / (dayCount / 12)).round();
          if (m < 0 || m > 11) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_monthLetters[m], style: style),
          );
        },
      ),
    ),
  );
}

FlGridData _grid(BuildContext context, double yInterval, int dayCount) {
  final c = Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4);
  return FlGridData(
    drawVerticalLine: true,
    horizontalInterval: yInterval,
    verticalInterval: dayCount / 12,
    getDrawingHorizontalLine: (_) => FlLine(color: c, strokeWidth: 1),
    getDrawingVerticalLine: (_) => FlLine(color: c, strokeWidth: 1),
  );
}

VerticalLine _todayLine(BuildContext context, double x) => VerticalLine(
      x: x,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      strokeWidth: 1.5,
      dashArray: [4, 4],
      label: VerticalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        labelResolver: (_) => 'today',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );

/// Width of the y-axis labels; the plot starts this far from the left.
const double _leftReserved = 40;

/// A line chart you can scrub through with a finger.
///
/// A swipe that starts sideways belongs to the chart for its whole length
/// (the page does not take it over), a vertical swipe scrolls the page, and a
/// tap pins the infobox on that day until the next touch.
class _ScrubChart extends StatefulWidget {
  final LineChartData data;
  final double reservedLeft;
  const _ScrubChart(this.data, {required this.reservedLeft});

  @override
  State<_ScrubChart> createState() => _ScrubChartState();
}

class _ScrubChartState extends State<_ScrubChart> {
  int? _index;

  void _show(double dx, double width) {
    final d = widget.data;
    final plotWidth = width - widget.reservedLeft;
    if (plotWidth <= 0) return;
    final x = d.minX + (dx - widget.reservedLeft) / plotWidth * (d.maxX - d.minX);
    final i = x.round().clamp(d.minX.toInt(), d.maxX.toInt());
    if (i != _index) setState(() => _index = i);
  }

  void _hide() {
    if (_index != null) setState(() => _index = null);
  }

  LineChartData _withIndicators(LineChartData d) {
    final i = _index;
    if (i == null) return d;
    final spots = <LineBarSpot>[];
    final bars = <LineChartBarData>[];
    for (var b = 0; b < d.lineBarsData.length; b++) {
      final bar = d.lineBarsData[b];
      final hasSpot = i < bar.spots.length && bar.spots[i] != FlSpot.nullSpot;
      bars.add(bar.copyWith(showingIndicators: hasSpot ? [i] : []));
      if (hasSpot) spots.add(LineBarSpot(bar, b, bar.spots[i]));
    }
    return d.copyWith(
      lineBarsData: bars,
      showingTooltipIndicators: spots.isEmpty ? [] : [ShowingTooltipIndicators(spots)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth;
      return RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          HorizontalDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
            HorizontalDragGestureRecognizer.new,
            (r) => r
              ..onDown = ((d) => _show(d.localPosition.dx, width))
              ..onUpdate = ((d) => _show(d.localPosition.dx, width))
              ..onEnd = ((_) => _hide())
              ..onCancel = _hide, // a vertical swipe went to the page
          ),
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            TapGestureRecognizer.new,
            (r) => r..onTapUp = ((d) => _show(d.localPosition.dx, width)),
          ),
        },
        child: LineChart(_withIndicators(widget.data),
            duration: Duration.zero),
      );
    });
  }
}

LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 2.5,
      isCurved: false,
      dotData: const FlDotData(show: false),
    );

LineTouchData _touch(BuildContext context, List<DaySun> days,
    String Function(LineBarSpot s) valueText) {
  final theme = Theme.of(context);
  return LineTouchData(
    // Touch is handled by _ScrubChart; fl_chart's own recognizers lose
    // swipes to the page scroll and flicker on tap-cancel.
    enabled: false,
    handleBuiltInTouches: false,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipItems: (spots) {
        return [
          for (var i = 0; i < spots.length; i++)
            LineTooltipItem(
              '${i == 0 ? '${_dateLabel(days[spots[i].x.toInt()].date)}\n' : ''}'
              '${valueText(spots[i])}',
              TextStyle(
                  color: spots[i].bar.color,
                  fontWeight: FontWeight.w600,
                  fontFeatures: tabular),
            ),
        ];
      },
    ),
  );
}

class _SunTimesChart extends StatelessWidget {
  final List<DaySun> days;
  final double todayIndex;
  const _SunTimesChart({required this.days, required this.todayIndex});

  @override
  Widget build(BuildContext context) {
    final rise = <FlSpot>[];
    final set = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      rise.add(d.sunrise == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), d.sunrise!));
      set.add(d.sunset == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), d.sunset!));
    }
    final n = days.length;
    return _ScrubChart(LineChartData(
      minX: 0,
      maxX: n - 1,
      minY: 0,
      maxY: 24,
      clipData: const FlClipData.all(),
      titlesData: _titles(context,
          yInterval: 6,
          yLabel: (v) => '${two(v.round())}:00',
          dayCount: n),
      gridData: _grid(context, 3, n),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        _line(rise, dayColor),
        _line(set, const Color(0xFFFF7043)),
      ],
      betweenBarsData: [
        BetweenBarsData(
            fromIndex: 0, toIndex: 1, color: dayColor.withValues(alpha: 0.15)),
      ],
      extraLinesData:
          ExtraLinesData(verticalLines: [_todayLine(context, todayIndex)]),
      lineTouchData: _touch(context, days,
          (s) => '${s.barIndex == 0 ? 'Sunrise' : 'Sunset'} ${hoursToHm(s.y)}'),
    ), reservedLeft: _leftReserved);
  }
}

class _HourLengthChart extends StatelessWidget {
  final List<DaySun> days;
  final double todayIndex;
  const _HourLengthChart({required this.days, required this.todayIndex});

  @override
  Widget build(BuildContext context) {
    final day = <FlSpot>[];
    final night = <FlSpot>[];
    var lo = 60.0, hi = 60.0;
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final x = i.toDouble();
      if (d.dayHourMinutes != null) {
        day.add(FlSpot(x, d.dayHourMinutes!));
        lo = d.dayHourMinutes! < lo ? d.dayHourMinutes! : lo;
        hi = d.dayHourMinutes! > hi ? d.dayHourMinutes! : hi;
      } else {
        day.add(FlSpot.nullSpot);
      }
      if (d.nightHourMinutes != null) {
        night.add(FlSpot(x, d.nightHourMinutes!));
        lo = d.nightHourMinutes! < lo ? d.nightHourMinutes! : lo;
        hi = d.nightHourMinutes! > hi ? d.nightHourMinutes! : hi;
      } else {
        night.add(FlSpot.nullSpot);
      }
    }
    // Round the range outward to 15 minutes, with a little air.
    final interval = (hi - lo) > 60 ? 30.0 : 15.0;
    final minY = ((lo - 3) / interval).floorToDouble() * interval;
    final maxY = ((hi + 3) / interval).ceilToDouble() * interval;
    final n = days.length;

    return _ScrubChart(LineChartData(
      minX: 0,
      maxX: n - 1,
      minY: minY < 0 ? 0 : minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      titlesData: _titles(context,
          yInterval: interval,
          yLabel: (v) => '${v.round()}m',
          dayCount: n),
      gridData: _grid(context, interval, n),
      borderData: FlBorderData(show: false),
      lineBarsData: [_line(day, dayColor), _line(night, nightColor)],
      extraLinesData: ExtraLinesData(
        verticalLines: [_todayLine(context, todayIndex)],
        horizontalLines: [
          HorizontalLine(
            y: 60,
            color: Theme.of(context).colorScheme.outline,
            strokeWidth: 1,
            dashArray: [2, 3],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topLeft,
              labelResolver: (_) => '60 min',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
      lineTouchData: _touch(context, days,
          (s) => '${s.barIndex == 0 ? 'Day' : 'Night'} hour '
              '${s.y.toStringAsFixed(1)} min'),
    ), reservedLeft: _leftReserved);
  }
}
