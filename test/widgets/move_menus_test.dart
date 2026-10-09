import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/move_subscriptions_screen.dart';
import 'package:onespend/screens/payment_method_picker_screen.dart';
import 'package:onespend/screens/settings/categories_screen.dart';
import 'package:onespend/screens/subscriptions_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    SubscriptionStore.instance.resetForTesting();
  });

  tearDown(OneUIToast.dismiss);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(screen, theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();
  }

  testWidgets('Move to category opens the categories page titled "Move to" and moves the selection', (tester) async {
    final store = SubscriptionStore.instance;
    await pump(tester, const SubscriptionsScreen());
    await tester.longPress(find.text('Netflix').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotify').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to category'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoriesScreen), findsOneWidget);
    expect(find.text('Move to'), findsOneWidget);
    await tester.tap(find.text('Health & Fitness'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    for (final name in ['Netflix', 'Spotify']) {
      expect(store.subscriptions.firstWhere((s) => s.name == name).category, same(SubscriptionCategory.health));
    }
  });

  testWidgets('Move subs: a radio list of the other cards; Save moves them', (tester) async {
    final store = SubscriptionStore.instance;
    final from = store.paymentMethods.firstWhere((m) => store.getSubscriptionsForMethod(m.id).isNotEmpty);
    final subIds = store.getSubscriptionsForMethod(from.id).map((s) => s.id).toList();
    final to = store.paymentMethods.lastWhere((m) => m.id != from.id);

    await pump(tester, const PaymentMethodPickerScreen(isManageOnly: true));
    final row = find.text(from.nickname).last;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.longPress(row);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move subs'));
    await tester.pumpAndSettle();

    expect(find.byType(MoveSubscriptionsScreen), findsOneWidget);
    expect(find.text('No card'), findsNothing); // only when deleting
    expect(find.descendant(of: find.byType(MoveSubscriptionsScreen), matching: find.text(from.displayName)), findsNothing);
    await tester.tap(find.descendant(of: find.byType(MoveSubscriptionsScreen), matching: find.text(to.displayName)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();

    for (final id in subIds) {
      expect(store.getSubscription(id)!.paymentMethodId, to.id);
    }
    expect(store.paymentMethods.any((m) => m.id == from.id), isTrue); // moving keeps the card
  });

  testWidgets('Move to page: Cancel changes nothing', (tester) async {
    final store = SubscriptionStore.instance;
    final from = store.paymentMethods.firstWhere((m) => store.getSubscriptionsForMethod(m.id).isNotEmpty);
    final before = {for (final s in store.subscriptions) s.id: s.paymentMethodId};
    PaymentMethod? result = PaymentMethod.none;
    await pump(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => result = await MoveSubscriptionsScreen.open(context, fromIds: {from.id}),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect({for (final s in store.subscriptions) s.id: s.paymentMethodId}, before);
  });
}
