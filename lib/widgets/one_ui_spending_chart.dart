import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';

/// Samsung One UI Month-over-Month Spending Trends Card.
/// Visualizes spending trajectory, month-over-month rate changes,
/// monthly budget threshold comparison, and interactive touch scrubbing.
class OneUISpendingTrendsCard extends StatefulWidget {
  final List<Subscription>? subscriptions;
  final double? monthlyBudget;
  final String? currency;
  final SpendingTrendHorizon initialHorizon;
  final DateTime? referenceDate;

  const OneUISpendingTrendsCard({
    super.key,
    this.subscriptions,
    this.monthlyBudget,
    this.currency,
    this.initialHorizon = SpendingTrendHorizon.sixMonths,
    this.referenceDate,
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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _curveAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizonChanged(SpendingTrendHorizon horizon) {
    if (_currentHorizon == horizon) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentHorizon = horizon;
      _selectedIndex = null;
    });
    _animController.reset();
    _animController.forward();
  }

  void _onPointSelected(int? index) {
    if (_selectedIndex != index) {
      if (index != null) {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SubscriptionStore.instance,
        OneUIEffectsController.instance,
      ]),
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        final subs = widget.subscriptions ?? store.subscriptions;
        final currency = widget.currency ?? store.currency;
        final budget = widget.monthlyBudget ?? store.monthlyBudget;

        final points = SpendingTrendsEngine.calculateTrends(
          subscriptions: subs,
          horizon: _currentHorizon,
          referenceDate: widget.referenceDate,
        );
        final summary = SpendingTrendsEngine.calculateSummary(points);

        if (points.isEmpty || !summary.hasData) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: OneUIEffectsController.instance.cardColor,
              borderRadius: OneUITheme.cardBorderRadius,
              border: OneUIEffectsController.instance.cardBorder,
              boxShadow: OneUIEffectsController.instance.cardShadow,
            ),
            child: const Column(
              children: [
                Icon(Icons.show_chart_rounded, size: 40, color: OneUITheme.textSecondary),
                SizedBox(height: 10),
                Text(
                  'No spending trajectory yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: OneUITheme.textPrimary,
                  ),
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

        // Active highlighted point
        final activePoint = (_selectedIndex != null && _selectedIndex! >= 0 && _selectedIndex! < points.length)
            ? points[_selectedIndex!]
            : points.last;

        return AnimatedBuilder(
          animation: OneUIEffectsController.instance,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: OneUIEffectsController.instance.cardColor,
                borderRadius: OneUITheme.cardBorderRadius,
                border: OneUIEffectsController.instance.cardBorder,
                boxShadow: OneUIEffectsController.instance.cardShadow,
              ),
              child: child,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Horizon Toggle Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Spending trajectory',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: OneUITheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildHorizonSelector(),
                ],
              ),

              const SizedBox(height: 14),

