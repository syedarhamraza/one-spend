import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/features/pro/data/purchase_service.dart';
import 'package:onespend/features/pro/domain/pro_product.dart';
import 'package:onespend/features/pro/presentation/pro_controller.dart';
import 'package:onespend/features/settings/data/datasources/settings_drift_datasource.dart';
import 'package:onespend/features/settings/data/repositories/settings_repository_impl.dart';

class FakePurchaseService implements PurchaseService {
  final controller = StreamController<List<ProPurchaseEvent>>.broadcast();
  bool? owns;
  String? price = '\$4.99';
  int buys = 0;
  int restores = 0;

  void emit(ProPurchaseStatus status, {String productId = proProductId}) =>
      controller.add([(productId: productId, status: status)]);

  @override
  Stream<List<ProPurchaseEvent>> get updates => controller.stream;

  @override
  Future<String?> loadPriceLabel() async => price;

  @override
  Future<void> buy() async => buys++;

  @override
  Future<void> restore() async => restores++;

  @override
  Future<bool?> ownsPro() async => owns;
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late FakePurchaseService store;

  ProController build() => ProController(
        purchases: store,
        settings: SettingsRepositoryImpl(SettingsDriftDataSource(db)),
      );

  // Lets init()'s background refresh and stream deliveries run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = FakePurchaseService();
  });

  tearDown(() async {
    await store.controller.close();
    await db.close();
  });

  test('starts locked and loads the price', () async {
    final pro = build();
    await pro.init();
    await settle();
    expect(pro.isPro, isFalse);
    expect(pro.priceLabel, '\$4.99');
  });

  test('a purchase unlocks Pro and survives a restart', () async {
    final pro = build();
    await pro.init();
    final messages = <String>[];
    pro.messages.listen(messages.add);

    store.emit(ProPurchaseStatus.purchased);
    await settle();
    await settle();
    expect(pro.isPro, isTrue);
    expect(messages, contains('Pro unlocked. Thank you!'));

    final again = build();
    await again.init();
    expect(again.isPro, isTrue);
  });

  test('a pending purchase or another product does not unlock', () async {
    final pro = build();
    await pro.init();
    store.emit(ProPurchaseStatus.pending);
    store.emit(ProPurchaseStatus.purchased, productId: 'something_else');
    await settle();
    expect(pro.isPro, isFalse);
  });

  test('Play reporting Pro owned (e.g. a redeemed promo code) unlocks it', () async {
    store.owns = true;
    final pro = build();
    await pro.init();
    await settle();
    expect(pro.isPro, isTrue);
  });

  test('a refund revokes Pro, but an unreachable store keeps it', () async {
    final pro = build();
    await pro.init();
    store.emit(ProPurchaseStatus.purchased);
    await settle();
    await settle();
    expect(pro.isPro, isTrue);

    store.owns = null;
    await pro.refresh();
    expect(pro.isPro, isTrue);

    store.owns = false;
    await pro.refresh();
    expect(pro.isPro, isFalse);

    final again = build();
    await again.init();
    expect(again.isPro, isFalse);
  });

  test('restore reports whether Pro was found', () async {
    final pro = build();
    await pro.init();
    final messages = <String>[];
    pro.messages.listen(messages.add);

    store.owns = false;
    await pro.restore();
    await settle();
    expect(store.restores, 1);
    expect(pro.isPro, isFalse);
    expect(messages.last, 'No Pro purchase found on this Google account');

    store.owns = true;
    await pro.restore();
    await settle();
    expect(pro.isPro, isTrue);
    expect(messages.last, 'Pro restored');
    expect(pro.busy, isFalse);
  });

  test('debugOverride forces Pro on and off', () async {
    final pro = build();
    await pro.init();
    pro.debugOverride = true;
    expect(pro.isPro, isTrue);
    pro.debugOverride = null;
    expect(pro.isPro, isFalse);
  });
}
