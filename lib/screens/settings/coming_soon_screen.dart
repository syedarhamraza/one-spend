import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import 'planned_feature.dart';

/// Placeholder subpage for a [PlannedFeature]: what it will do, in One UI style.
class ComingSoonScreen extends StatelessWidget {
  final PlannedFeature feature;

  const ComingSoonScreen({super.key, required this.feature});

  static Future<void> open(BuildContext context, PlannedFeature feature) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.comingSoon, extra: feature);
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: feature.title,
      builder: (context) => [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(feature.icon, size: 36, color: feature.color),
              ),
              const SizedBox(height: 18),
              const Text(
                'Coming soon',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: OneUITheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feature.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4, color: OneUITheme.textSecondary),
              ),
            ],
          ),
        ),
        OneUISection(
          title: 'What\'s planned',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              for (final h in feature.highlights)
                OneUIGroupItem(
                  leading: Icon(Icons.check_circle_rounded, color: feature.color, size: 22),
                  title: h,
                  trailing: const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
