import 'dart:async';

import '../domain/pro_product.dart';

/// Store boundary for the Pro purchase. Tests and non-Play builds use [NoopPurchaseService].
abstract class PurchaseService {
  /// Purchase updates: new purchases, restores, pending and failed ones.
  Stream<List<ProPurchaseEvent>> get updates;

  /// The localised price of [proProductId] (e.g. "$4.99"), or null when the store can't be reached.
  Future<String?> loadPriceLabel();

  /// Starts the purchase flow. The result arrives on [updates].
  Future<void> buy();

  /// Asks the store to re-send owned purchases on [updates].
  Future<void> restore();

  /// Whether the store currently reports [proProductId] as owned.
  /// Null when the store couldn't be asked, so a network error never revokes Pro.
  Future<bool?> ownsPro();
}

/// No store: nothing is for sale and nothing is owned.
class NoopPurchaseService implements PurchaseService {
  @override
  Stream<List<ProPurchaseEvent>> get updates => const Stream.empty();

  @override
  Future<String?> loadPriceLabel() async => null;

  @override
  Future<void> buy() async {}

  @override
  Future<void> restore() async {}

  @override
  Future<bool?> ownsPro() async => null;
}
