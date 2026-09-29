import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_floating_nav_bar.dart';
import '../widgets/one_ui_status_bar_scrim.dart';

/// Tab-level UI state that hides the floating nav bar (e.g. while the
/// Subscriptions tab is in multi-select or search mode).
class HomeChrome {
  const HomeChrome._();

  static final ValueNotifier<bool> selectionActive = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> searchActive = ValueNotifier<bool>(false);

  static void reset() {
    selectionActive.value = false;
    searchActive.value = false;
  }
}

/// Tab shell hosting the four bottom-navigation branches and the floating nav bar.
class HomeScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        OneUIEffectsController.instance,
        OneUIFloatingModal.isModalOpen,
        HomeChrome.selectionActive,
        HomeChrome.searchActive,
      ]),
      builder: (context, _) {
        final currentIndex = navigationShell.currentIndex;
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        final isNavHidden =
            (currentIndex == 0 && (HomeChrome.selectionActive.value || HomeChrome.searchActive.value)) ||
            isKeyboardOpen ||
            OneUIFloatingModal.isModalOpen.value;

        // System back on a secondary tab returns to the first tab before exiting the app.
        return PopScope(
          canPop: currentIndex == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) navigationShell.goBranch(0);
          },
          child: Scaffold(
            backgroundColor: OneUITheme.surfacePitch,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                // Current tab (each branch keeps its own state via the indexed stack shell)
                navigationShell,

                // Edge-to-Edge Progressive Status Bar Scrim (Strictly 80% of status bar)
                const Positioned(top: 0, left: 0, right: 0, child: OneUIStatusBarScrim()),

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
                        currentIndex: currentIndex,
                        onTap: (index) {
                          HapticFeedback.lightImpact();
                          navigationShell.goBranch(index);
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
                          OneUINavItem(activeIcon: Icons.menu_rounded, inactiveIcon: Icons.menu_rounded, label: 'Menu'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
