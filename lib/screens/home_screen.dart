import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_floating_nav_bar.dart';
import '../widgets/one_ui_status_bar_scrim.dart';
import '../core/haptics/haptics.dart';
import '../theme/one_ui_scroll.dart';

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

  /// A tab's bottom actions, hosted by the shell's nav bar so the bar morphs into
  /// them (see [HomeShellScope]). Only shown while [tab] is the current branch.
  static final ValueNotifier<({int tab, Widget content})?> dockedBar = ValueNotifier(null);

  /// Publishes (or, with null, withdraws) branch [tab]'s docked bottom actions.
  /// Safe to call from `build`: the update lands after the frame, and it only
  /// rebuilds the nav bar, not the tab content.
  static void dockBottomBar(int tab, Widget? content) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = dockedBar.value;
      if (content != null) {
        dockedBar.value = (tab: tab, content: content);
      } else if (current != null && current.tab == tab) {
        dockedBar.value = null;
      }
    });
  }

  static void reset() {
    dockedBar.value = null;
    selectionActive.value = false;
    searchActive.value = false;
    upcomingSelectionActive.value = false;
    settingsSearchActive.value = false;
  }
}

/// Marks content hosted inside the tab shell. Tabs in it dock their bottom actions
/// into the shell's nav bar via [HomeChrome.dockBottomBar] (so the bar morphs);
/// outside it (e.g. a pushed, card-filtered list) they draw their own bar.
class HomeShellScope extends InheritedWidget {
  const HomeShellScope({super.key, required super.child});

  static bool isHosted(BuildContext context) => context.getInheritedWidgetOfExactType<HomeShellScope>() != null;

  @override
  bool updateShouldNotify(HomeShellScope oldWidget) => false;
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
        // Selection modes don't hide the bar: it morphs into the tab's docked actions.
        final isNavHidden =
            (currentIndex == 0 && HomeChrome.searchActive.value) ||
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
                // The tabs are the big-header pages: no stretch at their top (see OneUINoTopStretch).
                OneUINoTopStretch(child: HomeShellScope(child: navigationShell)),

                // Edge-to-Edge Progressive Status Bar Scrim (Strictly 80% of status bar)
                const Positioned(top: 0, left: 0, right: 0, child: OneUIStatusBarScrim()),

                // Floating bottom navigation pill. Morphs into a tab's docked actions
                // (selection mode); slides away for search, the keyboard and modals.
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
                      child: ValueListenableBuilder(
                        valueListenable: HomeChrome.dockedBar,
                        builder: (context, docked, _) => OneUIFloatingNavBar(
                          currentIndex: currentIndex,
                          dockedContent: docked != null && docked.tab == currentIndex ? docked.content : null,
                          onTap: (index) {
                            Haptics.tap();
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
