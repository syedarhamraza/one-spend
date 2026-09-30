import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    SubscriptionStore.instance.resetForTesting();
  });

  /// Pumps the detail screen on a 360x800 dp phone and fails on any layout overflow.
  Future<void> pumpNarrow(WidgetTester tester, Subscription sub) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(SubscriptionDetailScreen(subscription: sub), theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();

    // Scroll through the whole page so every section is laid out.
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 12; i++) {
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  }

  testWidgets('detail screen fits a 360dp phone with default data', (tester) async {
    final store = SubscriptionStore.instance;
    await pumpNarrow(tester, store.subscriptions.first);
  });

  testWidgets('detail screen fits a 360dp phone with a larger system font size', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpNarrow(tester, SubscriptionStore.instance.subscriptions.first);
  });

  testWidgets('detail screen fits a 360dp phone with long names and a long card name', (tester) async {
    final store = SubscriptionStore.instance;
    final card = store.paymentMethods.first;
    final sub = store.subscriptions.first.copyWith(
      name: 'Adobe Creative Cloud All Apps Plan for Teams',
      price: 12345.67,
      paymentMethodId: card.id,
      paymentMethod: card.displayName,
      paymentHistory: [DateTime(2026, 8, 12), DateTime(2026, 9, 12)],
    );
    store.updateSubscription(sub);
    await pumpNarrow(tester, store.getSubscription(sub.id)!);
  });
}
