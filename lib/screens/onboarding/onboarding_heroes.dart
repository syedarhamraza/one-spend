import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_info.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_glass_surface.dart';
import '../../widgets/one_ui_subscription_card.dart';

/// The illustrations at the top of each onboarding page. They're decoration, built from
/// the app's own components so the first screen already looks like One Spend; screen
/// readers skip them (the page text says the same).
///
/// Each fills the box it's given (see `OnboardingScreen`), centred.

/// Welcome: three real subscription cards fanned out, with the app icon above.
class WelcomeHero extends StatelessWidget {
  /// The user's main currency; the sample prices are converted into it.
  final String currency;
  final double Function(double amount, String code) toMain;

  const WelcomeHero({super.key, required this.currency, required this.toMain});

  /// Fictional services (as in the store listing), so no real brand appears in the app's
  /// own illustrations.
  Subscription _sample(
    String id,
    String name,
    double usd,
    int color,
    IconData icon,
    int days,
    SubscriptionCategory category,
  ) {
    final converted = currency == 'USD' ? usd : toMain(usd, 'USD');
    return Subscription(
      id: 'onboarding_$id',
      name: name,
      description: '',
      price: converted > 0 ? converted : usd,
      currency: converted > 0 ? currency : 'USD',
      billingCycle: BillingCycle.monthly,
      category: category,
      nextBillingDate: DateTime.now().add(Duration(days: days)),
      brandColorValue: color,
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _sample('cloudvault', 'CloudVault', 9.99, 0xFF3B82F6, Icons.cloud_rounded, 12, SubscriptionCategory.cloud),
      _sample('tunebox', 'Tunebox', 11.99, 0xFF1DB97A, Icons.music_note_rounded, 5, SubscriptionCategory.music),
      _sample('streamly', 'Streamly', 15.99, 0xFFE5484D, Icons.movie_rounded, 2, SubscriptionCategory.entertainment),
    ];
    return ExcludeSemantics(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, box) {
            // Cards render at a phone-card width, then scale to the space available.
            const cardWidth = 340.0;
            final scale = math.min(1.0, (box.maxWidth - 24) / cardWidth) * 0.92;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // A Wallet-style deck: tops aligned, each back card peeking out by exactly
                // its name row, so no half-hidden text shows between them.
                for (var i = 0; i < cards.length; i++)
                  Transform.translate(
                    // Pushed down so the back card clears the app icon above it.
                    offset: Offset(0, 58 - (cards.length - 1 - i) * 34.0 * scale),
                    child: Opacity(
                      // Back cards recede, so the front one reads first.
                      opacity: const [0.55, 0.8, 1.0][i],
                      child: Transform.scale(
                        scale: scale * const [0.88, 0.94, 1.0][i],
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: cardWidth,
                          child: OneUISubscriptionCard(
                            subscription: cards[i],
                            hasNoCard: true,
                            isCardExpiring: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: -6,
                  child: OneUIGlassSurface(
                    borderRadius: BorderRadius.circular(22),
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Image.asset(AppInfo.logoAsset, width: 52, height: 52, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Currency: the main currency in a large glass tile, other currencies floating around it.
class CurrencyHero extends StatelessWidget {
  final String code;

  const CurrencyHero({super.key, required this.code});

  /// The first four that aren't the main currency float around it (AED fills in when one is).
  static const _others = ['USD', 'EUR', 'GBP', 'JPY', 'PKR', 'AED'];

  @override
  Widget build(BuildContext context) {
    final main = CurrencyCatalog.of(code);
    final orbit = [for (final c in _others) if (c != code) CurrencyCatalog.of(c)].take(4).toList();
    const positions = [Alignment(-0.78, -0.62), Alignment(0.8, -0.5), Alignment(-0.7, 0.66), Alignment(0.74, 0.7)];
    return ExcludeSemantics(
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < orbit.length; i++)
            Align(
              alignment: positions[i],
              child: OneUIGlassSurface(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  '${orbit[i].symbol}  ${orbit[i].code}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
                ),
              ),
            ),
          // Re-keyed by code so a new pick animates in.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: OneUIGlassSurface(
              key: ValueKey(main.code),
              width: 132,
              height: 132,
              borderRadius: BorderRadius.circular(40),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        main.symbol,
                        style: const TextStyle(
                          fontSize: 50,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          color: OneUITheme.accentGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    main.code,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reminders: what a renewal reminder looks like, as One UI notifications.
class ReminderHero extends StatelessWidget {
  final String currency;
  final int reminderDays;
  final double Function(double amount, String code) toMain;

  const ReminderHero({super.key, required this.currency, required this.reminderDays, required this.toMain});

  String _price(double usd) {
    final converted = currency == 'USD' ? usd : toMain(usd, 'USD');
    return converted > 0 ? formatMoney(converted, currency) : formatMoney(usd, 'USD');
  }

  /// Same wording as the real reminders (`NotificationPlanner`).
  static String _relativeDay(int days) => switch (days) {
        0 => 'today',
        1 => 'tomorrow',
        _ => 'in $days days',
      };

  @override
  Widget build(BuildContext context) {
    final dueText = DateFormat('MMM d').format(DateTime.now().add(Duration(days: reminderDays)));
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) {
          final width = math.min(box.maxWidth - 8, 360.0);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // A second reminder peeking out behind.
              Transform.translate(
                offset: const Offset(0, 46),
                child: Opacity(
                  opacity: 0.5,
                  child: _Notification(
                    width: width * 0.9,
                    title: 'CloudVault renews ${_relativeDay(reminderDays + 3)}',
                    body: '${_price(9.99)} will be charged soon.',
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -12),
                child: _Notification(
                  width: width,
                  title: 'Streamly renews ${_relativeDay(reminderDays)}',
                  body: '${_price(15.99)} will be charged on $dueText.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Notification extends StatelessWidget {
  final double width;
  final String title;
  final String body;

  const _Notification({required this.width, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return OneUIGlassSurface(
      width: width,
      borderRadius: BorderRadius.circular(OneUITheme.radiusCard),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(AppInfo.logoAsset, width: 18, height: 18, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    text: AppInfo.name,
                    style: TextStyle(color: OneUITheme.textSecondary),
                    children: [TextSpan(text: '  ·  now', style: TextStyle(color: OneUITheme.textTertiary))],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: OneUITheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// All set: a big green check in a glass circle.
class DoneHero extends StatelessWidget {
  const DoneHero({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Center(
        child: OneUIGlassSurface.circle(
          size: 132,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: OneUITheme.accentGreen.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 52, color: OneUITheme.accentGreen),
          ),
        ),
      ),
    );
  }
}
