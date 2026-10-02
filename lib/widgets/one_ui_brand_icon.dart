import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../utils/logo_image_cache.dart';
import '../utils/one_ui_brand_catalog.dart';

/// A subscription's icon: a rounded square in its colour showing, in order of
/// preference, the user's own image ([logoUrl]), a chosen system glyph, or initials
/// (the service's short form like "NF", else the name's initials).
///
/// No third-party logos ship with the app: brand marks only appear when the user
/// adds an image themselves.
class OneUIBrandIcon extends StatelessWidget {
  final Subscription? subscription;
  final String? name;
  final Color? brandColor;
  final IconData? iconData;
  final String? logoUrl;
  final String? brandPresetId;
  final double size;
  final double? borderRadius;

  /// Framing for a custom [logoUrl] image; defaults to the subscription's.
  final LogoTransform? logoTransform;

  const OneUIBrandIcon({
    super.key,
    this.subscription,
    this.name,
    this.brandColor,
    this.iconData,
    this.logoUrl,
    this.brandPresetId,
    this.size = 44,
    this.borderRadius,
    this.logoTransform,
  });

  @override
  Widget build(BuildContext context) {
    final subName = subscription?.name ?? name ?? 'Service';
    final effectiveLogoUrl = subscription?.logoUrl ?? logoUrl;
    final effectivePresetId = subscription?.brandPresetId ?? brandPresetId;
    final explicitIcon = iconData ?? (subscription?.iconCodePoint != null ? subscription?.iconData : null);

    final preset = (effectivePresetId != null && effectivePresetId != '__none__')
        ? OneUIBrandCatalog.findById(effectivePresetId)
        : (effectivePresetId == '__none__' || explicitIcon != null || (effectiveLogoUrl != null && effectiveLogoUrl.isNotEmpty))
            ? null
            : OneUIBrandCatalog.findPreset(subName);

    final effectiveColor = subscription?.brandColor ??
        brandColor ??
        (preset != null ? preset.color : OneUIBrandCatalog.getMonogramColor(subName));

    final effectiveRadius = borderRadius ?? (size * 0.32);

    // Keep glyphs legible on any background, including white: the preset's own
    // text colour on its own colour, otherwise dark-on-light / white-on-dark.
    final foreground = (preset != null && effectiveColor.toARGB32() == preset.color.toARGB32())
        ? preset.textColor
        : OneUIBrandCatalog.foregroundOn(effectiveColor);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: _buildInnerContent(context, subName, preset, effectiveLogoUrl, effectivePresetId, explicitIcon, foreground),
    );
  }

  Widget _buildInnerContent(
    BuildContext context,
    String subName,
    BrandPreset? preset,
    String? effectiveLogoUrl,
    String? effectivePresetId,
    IconData? explicitIcon,
    Color foreground,
  ) {
    // 1. Network image logo if provided (takes absolute precedence when custom URL is specified)
    if (effectiveLogoUrl != null && effectiveLogoUrl.isNotEmpty) {
      final framing = logoTransform ?? subscription?.logoTransform;
      // One shared, disk-cached decode per URL (see LogoImageCache): resizing,
      // zooming or another screen showing the same logo never refetches it.
      final image = Image(
        image: LogoImageCache.provider(effectiveLogoUrl),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(subName, preset, explicitIcon, foreground),
        // The fallback shows only until the very first download arrives.
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
            frame == null && !wasSynchronouslyLoaded ? _buildFallback(subName, preset, explicitIcon, foreground) : child,
      );
      // The editor's zoom and offset, applied inside the icon's clipped square.
      return Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: framing == null || framing.isIdentity
            ? image
            : Transform.translate(
                offset: Offset(framing.dx * size, framing.dy * size),
                child: Transform.scale(scale: framing.scale, child: image),
              ),
      );
    }

    // 2. If explicitly opted out of brand preset (effectivePresetId == '__none__'),
    // render explicit icon or dynamic monogram without SVG brand matching
    if (effectivePresetId == '__none__') {
      return _buildFallback(subName, null, explicitIcon, foreground);
    }

    return _buildFallback(subName, preset, explicitIcon, foreground);
  }

  Widget _buildFallback(String subName, BrandPreset? preset, IconData? explicitIcon, Color foreground) {
    // 1. Curated brand preset monogram or icon
    if (preset != null && preset.monogram.isNotEmpty) {
      return Center(
        child: Text(
          preset.monogram,
          style: TextStyle(
            color: foreground,
            fontSize: size * 0.40,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      );
    }

    // 2. Subscription IconData if explicit
    final effectiveIcon = explicitIcon ?? subscription?.iconData ?? iconData ?? preset?.icon;
    if (effectiveIcon != null && effectiveIcon != Icons.subscriptions_rounded) {
      return Icon(
        effectiveIcon,
        color: foreground,
        size: size * 0.52,
      );
    }

    // 3. Dynamic styled monogram
    final monogram = OneUIBrandCatalog.getMonogram(subName);
    return Center(
      child: Text(
        monogram,
        style: TextStyle(
          color: foreground,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
