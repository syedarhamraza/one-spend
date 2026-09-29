import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/core/router/app_router.dart';
import 'package:onespend/main.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/analytics_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/screens/subscriptions_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpRouter(WidgetTester tester, String location) async {
  await tester.pumpWidget(MaterialApp.router(
    theme: OneUITheme.darkTheme,
    routerConfig: createAppRouter(initialLocation: location),
  ));
  await tester.pumpAndSettle();
}

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

  tearDown(() {
    OneUIToast.dismiss();
  });

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('deep link to a subscription id opens its detail page', (tester) async {
    useTallSurface(tester);
    final netflix = SubscriptionStore.instance.subscriptions.firstWhere((s) => s.name == 'Netflix');

    await _pumpRouter(tester, AppRoutes.subscriptionDetail(netflix.id));

    final detail = tester.widget<SubscriptionDetailScreen>(find.byType(SubscriptionDetailScreen));
    expect(detail.subscription.id, netflix.id);
  });

  testWidgets('unknown subscription id shows the not-found fallback', (tester) async {
    useTallSurface(tester);
    await _pumpRouter(tester, AppRoutes.subscriptionDetail('does_not_exist'));

    expect(find.text('This subscription no longer exists'), findsOneWidget);
    expect(find.byType(SubscriptionDetailScreen), findsNothing);
  });

  testWidgets('card-filtered subscriptions route opens a filtered list', (tester) async {
    useTallSurface(tester);
    final card = SubscriptionStore.instance.paymentMethods.first;

    await _pumpRouter(tester, AppRoutes.methodSubscriptions(card.id));

    final screen = tester.widget<SubscriptionsScreen>(find.byType(SubscriptionsScreen));
    expect(screen.filterPaymentMethodId, card.id);
  });

  testWidgets('tapping a subscription pushes detail and system back returns to the list', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Netflix').first);
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionDetailScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionDetailScreen), findsNothing);
    expect(find.byType(SubscriptionsScreen), findsOneWidget);
  });

  testWidgets('system back on a secondary tab returns to the Spend tab', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.byType(AnalyticsScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionsScreen).hitTestable(), findsOneWidget);
    expect(find.byType(AnalyticsScreen).hitTestable(), findsNothing);
  });
}
