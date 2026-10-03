import 'package:flutter/material.dart';

import '../../theme/one_ui_theme.dart';

/// Features that have a "Soon" placeholder in Settings. Each opens [ComingSoonScreen].
enum PlannedFeature {
  widgets(
    'Widgets',
    Icons.widgets_rounded,
    OneUITheme.accentPurple,
    'Home screen widgets so you can check what\'s due without opening One Spend.',
    ['Next renewals at a glance', 'Monthly budget progress', 'Tap a renewal to open it'],
  ),
  appLock(
    'App lock',
    Icons.fingerprint_rounded,
    OneUITheme.accentBlue,
    'Keep your spending private with your fingerprint, face or device PIN.',
    ['Unlock with biometrics', 'Lock when the app goes to the background', 'Hide amounts in the recent apps view'],
  ),
  driveBackup(
    'Google Drive backup',
    Icons.add_to_drive_rounded,
    OneUITheme.accentTeal,
    'Automatic backups to a private folder in your Google Drive.',
    ['Daily or weekly automatic backups', 'Keeps several versions', 'Restore on a new phone in one tap'],
  ),
  rateApp(
    'Rate One Spend',
    Icons.star_rounded,
    OneUITheme.accentAmber,
    'Rating will open once One Spend is on the Play Store.',
    ['Leave a rating and review', 'Share One Spend with friends'],
  ),
  privacyPolicy(
    'Privacy policy',
    Icons.privacy_tip_rounded,
    OneUITheme.accentTeal,
    'One Spend keeps everything on your device. It has no account, no ads and no analytics. A full policy will be published with the Play Store release.',
    ['Data stays on your device', 'No tracking or ads', 'You can export or delete everything'],
  );

  final String title;
  final IconData icon;
  final Color color;
  final String message;
  final List<String> highlights;

  const PlannedFeature(this.title, this.icon, this.color, this.message, this.highlights);
}
