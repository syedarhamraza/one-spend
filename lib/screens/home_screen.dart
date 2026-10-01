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

  /// Multi-select mode on the Upcoming tab.
  static final ValueNotifier<bool> upcomingSelectionActive = ValueNotifier<bool>(false);

  /// Floating search open on the Settings tab.
  static final ValueNotifier<bool> settingsSearchActive = ValueNotifier<bool>(false);

  /// Per-tab handlers that close the tab's transient mode (selection or search) on
  /// system back. Branch-level `PopScope`s never see back presses inside the
  /// go_router shell, so the shell consults these instead. Keyed by branch index.
  static final Map<int, VoidCallback> backHandlers = {};

  /// Whether branch [index] is in a mode that system back should close first.
  static bool consumesBack(int index) => switch (index) {
        0 => selectionActive.value || searchActive.value,
        1 => upcomingSelectionActive.value,
        3 => settingsSearchActive.value,
        _ => false,
      };

  static void reset() {
    selectionActive.value = false;
    searchActive.value = false;
    upcomingSelectionActive.value = false;
    settingsSearchActive.value = false;
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
        HomeChrome.upcomingSelectionActive,
        HomeChrome.settingsSearchActive,
      ]),
      builder: (context, _) {
        final currentIndex = navigationShell.currentIndex;
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        final isNavHidden =
            (currentIndex == 0 && (HomeChrome.selectionActive.value || HomeChrome.searchActive.value)) ||
            (currentIndex == 1 && HomeChrome.upcomingSelectionActive.value) ||
            (currentIndex == 3 && HomeChrome.settingsSearchActive.value) ||
            isKeyboardOpen ||
            OneUIFloatingModal.isModalOpen.value;

        // System back first closes the tab's selection/search mode, then returns
        // to the first tab, then exits the app.
        final tabConsumesBack = HomeChrome.consumesBack(currentIndex);
        return PopScope(
          canPop: currentIndex == 0 && !tabConsumesBack,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            final handler = HomeChrome.backHandlers[currentIndex];
            if (tabConsumesBack && handler != null) {
              handler();
            } else if (currentIndex != 0) {
              navigationShell.goBranch(0);
            }
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
