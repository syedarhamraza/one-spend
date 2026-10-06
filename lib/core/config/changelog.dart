/// Release notes shown on Settings › Software update › Changelog, newest first.
///
/// `tool/release.ps1` adds an entry for each new version name in pubspec.yaml; fill in
/// its changes before uploading. Notes can also be written ahead as an
/// [Changelog.inDevelopment] entry for the next version. A test checks that the newest
/// released entry matches pubspec.
/// Several uploads of the same name (`-Rebuild`) share one entry.
class ChangelogEntry {
  /// The version name from pubspec.yaml, e.g. `1.0.0-beta.1` (see [AppVersion]).
  final String version;

  /// Release date as shown to users (e.g. "Oct 2026"), or a status like "In development".
  final String date;
  final List<String> changes;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
  });
}

class Changelog {
  const Changelog._();

  /// Date of notes written ahead of their release. `tool/release.ps1` stamps the month
  /// when it releases that version, so entries spell it out as a quoted string.
  static const String inDevelopment = 'In development';

  static const List<ChangelogEntry> entries = [
    ChangelogEntry(
      version: '1.0.0-alpha.4',
      date: 'In development', // tool/release.ps1 looks for a quoted date to stamp
      changes: [
        'New Software update page in Settings, in the style of One UI: check for updates and install them in one tap',
        'Choose when One Spend checks for updates on its own: never, on Wi-Fi only, or on Wi-Fi or mobile data',
        "What's new is now Changelog, under Software update: your installed version first, earlier versions tap to open",
        'See your version, build and where One Spend was installed from in Software update › Software information',
        'About is simpler: just the developer, open source licences and the privacy policy',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-alpha.3',
      date: 'Oct 2026',
      changes: [
        'Read the privacy policy from Settings › About or Settings › Security & privacy',
        'Security & privacy now explains what data One Spend collects and what it never sends',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-alpha.2',
      date: 'Oct 2026',
      changes: [
        'New name and icon: OneSpend is now One Spend',
        'Faster subscription list, and PDF reports no longer freeze the app while they are made',
        'Improved performance and stability',
        'Smaller download and install size',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-alpha.1',
      date: 'In development',
      changes: [
        'Backup to a file and restore, with automatic restore points you can go back to',
        'Check for updates from Google Play',
        'Crash reports and anonymous usage statistics help fix bugs faster (never your subscription details)',
        'Send feedback and problem reports with your app version and phone filled in',
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
