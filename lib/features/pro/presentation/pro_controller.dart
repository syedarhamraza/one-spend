import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/di/injection.dart';
import '../../settings/domain/repositories/settings_repository.dart';
import '../data/purchase_service.dart';
import '../domain/pro_product.dart';

/// The OneSpend Pro entitlement. Google Play is the source of truth; the result is cached
/// in settings so Pro works offline and from the first frame.
class ProController extends ChangeNotifier {
  final PurchaseService purchases;
  final SettingsRepository settings;

  ProController({required this.purchases, required this.settings});

  static ProController get instance {
    if (!sl.isRegistered<ProController>()) {
      setupDependencies();
    }
    return sl<ProController>();
  }

  bool _unlocked = false;
  bool? _debugOverride;
  bool _busy = false;
  String? _priceLabel;
  StreamSubscription<List<ProPurchaseEvent>>? _updates;
  final _messages = StreamController<String>.broadcast();

  /// Whether Pro features are unlocked.
  bool get isPro => _debugOverride ?? _unlocked;

  /// Debug builds only (Developer options, tests): forces Pro on or off; null follows the store.
  bool? get debugOverride => _debugOverride;
  set debugOverride(bool? value) {
    if (!kDebugMode || _debugOverride == value) return;
    _debugOverride = value;
    notifyListeners();
  }

  /// True while a purchase or restore is in flight.
  bool get busy => _busy;

  /// Localised price from the store, once loaded.
  String? get priceLabel => _priceLabel;

  /// Short user-facing results ("Pro unlocked", "Purchase failed") for the Pro screen to toast.
  Stream<String> get messages => _messages.stream;

  /// Loads the cached entitlement, then checks with the store in the background.
  Future<void> init() async {
    try {
      _unlocked = await settings.getProUnlocked();
    } catch (e) {
      debugPrint('OneSpend: Couldn\'t read Pro state: $e');
    }
    await _updates?.cancel();
    _updates = purchases.updates.listen(_onUpdates, onError: (Object e) => _finish('Purchase failed'));
    notifyListeners();
    unawaited(refresh());
  }

  /// Re-checks ownership with the store (start-up, app resume) and fetches the price.
  Future<void> refresh() async {
    final owned = await purchases.ownsPro();
    // Null means the store couldn't be asked: keep what we have.
    if (owned != null) await _setUnlocked(owned);
    final price = await purchases.loadPriceLabel();
    if (price != null && price != _priceLabel) {
      _priceLabel = price;
      notifyListeners();
    }
  }

  Future<void> buy() async {
    if (_busy) return;
    _setBusy(true);
    try {
      await purchases.buy();
    } catch (e) {
      debugPrint('OneSpend: Pro purchase failed to start: $e');
      _finish('Google Play isn\'t available right now');
    }
  }

  Future<void> restore() async {
    if (_busy) return;
    _setBusy(true);
    try {
      await purchases.restore();
      final owned = await purchases.ownsPro();
      if (owned != null) await _setUnlocked(owned);
      _finish(isPro ? 'Pro restored' : 'No Pro purchase found on this Google account');
    } catch (e) {
      debugPrint('OneSpend: Pro restore failed: $e');
      _finish('Couldn\'t reach Google Play');
    }
  }

  Future<void> _onUpdates(List<ProPurchaseEvent> events) async {
    for (final event in events) {
      if (event.productId != proProductId) continue;
      switch (event.status) {
        case ProPurchaseStatus.purchased:
          final wasPro = _unlocked;
          await _setUnlocked(true);
          if (_busy || !wasPro) _finish('Pro unlocked. Thank you!');
        case ProPurchaseStatus.restored:
          await _setUnlocked(true);
        case ProPurchaseStatus.pending:
          _finish('Purchase pending. Pro unlocks when Google Play confirms it');
        case ProPurchaseStatus.error:
          _finish('Purchase failed');
        case ProPurchaseStatus.canceled:
          _finish(null);
      }
    }
  }

  Future<void> _setUnlocked(bool value) async {
    if (_unlocked == value) return;
    _unlocked = value;
    notifyListeners();
    try {
      await settings.setProUnlocked(value);
    } catch (e) {
      debugPrint('OneSpend: Couldn\'t save Pro state: $e');
    }
  }

  void _setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  void _finish(String? message) {
    _setBusy(false);
    if (message != null) _messages.add(message);
  }

  @override
  void dispose() {
    _updates?.cancel();
    _messages.close();
    super.dispose();
  }
}
