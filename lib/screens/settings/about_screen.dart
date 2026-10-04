import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/config/changelog.dart';
import '../../core/router/app_router.dart';
import '../../features/updates/data/update_service.dart';
import '../../features/updates/presentation/update_controller.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import 'whats_new_screen.dart';

/// Settings › About, in the style of One UI's "About" pages: large app icon,
/// name and version, then links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsAbout);
  }

  Future<void> _onUpdateTap(BuildContext context) async {
    HapticFeedback.lightImpact();
    final updates = UpdateController.instance;
    if (!updates.updateAvailable) {
      await updates.check();
      if (!updates.updateAvailable) return; // the row's subtitle shows the result
    }
    final result = await updates.install();
    if (!context.mounted) return;
    switch (result) {
      case UpdateInstallResult.started:
        break; // Play takes over and restarts One Spend
      case UpdateInstallResult.declined:
        OneUIToast.show(context, 'Update cancelled. You can install it any time from here.');
      case UpdateInstallResult.failed:
        OneUIToast.show(context, "Couldn't start the update. Try again from Google Play.");
    }
  }

  /// "Check for updates": Google Play in-app updates (immediate flow).
  OneUIGroupItem _updateItem(BuildContext context) {
    final updates = UpdateController.instance;
    final (subtitle, color) = switch (updates.status) {
      UpdateStatus.notChecked => ('Check Google Play for a newer version', OneUITheme.textSecondary),
      UpdateStatus.checking => ('Checking…', OneUITheme.textSecondary),
      UpdateStatus.upToDate => ('One Spend is up to date', OneUITheme.textSecondary),
      UpdateStatus.available => ('A new version is ready to install', OneUITheme.accentBlue),
      UpdateStatus.notFromPlay => ("Updates come from Google Play. This copy wasn't installed from Play.",
          OneUITheme.textSecondary),
      UpdateStatus.failed => ("Couldn't reach Google Play. Tap to try again.", OneUITheme.textSecondary),
    };
    return OneUIGroupItem(
      title: updates.updateAvailable ? 'Update available' : 'Check for updates',
      subtitle: subtitle,
      subtitleColor: color,
      trailing: updates.status == UpdateStatus.checking || updates.installing
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: OneUITheme.accentBlue),
            )
          : updates.updateAvailable
              ? const OneUIDot()
              : const SizedBox.shrink(),
      onTap: () => _onUpdateTap(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'About',
      listenable: UpdateController.instance,
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
          items: [_updateItem(context)],
        ),
        const SizedBox(height: 14),
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
            OneUIGroupItem(
              title: 'Privacy policy',
              subtitle: 'Opens in your browser',
              subtitleColor: OneUITheme.textSecondary,
              onTap: () {
                HapticFeedback.lightImpact();
                openExternalLink(context, AppInfo.privacyPolicyUrl);
              },
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
