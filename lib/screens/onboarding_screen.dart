import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_info.dart';
import '../core/di/injection.dart';
import '../core/router/app_router.dart';
import '../core/telemetry/events.dart';
import '../core/telemetry/telemetry.dart';
import '../features/notifications/data/notification_service.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/reminder_format.dart';
import '../widgets/one_ui_ambient_glow.dart';
import '../widgets/one_ui_glass_surface.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_subpage.dart';
import 'onboarding/onboarding_heroes.dart';
import 'settings/currency_picker_screen.dart';

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
/// One UI app-intro style: a glowing illustration per page (see `onboarding_heroes.dart`),
/// a big left-aligned title, info rows in group cards, a glass "Skip" capsule and an
/// accent pill. It runs before Settings can be reached, so it always shows the default
/// flat glass look.
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

  /// Glow behind each page's illustration (welcome, currency, reminders, all set).
  static const _glowColors = [
    OneUITheme.glowDefault,
    OneUITheme.accentGreen,
    OneUITheme.accentTeal,
    OneUITheme.accentGreen,
  ];

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
          child: LayoutBuilder(
            builder: (context, box) {
              final heroHeight = (box.maxHeight * 0.28).clamp(170.0, 236.0);
              // Centre the glow on the illustration (56 = the Skip row above it).
              final glowY = ((56 + heroHeight / 2) / box.maxHeight) * 2 - 1;
              return Stack(
                children: [
                  // One glow for the whole flow; it cross-fades to each page's colour.
                  OneUIAmbientGlow(color: _glowColors[_page], center: Alignment(0, glowY), radius: 0.95),
                  Column(
                    children: [
                      SizedBox(
                        height: 56,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: AnimatedOpacity(
                              opacity: isLast ? 0 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(ignoring: isLast, child: _skipButton()),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        // Content that doesn't fit fades out above the dots, hinting it scrolls.
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black, Colors.black, Colors.transparent],
                            stops: [0, 0.93, 1],
                          ).createShader(rect),
                          child: PageView(
                            controller: _pages,
                            onPageChanged: (i) => setState(() => _page = i),
                            children: [
                              _welcomePage(heroHeight),
                              _currencyPage(heroHeight),
                              _remindersPage(heroHeight),
                              _donePage(heroHeight),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _dots(),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                            child: const Text(
                              'Not now',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: OneUITheme.textSecondary,
                              ),
                            ),
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// A glass capsule like the app's other floating buttons, so it reads as tappable.
  Widget _skipButton() {
    return Semantics(
      button: true,
      label: 'Skip setup',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          _finish();
        },
        child: const OneUIGlassSurface(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            'Skip',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
          ),
        ),
      ),
    );
  }

  // --- Pages ----------------------------------------------------------------

  /// Illustration, big left-aligned title, text, then [extra] (usually a group card).
  Widget _pageLayout({
    required int index,
    required double heroHeight,
    required Widget hero,
    required String title,
    required String body,
    Widget? extra,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: heroHeight, width: double.infinity, child: _parallax(index, hero)),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(fontSize: 15.5, height: 1.45, color: OneUITheme.textSecondary)),
          if (extra != null) ...[const SizedBox(height: 22), extra],
          // Room to scroll the last row clear of the fade at the bottom.
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  /// The illustration trails the page slightly as you swipe (off with reduced motion).
  Widget _parallax(int index, Widget hero) {
    if (MediaQuery.disableAnimationsOf(context)) return hero;
    return AnimatedBuilder(
      animation: _pages,
      child: hero,
      builder: (context, child) {
        final position = _pages.hasClients && _pages.position.haveDimensions ? _pages.page ?? 0.0 : _page.toDouble();
        final width = MediaQuery.sizeOf(context).width;
        return Transform.translate(offset: Offset((position - index) * width * 0.35, 0), child: child);
      },
    );
  }

  /// A row in an info card: icon badge, title, subtitle, and no chevron (not tappable).
  OneUIGroupItem _info(IconData icon, Color color, String title, String subtitle, {Color? subtitleColor}) {
    return OneUIGroupItem(
      leading: OneUIIconBadge(icon, color),
      title: title,
      subtitle: subtitle,
      subtitleColor: subtitleColor ?? OneUITheme.textSecondary,
      trailing: const SizedBox.shrink(),
    );
  }

  Widget _welcomePage(double heroHeight) {
    final store = SubscriptionStore.instance;
    return _pageLayout(
      index: 0,
      heroHeight: heroHeight,
      hero: WelcomeHero(currency: store.currency, toMain: store.toMain),
      title: 'Welcome to\n${AppInfo.name}',
      body: 'Every subscription in one place, with a heads-up before it renews.',
      extra: OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          _info(
            Icons.notifications_active_rounded,
            OneUITheme.accentTeal,
            'Renewal reminders',
            'A heads-up before every charge',
          ),
          _info(
            Icons.insights_rounded,
            OneUITheme.accentGreen,
            'Spending insights',
            'Monthly totals, trends and budgets',
          ),
          _info(
            Icons.smartphone_rounded,
            OneUITheme.accentBlue,
            'Your subscriptions stay on this phone',
            'No account needed',
          ),
        ],
      ),
    );
  }

  Widget _currencyPage(double heroHeight) {
    final store = SubscriptionStore.instance;
    return _pageLayout(
      index: 1,
      heroHeight: heroHeight,
      hero: CurrencyHero(code: store.currency),
      title: 'Your main currency',
      body: 'Totals, budgets and insights use this currency. Subscriptions billed in other currencies are converted.',
      extra: OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          OneUIGroupItem(
            leading: const OneUIIconBadge(Icons.currency_exchange_rounded, OneUITheme.accentGreen),
            title: 'Main currency',
            subtitle: currencyLabel(store.currency),
            subtitleColor: OneUITheme.accentBlue,
            onTap: _pickCurrency,
          ),
        ],
      ),
    );
  }

  Widget _remindersPage(double heroHeight) {
    final store = SubscriptionStore.instance;
    return _pageLayout(
      index: 2,
      heroHeight: heroHeight,
      hero: ReminderHero(currency: store.currency, reminderDays: store.defaultReminderDays, toMain: store.toMain),
      title: 'Never miss a renewal',
      body: 'Get a reminder before each charge, so you can cancel what you no longer use in time.',
      extra: OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          _info(
            Icons.alarm_rounded,
            OneUITheme.accentTeal,
            'Reminder',
            describeReminder(store.defaultReminderDays, store.defaultReminderTimeMinutes),
          ),
          if (_remindersAllowed == false)
            _info(
              Icons.notifications_off_rounded,
              OneUITheme.accentAmber,
              'Notifications are blocked',
              'You can allow them later in Android settings',
              subtitleColor: OneUITheme.accentAmber,
            ),
        ],
      ),
    );
  }

  Widget _donePage(double heroHeight) {
    final store = SubscriptionStore.instance;
    final reminders = switch (_remindersAllowed) {
      true => 'On · ${describeReminder(store.defaultReminderDays, store.defaultReminderTimeMinutes)}',
      false => 'Blocked in Android settings',
      null => 'Off for now · turn on any time in Settings',
    };
    return _pageLayout(
      index: 3,
      heroHeight: heroHeight,
      hero: const DoneHero(),
      title: "You're all set",
      body: 'Add your first subscription to start tracking. Switching phones? Restore your backup instead.',
      extra: OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          _info(
            Icons.currency_exchange_rounded,
            OneUITheme.accentGreen,
            'Main currency',
            currencyLabel(store.currency),
          ),
          _info(Icons.notifications_active_rounded, OneUITheme.accentTeal, 'Reminders', reminders),
        ],
      ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
