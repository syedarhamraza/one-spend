import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../domain/pro_product.dart';
import 'purchase_service.dart';

/// Google Play Billing via `in_app_purchase`.
class PlayPurchaseService implements PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  ProductDetails? _product;

  @override
  late final Stream<List<ProPurchaseEvent>> updates = _iap.purchaseStream.asyncMap((purchases) async {
    final events = <ProPurchaseEvent>[];
    for (final p in purchases) {
      // Play refunds a purchase that isn't acknowledged within 3 days.
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (e) {
          debugPrint('OneSpend: completePurchase failed: $e');
        }
      }
      events.add((productId: p.productID, status: _status(p.status)));
    }
    return events;
  });

  static ProPurchaseStatus _status(PurchaseStatus status) => switch (status) {
    PurchaseStatus.pending => ProPurchaseStatus.pending,
    PurchaseStatus.purchased => ProPurchaseStatus.purchased,
    PurchaseStatus.restored => ProPurchaseStatus.restored,
    PurchaseStatus.error => ProPurchaseStatus.error,
    PurchaseStatus.canceled => ProPurchaseStatus.canceled,
  };

  Future<ProductDetails?> _loadProduct() async {
    if (_product != null) return _product;
    if (!await _iap.isAvailable()) return null;
    final response = await _iap.queryProductDetails({proProductId});
    if (response.productDetails.isEmpty) return null;
    return _product = response.productDetails.first;
  }

  @override
  Future<String?> loadPriceLabel() async {
    try {
      return (await _loadProduct())?.price;
    } catch (e) {
      debugPrint('OneSpend: Pro price unavailable: $e');
      return null;
    }
  }

  @override
  Future<void> buy() async {
    final product = await _loadProduct();
    if (product == null) throw StateError('Pro is not available from Google Play right now');
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<bool?> ownsPro() async {
    try {
      if (!await _iap.isAvailable()) return null;
      final android = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await android.queryPastPurchases();
      final owned = response.pastPurchases.any(
        (p) => p.productID == proProductId && p.status == PurchaseStatus.purchased,
      );
      if (owned) return true;
      return response.error == null ? false : null;
    } catch (e) {
      debugPrint('OneSpend: Couldn\'t check Pro ownership: $e');
      return null;
    }
  }
}
