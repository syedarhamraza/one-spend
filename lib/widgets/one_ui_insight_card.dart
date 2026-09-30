import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/subscriptions/domain/services/insight_cards.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_ambient_glow.dart';

extension InsightToneColor on InsightTone {
  /// Red = bad, amber = heads-up, green = good, blue = information.
  Color get color => switch (this) {
        InsightTone.negative => OneUITheme.accentRed,
        InsightTone.caution => OneUITheme.accentAmber,
        InsightTone.positive => OneUITheme.accentGreen,
        InsightTone.info => OneUITheme.accentBlue,
      };
}

/// Samsung Digital Wellbeing style tip card: a tone-coloured headline, a short message and a
/// light grey pill, over a soft glow in the tone colour. Swipe sideways or tap ✕ to dismiss.
class OneUIInsightCard extends StatefulWidget {
  final InsightCardData data;

  /// Position in the queue (0-based) and queue length, for the "1 of 3" caption.
  final int index;
  final int total;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  const OneUIInsightCard({
    super.key,
    required this.data,
    required this.onAction,
    required this.onDismiss,
    this.index = 0,
    this.total = 1,
  });

  @override
  State<OneUIInsightCard> createState() => _OneUIInsightCardState();
}

class _OneUIInsightCardState extends State<OneUIInsightCard> with SingleTickerProviderStateMixin {
  /// Horizontal drag offset in logical pixels.
  late final AnimationController _drag = AnimationController.unbounded(vsync: this);
  bool _dismissing = false;

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  Future<void> _flyOut(double direction, double width) async {
    if (_dismissing) return;
    _dismissing = true;
    await _drag.animateTo(direction * width * 1.1, duration: const Duration(milliseconds: 220), curve: Curves.easeInCubic);
    if (mounted) widget.onDismiss();
  }

  void _onDragEnd(DragEndDetails details, double width) {
    final velocity = details.primaryVelocity ?? 0;
    if (_drag.value.abs() > width * 0.35 || velocity.abs() > 900) {
      _flyOut(_drag.value + velocity * 0.01 >= 0 ? 1.0 : -1.0, width);
    } else {
      _drag.animateTo(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final tone = data.tone.color;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: _dismissing ? null : (d) => _drag.value += d.delta.dx,
          onHorizontalDragEnd: _dismissing ? null : (d) => _onDragEnd(d, width),
          child: AnimatedBuilder(
            animation: _drag,
            builder: (context, child) => Transform.translate(
              offset: Offset(_drag.value, 0),
              child: Opacity(
                opacity: (1 - _drag.value.abs() / (width * 1.1)).clamp(0.0, 1.0),
                child: child,
              ),
            ),
            child: _card(data, tone),
          ),
        );
      },
    );
  }

  Widget _card(InsightCardData data, Color tone) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.cardBorder,
        boxShadow: OneUITheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Soft glow in the tone colour rising from the bottom edge.
          OneUIAmbientGlow(
            color: tone,
            center: const Alignment(0, 1.15),
            radius: 0.95,
            alphas: const [0.30, 0.10, 0.0],
            stops: const [0.0, 0.55, 1.0],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: tone,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.35,
                    color: OneUITheme.textPrimary.withValues(alpha: 0.9),
                  ),
                ),
                if (widget.total > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${widget.index + 1} of ${widget.total}',
                    style: const TextStyle(fontSize: 12, color: OneUITheme.textTertiary),
                  ),
                ],
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Material(
                      color: OneUITheme.surfaceButtonLight,
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onAction();
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              data.actionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: OneUITheme.textOnLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Semantics(
              button: true,
              label: 'Dismiss tip',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close_rounded, size: 18, color: OneUITheme.textTertiary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
