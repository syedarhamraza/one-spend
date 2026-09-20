import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../utils/one_ui_brand_catalog.dart';

/// Samsung One UI Squircle Brand & Service Icon
/// - Renders company logo if image URL is available (with safe inner padding & contain fit)
/// - Renders curated brand preset monogram / icon
/// - Renders dynamic monogram for custom services
/// - Uses smooth rounded squircle geometry with subtle rim border
class OneUIBrandIcon extends StatelessWidget {
  final Subscription? subscription;
  final String? name;
  final Color? brandColor;
  final IconData? iconData;
  final String? logoUrl;
  final String? brandPresetId;
  final double size;
  final double? borderRadius;

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
  });

  @override
  Widget build(BuildContext context) {
    final subName = subscription?.name ?? name ?? 'Service';
    final effectiveLogoUrl = subscription?.logoUrl ?? logoUrl;
    final effectivePresetId = subscription?.brandPresetId ?? brandPresetId;
    final preset = OneUIBrandCatalog.findById(effectivePresetId) ?? OneUIBrandCatalog.findPreset(subName);

    final effectiveColor = subscription?.brandColor ??
        brandColor ??
        (preset != null ? preset.color : OneUIBrandCatalog.getMonogramColor(subName));

    final effectiveRadius = borderRadius ?? (size * 0.32);

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
      child: _buildInnerContent(subName, preset, effectiveLogoUrl),
    );
  }

  Widget _buildInnerContent(String subName, BrandPreset? preset, String? effectiveLogoUrl) {
    // 1. Network image logo if provided
    if (effectiveLogoUrl != null && effectiveLogoUrl.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: Image.network(
          effectiveLogoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallback(subName, preset),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallback(subName, preset);
          },
        ),
      );
    }

    return _buildFallback(subName, preset);
  }

  Widget _buildFallback(String subName, BrandPreset? preset) {
    // 2. Curated brand preset monogram or icon
    if (preset != null && preset.monogram.isNotEmpty && preset.monogram != '') {
      return Center(
        child: Text(
          preset.monogram,
          style: TextStyle(
            color: preset.textColor,
            fontSize: size * 0.40,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      );
    }

    // 3. Subscription IconData if explicit
    final effectiveIcon = subscription?.iconData ?? iconData ?? preset?.icon;
    if (effectiveIcon != null && effectiveIcon != Icons.subscriptions_rounded) {
      return Icon(
        effectiveIcon,
        color: Colors.white,
        size: size * 0.52,
      );
    }

    // 4. Dynamic styled monogram
    final monogram = OneUIBrandCatalog.getMonogram(subName);
    return Center(
      child: Text(
        monogram,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
