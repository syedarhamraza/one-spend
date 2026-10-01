/// Release notes shown on Settings › About › What's new, newest first.
///
/// When you bump `version:` in pubspec.yaml, add an entry here with the same
/// version so the app and its notes stay in step.
class ChangelogEntry {
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
      version: '1.0.0',
      date: 'In development',
      changes: [
        'Track subscriptions with renewal reminders, budgets and spending insights',
        'Multiple currencies with exchange rates and main-currency totals',
        'Backup to a file and restore, with restore points',
        'One UI 8.5 glass with an optional 3D look',
        'Selection mode that morphs the header and nav bar in place',
        'Undo an accidental Renew',
      ],
    ),
  ];
}

/// Build details passed in at build time (see tool/build.ps1). Empty in plain
/// `flutter run` builds.
class BuildInfo {
  const BuildInfo._();

  /// Short git commit the build was made from.
  static const String commit = String.fromEnvironment('GIT_SHA');
}
