import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_search_field.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_subpage.dart';
import 'home_screen.dart';
import 'settings/settings_catalog.dart';

/// Settings tab, laid out like Samsung Settings: grouped rows with just an icon and a title.
/// Every row opens a subpage; options, switches and dialogs live there, never here.
class SettingsScreen extends StatefulWidget {
  /// Shows "Developer options". Debug builds only by default.
  final bool showDeveloperOptions;

  const SettingsScreen({super.key, this.showDeveloperOptions = kDebugMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searching = false;
  String _query = '';

  late final VoidCallback _shellBackHandler = _closeSearch;

  @override
  void initState() {
    super.initState();
    HomeChrome.backHandlers[3] = _shellBackHandler;
  }

  @override
  void dispose() {
    if (HomeChrome.backHandlers[3] == _shellBackHandler) HomeChrome.backHandlers.remove(3);
    HomeChrome.settingsSearchActive.value = false;
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    setState(() => _searching = true);
    HomeChrome.settingsSearchActive.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  void _closeSearch() {
    if (!_searching) return;
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() {
      _searching = false;
      _query = '';
    });
    HomeChrome.settingsSearchActive.value = false;
  }

  void _open(SettingsDestination destination) {
    _searchFocus.unfocus();
    destination.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final searchPillBottom = math.max(bottomPadding + 16, bottomInset + 14);
    final groups = SettingsCatalog.groups(developerOptions: widget.showDeveloperOptions);

    return PopScope(
      // System back closes search before leaving the tab.
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: Scaffold(
        backgroundColor: OneUITheme.surfacePitch,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: OneUICollapsibleHeaderDelegate(
                    title: 'Settings',
                    hasBigHeader: true,
                    expandedHeight: 270.0,
                    actions: [
                      _searching
                          ? OneUIHeaderAction(icon: Icons.close_rounded, tooltip: 'Close search', onTap: _closeSearch)
                          : OneUIHeaderAction(icon: Icons.search_rounded, tooltip: 'Search settings', onTap: _openSearch),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, _searching ? searchPillBottom + 80 : 140),
                  sliver: SliverToBoxAdapter(
                    child: _searching && _query.trim().isNotEmpty ? _results() : _groups(groups),
                  ),
                ),
              ],
            ),
            const Positioned(left: 0, right: 0, bottom: 0, child: OneUIBottomVignette()),
            if (_searching)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: 18,
                right: 18,
                bottom: searchPillBottom,
                child: OneUIFloatingSearchField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  hintText: 'Search settings',
                  onChanged: (value) => setState(() => _query = value),
                  onSubmitted: (_) => _searchFocus.unfocus(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _groups(List<List<SettingsDestination>> groups) {
    return Column(
      children: [
        for (final group in groups)
          OneUIGroupCard(
            items: [
              for (final d in group)
                OneUIGroupItem(
                  leading: OneUIIconBadge(d.icon, d.color),
                  title: d.title,
                  // Samsung Settings rows carry no chevron; "Soon" rows get a chip instead.
                  trailing: d.soon ? const OneUISoonChip() : const SizedBox.shrink(),
                  onTap: () => _open(d),
                ),
            ],
          ),
      ],
    );
  }

  Widget _results() {
    final results = SettingsCatalog.search(_query, developerOptions: widget.showDeveloperOptions);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: OneUITheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No results for "${_query.trim()}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
            ),
          ],
        ),
      );
    }
    return OneUIGroupCard(
      items: [
        for (final r in results)
          OneUIGroupItem(
            leading: OneUIIconBadge(r.destination.icon, r.destination.color),
            title: r.title,
            subtitle: r.path == null ? null : 'Settings › ${r.path}',
            subtitleColor: OneUITheme.textSecondary,
            trailing: r.destination.soon ? const OneUISoonChip() : const SizedBox.shrink(),
            onTap: () => _open(r.destination),
          ),
      ],
    );
  }
}
