import 'package:flutter/widgets.dart';

/// Glides a chart's y-axis range to new limits instead of jumping, while
/// the data itself changes at once. The first build shows [min]–[max]
/// directly; later changes animate from wherever the range is at that
/// moment, so fast changes (scrubbing through days) stay smooth.
class AnimatedYRange extends StatelessWidget {
  final double min;
  final double max;
  final Widget Function(BuildContext context, double min, double max) builder;
  final Duration duration;

  const AnimatedYRange({
    super.key,
    required this.min,
    required this.max,
    required this.builder,
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(end: Offset(min, max)),
      duration: duration,
      curve: Curves.easeInOutCubic,
      builder: (context, v, _) => builder(context, v.dx, v.dy),
    );
  }
}

/// True when [v] is a whole multiple of [interval]. While the range glides,
/// the chart also offers labels at its (fractional) ends; only multiples get
/// one.
bool onInterval(double v, double interval) {
  final q = v / interval;
  return (q - q.roundToDouble()).abs() < 1e-6;
}

/// The y-axis step for a chart [height] pixels tall showing [span] units:
/// the first of [steps] that is at least [minStep] and leaves the labels
/// at least [minGap] pixels apart, so short charts (the wide grid) get
/// fewer labels instead of overlapping ones.
double axisStep(double minStep, double span, double height, List<double> steps,
    {double minGap = 22}) {
  final usable = height - 28; // the bottom axis labels
  for (final step in steps) {
    if (step < minStep) continue;
    final labels = span / step + 1;
    if (usable / labels >= minGap) return step;
  }
  return steps.last;
}
