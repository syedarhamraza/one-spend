/// Release notes shown on Settings › About › What's new, newest first.
///
/// `tool/release.ps1` adds an entry for each new version name in pubspec.yaml; fill in
/// its changes before uploading. A test checks that the newest entry matches pubspec.
/// Several uploads of the same name (`-Rebuild`) share one entry.
class ChangelogEntry {
  /// The version name from pubspec.yaml, e.g. `1.0.0-beta.1` (see [AppVersion]).
  final String version;

  /// Release date as shown to users (e.g. "Oct 2026"), or a status like "In development".
  final String date;
  final List<String> changes;

  const ChangelogEntry({required this.version, required this.date, required this.changes});
}

class Changelog {
  const Changelog._();

  static const List<ChangelogEntry> entries = [
    ChangelogEntry(
      version: '1.0.0-alpha.1',
      date: 'In development',
      changes: [
        'Track subscriptions with renewal reminders, budgets and spending insights',
        'Multiple currencies with exchange rates and main-currency totals',
        'Backup to a file and restore, with automatic restore points you can go back to',
        'Custom categories, annual plan savings and a year-end projection',
        'Check for updates from Google Play in Settings › About',
        'Crash reports and anonymous usage statistics help fix bugs faster (never your subscription details)',
        'Send feedback and problem reports with your app version and phone filled in',
        'One UI 8.5 glass with an optional 3D look',
        'Selection mode that morphs the header and nav bar in place',
        'Undo an accidental Renew',
      ],
    ),
  ];
}

/// Build details passed in at build time (see tool/release.ps1). Empty in plain
/// `flutter run` builds.
class BuildInfo {
  const BuildInfo._();

  /// Short git commit the build was made from.
  static const String commit = String.fromEnvironment('GIT_SHA');
}
