import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/one_ui_bare_top_bar.dart';

/// Settings › About One Spend: the app icon, name and version in the middle of the page,
/// and the links as capsule buttons at the bottom (same layout as Software update).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsAbout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: SafeArea(
        child: Column(
          children: [
            const OneUIBareTopBar(),
            Expanded(
              // Scrolls only when it doesn't fit (large text, short screens).
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Column(
                          children: [
                            // The headline centres in whatever height the buttons leave.
                            const Expanded(child: Center(child: _AppHeadline())),
                            const SizedBox(height: 32),
                            _AboutButton(label: 'Developer', onTap: () => context.push(AppRoutes.settingsAuthor)),
                            const SizedBox(height: 10),
                            _AboutButton(
                              label: 'Open source licences',
                              onTap: () => context.push(AppRoutes.settingsLicenses),
                            ),
                            const SizedBox(height: 10),
                            _AboutButton(
                              label: 'Privacy policy',
                              onTap: () => openInAppBrowser(context, AppInfo.privacyPolicyUrl),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '© ${DateTime.now().year} ${AuthorInfo.name}',
                              style: const TextStyle(fontSize: 12.5, color: OneUITheme.textTertiary),
                            ),
                          ],
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
    );
  }
}

/// App icon, "One Spend" and the version, centred in the space above the buttons.
class _AppHeadline extends StatelessWidget {
  const _AppHeadline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(AppInfo.logoAsset, width: 96, height: 96, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          const Text(
            AppInfo.name,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          FutureBuilder<AppVersion?>(
            future: AppVersion.current(),
            builder: (context, snapshot) => _VersionLine(snapshot.data),
          ),
        ],
      ),
    );
  }
}

/// Full-width grey capsule, like the link buttons at the bottom of Samsung's app About pages.
class _AboutButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AboutButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Material(
        color: OneUITheme.surfacePill,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Version 1.0.0 Alpha 4" in one grey line. The build number is in Software update ›
/// Software information.
class _VersionLine extends StatelessWidget {
  final AppVersion? version;

  const _VersionLine(this.version);

  @override
  Widget build(BuildContext context) {
    return Text(
      version == null ? 'Version' : 'Version ${version!.label}',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15, color: OneUITheme.textSecondary),
    );
  }
}
