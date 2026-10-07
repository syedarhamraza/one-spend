import 'package:flutter/material.dart';

import '../../core/config/feature_flags.dart';
import '../../features/updates/presentation/update_controller.dart';
import '../../theme/one_ui_theme.dart';
import '../payment_methods_screen.dart';
import 'about_screen.dart';
import 'appearance_settings_screen.dart';
import 'backup_data_screen.dart';
import 'budget_currency_screen.dart';
import 'categories_screen.dart';
import 'coming_soon_screen.dart';
import 'developer_options_screen.dart';
import 'help_feedback_screen.dart';
import 'notification_settings_screen.dart';
import 'planned_feature.dart';
import 'security_settings_screen.dart';
import 'software_update_screen.dart';
import 'vibration_settings_screen.dart';

/// An option inside a subpage, listed so Settings search can find it.
typedef SettingsOption = ({String title, List<String> keywords, bool placeholder});

/// One row on the main Settings page and the subpage it opens.
class SettingsDestination {
  final String title;

  /// The grey line under the title on the main page, Samsung style: what's inside,
  /// separated by " • ".
  final String description;
  final IconData icon;
  final Color color;
  final void Function(BuildContext context) open;

  /// Shows a "Soon" chip (the destination is a [ComingSoonScreen]).
  final bool soon;

  /// Every option inside is a placeholder, so the row is hidden with them.
  final bool placeholderOnly;
  final List<String> keywords;
  final List<SettingsOption> options;

  /// When it returns true the row shows an orange dot (e.g. an update is available).
  final bool Function()? badge;

  const SettingsDestination({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.open,
    this.soon = false,
    this.placeholderOnly = false,
    this.keywords = const [],
    this.options = const [],
    this.badge,
  });
}

/// A search hit: a main row, or an option inside one (with the row as its path).
typedef SettingsSearchResult = ({String title, String? path, SettingsDestination destination});

class SettingsCatalog {
  const SettingsCatalog._();

  /// Main page groups, top to bottom. Placeholder rows appear only when
  /// [FeatureFlags.showPlannedFeatures] is on (debug builds).
  static List<List<SettingsDestination>> groups({required bool developerOptions}) => [
    for (final group in _allGroups(developerOptions: developerOptions))
      [
        for (final d in group)
          if (FeatureFlags.showPlannedFeatures || (!d.soon && !d.placeholderOnly)) d,
      ],
  ].where((g) => g.isNotEmpty).toList();

