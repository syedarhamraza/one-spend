import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/one_ui_theme.dart';
import '../../../../utils/one_ui_brand_catalog.dart';
import '../../../../widgets/one_ui_brand_icon.dart';
import '../../domain/entities/subscription_enums.dart';
import '../utils/subscription_ui_adapters.dart';

/// The Subscriptions tab before anything has been added: the first screen a new
/// user sees. A hero of category tiles that pop in over a soft glow, a
/// headline, the main "Add subscription" action, one-tap starts for popular
/// services, and a way back in for people restoring a backup.
///
/// The hero (category glyphs, never third-party logos) animates once on entry (never in a loop), and not at all when the
/// system's "Remove animations" is on.
class FirstRunEmptyState extends StatefulWidget {
  final VoidCallback onAdd;

  /// Starts a new subscription from the brand preset with this id.
  final ValueChanged<String> onQuickAdd;
  final VoidCallback onRestore;

  const FirstRunEmptyState({
    super.key,
    required this.onAdd,
    required this.onQuickAdd,
    required this.onRestore,
  });

  /// Hero tiles: neutral category glyphs (no third-party logos), placed around
  /// the centre as (category, dx, dy, size) in logical px.
  static const List<(SubscriptionCategory, double, double, double)> heroTiles = [
    (SubscriptionCategory.entertainment, 0, -6, 64),
    (SubscriptionCategory.music, -86, -40, 50),
    (SubscriptionCategory.cloud, 88, -44, 52),
    (SubscriptionCategory.gaming, -112, 34, 42),
    (SubscriptionCategory.productivity, 106, 36, 44),
    (SubscriptionCategory.health, -40, 62, 40),
    (SubscriptionCategory.design, 48, 66, 40),
  ];

  /// One-tap starts, in order.
  static const List<String> quickAddIds = [
    'netflix',
    'spotify',
    'youtube_premium',
    'chatgpt',
    'disney_plus',
    'amazon_prime',
    'apple_music',
    'google_one',
  ];

  @override
  State<FirstRunEmptyState> createState() => _FirstRunEmptyStateState();
}

class _FirstRunEmptyStateState extends State<FirstRunEmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (!_intro.isAnimating && _intro.value == 0) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// [index]-th item's 0–1 entrance progress, staggered across the intro.
  double _stagger(int index, int count, {double span = 0.45}) {
    final start = (1 - span) * index / math.max(1, count - 1);
    return Curves.easeOutBack.transform(((_intro.value - start) / span).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _hero(),
          const SizedBox(height: 28),
          const Text(
            'Every subscription,\none place',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add what you pay for. One Spend reminds you before each renewal and shows where your money goes.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.45, color: OneUITheme.textSecondary),
          ),
          const SizedBox(height: 26),
          _primaryButton(),
          const SizedBox(height: 32),
          _quickAdd(),
          const SizedBox(height: 22),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onRestore();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text.rich(
                  TextSpan(
                    text: 'Switching phones? ',
                    style: TextStyle(fontSize: 14, color: OneUITheme.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Restore from backup',
                        style: TextStyle(fontWeight: FontWeight.w600, color: OneUITheme.accentBlue),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    const logos = FirstRunEmptyState.heroTiles;
    return ExcludeSemantics(
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _intro,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Soft blue glow that blooms in behind the logos.
                Opacity(
                  opacity: Curves.easeOut.transform(_intro.value),
                  child: Container(
                    width: 300,
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          OneUITheme.glowDefault.withValues(alpha: 0.30),
                          OneUITheme.glowDefault.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                for (final (i, (category, dx, dy, size)) in logos.indexed)
                  Transform.translate(
                    offset: Offset(dx, dy + (1 - _stagger(i, logos.length)) * 18),
                    child: Opacity(
                      opacity: _stagger(i, logos.length).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * _stagger(i, logos.length),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(size * 0.32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: category.color,
                              borderRadius: BorderRadius.circular(size * 0.32),
                            ),
                            child: Icon(
                              category.icon,
                              size: size * 0.5,
                              color: OneUIBrandCatalog.foregroundOn(category.color),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _primaryButton() {
    return Semantics(
      button: true,
      child: Material(
        color: OneUITheme.accentBlue,
        borderRadius: OneUITheme.pillBorderRadius,
        child: InkWell(
          borderRadius: OneUITheme.pillBorderRadius,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onAdd();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 21, color: Colors.white),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Add subscription',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAdd() {
    final presets = [
      for (final id in FirstRunEmptyState.quickAddIds) ?OneUIBrandCatalog.findById(id),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'POPULAR',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: OneUITheme.textSecondary,
            ),
          ),
        ),
        // Wraps rather than scrolls so every option stays visible on any width.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in presets)
              Semantics(
                button: true,
                label: 'Add ${preset.name}',
                excludeSemantics: true,
                child: Material(
                  color: OneUITheme.surfacePill,
                  borderRadius: OneUITheme.pillBorderRadius,
                  child: InkWell(
                    borderRadius: OneUITheme.pillBorderRadius,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onQuickAdd(preset.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OneUIBrandIcon(name: preset.name, brandPresetId: preset.id, size: 26, borderRadius: 9),
                          const SizedBox(width: 8),
                          Text(
                            preset.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: OneUITheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
