import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';
import 'subscription_detail_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _hapticsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: OneUITheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Preferences and One UI 9 design system',
                style: TextStyle(
                  fontSize: 15,
                  color: OneUITheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Section: One UI Design Reference Demo
              OneUISection(
                title: 'Design System & Reference Test',
                child: Column(
                  children: [
                    OneUICard(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: OneUITheme.accentTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                      ),
                      title: 'Open Routine Demo (Screenshot 3)',
                      subtitle: 'Pixel-perfect 1:1 view of the reference routine screen',
                      subtitleColor: OneUITheme.accentTeal,
                      trailing: const Icon(Icons.chevron_right_rounded, color: OneUITheme.textSecondary),
                      onTap: () {
                        // Launch the exact "Color filter" demo
                        final demoSub = Subscription(
                          id: 'demo_routine',
                          name: 'Color filter',
                          description: 'Make text easier to read by applying a color filter to the screen while using selected apps.',
                          price: 0,
                          billingCycle: BillingCycle.monthly,
                          category: SubscriptionCategory.utilities,
                          brandColor: OneUITheme.accentTeal,
                          iconData: Icons.menu_book_rounded,
                          nextBillingDate: DateTime.now(),
                          status: SubscriptionStatus.active,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubscriptionDetailScreen(subscription: demoSub),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Section: Preferences
              OneUISection(
                title: 'Preferences',
                child: Column(
                  children: [
                    OneUICard(
                      leading: const Icon(Icons.attach_money_rounded, color: OneUITheme.accentGreen),
                      title: 'Default Currency',
                      subtitle: 'USD (\$)',
                      trailing: const Icon(Icons.chevron_right_rounded, color: OneUITheme.textSecondary),
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    OneUICard(
                      leading: const Icon(Icons.notifications_active_rounded, color: OneUITheme.accentBlue),
                      title: 'Push Notifications',
                      subtitle: _notificationsEnabled ? 'Alerts active 2 days prior' : 'Disabled',
                      trailing: Switch.adaptive(
                        value: _notificationsEnabled,
                        activeTrackColor: OneUITheme.accentBlue,
                        onChanged: (val) => setState(() => _notificationsEnabled = val),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OneUICard(
                      leading: const Icon(Icons.vibration_rounded, color: OneUITheme.accentAmber),
                      title: 'Haptic Feedback',
                      subtitle: 'Samsung One UI dynamic touch response',
                      trailing: Switch.adaptive(
                        value: _hapticsEnabled,
                        activeTrackColor: OneUITheme.accentBlue,
                        onChanged: (val) => setState(() => _hapticsEnabled = val),
                      ),
                    ),
                  ],
                ),
              ),

              // Section: About
              OneUISection(
                title: 'About',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: OneUITheme.surfaceCard,
                    borderRadius: OneUITheme.cardBorderRadius,
                    border: OneUITheme.subtleBorder,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OneSpend for Android',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: OneUITheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Version 1.0.0 • Samsung One UI 9 Design Edition',
                        style: TextStyle(
                          fontSize: 13,
                          color: OneUITheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Engineered with pure OLED pitch black canvas, floating navigation capsules, One UI typography, and responsive interaction hierarchy.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: OneUITheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
