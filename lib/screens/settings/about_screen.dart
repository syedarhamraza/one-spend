import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/config/changelog.dart';
import '../../core/config/feature_flags.dart';
import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import 'coming_soon_screen.dart';
import 'planned_feature.dart';
import 'whats_new_screen.dart';

/// Settings › About, in the style of One UI's "About" pages: large app icon,
/// name and version, then links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsAbout);
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'About',
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
              FutureBuilder<AppVersion?>(
                future: AppVersion.current(),
                builder: (context, snapshot) => _VersionLine(snapshot.data),
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
              title: "What's new",
              subtitle: 'Version ${AppVersion.describe(Changelog.entries.first.version)}',
              subtitleColor: OneUITheme.textSecondary,
              onTap: () => WhatsNewScreen.open(context),
            ),
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
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Text(
            'Product and company names are trademarks of their respective owners. '
            'Their use does not imply affiliation with or endorsement by them.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, height: 1.4, color: OneUITheme.textTertiary),
          ),
        ),
      ],
    );
  }
}

/// "Version 1.0.0 [Beta 1]" with "Build 5" underneath (plus the commit in debug builds).
class _VersionLine extends StatelessWidget {
  final AppVersion? version;

  const _VersionLine(this.version);

  @override
  Widget build(BuildContext context) {
    final v = version;
    if (v == null) {
      return const Text('Version', style: TextStyle(fontSize: 14.5, color: OneUITheme.textSecondary));
    }
    final build = [
      if (v.code != null) 'Build ${v.code}',
      // Builds made with tool/release.ps1 carry the commit; only debug builds show it.
      if (kDebugMode && BuildInfo.commit.isNotEmpty) BuildInfo.commit,
    ].join(' · ');
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Version ${v.number}', style: const TextStyle(fontSize: 14.5, color: OneUITheme.textSecondary)),
            if (v.isPreRelease) ...[
              const SizedBox(width: 8),
              _ChannelChip(v.channelLabel),
            ],
          ],
        ),
        if (build.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(build, style: const TextStyle(fontSize: 12.5, color: OneUITheme.textTertiary)),
        ],
      ],
    );
  }
}

/// Amber capsule naming the pre-release, e.g. "Beta 1".
class _ChannelChip extends StatelessWidget {
  final String label;

  const _ChannelChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: OneUITheme.accentAmber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(OneUITheme.radiusBadge),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OneUITheme.accentAmber),
      ),
    );
  }
}
