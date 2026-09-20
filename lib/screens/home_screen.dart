import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';
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
      animation: OneUIEffectsController.instance,
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

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              // Current Page
              IndexedStack(
                index: _currentIndex,
                children: pages,
              ),

              // Edge-to-Edge Progressive Status Bar Scrim (Strictly 80% of status bar)
              const OneUIStatusBarScrim(),

              // Floating Bottom Navigation Pill (1:1 with Screenshot 1 & 4)
              // Smoothly slides down and hides during multi-selection mode
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: 0,
                right: 0,
                bottom: (_currentIndex == 0 && _isSelectionActive) ? -100 : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: (_currentIndex == 0 && _isSelectionActive) ? 0.0 : 1.0,
                  child: OneUIFloatingNavBar(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    items: const [
                      OneUINavItem(
                        activeIcon: Icons.photo_library_rounded,
                        inactiveIcon: Icons.photo_library_outlined,
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
            ],
          ),
        );
      },
    );
  }
}
