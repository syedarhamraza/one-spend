import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// One row of the hero card's key-value panel.
typedef AnalyticsHeroRow = ({String label, String value, String? caption, Color? valueColor});

/// Samsung One UI hero card for the Analytics tab, the sibling of [OneUIUpcomingHeroCard]:
/// the soft blue glow under a frosted glass body, a 32pt yearly amount, a 12dp track split
/// by category and a Device Care style key-value panel.
class OneUIAnalyticsHeroCard extends StatelessWidget {
  /// e.g. "Yearly cost" or "Entertainment · yearly".
  final String title;
  final String amount;

  /// Small pill next to the title, e.g. "8 active".
  final String badge;

  /// Category split for the track, in display order.
  final List<({Color color, double total})> segments;
  final List<AnalyticsHeroRow> rows;

  static const Color trackBackground = Color(0xFF2C2D30);

  const OneUIAnalyticsHeroCard({
    super.key,
    required this.title,
    required this.amount,
    required this.badge,
    required this.segments,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: OneUITheme.cardBorderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.2),
                  radius: 1.05,
                  colors: [
                    const Color(0xFF0381FE).withValues(alpha: 0.26),
                    const Color(0xFF0381FE).withValues(alpha: 0.11),
                    const Color(0xFF0381FE).withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.50, 0.85, 1.0],
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1B1C20).withValues(alpha: 0.68),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: OneUITheme.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OneUITheme.accentBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: OneUITheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _track(),
                  if (rows.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0) Divider(height: 14, thickness: 0.6, color: Colors.white.withValues(alpha: 0.06)),
                            _row(rows[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _track() {
    final total = segments.fold(0.0, (sum, s) => sum + s.total);
    return Semantics(
      label: 'Split by category',
      child: Container(
        height: 12,
        decoration: BoxDecoration(color: trackBackground, borderRadius: BorderRadius.circular(100)),
        clipBehavior: Clip.antiAlias,
        child: total <= 0
            ? null
            : Row(
                children: [
                  for (final (i, segment) in segments.indexed)
                    Expanded(
                      flex: (segment.total / total * 1000).round().clamp(1, 1000),
                      child: Container(
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                        color: segment.color,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _row(AnalyticsHeroRow row) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            row.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: OneUITheme.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                row.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: row.valueColor ?? OneUITheme.textPrimary,
                ),
              ),
              if (row.caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  row.caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: OneUITheme.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