              // Prominent Active Month Total & MoM Delta Indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currency${activePoint.amount.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: OneUITheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                activePoint.fullLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: OneUITheme.textSecondary,
                                ),
                              ),
                            ),
                            if (activePoint.isProjected) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: OneUITheme.accentTeal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Projected',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: OneUITheme.accentTeal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildMoMBadge(activePoint, currency),
                ],
              ),

              const SizedBox(height: 20),

              // Interactive Line Chart Canvas
              SizedBox(
                height: 195,
                child: AnimatedBuilder(
                  animation: _curveAnimation,
                  builder: (context, _) {
                    return OneUILineChart(
                      points: points,
                      selectedIndex: _selectedIndex,
                      onPointSelected: _onPointSelected,
                      currency: currency,
                      monthlyBudget: budget,
                      animationProgress: _curveAnimation.value,
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Statistical Summary Footer: Avg, Peak, Lowest
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCol('Monthly Avg', '$currency${summary.averageMonthlySpend.toStringAsFixed(2)}')),
                    _buildFooterDivider(),
                    Expanded(child: _buildStatCol('Peak', summary.peakMonth != null ? '${summary.peakMonth!.label} ($currency${summary.peakMonth!.amount.toStringAsFixed(0)})' : '—')),
                    _buildFooterDivider(),
                    Expanded(child: _buildStatCol('Lowest', summary.lowestMonth != null ? '${summary.lowestMonth!.label} ($currency${summary.lowestMonth!.amount.toStringAsFixed(0)})' : '—')),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizonSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: OneUITheme.surfacePill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SpendingTrendHorizon.values.map((horizon) {
          final isSelected = _currentHorizon == horizon;
          return GestureDetector(
            onTap: () => _onHorizonChanged(horizon),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? OneUITheme.surfacePillActive : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                horizon.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? OneUITheme.textPrimary : OneUITheme.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
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
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: OneUITheme.textSecondary,
          ),
        ),
      );
    }

    final isIncrease = point.isIncrease;
    final isDecrease = point.isDecrease;
    final color = isIncrease
        ? OneUITheme.accentRed
        : (isDecrease ? OneUITheme.accentGreen : OneUITheme.textSecondary);
    final icon = isIncrease
        ? Icons.trending_up_rounded
        : (isDecrease ? Icons.trending_down_rounded : Icons.trending_flat_rounded);
    final sign = isIncrease ? '+' : (isDecrease ? '-' : '');
    final absDiff = point.momDifference.abs();
    final absPct = point.momPercentage.abs();

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
            '$sign$currency${absDiff.toStringAsFixed(2)} (${absPct.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: OneUITheme.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: OneUITheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterDivider() {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

/// Standalone Interactive Line Chart Widget
class OneUILineChart extends StatelessWidget {
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

    const double leftPadding = 8.0;
    final double chartWidth = width - (leftPadding * 2);
    final double step = chartWidth / (points.length - 1);

    final clampedX = (touchX - leftPadding).clamp(0.0, chartWidth);
    final nearest = (clampedX / step).round().clamp(0, points.length - 1);
    onPointSelected(nearest);
  }
}

/// CustomPainter rendering smooth Bezier curves, area gradients,
/// budget guide lines, and interactive touch nodes
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

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const double bottomLabelHeight = 24.0;
    const double topPadding = 18.0;
    const double horizontalPadding = 12.0;

    final double chartWidth = size.width - (horizontalPadding * 2);
    final double chartHeight = size.height - topPadding - bottomLabelHeight;
    final double zeroY = topPadding + chartHeight;

    // Determine scale bounds
    double maxVal = monthlyBudget;
    for (final p in points) {
      if (p.amount > maxVal) maxVal = p.amount;
    }
    if (maxVal < 10.0) maxVal = 50.0;
    // Add 16% headroom
    final double yCeiling = maxVal * 1.16;

    // Calculate canvas points
    final List<Offset> canvasPoints = [];
    final double stepX = points.length > 1 ? chartWidth / (points.length - 1) : chartWidth / 2;

    for (int i = 0; i < points.length; i++) {
      final double x = horizontalPadding + (i * stepX);
      final double normalizedAmount = (points[i].amount / yCeiling).clamp(0.0, 1.0);
      // Animate growth from bottom
      final double animatedAmount = normalizedAmount * progress;
      final double y = zeroY - (animatedAmount * chartHeight);
      canvasPoints.add(Offset(x, y));
    }

    // 1. Draw subtle horizontal gridlines
    _drawGridlines(canvas, size, topPadding, chartHeight, yCeiling, horizontalPadding);

    // 2. Draw Monthly Budget Reference Line (if budget > 0)
    if (monthlyBudget > 0.01 && monthlyBudget <= yCeiling) {
      _drawBudgetLine(canvas, size, topPadding, chartHeight, yCeiling, horizontalPadding);
    }

    // 3. Draw Chart Line and Gradient Area Fill
    if (canvasPoints.length == 1) {
      // Single point edge case
      final p = canvasPoints.first;
      final dotPaint = Paint()..color = OneUITheme.accentBlue..style = PaintingStyle.fill;
      canvas.drawCircle(p, 5.0, dotPaint);
    } else {
      _drawSmoothCurve(canvas, canvasPoints, zeroY, size, horizontalPadding);
    }

    // 4. Draw X-Axis Month Labels
    _drawXAxisLabels(canvas, size, canvasPoints, zeroY);

    // 5. Draw Interactive Hover/Touch Cursor and Node
    final activeIndex = (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < canvasPoints.length)
        ? selectedIndex!
        : (canvasPoints.length - 1);

    _drawActiveNode(canvas, canvasPoints[activeIndex], points[activeIndex], zeroY, topPadding);
  }

  void _drawGridlines(Canvas canvas, Size size, double top, double height, double ceiling, double pad) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // 3 Reference levels: Top, Mid, Bottom
    for (int i = 0; i <= 2; i++) {
      final y = top + (height * (i / 2.0));
      _drawDashedHorizontalLine(canvas, pad, size.width - pad, y, gridPaint, dashWidth: 4, dashSpace: 4);
    }
  }

  void _drawBudgetLine(Canvas canvas, Size size, double top, double height, double ceiling, double pad) {
    final normalized = (monthlyBudget / ceiling).clamp(0.0, 1.0);
    final y = (top + height) - (normalized * height);

    final budgetPaint = Paint()
      ..color = OneUITheme.accentAmber.withValues(alpha: 0.65)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _drawDashedHorizontalLine(canvas, pad, size.width - pad, y, budgetPaint, dashWidth: 5, dashSpace: 3);

    // Small "Budget" label tag on right edge
    final textSpan = TextSpan(
      text: 'Budget $currency${monthlyBudget.toStringAsFixed(0)}',
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: OneUITheme.accentAmber,
        letterSpacing: -0.2,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final tagOffset = Offset(size.width - pad - tp.width - 2, y - tp.height - 3);
    tp.paint(canvas, tagOffset);
  }

  void _drawSmoothCurve(Canvas canvas, List<Offset> pts, double zeroY, Size size, double pad) {
    final Path linePath = Path();
    linePath.moveTo(pts[0].dx, pts[0].dy);

    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = (i + 2 < pts.length) ? pts[i + 2] : p2;

      // Cubic spline control points
      const tension = 0.22;
      final cp1x = p1.dx + (p2.dx - p0.dx) * tension;
      final cp1y = p1.dy + (p2.dy - p0.dy) * tension;
      final cp2x = p2.dx - (p3.dx - p1.dx) * tension;
      final cp2y = p2.dy - (p3.dy - p1.dy) * tension;

      linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // 1. Draw Area Gradient
    final Path areaPath = Path.from(linePath);
    areaPath.lineTo(pts.last.dx, zeroY);
    areaPath.lineTo(pts.first.dx, zeroY);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, pts.map((p) => p.dy).reduce(math.min)),
        Offset(0, zeroY),
        [
          OneUITheme.accentBlue.withValues(alpha: 0.24 * progress),
          OneUITheme.accentBlue.withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);

    // 2. Draw Smooth Stroke
    final strokePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(pts.first.dx, 0),
        Offset(pts.last.dx, 0),
        const [
          OneUITheme.accentBlue,
          OneUITheme.accentTeal,
        ],
      )
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, strokePaint);

    // 3. Draw small inactive dots at all points
    final dotPaint = Paint()
      ..color = OneUITheme.accentBlue.withValues(alpha: 0.45 * progress)
      ..style = PaintingStyle.fill;
    for (final p in pts) {
      canvas.drawCircle(p, 2.5, dotPaint);
    }
  }

  void _drawXAxisLabels(Canvas canvas, Size size, List<Offset> pts, double zeroY) {
    for (int i = 0; i < points.length; i++) {
      final isSelected = (selectedIndex != null && selectedIndex == i) ||
          (selectedIndex == null && i == points.length - 1);

      final textSpan = TextSpan(
        text: points[i].label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? OneUITheme.textPrimary : OneUITheme.textSecondary,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      final offset = Offset(pts[i].dx - (tp.width / 2), zeroY + 8);
      tp.paint(canvas, offset);
    }
  }

  void _drawActiveNode(Canvas canvas, Offset pt, MonthlySpendPoint point, double zeroY, double topPadding) {
    // 1. Vertical cursor line
    final cursorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    _drawDashedVerticalLine(canvas, pt.dx, topPadding, zeroY, cursorPaint, dashHeight: 3, dashSpace: 3);

    // 2. Outer glowing ring
    final glowPaint = Paint()
      ..color = OneUITheme.accentBlue.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pt, 11.0, glowPaint);

    final ringPaint = Paint()
      ..color = OneUITheme.accentBlue
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pt, 6.0, ringPaint);

    // 3. Solid center dot
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pt, 3.5, centerPaint);
  }

  void _drawDashedHorizontalLine(Canvas canvas, double x1, double x2, double y, Paint paint, {double dashWidth = 4, double dashSpace = 4}) {
    double currentX = x1;
    while (currentX < x2) {
      final nextX = math.min(currentX + dashWidth, x2);
      canvas.drawLine(Offset(currentX, y), Offset(nextX, y), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  void _drawDashedVerticalLine(Canvas canvas, double x, double y1, double y2, Paint paint, {double dashHeight = 3, double dashSpace = 3}) {
    double currentY = y1;
    while (currentY < y2) {
      final nextY = math.min(currentY + dashHeight, y2);
      canvas.drawLine(Offset(x, currentY), Offset(x, nextY), paint);
      currentY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant OneUILineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.monthlyBudget != monthlyBudget ||
        oldDelegate.progress != progress;
  }
}
