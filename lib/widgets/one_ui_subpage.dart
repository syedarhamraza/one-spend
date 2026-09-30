import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_bottom_vignette.dart';
import 'one_ui_collapsible_header.dart';

/// Standard One UI subpage (design doc §5.1): pinned small header with a back button,
/// padded scrolling content, the bottom vignette and an optional floating pill.
///
/// [builder] runs again whenever [listenable] notifies, so rows can show live values.
class OneUISubpage extends StatelessWidget {
  final String title;
  final List<Widget> Function(BuildContext context) builder;
  final Listenable? listenable;

  /// Floating bottom control, e.g. `OneUIFloatingCancelSavePill`.
  final Widget? bottomPill;
  final VoidCallback? onBack;

  const OneUISubpage({
    super.key,
    required this.title,
    required this.builder,
    this.listenable,
    this.bottomPill,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Widget content(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: builder(context),
        );

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: title,
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: onBack ?? () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                  child: listenable == null
                      ? content(context)
                      : AnimatedBuilder(animation: listenable!, builder: (context, _) => content(context)),
                ),
              ),
            ],
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: OneUIBottomVignette()),
          if (bottomPill != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Center(child: bottomPill),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small "Soon" capsule for rows whose feature isn't built yet.
class OneUISoonChip extends StatelessWidget {
  const OneUISoonChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: OneUITheme.surfacePill,
        borderRadius: BorderRadius.circular(OneUITheme.radiusBadge),
      ),
      child: const Text(
        'Soon',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
      ),
    );
  }
}

/// Small amber "Pro" capsule for features that will need OneSpend Pro.
class OneUIProChip extends StatelessWidget {
  const OneUIProChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: OneUITheme.accentAmber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(OneUITheme.radiusBadge),
      ),
      child: const Text(
        'Pro',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OneUITheme.accentAmber),
      ),
    );
  }
}

/// 36dp solid circle list badge with a white icon (design doc §4, "Leading icon badges").
class OneUIIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const OneUIIconBadge(this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
