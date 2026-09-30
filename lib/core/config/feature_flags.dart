import 'package:flutter/foundation.dart';

/// Build-time switches.
class FeatureFlags {
  const FeatureFlags._();

  /// "Coming soon" and Pro placeholders in Settings. Debug builds only, so release users
  /// see nothing that doesn't work yet. Mutable so tests can cover both modes.
  static bool showPlannedFeatures = kDebugMode;
}
