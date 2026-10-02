import 'package:flutter/material.dart';
import '../utils/one_ui_brand_catalog.dart';
import '../models/payment_method.dart';

/// A payment method's badge: a tile in the network's colour with a generic card
/// or wallet glyph. The network's name is shown as text next to it; no company
/// logos ship with the app.
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: brand.defaultColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
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
      alignment: Alignment.center,
      child: Icon(brand.icon, size: height * 0.55, color: OneUIBrandCatalog.foregroundOn(brand.defaultColor)),
    );
  }
}
