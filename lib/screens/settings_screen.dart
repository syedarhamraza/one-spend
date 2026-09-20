import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_alternative_options_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_search_pill.dart';
import '../widgets/one_ui_group_card.dart';
import 'subscription_detail_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
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

              // 2. Settings Content matching Screenshot 1:1
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                  child: Column(
                    children: [
                      // Profile Card (Matches Screenshot top card)
                      Container(
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Syed Arham Raza',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      color: OneUITheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Samsung account',
                                    style: TextStyle(
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
                              child: const Text(
                                'SA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Card 1: Warranty and care (Single item card matching screenshot)
                      OneUIGroupCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        items: [
                          OneUIGroupItem(
                            leading: _buildIconBadge(Icons.health_and_safety_rounded, OneUITheme.accentGreen),
                            title: 'Warranty and care',
                            onTap: () {},
                          ),
                        ],
                      ),

                      // Card 2: Connections & Connected devices (2 items matching screenshot)
                      OneUIGroupCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        items: [
                          OneUIGroupItem(
                            leading: _buildIconBadge(Icons.wifi_rounded, OneUITheme.accentBlue),
                            title: 'Connections',
                            onTap: () {},
                          ),
                          OneUIGroupItem(
                            leading: _buildIconBadge(Icons.devices_other_rounded, OneUITheme.accentBlue),
                            title: 'Connected devices',
                            onTap: () {},
                          ),
                        ],
                      ),

                      // Card 3: Galaxy AI, Modes, Sounds, Notifications (4 items matching screenshot)
                      OneUIGroupCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        items: [
                          OneUIGroupItem(
                            leading: _buildIconBadge(Icons.auto_awesome_rounded, const Color(0xFF3880FF)),
                            title: 'Galaxy AI',
                            onTap: () {},
                          ),
                          OneUIGroupItem(
                            leading: _buildIconBadge(Icons.timelapse_rounded, OneUITheme.accentPurple),
                            title: 'Modes and Routines',
                            onTap: () {},
                          ),
                          OneUIGroupItem(
                            leading: _buildIconBadge(Icons.volume_up_rounded, OneUITheme.accentPurple),
                            title: 'Sounds and vibration',
                            onTap: () {},
                          ),
                          OneUIGroupItem(
                            leading: _buildIconBadge(Icons.notifications_rounded, const Color(0xFFFF7A00)),
                            title: 'Notifications',
                            onTap: () {},
                          ),
                        ],
                      ),

                      // Card 4: Navigation, Floating Elements & Cards 3D Appearance
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

                      // Card 5: Device Info & Routine Demo
                      OneUIGroupCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        items: [
                          OneUIGroupItem(
                            leading: _buildIconBadge(Icons.phone_android_rounded, const Color(0xFF1E88E5)),
                            title: 'About OneSpend',
                            onTap: () {},
                          ),
                          OneUIGroupItem(
                            leading: _buildIconBadge(Icons.menu_book_rounded, OneUITheme.accentTeal),
                            title: 'Open Routine Demo (Screenshot 3)',
                            onTap: () {
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

                      const SizedBox(height: 8),

                      // "Looking for something else?" Card matching Screenshot 1
                      OneUIAlternativeOptionsCard(
                        title: 'Looking for something else?',
                        actions: [
                          OneUIAlternativeAction(
                            title: 'Software update',
                            onTap: () {},
                          ),
                          OneUIAlternativeAction(
                            title: 'Reset',
                            onTap: () {},
                          ),
                          OneUIAlternativeAction(
                            title: 'Contact us',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Search Pill matching Screenshot 1:1
          Positioned(
            left: 20,
            right: 20,
            bottom: 74, // Positioned right above the bottom navigation bar
            child: OneUIFloatingSearchPill(
              hintText: 'Search',
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
