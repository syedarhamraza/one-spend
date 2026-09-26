import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_toast.dart';
import 'subscription_card_customizer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showSearch = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _actionPillKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _editProfile(BuildContext context, SubscriptionStore store) {
    OneUIFloatingModal.show(
      context: context,
      builder: (ctx) => _ProfileEditModal(
        initialName: store.userName,
        initialEmail: store.userEmail,
        onSave: (name, email) => store.setUserProfile(name, email),
      ),
    );
  }

  void _pickCurrency(BuildContext context, SubscriptionStore store) {
    final currencies = [
      {'symbol': '\$', 'name': r'USD / AUD / CAD ($)'},
      {'symbol': '€', 'name': 'Euro (€)'},
      {'symbol': '£', 'name': 'British Pound (£)'},
      {'symbol': '¥', 'name': 'Japanese Yen / Yuan (¥)'},
      {'symbol': '₹', 'name': 'Indian Rupee (₹)'},
      {'symbol': '₩', 'name': 'Korean Won (₩)'},
      {'symbol': 'CHF', 'name': 'Swiss Franc (CHF)'},
      {'symbol': 'AED', 'name': 'UAE Dirham (AED)'},
    ];

    OneUIFloatingModal.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Currency',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OneUITheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.40,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...currencies.map((curr) {
                    final isSelected = store.currency == curr['symbol'];
                    return InkWell(
                      onTap: () {
                        store.setCurrency(curr['symbol']!);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2C69FF)
                                      : const Color(0xFF5E5E62),
                                  width: isSelected ? 2.0 : 1.6,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: isSelected
                                  ? Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF2C69FF),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                curr['name']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: OneUITheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: OneUITheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editBudget(BuildContext context, SubscriptionStore store) {
    OneUIFloatingModal.showTextInputDialog(
      context: context,
      title: 'Monthly Budget Limit',
      message: 'Set your monthly subscription limit threshold:',
      initialValue: store.monthlyBudget.toStringAsFixed(0),
      prefixText: '${store.currency} ',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      cancelLabel: 'Cancel',
      confirmLabel: 'Save',
    ).then((result) {
      if (result != null) {
        final parsed = double.tryParse(result.trim().replaceAll(',', '.'));
        if (parsed != null && parsed >= 0) {
          store.setMonthlyBudget(parsed.clamp(0.0, 999999.0));
        }
      }
    });
  }

  void _pickReminderDays(BuildContext context, SubscriptionStore store) {
    final days = [1, 2, 3, 7];

    OneUIFloatingModal.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Default Renewal Notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OneUITheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          ...days.map((d) {
            final isSelected = store.defaultReminderDays == d;
            final label = d == 1 ? '1 day before' : (d == 7 ? '1 week before' : '$d days before');
            return InkWell(
              onTap: () {
                store.setDefaultReminderDays(d);
                Navigator.pop(ctx);
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2C69FF)
                              : const Color(0xFF5E5E62),
                          width: isSelected ? 2.0 : 1.6,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isSelected
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2C69FF),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: OneUITheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: OneUITheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportJson(BuildContext context, SubscriptionStore store) {
    final jsonStr = store.exportDataAsJson();

    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Export Subscriptions (JSON)',
      message: 'Preview and copy your full JSON backup:',
      customContent: Container(
        height: 140,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OneUITheme.surfacePill, borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Text(jsonStr, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: OneUITheme.textSecondary)),
        ),
      ),
      cancelLabel: 'Close',
      confirmLabel: 'Copy JSON',
      onConfirm: () {
        Clipboard.setData(ClipboardData(text: jsonStr));
      },
    );
  }

  void _clearData(BuildContext context, SubscriptionStore store) {
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Clear All Subscriptions?',
      message: 'This will delete all your subscriptions from OneSpend. This action cannot be undone.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Clear All',
      onConfirm: () {
        store.clearAllData();
        OneUIToast.show(context, 'All subscriptions cleared');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SubscriptionStore.instance,
        OneUIEffectsController.instance,
      ]),
      builder: (context, _) {
        final store = SubscriptionStore.instance;

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. One UI Signature Collapsible Header
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: OneUICollapsibleHeaderDelegate(
                      title: 'Settings',
                      hasBigHeader: true,
                      expandedHeight: 270.0,
                      actionsPillKey: _actionPillKey,
                      actions: [
                        OneUIHeaderAction(
                          icon: Icons.search_rounded,
                          tooltip: 'Search settings',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _showSearch = !_showSearch;
                              if (!_showSearch) {
                                _searchQuery = '';
                                _searchController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Search bar if toggled (matching SubscriptionsScreen)
                  if (_showSearch)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.pillBorderRadius,
                            border: OneUITheme.cardBorder,
                            boxShadow: OneUITheme.cardShadow,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(
                              fontSize: 16,
                              color: OneUITheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search settings...',
                              hintStyle: const TextStyle(color: OneUITheme.textSecondary),
                              border: InputBorder.none,
                              icon: const Icon(Icons.search_rounded, color: OneUITheme.textSecondary),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: OneUITheme.textSecondary),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim().toLowerCase();
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                  // 2. Settings Content
                  Builder(
                    builder: (context) {
                      bool matches(String? text) =>
                          text != null && text.toLowerCase().contains(_searchQuery);
                      bool itemMatches(OneUIGroupItem item) =>
                          _searchQuery.isEmpty ||
                          matches(item.title) ||
                          matches(item.subtitle);

                      final showProfile = _searchQuery.isEmpty ||
                          matches(store.userName) ||
                          matches(store.userEmail) ||
                          matches('profile') ||
                          matches('account');

                      final appPrefItems = <OneUIGroupItem>[
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.monetization_on_rounded, OneUITheme.accentGreen),
                          title: 'Currency',
                          subtitle: 'Default currency symbol: ${store.currency}',
                          onTap: () => _pickCurrency(context, store),
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.account_balance_wallet_rounded, OneUITheme.accentBlue),
                          title: 'Monthly budget threshold',
                          subtitle: '${store.currency}${store.monthlyBudget.toStringAsFixed(0)} limit',
                          onTap: () => _editBudget(context, store),
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.notifications_active_rounded, OneUITheme.accentAmber),
                          title: 'Renewal notification alert',
                          subtitle: '${store.defaultReminderDays} days before renewal date',
                          onTap: () => _pickReminderDays(context, store),
                        ),
                      ].where(itemMatches).toList();

                      final isNavbar3d = OneUIEffectsController.instance.navbar3dEffect;
                      final isFloating3d = OneUIEffectsController.instance.floating3dEffect;
                      final isCards3d = OneUIEffectsController.instance.card3dEffect;
                      final isBottomVignette = OneUIEffectsController.instance.bottomVignetteEffect;

                      final appearanceItems = <OneUIGroupItem>[
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.tune_rounded, OneUITheme.accentPurple),
                          title: 'Card details & indicators',
                          subtitle: 'Price format, cycle progress bar, and metadata chips',
                          trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SubscriptionCardCustomizerScreen(),
                              ),
                            );
                          },
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.view_agenda_rounded, OneUITheme.accentBlue),
                          title: 'Navigation bar 3D effect',
                          subtitle: isNavbar3d
                              ? '3D floating pill elevation & top rim highlight'
                              : 'Classic flat appearance',
                          trailing: Switch.adaptive(
                            value: isNavbar3d,
                            activeTrackColor: OneUITheme.accentBlue,
                            onChanged: (val) {
                              OneUIEffectsController.instance.navbar3dEffect = val;
                            },
                          ),
                          onTap: () {
                            OneUIEffectsController.instance.navbar3dEffect = !isNavbar3d;
                          },
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.radio_button_checked_rounded, OneUITheme.accentPurple),
                          title: 'Floating buttons & pills 3D effect',
                          subtitle: isFloating3d
                              ? '3D elevation & rim highlight on search, back & action pills'
                              : 'Classic flat appearance',
                          trailing: Switch.adaptive(
                            value: isFloating3d,
                            activeTrackColor: OneUITheme.accentPurple,
                            onChanged: (val) {
                              OneUIEffectsController.instance.floating3dEffect = val;
                            },
                          ),
                          onTap: () {
                            OneUIEffectsController.instance.floating3dEffect = !isFloating3d;
                          },
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.layers_rounded, OneUITheme.accentTeal),
                          title: 'Cards 3D depth effect',
                          subtitle: isCards3d
                              ? '3D elevation, rim highlight & soft shadows on all cards'
                              : 'Classic flat appearance',
                          trailing: Switch.adaptive(
                            value: isCards3d,
                            activeTrackColor: OneUITheme.accentTeal,
                            onChanged: (val) {
                              OneUIEffectsController.instance.card3dEffect = val;
                            },
                          ),
                          onTap: () {
                            OneUIEffectsController.instance.card3dEffect = !isCards3d;
                          },
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.gradient_rounded, OneUITheme.accentBlue),
                          title: 'Bottom gradient vignette',
                          subtitle: isBottomVignette
                              ? 'Smooth pitch-black fade behind floating navigation'
                              : 'Classic flat appearance',
                          trailing: Switch.adaptive(
                            value: isBottomVignette,
                            activeTrackColor: OneUITheme.accentBlue,
                            onChanged: (val) {
                              OneUIEffectsController.instance.bottomVignetteEffect = val;
                            },
                          ),
                          onTap: () {
                            OneUIEffectsController.instance.bottomVignetteEffect = !isBottomVignette;
                          },
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.refresh_rounded, OneUITheme.accentOrange),
                          title: 'Reset appearance effects',
                          subtitle: 'Restore default visual effects across the app',
                          onTap: () {
                            OneUIEffectsController.instance.navbar3dEffect = true;
                            OneUIEffectsController.instance.floating3dEffect = true;
                            OneUIEffectsController.instance.card3dEffect = true;
                            OneUIEffectsController.instance.bottomVignetteEffect = true;
                            OneUIToast.show(context, 'Reset appearance to default effects');
                          },
                        ),
                      ].where(itemMatches).toList();

                      final dataItems = <OneUIGroupItem>[
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.file_download_outlined, OneUITheme.accentTeal),
                          title: 'Export backup (JSON)',
                          subtitle: 'Export subscriptions into JSON data format',
                          onTap: () => _exportJson(context, store),
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.restore_rounded, OneUITheme.accentBlue),
                          title: 'Restore sample subscriptions',
                          subtitle: 'Reload default popular catalog presets',
                          onTap: () {
                            store.restoreDefaultCatalog();
                            OneUIToast.show(context, 'Restored default catalog subscriptions');
                          },
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.delete_sweep_rounded, OneUITheme.accentRed),
                          title: 'Clear all subscriptions',
                          subtitle: 'Reset and remove all tracked subscriptions',
                          onTap: () => _clearData(context, store),
                        ),
                      ].where(itemMatches).toList();

                      final aboutItems = <OneUIGroupItem>[
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.info_outline_rounded, const Color(0xFF1E88E5)),
                          title: 'About OneSpend',
                          subtitle: 'Version 1.0.0 • Samsung One UI 9 Engine',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'OneSpend',
                              applicationVersion: '1.0.0',
                              applicationIcon: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/logos/app_logo.png',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              children: const [
                                Text('A feature-rich subscription and spend manager designed to match Samsung One UI 9 aesthetics and ergonomics.'),
                              ],
                            );
                          },
                        ),
                        OneUIGroupItem(
                          leading: _buildIconBadge(Icons.help_outline_rounded, OneUITheme.accentPurple),
                          title: 'Help & feedback',
                          subtitle: 'Contact support at help@onespend.app',
                          onTap: () {
                            OneUIToast.show(context, 'Contact support at help@onespend.app');
                          },
                        ),
                      ].where(itemMatches).toList();

                      final hasAnyResult = showProfile ||
                          appPrefItems.isNotEmpty ||
                          appearanceItems.isNotEmpty ||
                          dataItems.isNotEmpty ||
                          aboutItems.isNotEmpty;

                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                          child: Column(
                            children: [
                              // Profile Card
                              if (showProfile)
                                GestureDetector(
                                  onTap: () => _editProfile(context, store),
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: OneUITheme.cardColor,
                                      borderRadius: OneUITheme.cardBorderRadius,
                                      border: OneUITheme.cardBorder,
                                      boxShadow: OneUITheme.cardShadow,
                                    ),
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                store.userName,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.3,
                                                  color: OneUITheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${store.userEmail} • ${store.totalActiveCount} active subscriptions',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: OneUITheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF8B0000), Color(0xFF2C0A0A)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            () {
                                              final clean = store.userName.trim();
                                              if (clean.isEmpty) return 'SA';
                                              final parts = clean.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
                                              if (parts.isEmpty) return 'SA';
                                              if (parts.length == 1) {
                                                return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
                                              }
                                              return (parts[0][0] + parts[1][0]).toUpperCase();
                                            }(),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Card 1: App Preferences
                              if (appPrefItems.isNotEmpty)
                                OneUIGroupCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  items: appPrefItems,
                                ),

                              // Card 2: 3D Appearance & Visual Styling
                              if (appearanceItems.isNotEmpty)
                                OneUIGroupCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  items: appearanceItems,
                                ),

                              // Card 3: Data Management & Backup
                              if (dataItems.isNotEmpty)
                                OneUIGroupCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  items: dataItems,
                                ),

                              // Card 4: About OneSpend
                              if (aboutItems.isNotEmpty)
                                OneUIGroupCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  items: aboutItems,
                                ),

                              const SizedBox(height: 8),

                              // Empty search state
                              if (!hasAnyResult)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 48),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 48,
                                        color: OneUITheme.textSecondary.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No settings found for "$_searchQuery"',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: OneUITheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: OneUIBottomVignette(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _ProfileEditModal extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final void Function(String name, String email) onSave;

  const _ProfileEditModal({
    required this.initialName,
    required this.initialEmail,
    required this.onSave,
  });

  @override
  State<_ProfileEditModal> createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends State<_ProfileEditModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OneUIFloatingModal(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Update your display profile information:',
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFFC4C4CA),
              height: 1.35,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: OneUITheme.surfacePill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: OneUITheme.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: OneUITheme.surfacePill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: OneUITheme.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 18,
                color: Colors.white.withValues(alpha: 0.10),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final email = _emailController.text.trim();
                    if (name.isNotEmpty && email.isNotEmpty) {
                      widget.onSave(name, email);
                    }
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
