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
      version: '1.0.0-beta.1',
      date: 'Oct 2026',
      changes: [
        'One Spend is now in closed beta. Thank you for testing!',
        'Everything from 1.0.0 Alpha 5, now on the beta track',
        'Send feedback or report a problem from Settings › Help & feedback',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-alpha.5',
      date: 'Oct 2026',
      changes: [
        'Updates now download in the background while you keep using One Spend, then install with one tap',
        'Automatic update checks are now off by default; turn them on in Software update › Auto download',
        'Checking for updates shows its result with a smoother animation, and says when you are offline',
        'A cleaner About page, and a simpler Developer page',
        'Rate One Spend and see known issues on GitHub from Help & feedback',
        'The privacy policy opens inside the app',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-alpha.4',
      date: 'Oct 2026',
      changes: [
        'New Software update page in Settings: check for updates and install them in one tap',
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
