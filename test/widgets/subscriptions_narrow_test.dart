import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/main.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/home_screen.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets('the Spend list lays out without overflow on a 360dp phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    HomeChrome.reset();
    final store = SubscriptionStore.instance..resetForTesting();
    // A card that expires soon shows the "Card expiring" badge next to its name.
    final card = store.paymentMethods.first;
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final yy = (now.year % 100).toString().padLeft(2, '0');
    store.updatePaymentMethod(card.copyWith(expiryDate: '$mm/$yy'));

    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -500), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
