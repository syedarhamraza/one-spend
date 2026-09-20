import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_floating_nav_bar.dart';
import '../widgets/one_ui_status_bar_scrim.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'subscriptions_screen.dart';
import 'upcoming_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSelectionActive = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        OneUIEffectsController.instance,
        OneUIFloatingModal.isModalOpen,
      ]),
      builder: (context, _) {
        final pages = [
          SubscriptionsScreen(
            onSelectionModeChanged: (active) {
              setState(() {
                _isSelectionActive = active;
              });
            },
          ),
          const UpcomingScreen(),
          const AnalyticsScreen(),
          const SettingsScreen(),
        ];

        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        final isNavHidden = (_currentIndex == 0 && _isSelectionActive) || isKeyboardOpen || OneUIFloatingModal.isModalOpen.value;

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Current Page
              IndexedStack(
                index: _currentIndex,
                children: pages,
              ),

              // Edge-to-Edge Progressive Status Bar Scrim (Strictly 80% of status bar)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OneUIStatusBarScrim(),
              ),

              // Floating Bottom Navigation Pill (1:1 with Screenshot 1 & 4)
              // Smoothly slides down and hides during multi-selection mode or keyboard input
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: 0,
                right: 0,
                bottom: isNavHidden ? -120 : 0,
                child: IgnorePointer(
                  ignoring: isNavHidden,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isNavHidden ? 0.0 : 1.0,
                    child: OneUIFloatingNavBar(
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      items: const [
                        OneUINavItem(
                          activeIcon: Icons.account_balance_wallet_rounded,
                          inactiveIcon: Icons.account_balance_wallet_outlined,
                          label: 'Spend',
                        ),
                        OneUINavItem(
                          activeIcon: Icons.calendar_today_rounded,
                          inactiveIcon: Icons.calendar_today_outlined,
                          label: 'Upcoming',
                        ),
                        OneUINavItem(
                          activeIcon: Icons.pie_chart_rounded,
                          inactiveIcon: Icons.pie_chart_outline_rounded,
                          label: 'Analytics',
                        ),
                        OneUINavItem(
                          activeIcon: Icons.menu_rounded,
                          inactiveIcon: Icons.menu_rounded,
                          label: 'Menu',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
