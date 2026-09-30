/// Static app and author details shown on the About and Developer pages.
///
/// Fill in the empty author fields; rows whose value is empty are hidden automatically.
class AppInfo {
  const AppInfo._();

  static const String name = 'OneSpend';
  static const String tagline = 'Track every subscription, in the style of One UI.';
  static const String logoAsset = 'assets/logos/app_logo.png';

  static const String repositoryUrl = 'https://github.com/syedarhamraza/one-spend';
  static const String issuesUrl = '$repositoryUrl/issues';
}

class AuthorInfo {
  const AuthorInfo._();

  static const String name = 'Syed Arham Raza';

  /// e.g. "Flutter developer".
  static const String role = 'Flutter developer';

  /// One or two sentences about you.
  static const String bio = '';

  /// e.g. "Karachi, Pakistan".
  static const String location = '';

  /// Optional photo, e.g. 'assets/author.jpg' (add it to pubspec assets). Initials are shown otherwise.
  static const String photoAsset = '';

  static const String email = 'arhamraza399@gmail.com';
  static const String githubUsername = 'syedarhamraza';

  /// Full profile URL, e.g. 'https://www.linkedin.com/in/your-handle'.
  static const String linkedInUrl = '';

  /// Portfolio or personal site, e.g. 'https://your.site'.
  static const String websiteUrl = '';

  static String get githubUrl => githubUsername.isEmpty ? '' : 'https://github.com/$githubUsername';

  static String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
