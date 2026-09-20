import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_alternative_options_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_floating_search_pill.dart';
import '../widgets/one_ui_group_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _editProfile(BuildContext context, SubscriptionStore store) {
    final nameController = TextEditingController(text: store.userName);
    final emailController = TextEditingController(text: store.userEmail);

    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Edit Profile',
      message: 'Update your display profile information:',
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: OneUITheme.surfacePill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: nameController,
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
              controller: emailController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: OneUITheme.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
      cancelLabel: 'Cancel',
      confirmLabel: 'Save',
      onConfirm: () {
        final name = nameController.text.trim();
        final email = emailController.text.trim();
        if (name.isNotEmpty && email.isNotEmpty) {
          store.setUserProfile(name, email);
        }
      },
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
    final controller = TextEditingController(text: store.monthlyBudget.toStringAsFixed(0));

    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Monthly Budget Limit',
      message: 'Set your monthly subscription limit threshold:',
      customContent: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: OneUITheme.surfacePill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: '${store.currency} ',
            prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
            border: InputBorder.none,
          ),
        ),
      ),
      cancelLabel: 'Cancel',
      confirmLabel: 'Save',
      onConfirm: () {
        final newBudget = double.tryParse(controller.text.trim()) ?? store.monthlyBudget;
        store.setMonthlyBudget(newBudget);
      },
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('JSON copied to clipboard'),
            backgroundColor: OneUITheme.surfacePill,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All subscriptions cleared'),
            backgroundColor: OneUITheme.surfacePill,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
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
                  const SliverPersistentHeader(
                    pinned: true,
                    delegate: OneUICollapsibleHeaderDelegate(
                      title: 'Settings',
                      hasBigHeader: true,
                      expandedHeight: 270.0,
                    ),
                  ),

                  // 2. Settings Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                      child: Column(
                        children: [
                          // Profile Card
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
                                      store.userName.isNotEmpty
                                          ? store.userName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                                          : 'SA',
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
                          OneUIGroupCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            items: [
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
                            ],
                          ),

                          // Card 2: 3D Appearance & Visual Styling
                          AnimatedBuilder(
                            animation: OneUIEffectsController.instance,
                            builder: (context, _) {
                              final isNavbar3d = OneUIEffectsController.instance.navbar3dEffect;
                              final isFloating3d = OneUIEffectsController.instance.floating3dEffect;
                              final isCards3d = OneUIEffectsController.instance.card3dEffect;

                              return OneUIGroupCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                items: [
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
                                ],
                              );
                            },
                          ),

                          // Card 3: Data Management & Backup
                          OneUIGroupCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            items: [
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Restored default catalog subscriptions'),
                                      backgroundColor: OneUITheme.surfacePill,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  );
                                },
                              ),
                              OneUIGroupItem(
                                leading: _buildIconBadge(Icons.delete_sweep_rounded, OneUITheme.accentRed),
                                title: 'Clear all subscriptions',
                                subtitle: 'Reset and remove all tracked subscriptions',
                                onTap: () => _clearData(context, store),
                              ),
                            ],
                          ),

                          // Card 4: About OneSpend
                          OneUIGroupCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            items: [
                              OneUIGroupItem(
                                leading: _buildIconBadge(Icons.info_outline_rounded, const Color(0xFF1E88E5)),
                                title: 'About OneSpend',
                                subtitle: 'Version 1.0.0 • Samsung One UI 9 Engine',
                                onTap: () {
                                  showAboutDialog(
                                    context: context,
                                    applicationName: 'OneSpend',
                                    applicationVersion: '1.0.0',
                                    applicationIcon: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: OneUITheme.accentBlue,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.subscriptions_rounded, color: Colors.white, size: 28),
                                    ),
                                    children: const [
                                      Text('A feature-rich subscription and spend manager designed to match Samsung One UI 9 aesthetics and ergonomics.'),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // "Looking for something else?" Card
                          OneUIAlternativeOptionsCard(
                            title: 'Looking for something else?',
                            actions: [
                              OneUIAlternativeAction(
                                title: 'Reset appearance settings',
                                onTap: () {
                                  OneUIEffectsController.instance.navbar3dEffect = true;
                                  OneUIEffectsController.instance.floating3dEffect = true;
                                  OneUIEffectsController.instance.card3dEffect = true;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Reset appearance to default 3D effects'),
                                      backgroundColor: OneUITheme.surfacePill,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  );
                                },
                              ),
                              OneUIAlternativeAction(
                                title: 'Help & feedback',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Contact support at help@onespend.app'),
                                      backgroundColor: OneUITheme.surfacePill,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Search Pill
              Positioned(
                left: 20,
                right: 20,
                bottom: 74,
                child: OneUIFloatingSearchPill(
                  hintText: 'Search settings',
                  onTap: () {},
                ),
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
