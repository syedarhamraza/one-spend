import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_floating_nav_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SubscriptionsScreen(),
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

              // Floating Bottom Navigation Pill (1:1 with Screenshot 1 & 4)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
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
            ],
          ),
        );
  }
}
