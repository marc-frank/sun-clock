import 'package:fl_chart/fl_chart.dart';
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

  const YearCharts(
      {super.key, required this.lat, required this.lon, required this.zone});

  @override
  State<YearCharts> createState() => _YearChartsState();
}

class _YearChartsState extends State<YearCharts> {
  final _cache = YearDataCache();

  @override
  Widget build(BuildContext context) {
    final today = inZone(DateTime.now(), widget.zone);
    final days = _cache.get(today.year, widget.lat, widget.lon, widget.zone);
    final todayIndex = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(today.year))
        .inDays
        .toDouble();
    final hasPolar = days.any((d) => d.polar != PolarState.none);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Section(
        title: 'Sunrise and sunset',
        subtitle: '${today.year} · local time, ${widget.zone.name}',
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
      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
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
        reservedSize: 40,
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
  final c = Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4);
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
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      strokeWidth: 1.5,
      dashArray: [4, 4],
      label: VerticalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        labelResolver: (_) => 'today',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );

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
    handleBuiltInTouches: true,
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
    return LineChart(LineChartData(
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
            fromIndex: 0, toIndex: 1, color: dayColor.withOpacity(0.15)),
      ],
      extraLinesData:
          ExtraLinesData(verticalLines: [_todayLine(context, todayIndex)]),
      lineTouchData: _touch(context, days,
          (s) => '${s.barIndex == 0 ? 'Sunrise' : 'Sunset'} ${hoursToHm(s.y)}'),
    ));
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

    return LineChart(LineChartData(
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
    ));
  }
}
