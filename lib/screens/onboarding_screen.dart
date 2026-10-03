import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_info.dart';
import '../core/di/injection.dart';
import '../core/router/app_router.dart';
import '../features/notifications/data/notification_service.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_group_card.dart';
import 'settings/currency_picker_screen.dart';
import '../core/telemetry/events.dart';
import '../core/telemetry/telemetry.dart';

/// Whether to open the first-run welcome. A fresh install sees it once; installs
/// that already have data (from before onboarding existed) are marked done
/// without showing it.
Future<bool> needsOnboarding() async {
  final settings = sl<SettingsRepository>();
  if (await settings.getOnboardingDone()) return false;
  if (SubscriptionStore.instance.subscriptions.isNotEmpty) {
    await settings.setOnboardingDone(true);
    return false;
  }
  return true;
}

/// First-run welcome, shown once on a fresh install before the tabs:
/// welcome → main currency → reminders → all set (start, or restore a backup).
///
/// Every page can be skipped; finishing or skipping marks onboarding done and
/// opens the Subscriptions tab.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 4;

  final PageController _pages = PageController();
  int _page = 0;

  /// Whether reminders were turned on (and permission asked) on the reminders page.
  bool? _remindersAllowed;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Duration get _pageDuration =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 320);

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < _pageCount - 1) {
      _pages.nextPage(duration: _pageDuration, curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  /// Marks onboarding done and opens the tabs, then [then] (e.g. Backup & data).
  void _finish({String? then}) {
    AppLog.event(TelemetryEvent.onboardingCompleted);
    // Saved in the background: navigating never waits on the database.
    if (sl.isRegistered<SettingsRepository>()) {
      unawaited(sl<SettingsRepository>().setOnboardingDone(true));
    }
    context.go(AppRoutes.subscriptions);
    if (then != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) GoRouter.maybeOf(context)?.push(then);
      });
    }
  }

  Future<void> _pickCurrency() async {
    final store = SubscriptionStore.instance;
    final picked = await CurrencyPickerScreen.open(
      context,
      initialCode: store.currency,
      title: 'Main currency',
      footnote: 'Totals, budgets and insights are shown in this currency. You can change it later in Settings.',
    );
    if (picked != null) {
      store.setCurrency(picked);
      setState(() {});
    }
  }

  Future<void> _allowReminders() async {
    HapticFeedback.lightImpact();
    final store = SubscriptionStore.instance;
    store.setNotificationsEnabled(true);
    var allowed = true;
    if (sl.isRegistered<NotificationService>()) {
      final service = sl<NotificationService>();
      allowed = await service.areEnabled() || await service.requestPermission();
    }
    if (!mounted) return;
    setState(() => _remindersAllowed = allowed);
    if (allowed) _next();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pageCount - 1;
    return PopScope(
      // System back steps through the pages before leaving the app.
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pages.previousPage(duration: _pageDuration, curve: Curves.easeOutCubic);
      },
      child: Scaffold(
        backgroundColor: OneUITheme.surfacePitch,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: isLast,
                      child: TextButton(
                        onPressed: () => _finish(),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _welcomePage(),
                    _currencyPage(),
                    _remindersPage(),
                    _donePage(),
                  ],
                ),
              ),
              _dots(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _primaryButton(
                  label: switch (_page) {
                    0 => 'Get started',
                    2 => _remindersAllowed == null ? 'Turn on reminders' : 'Continue',
                    3 => 'Start tracking',
                    _ => 'Continue',
                  },
                  onTap: _page == 2 && _remindersAllowed == null ? _allowReminders : _next,
                ),
              ),
              SizedBox(
                height: 44,
                child: switch (_page) {
                  2 when _remindersAllowed == null => TextButton(
                      onPressed: _next,
                      child: const Text('Not now', style: TextStyle(fontSize: 15, color: OneUITheme.textSecondary)),
                    ),
                  3 => TextButton(
                      onPressed: () => _finish(then: AppRoutes.settingsData),
                      child: const Text(
                        'Restore from backup',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.accentBlue),
                      ),
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // --- Pages ----------------------------------------------------------------

  Widget _pageLayout({required Widget art, required String title, required String body, Widget? extra}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          art,
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15.5, height: 1.45, color: OneUITheme.textSecondary),
          ),
          if (extra != null) ...[const SizedBox(height: 28), extra],
        ],
      ),
    );
  }

  /// A large glowing badge used as each page's illustration.
  Widget _badge(IconData icon, Color color) {
    return ExcludeSemantics(
      child: Container(
        width: 200,
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.08), Colors.transparent],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(icon, size: 48, color: color),
        ),
      ),
    );
  }

  Widget _welcomePage() {
    return _pageLayout(
      art: ExcludeSemantics(
        child: Container(
          width: 200,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                OneUITheme.glowDefault.withValues(alpha: 0.30),
                OneUITheme.glowDefault.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(AppInfo.logoAsset, width: 104, height: 104, fit: BoxFit.cover),
          ),
        ),
      ),
      title: 'Welcome to ${AppInfo.name}',
      body: 'Keep every subscription in one place, get a heads-up before renewals, and see where your money goes.',
      extra: Column(
        children: [
          _point(Icons.notifications_active_rounded, OneUITheme.accentBlue, 'Reminders before every renewal'),
          _point(Icons.insights_rounded, OneUITheme.accentGreen, 'Monthly spending and trends'),
          _point(Icons.lock_rounded, OneUITheme.accentAmber, 'Private: your data stays on this phone'),
        ],
      ),
    );
  }

  Widget _point(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, color: OneUITheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _currencyPage() {
    final store = SubscriptionStore.instance;
    return _pageLayout(
      art: _badge(Icons.currency_exchange_rounded, OneUITheme.accentGreen),
      title: 'Your main currency',
      body: 'Totals, budgets and insights use this currency. Subscriptions billed in other currencies are converted.',
      extra: OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          OneUIGroupItem(
            title: 'Main currency',
            subtitle: currencyLabel(store.currency),
            subtitleColor: OneUITheme.accentBlue,
            onTap: _pickCurrency,
          ),
        ],
      ),
    );
  }

  Widget _remindersPage() {
    final allowed = _remindersAllowed;
    return _pageLayout(
      art: _badge(Icons.notifications_active_rounded, OneUITheme.accentBlue),
      title: 'Never miss a renewal',
      body: 'Get a reminder a few days before each charge, so you can cancel what you no longer use in time.',
      extra: allowed == false
          ? const Text(
              'Notifications are blocked for One Spend. You can allow them later in Android settings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: OneUITheme.accentAmber),
            )
          : null,
    );
  }

  Widget _donePage() {
    return _pageLayout(
      art: _badge(Icons.check_rounded, OneUITheme.accentGreen),
      title: "You're all set",
      body: 'Add your first subscription to start tracking. Switching phones? Restore your backup instead.',
    );
  }

  // --- Controls ---------------------------------------------------------------

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _pageCount; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _page ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == _page ? OneUITheme.textPrimary : OneUITheme.textTertiary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onTap}) {
    return Semantics(
      button: true,
      child: Material(
        color: OneUITheme.accentBlue,
        borderRadius: OneUITheme.pillBorderRadius,
        child: InkWell(
          borderRadius: OneUITheme.pillBorderRadius,
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
