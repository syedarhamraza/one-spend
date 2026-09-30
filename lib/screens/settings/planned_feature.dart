import 'package:flutter/material.dart';
import '../../theme/one_ui_theme.dart';

/// Features that have a "Soon" placeholder in Settings. Each opens [ComingSoonScreen].
enum PlannedFeature {
  widgets(
    'Widgets',
    Icons.widgets_rounded,
    OneUITheme.accentPurple,
    'Home screen widgets so you can check what\'s due without opening OneSpend.',
    ['Next renewals at a glance', 'Monthly budget progress', 'Tap a renewal to open it'],
  ),
  appLock(
    'App lock',
    Icons.fingerprint_rounded,
    OneUITheme.accentBlue,
    'Keep your spending private with your fingerprint, face or device PIN.',
    ['Unlock with biometrics', 'Lock when the app goes to the background', 'Hide amounts in the recent apps view'],
  ),
  cloudBackup(
    'Backup & sync',
    Icons.cloud_sync_rounded,
    OneUITheme.accentTeal,
    'Back up to your Google Drive and keep your subscriptions in sync across devices.',
    ['Automatic daily backups', 'Restore on a new phone', 'Sync between devices'],
  ),
  import(
    'Import',
    Icons.file_upload_outlined,
    OneUITheme.accentGreen,
    'Bring your subscriptions in from a file instead of adding them one by one.',
    ['Import a OneSpend backup', 'Import from CSV', 'Preview before importing'],
  ),
  multiCurrency(
    'Multiple currencies',
    Icons.currency_exchange_rounded,
    OneUITheme.accentAmber,
    'Track each subscription in the currency you pay in, with totals converted to your main currency.',
    ['Per-subscription currency', 'Automatic exchange rates', 'Totals in your main currency'],
  ),
  rateApp(
    'Rate OneSpend',
    Icons.star_rounded,
    OneUITheme.accentAmber,
    'Rating will open once OneSpend is on the Play Store.',
    ['Leave a rating and review', 'Share OneSpend with friends'],
  ),
  privacyPolicy(
    'Privacy policy',
    Icons.privacy_tip_rounded,
    OneUITheme.accentTeal,
    'OneSpend keeps everything on your device. It has no account, no ads and no analytics. A full policy will be published with the Play Store release.',
    ['Data stays on your device', 'No tracking or ads', 'You can export or delete everything'],
  );

  final String title;
  final IconData icon;
  final Color color;
  final String message;
  final List<String> highlights;

  const PlannedFeature(this.title, this.icon, this.color, this.message, this.highlights);
}
