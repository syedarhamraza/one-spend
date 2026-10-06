/// Static app and author details shown on the About, Developer and Help & feedback pages.
class AppInfo {
  const AppInfo._();

  static const String name = 'One Spend';
  static const String logoAsset = 'assets/logos/app_logo.png';

  /// Android application id, also the Play Store listing id.
  static const String packageId = 'com.syedarhamraza.onespend';

  /// The Play Store listing, in the Play Store app.
  static const String playStoreMarketUrl = 'market://details?id=$packageId';

  /// The Play Store listing on the web, for phones without the Play Store app.
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageId';

  /// Public issue tracker for feedback, bug reports and feature requests.
  static const String feedbackRepoUrl = 'https://github.com/syedarhamraza/one-spend-feedback/issues';

  /// Public policy page (source: docs/privacy-policy.md, published by the website repo).
  static const String privacyPolicyUrl = 'https://syedarhamraza.github.io/privacy/';
}

class AuthorInfo {
  const AuthorInfo._();

  static const String name = 'Syed Arham Raza';
  static const String email = 'arhamraza399@gmail.com';
  static const String githubUsername = 'syedarhamraza';

  static String get githubUrl => 'https://github.com/$githubUsername';
}