  static List<List<SettingsDestination>> _allGroups({required bool developerOptions}) => [
    [
      SettingsDestination(
        title: 'Budget & currency',
        description: 'Monthly budget • Main currency • Exchange rates',
        icon: Icons.account_balance_wallet_rounded,
        color: OneUITheme.accentGreen,
        open: BudgetCurrencyScreen.open,
        keywords: ['money', 'limit', 'spending'],
        options: [
          (title: 'Monthly budget', keywords: ['limit', 'spending cap'], placeholder: false),
          (title: 'Main currency', keywords: ['currency', 'symbol', 'dollar', 'euro', 'pound', 'rupee', 'yen'], placeholder: false),
          (title: 'Exchange rates', keywords: ['exchange', 'conversion', 'convert', 'rate', 'multi-currency'], placeholder: false),
        ],
      ),
      SettingsDestination(
        title: 'Categories',
        description: 'Built-in categories • Your own categories',
        icon: Icons.label_rounded,
        color: OneUITheme.accentOrange,
        open: CategoriesScreen.open,
        keywords: ['category', 'categories', 'tag', 'tags', 'custom', 'group', 'pro'],
        options: [
          (title: 'New category', keywords: ['create', 'add', 'custom', 'pro'], placeholder: false),
        ],
      ),
      SettingsDestination(
        title: 'Notifications',
        description: 'Renewal reminders • Default reminder time',
        icon: Icons.notifications_rounded,
        color: OneUITheme.accentOrange,
        open: NotificationSettingsScreen.open,
        keywords: ['alerts'],
        options: [
          (
            title: 'Default reminder',
            keywords: ['reminder time', 'days before', 'alert', 'renewal'],
            placeholder: false,
          ),
        ],
      ),
      SettingsDestination(
        title: 'Vibration',
        description: 'Haptic feedback • Intensity • Notifications',
        icon: Icons.vibration_rounded,
        color: OneUITheme.accentTeal,
        open: VibrationSettingsScreen.open,
        keywords: ['vibrate', 'haptic', 'haptics', 'touch feedback'],
        options: [
          (title: 'Haptic feedback', keywords: ['vibrate', 'touch', 'tap', 'buzz'], placeholder: false),
          (title: 'Intensity', keywords: ['vibration strength', 'stronger', 'weaker', 'haptic strength'], placeholder: false),
          (
            title: 'Vibrate for notifications',
            keywords: ['notification', 'reminder', 'silent', 'vibration'],
            placeholder: false,
          ),
        ],
      ),
      SettingsDestination(
        title: 'Payment methods',
        description: 'Cards • Wallets • Card expiry',
        icon: Icons.credit_card_rounded,
        color: OneUITheme.accentBlue,
        open: PaymentMethodsScreen.open,
        keywords: ['cards', 'credit', 'debit', 'wallet', 'bank'],
      ),
    ],
    [
      SettingsDestination(
        title: 'Appearance',
        description: '3D effects • Subscription cards • Details',
        icon: Icons.palette_rounded,
        color: OneUITheme.accentPurple,
        open: AppearanceSettingsScreen.open,
        keywords: ['theme', 'style', 'customise', 'customize', 'look'],
        options: [
          (
            title: '3D floating elements',
            keywords: ['3d', 'effects', 'navigation bar', 'glass', 'depth'],
            placeholder: false,
          ),
          (
            title: 'Subscription cards',
            keywords: ['card studio', 'price display', 'renewal badge', 'chips'],
            placeholder: false,
          ),
          (title: 'Subscription details', keywords: ['icons', 'highlight', 'detail screen'], placeholder: false),
          (title: 'Reset appearance', keywords: ['defaults'], placeholder: false),
        ],
      ),
      SettingsDestination(
        title: PlannedFeature.widgets.title,
        description: 'Home screen widgets',
        icon: PlannedFeature.widgets.icon,
        color: OneUITheme.accentAmber,
        open: (context) => ComingSoonScreen.open(context, PlannedFeature.widgets),
        soon: true,
        keywords: ['home screen'],
      ),
    ],
    [
      SettingsDestination(
        title: 'Security & privacy',
        description: "Privacy policy • What's collected",
        icon: Icons.shield_rounded,
        color: OneUITheme.accentBlue,
        open: SecuritySettingsScreen.open,
        options: [
          (
            title: PlannedFeature.appLock.title,
            keywords: ['fingerprint', 'biometric', 'pin', 'password'],
            placeholder: true,
          ),
          (title: 'Privacy policy', keywords: ['data', 'policy'], placeholder: false),
        ],
      ),
      SettingsDestination(
        title: 'Backup & data',
        description: 'Backup • Restore • Export',
        icon: Icons.cloud_rounded,
        color: OneUITheme.accentTeal,
        open: BackupDataScreen.open,
        keywords: ['storage', 'backup'],
        options: [
          (title: 'Save backup to device', keywords: ['backup', 'save', 'json', 'file'], placeholder: false),
          (title: 'Restore from backup', keywords: ['restore', 'import', 'load'], placeholder: false),
          (
            title: PlannedFeature.driveBackup.title,
            keywords: ['cloud', 'drive', 'automatic'],
            placeholder: true,
          ),
          (title: 'Export & share', keywords: ['csv', 'spreadsheet', 'pdf', 'report', 'excel'], placeholder: false),
          (title: 'Clear all subscriptions', keywords: ['delete', 'erase', 'reset'], placeholder: false),
        ],
      ),
    ],
    [
      SettingsDestination(
        title: 'Software update',
        description: 'Check for updates • Changelog',
        icon: Icons.system_update_rounded,
        color: OneUITheme.accentBlue,
        open: SoftwareUpdateScreen.open,
        keywords: ['update', 'upgrade', 'new version', 'play store'],
        badge: () => UpdateController.instance.updateAvailable,
        options: [
          (title: 'Check for updates', keywords: ['software update', 'download', 'install'], placeholder: false),
          (title: 'Auto download', keywords: ['auto check', 'automatic', 'wi-fi', 'wifi', 'mobile data'], placeholder: false),
          (title: 'Software information', keywords: ['version', 'build', 'android'], placeholder: false),
          (
            title: 'Changelog',
            keywords: ["what's new", 'whats new', 'release notes', 'last update'],
            placeholder: false,
          ),
        ],
      ),
      SettingsDestination(
        title: 'Help & feedback',
        description: 'Send feedback • Report a problem • Rate',
        icon: Icons.help_rounded,
        color: OneUITheme.textTertiary,
        open: HelpFeedbackScreen.open,
        keywords: ['support', 'contact'],
        options: [
          (title: 'Send feedback', keywords: ['email', 'contact'], placeholder: false),
          (title: 'Report a problem', keywords: ['bug', 'issue'], placeholder: false),
          (
            title: 'Feedback on GitHub',
            keywords: ['github', 'issues', 'bug', 'feature request', 'suggest'],
            placeholder: false,
          ),
          (title: 'Rate One Spend', keywords: ['rating', 'review', 'stars', 'play store'], placeholder: false),
        ],
      ),
      SettingsDestination(
        title: 'About One Spend',
        description: 'Version • Licences • Developer',
        icon: Icons.info_rounded,
        color: OneUITheme.textTertiary,
        open: AboutScreen.open,
        keywords: ['app info'],
        options: [
          (title: 'Developer', keywords: ['author', 'made by'], placeholder: false),
          (title: 'Open source licences', keywords: ['licenses', 'legal'], placeholder: false),
        ],
      ),
    ],
    if (developerOptions)
      [
        SettingsDestination(
          title: 'Developer options',
          description: 'Test notifications • Sample data',
          icon: Icons.code_rounded,
          color: OneUITheme.textTertiary,
          open: DeveloperOptionsScreen.open,
          keywords: ['debug'],
          options: [
            (title: 'Send test notification now', keywords: ['notification'], placeholder: false),
            (title: 'Pending notifications', keywords: ['scheduled'], placeholder: false),
            (title: 'Load sample subscriptions', keywords: ['demo', 'catalog'], placeholder: false),
            (title: 'Restore dismissed tips', keywords: ['insights'], placeholder: false),
          ],
        ),
      ],
  ];

  /// Rows and subpage options matching [query] (case-insensitive), rows first.
  static List<SettingsSearchResult> search(String query, {required bool developerOptions}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    bool hit(String title, List<String> keywords) =>
        title.toLowerCase().contains(q) || keywords.any((k) => k.toLowerCase().contains(q));

    final rows = <SettingsSearchResult>[];
    final options = <SettingsSearchResult>[];
    for (final group in groups(developerOptions: developerOptions)) {
      for (final d in group) {
        if (hit(d.title, d.keywords)) rows.add((title: d.title, path: null, destination: d));
        for (final o in d.options) {
          if (o.placeholder && !FeatureFlags.showPlannedFeatures) continue;
          if (hit(o.title, o.keywords)) options.add((title: o.title, path: d.title, destination: d));
        }
      }
    }
    return [...rows, ...options];
  }
}
