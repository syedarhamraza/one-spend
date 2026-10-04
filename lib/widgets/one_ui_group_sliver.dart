import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_card.dart';
import 'one_ui_group_card.dart';

/// A titled [OneUIGroupCard] as a lazy sliver, for long lists inside a
/// [CustomScrollView]: only the rows on screen are built.
///
/// Looks the same as `OneUISection(title: …, child: OneUIGroupCard(items: …))`. The card
/// is drawn as one background segment per row (rounded at the first and last row), which
/// matches the single card because cards have no border or shadow
/// ([OneUIEffectsController.cardBorder] / [OneUIEffectsController.cardShadow]).
class OneUIGroupSliver extends StatelessWidget {
  final String title;
  final int itemCount;
  final OneUIGroupItem Function(BuildContext context, int index) itemBuilder;

  const OneUIGroupSliver({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
  });

  /// Space below the card, as [OneUIGroupCard]'s default margin.
  static const double _bottomGap = 14;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // OneUISection's header (title row only).
        SliverToBoxAdapter(child: OneUISection(title: title, child: const SizedBox.shrink())),
        SliverList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => _GroupRow(
            item: itemBuilder(context, index),
            isFirst: index == 0,
            isLast: index == itemCount - 1,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: _bottomGap)),
      ],
    );
  }
}

class _GroupRow extends StatelessWidget {
  final OneUIGroupItem item;
  final bool isFirst;
  final bool isLast;

  const _GroupRow({required this.item, required this.isFirst, required this.isLast});

  static const Radius _radius = Radius.circular(OneUITheme.radiusCard);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: OneUIEffectsController.instance.resolveCardBackground(),
          borderRadius: BorderRadius.vertical(
            top: isFirst ? _radius : Radius.zero,
            bottom: isLast ? _radius : Radius.zero,
          ),
        ),
        child: child,
      ),
      child: OneUIGroupItemTile(item: item, isFirst: isFirst, isLast: isLast),
    );
  }
}
