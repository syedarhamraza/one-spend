import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/payment_method.dart';

/// Samsung One UI Payment Brand Badge / Icon
/// - Renders official vector SVG from Datatrans payment-logos library
/// - Preserves card aspect ratio (3:2 standard payment card ratio)
/// - Graceful fallback to Material Icon if SVG fails or brand is custom
class OneUIPaymentBrandIcon extends StatelessWidget {
  final CardBrand brand;
  final double width;
  final double height;
  final double? borderRadius;
  final bool showShadow;

  const OneUIPaymentBrandIcon({
    super.key,
    required this.brand,
    this.width = 44,
    this.height = 30,
    this.borderRadius,
    this.showShadow = false,
  });

  /// Square avatar icon helper (e.g. for selection circles or compact rows)
  const OneUIPaymentBrandIcon.square({
    super.key,
    required this.brand,
    double size = 36,
    this.borderRadius,
    this.showShadow = false,
  })  : width = size,
        height = size;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? (height * 0.22);
    final assetPath = brand.assetPath;

    Widget content;
    if (assetPath != null && assetPath.isNotEmpty) {
      content = SvgPicture.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => _buildFallback(),
      );
    } else {
      content = _buildFallback();
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: content,
    );
  }

  Widget _buildFallback() {
    return Container(
      color: brand.defaultColor,
      alignment: Alignment.center,
      child: Icon(
        brand.icon,
        size: height * 0.55,
        color: Colors.white,
      ),
    );
  }
}
