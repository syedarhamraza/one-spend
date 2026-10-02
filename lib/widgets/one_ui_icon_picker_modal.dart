import 'package:flutter/widgets.dart';

import '../features/subscriptions/domain/entities/logo_transform.dart';

/// What the icon picker returns: colour, glyph, the user's own image (if any)
/// and the preset used for initials.
class IconPickerResult {
  final IconData iconData;
  final Color brandColor;
  final String? logoUrl;
  final String? brandPresetId;

  /// Framing of a custom [logoUrl] image from the image editor.
  final LogoTransform? logoTransform;

  const IconPickerResult({
    required this.iconData,
    required this.brandColor,
    this.logoUrl,
    this.brandPresetId,
    this.logoTransform,
  });
}
