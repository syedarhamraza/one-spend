import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_brand_icon.dart';
import 'one_ui_segmented_pills.dart';

/// "$1.2k" / "Rs 42k" / "Rp 2.4M" style labels for chart axes.
String compactMoney(String currency, double value) {
  String scaled(double v, String suffix) {
    final text = v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}$suffix';
  }

  final number = value >= 1e6
      ? scaled(value / 1e6, 'M')
      : value >= 1000
          ? scaled(value / 1000, 'k')
          : '${value.round()}';
  final c = CurrencyCatalog.of(currency);
  return c.symbolAfter ? '$number ${c.symbol}' : '${currencyPrefix(currency)}$number';
}

/// Samsung One UI spending trajectory card: past months as a solid line, the current month,
/// and a dashed forecast, with a budget guide, touch scrubbing, and the charges behind each month.
class OneUISpendingTrendsCard extends StatefulWidget {
  final List<Subscription>? subscriptions;
  final double? monthlyBudget;
  final String? currency;
  final SpendingTrendHorizon initialHorizon;
  final DateTime? referenceDate;

  /// Opens a subscription from the "Top charges" panel.
  final ValueChanged<Subscription>? onOpenSubscription;

  const OneUISpendingTrendsCard({
    super.key,
    this.subscriptions,
    this.monthlyBudget,
    this.currency,
    this.initialHorizon = SpendingTrendHorizon.sixMonths,
    this.referenceDate,
    this.onOpenSubscription,
  });

  @override
  State<OneUISpendingTrendsCard> createState() => _OneUISpendingTrendsCardState();
}

class _OneUISpendingTrendsCardState extends State<OneUISpendingTrendsCard> with SingleTickerProviderStateMixin {
  late SpendingTrendHorizon _currentHorizon;
  int? _selectedIndex;
  late AnimationController _animController;
  late Animation<double> _curveAnimation;

