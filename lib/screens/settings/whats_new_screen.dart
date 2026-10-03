import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_version.dart';
import '../../core/config/changelog.dart';
import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_subpage.dart';

/// Settings › About › What's new: release notes from [Changelog], newest first.
class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsWhatsNew);
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: "What's new",
      builder: (context) => [
        for (final entry in Changelog.entries)
          OneUISection(
            title: '${AppVersion.describe(entry.version)} · ${entry.date}',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final change in entry.changes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 7, right: 12),
                            child: SizedBox(
                              width: 6,
                              height: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: OneUITheme.accentBlue, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              change,
                              style: const TextStyle(fontSize: 15, height: 1.4, color: OneUITheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
