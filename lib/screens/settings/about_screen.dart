import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_info.dart';
import '../../core/config/feature_flags.dart';
import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import 'coming_soon_screen.dart';
import 'planned_feature.dart';

/// Settings › About OneSpend, in the style of One UI's "About" pages: large app icon,
/// name and version, then links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsAbout);
  }

  static Future<PackageInfo?> _packageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'About ${AppInfo.name}',
      builder: (context) => [
        const SizedBox(height: 18),
        Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(AppInfo.logoAsset, width: 96, height: 96, fit: BoxFit.cover),
              ),
              const SizedBox(height: 18),
              const Text(
                AppInfo.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: OneUITheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              FutureBuilder<PackageInfo?>(
                future: _packageInfo(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  return Text(
                    info == null ? 'Version' : 'Version ${info.version} (${info.buildNumber})',
                    style: const TextStyle(fontSize: 14.5, color: OneUITheme.textSecondary),
                  );
                },
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  AppInfo.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.4, color: OneUITheme.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            OneUIGroupItem(
              title: 'Developer',
              subtitle: AuthorInfo.name,
              subtitleColor: OneUITheme.textSecondary,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(AppRoutes.settingsAuthor);
              },
            ),
            OneUIGroupItem(
              title: 'Open source licences',
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(AppRoutes.settingsLicenses);
              },
            ),
            OneUIGroupItem(
              title: 'Source code',
              subtitle: 'GitHub',
              subtitleColor: OneUITheme.textSecondary,
              trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: OneUITheme.textSecondary),
              onTap: () => openExternalLink(context, AppInfo.repositoryUrl),
            ),
            if (FeatureFlags.showPlannedFeatures)
              OneUIGroupItem(
                title: PlannedFeature.privacyPolicy.title,
                trailing: const OneUISoonChip(),
                onTap: () => ComingSoonScreen.open(context, PlannedFeature.privacyPolicy),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '© ${DateTime.now().year} ${AuthorInfo.name}',
            style: const TextStyle(fontSize: 12.5, color: OneUITheme.textTertiary),
          ),
        ),
      ],
    );
  }
}