  @override
  void initState() {
    super.initState();
    _currentHorizon = widget.initialHorizon;
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _curveAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant OneUISpendingTrendsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different data set (e.g. a category filter) replays the draw-in animation.
    final oldIds = oldWidget.subscriptions?.map((s) => s.id).toSet();
    final newIds = widget.subscriptions?.map((s) => s.id).toSet();
    final changed = (oldIds == null) != (newIds == null) ||
        (oldIds != null && (oldIds.length != newIds!.length || !oldIds.containsAll(newIds)));
    if (changed) {
      _selectedIndex = null;
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizonChanged(SpendingTrendHorizon horizon) {
    if (_currentHorizon == horizon) return;
    setState(() {
      _currentHorizon = horizon;
      _selectedIndex = null;
    });
    _animController.forward(from: 0);
  }

  void _onPointSelected(int? index) {
    if (_selectedIndex != index) {
      if (index != null) HapticFeedback.selectionClick();
      setState(() => _selectedIndex = index);
    }
  }

  String _money(String currency, double v) => formatMoney(v, currency, style: MoneyStyle.summary);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([SubscriptionStore.instance, OneUIEffectsController.instance]),
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        final subs = widget.subscriptions ?? store.subscriptions;
        final currency = widget.currency ?? store.currency;
        final budget = widget.monthlyBudget ?? store.monthlyBudget;

        final points = SpendingTrendsEngine.calculateTrends(
          subscriptions: subs,
          horizon: _currentHorizon,
          referenceDate: widget.referenceDate,
          toMain: store.toMain,
        );
        final summary = SpendingTrendsEngine.calculateSummary(points, monthlyBudget: budget);

        final decoration = BoxDecoration(
          color: OneUIEffectsController.instance.cardColor,
          borderRadius: OneUITheme.cardBorderRadius,
          border: OneUIEffectsController.instance.cardBorder,
          boxShadow: OneUIEffectsController.instance.cardShadow,
        );

        if (points.isEmpty || !summary.hasData) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: decoration,
            child: const Column(
              children: [
                Icon(Icons.show_chart_rounded, size: 40, color: OneUITheme.textSecondary),
                SizedBox(height: 10),
                Text(
                  'No spending trajectory yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: OneUITheme.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Add active subscriptions to view month-over-month spending trends',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: OneUITheme.textSecondary),
                ),
              ],
            ),
          );
        }

        final currentIndex = math.max(0, points.indexWhere((p) => p.isCurrent));
        final activeIndex =
            (_selectedIndex != null && _selectedIndex! < points.length) ? _selectedIndex! : currentIndex;
        final activePoint = points[activeIndex];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: decoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Spending trajectory',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 132,
                    child: OneUISegmentedPills<SpendingTrendHorizon>(
                      dense: true,
                      segments: [for (final h in SpendingTrendHorizon.values) (value: h, label: h.label)],
                      selected: _currentHorizon,
                      onChanged: _onHorizonChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _headline(activePoint, currency),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Semantics(
                  label: 'Spending chart. ${activePoint.fullLabel}: ${_money(currency, activePoint.amount)}'
                      '${activePoint.isForecast ? ', forecast' : ''}',
                  child: AnimatedBuilder(
                    animation: _curveAnimation,
                    builder: (context, _) => OneUILineChart(
                      points: points,
                      selectedIndex: _selectedIndex,
                      onPointSelected: _onPointSelected,
                      currency: currency,
                      monthlyBudget: budget,
                      animationProgress: _curveAnimation.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _legend(budget, summary),
              const SizedBox(height: 14),
              _topCharges(activePoint, currency),
              const SizedBox(height: 10),
              _statsRow(summary, currency),
            ],
          ),
        );
      },
    );
  }

  Widget _headline(MonthlySpendPoint point, String currency) {
    final (String? chip, Color chipColor) = point.isCurrent
        ? ('This month', OneUITheme.accentBlue)
        : point.isForecast
            ? ('Forecast', OneUITheme.accentTeal)
            : (null, OneUITheme.textSecondary);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money(currency, point.amount),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: OneUITheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      point.fullLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: OneUITheme.textSecondary),
                    ),
                  ),
                  if (chip != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        chip,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: chipColor),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildMoMBadge(point, currency),
      ],
    );
  }

  /// Key for the line styles, plus how many months break the budget.
  Widget _legend(double budget, TrendSummary summary) {
    Widget item(Widget swatch, String label, {Color color = OneUITheme.textSecondary}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch,
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: color)),
          ],
        );
    Widget line(Color color, {bool dashed = false}) => SizedBox(
          width: 14,
          height: 3,
          child: dashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 3; i++) Container(width: 3, height: 3, color: color),
                  ],
                )
              : DecoratedBox(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
        );

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        item(line(OneUITheme.accentBlue), 'Actual'),
        item(line(OneUITheme.accentTeal, dashed: true), 'Forecast'),
        if (budget > 0.01)
          item(
            line(OneUITheme.accentAmber, dashed: true),
            summary.overBudgetCount > 0
                ? 'Budget · ${summary.overBudgetCount} month${summary.overBudgetCount == 1 ? '' : 's'} over'
                : 'Budget',
            color: summary.overBudgetCount > 0 ? OneUITheme.accentRed : OneUITheme.textSecondary,
          ),
      ],
    );
  }

  /// "What drove this month": the biggest charges of the highlighted month.
  Widget _topCharges(MonthlySpendPoint point, String currency) {
    final top = point.topCharges.take(3).toList();
    final rest = point.topCharges.length - top.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            point.isForecast ? 'Due in ${point.label}' : 'Top charges in ${point.label}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
          ),
          const SizedBox(height: 8),
          if (top.isEmpty)
            const Text('No charges this month', style: TextStyle(fontSize: 13, color: OneUITheme.textTertiary))
          else
            for (final (i, c) in top.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpenSubscription == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        widget.onOpenSubscription!(c.subscription);
                      },
                child: Row(
                  children: [
                    OneUIBrandIcon(subscription: c.subscription, size: 22, borderRadius: 7),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.subscription.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _money(currency, c.amount),
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          if (rest > 0) ...[
            const SizedBox(height: 8),
            Text(
              '+ $rest more',
              style: const TextStyle(fontSize: 12, color: OneUITheme.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsRow(TrendSummary summary, String currency) {
    final avg = summary.pastAverage > 0 ? summary.pastAverage : summary.averageMonthlySpend;
    final peak = summary.peakMonth;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatCol('Avg / month', _money(currency, avg), summary.pastAverage > 0 ? 'past months' : 'this range')),
          _buildFooterDivider(),
          Expanded(child: _buildStatCol('Peak', peak == null ? '—' : _money(currency, peak.amount), peak?.label ?? '')),
          _buildFooterDivider(),
          Expanded(
            child: _buildStatCol(
              'Forecast',
              _money(currency, summary.forecastTotal),
              'next ${summary.forecastMonths} mo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoMBadge(MonthlySpendPoint point, String currency) {
    if (point.previousAmount == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Baseline',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
        ),
      );
    }

    final isIncrease = point.isIncrease;
    final isDecrease = point.isDecrease;
    final color = isIncrease ? OneUITheme.accentRed : (isDecrease ? OneUITheme.accentGreen : OneUITheme.textSecondary);
    final icon = isIncrease
        ? Icons.trending_up_rounded
        : (isDecrease ? Icons.trending_down_rounded : Icons.trending_flat_rounded);
    final sign = isIncrease ? '+' : (isDecrease ? '-' : '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$sign${compactMoney(currency, point.momDifference.abs())} (${point.momPercentage.abs().toStringAsFixed(0)}%)',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String title, String value, String caption) {
    return Column(
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: OneUITheme.textSecondary)),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
          ),
        ),
        const SizedBox(height: 1),
        Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: OneUITheme.textTertiary)),
      ],
    );
  }

  Widget _buildFooterDivider() {
    return Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.08));
  }
}

/// Standalone Interactive Line Chart Widget
class OneUILineChart extends StatelessWidget {
  /// Horizontal inset of the first and last point, shared by painting and hit-testing.
  static const double inset = 14.0;

  final List<MonthlySpendPoint> points;
  final int? selectedIndex;
  final ValueChanged<int?> onPointSelected;
  final String currency;
  final double monthlyBudget;
  final double animationProgress;

  const OneUILineChart({
    super.key,
    required this.points,
    required this.selectedIndex,
    required this.onPointSelected,
    required this.currency,
    required this.monthlyBudget,
    this.animationProgress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) => _handleTouch(details.localPosition.dx, width),
          onPanUpdate: (details) => _handleTouch(details.localPosition.dx, width),
          onTapUp: (details) => _handleTouch(details.localPosition.dx, width),
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(width, height),
              painter: OneUILineChartPainter(
                points: points,
                selectedIndex: selectedIndex,
                currency: currency,
                monthlyBudget: monthlyBudget,
                progress: animationProgress,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTouch(double touchX, double width) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      onPointSelected(0);
      return;
    }
    final chartWidth = width - inset * 2;
    final step = chartWidth / (points.length - 1);
    final clampedX = (touchX - inset).clamp(0.0, chartWidth);
    onPointSelected((clampedX / step).round().clamp(0, points.length - 1));
  }
}

/// Paints the trajectory: labelled gridlines, budget guide, a solid actual line that turns
/// into a dashed forecast at the current month, a "today" marker and the touch cursor.
class OneUILineChartPainter extends CustomPainter {
  final List<MonthlySpendPoint> points;
  final int? selectedIndex;
  final String currency;
  final double monthlyBudget;
  final double progress; // Animation progress from 0.0 to 1.0

  OneUILineChartPainter({
    required this.points,
    required this.selectedIndex,
    required this.currency,
    required this.monthlyBudget,
    required this.progress,
  });

  static const double _bottomLabelHeight = 24.0;
  static const double _topPadding = 30.0; // Room for the tooltip bubble.

  /// Rounds [value] up to 1, 2, 2.5 or 5 × a power of ten.
  static double niceCeiling(double value) {
    if (value <= 0) return 10;
    final magnitude = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
    for (final step in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (step * magnitude >= value) return step * magnitude;
    }
    return 10 * magnitude;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const pad = OneUILineChart.inset;
    final chartWidth = size.width - pad * 2;
    final chartHeight = size.height - _topPadding - _bottomLabelHeight;
    final zeroY = _topPadding + chartHeight;

    var maxVal = monthlyBudget;
    for (final p in points) {
      maxVal = math.max(maxVal, p.amount);
    }
    final yCeiling = niceCeiling(math.max(maxVal * 1.08, 1));

    final stepX = points.length > 1 ? chartWidth / (points.length - 1) : 0.0;
    final canvasPoints = [
      for (var i = 0; i < points.length; i++)
        Offset(
          points.length > 1 ? pad + i * stepX : size.width / 2,
          zeroY - (points[i].amount / yCeiling).clamp(0.0, 1.0) * progress * chartHeight,
        ),
    ];
    final currentIndex = points.indexWhere((p) => p.isCurrent);
    final activeIndex = (selectedIndex != null && selectedIndex! < points.length)
        ? selectedIndex!
        : (currentIndex >= 0 ? currentIndex : points.length - 1);

    _drawGridlines(canvas, size, chartHeight, yCeiling);
    if (monthlyBudget > 0.01 && monthlyBudget <= yCeiling) {
      _drawBudgetLine(canvas, size, chartHeight, yCeiling);
    }
    if (currentIndex >= 0) _drawTodayMarker(canvas, canvasPoints[currentIndex].dx, zeroY);

    if (canvasPoints.length == 1) {
      canvas.drawCircle(canvasPoints.first, 5.0, Paint()..color = OneUITheme.accentBlue);
    } else {
      _drawSeries(canvas, canvasPoints, zeroY, currentIndex < 0 ? canvasPoints.length - 1 : currentIndex);
    }

    _drawXAxisLabels(canvas, canvasPoints, zeroY, activeIndex, currentIndex);
    _drawActiveNode(canvas, canvasPoints[activeIndex], zeroY);
    if (selectedIndex != null) _drawTooltip(canvas, size, canvasPoints[activeIndex], points[activeIndex]);
  }

  TextPainter _text(String text, TextStyle style) =>
      TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();

  void _drawGridlines(Canvas canvas, Size size, double height, double ceiling) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.8;
    const pad = OneUILineChart.inset;
    for (var i = 0; i <= 2; i++) {
      final y = _topPadding + height * (i / 2.0);
      _drawDashedHorizontalLine(canvas, pad, size.width - pad, y, gridPaint, dashWidth: 4, dashSpace: 4);
      if (i < 2) {
        final value = ceiling * (1 - i / 2.0);
        final tp = _text(
          compactMoney(currency, value),
          const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: OneUITheme.textTertiary),
        );
        tp.paint(canvas, Offset(pad - 2, y - tp.height - 2));
      }
    }
  }

  void _drawBudgetLine(Canvas canvas, Size size, double height, double ceiling) {
    const pad = OneUILineChart.inset;
    final y = (_topPadding + height) - (monthlyBudget / ceiling).clamp(0.0, 1.0) * height;
    final budgetPaint = Paint()
      ..color = OneUITheme.accentAmber.withValues(alpha: 0.65)
      ..strokeWidth = 1.0;
    _drawDashedHorizontalLine(canvas, pad, size.width - pad, y, budgetPaint, dashWidth: 5, dashSpace: 3);

    final tp = _text(
      'Budget ${compactMoney(currency, monthlyBudget)}',
      const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: OneUITheme.accentAmber, letterSpacing: -0.2),
    );
    tp.paint(canvas, Offset(size.width - pad - tp.width, y - tp.height - 3));
  }

  void _drawTodayMarker(Canvas canvas, double x, double zeroY) {
    final paint = Paint()
      ..color = OneUITheme.accentBlue.withValues(alpha: 0.28)
      ..strokeWidth = 1.0;
    _drawDashedVerticalLine(canvas, x, _topPadding - 6, zeroY, paint, dashHeight: 2, dashSpace: 3);
  }

  /// Catmull-Rom style cubic segment from pts[i] to pts[i + 1].
  void _addSegment(Path path, List<Offset> pts, int i) {
    const tension = 0.2;
    final p0 = i > 0 ? pts[i - 1] : pts[i];
    final p1 = pts[i];
    final p2 = pts[i + 1];
    final p3 = (i + 2 < pts.length) ? pts[i + 2] : p2;
    path.cubicTo(
      p1.dx + (p2.dx - p0.dx) * tension,
      p1.dy + (p2.dy - p0.dy) * tension,
      p2.dx - (p3.dx - p1.dx) * tension,
      p2.dy - (p3.dy - p1.dy) * tension,
      p2.dx,
      p2.dy,
    );
  }

  Path _curve(List<Offset> pts, int from, int to) {
    final path = Path()..moveTo(pts[from].dx, pts[from].dy);
    for (var i = from; i < to; i++) {
      _addSegment(path, pts, i);
    }
    return path;
  }

  Path _area(Path curve, List<Offset> pts, int from, int to, double zeroY) {
    return Path.from(curve)
      ..lineTo(pts[to].dx, zeroY)
      ..lineTo(pts[from].dx, zeroY)
      ..close();
  }

  void _drawSeries(Canvas canvas, List<Offset> pts, double zeroY, int splitIndex) {
    final top = pts.map((p) => p.dy).reduce(math.min);
    final last = pts.length - 1;

    // Actual: points up to the current month, solid.
    if (splitIndex > 0) {
      final actual = _curve(pts, 0, splitIndex);
      canvas.drawPath(
        _area(actual, pts, 0, splitIndex, zeroY),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, zeroY), [
            OneUITheme.accentBlue.withValues(alpha: 0.26 * progress),
            OneUITheme.accentBlue.withValues(alpha: 0.0),
          ]),
      );
      canvas.drawPath(
        actual,
        Paint()
          ..color = OneUITheme.accentBlue
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    // Forecast: from the current month on, dashed with a fainter fill.
    if (splitIndex < last) {
      final forecast = _curve(pts, splitIndex, last);
      canvas.drawPath(
        _area(forecast, pts, splitIndex, last, zeroY),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, zeroY), [
            OneUITheme.accentTeal.withValues(alpha: 0.12 * progress),
            OneUITheme.accentTeal.withValues(alpha: 0.0),
          ]),
      );
      final dashPaint = Paint()
        ..color = OneUITheme.accentTeal
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final metric in forecast.computeMetrics()) {
        for (double d = 0; d < metric.length; d += 10) {
          canvas.drawPath(metric.extractPath(d, math.min(d + 5.5, metric.length)), dashPaint);
        }
      }
    }

    // Point dots; months over budget are flagged red.
    for (var i = 0; i < pts.length; i++) {
      final over = monthlyBudget > 0.01 && points[i].amount > monthlyBudget + 0.001;
      final base = over ? OneUITheme.accentRed : (i > splitIndex ? OneUITheme.accentTeal : OneUITheme.accentBlue);
      canvas.drawCircle(pts[i], over ? 3.4 : 2.5, Paint()..color = base.withValues(alpha: (over ? 1.0 : 0.55) * progress));
    }
  }

  void _drawXAxisLabels(Canvas canvas, List<Offset> pts, double zeroY, int activeIndex, int currentIndex) {
    // Dense ranges (2Y) label every third month, keeping the current month on the grid.
    final every = points.length > 12 ? 3 : 1;
    final anchor = currentIndex >= 0 ? currentIndex : 0;
    for (var i = 0; i < points.length; i++) {
      final isActive = i == activeIndex;
      if (!isActive && (i - anchor) % every != 0) continue;
      if (!isActive && every > 1 && (i - activeIndex).abs() < 2) continue; // avoid overlap with the active label
      final color = isActive
          ? OneUITheme.textPrimary
          : (i == currentIndex ? OneUITheme.accentBlue : OneUITheme.textSecondary);
      final tp = _text(
        points[i].label,
        TextStyle(fontSize: 11, fontWeight: isActive || i == currentIndex ? FontWeight.w700 : FontWeight.w500, color: color),
      );
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, zeroY + 8));
    }
  }

  void _drawActiveNode(Canvas canvas, Offset pt, double zeroY) {
    _drawDashedVerticalLine(
      canvas,
      pt.dx,
      pt.dy + 8,
      zeroY,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = 1.2,
      dashHeight: 3,
      dashSpace: 3,
    );
    canvas.drawCircle(pt, 11.0, Paint()..color = OneUITheme.accentBlue.withValues(alpha: 0.22));
    canvas.drawCircle(
      pt,
      6.0,
      Paint()
        ..color = OneUITheme.accentBlue
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(pt, 3.5, Paint()..color = Colors.white);
  }

  /// Capsule above the scrubbed point with its month and amount.
  void _drawTooltip(Canvas canvas, Size size, Offset pt, MonthlySpendPoint point) {
    final tp = _text(
      '${point.label} · ${formatMoney(point.amount, currency, style: MoneyStyle.summary)}',
      const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
    );
    final w = tp.width + 16;
    final h = tp.height + 8;
    final left = (pt.dx - w / 2).clamp(0.0, math.max(0.0, size.width - w)).toDouble();
    var top = pt.dy - h - 14;
    if (top < 0) top = pt.dy + 14;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), Radius.circular(h / 2));
    canvas.drawRRect(rect, Paint()..color = OneUITheme.surfacePillActive);
    tp.paint(canvas, Offset(left + 8, top + 4));
  }

  void _drawDashedHorizontalLine(Canvas canvas, double x1, double x2, double y, Paint paint,
      {double dashWidth = 4, double dashSpace = 4}) {
    for (var x = x1; x < x2; x += dashWidth + dashSpace) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dashWidth, x2), y), paint);
    }
  }

  void _drawDashedVerticalLine(Canvas canvas, double x, double y1, double y2, Paint paint,
      {double dashHeight = 3, double dashSpace = 3}) {
    for (var y = y1; y < y2; y += dashHeight + dashSpace) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + dashHeight, y2)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant OneUILineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.monthlyBudget != monthlyBudget ||
        oldDelegate.currency != currency ||
        oldDelegate.progress != progress;
  }
}
