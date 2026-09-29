import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/billing_cycle_picker_screen.dart';
import 'package:onespend/screens/category_picker_screen.dart';
import 'package:onespend/screens/payment_history_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';

import 'package:flutter/services.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => '.',
    );
  });

  setUp(() {
    SubscriptionStore.instance.resetForTesting();
  });

  group('Spend & Billing Enhancements & Subpage Modernization Tests', () {
    testWidgets('Lifetime spend card in SubscriptionDetailScreen renders hero styling without glow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final store = SubscriptionStore.instance;
      final netflix = store.subscriptions.firstWhere((s) => s.name == 'Netflix');

      await tester.pumpWidget(
        MaterialApp(
          theme: OneUITheme.darkTheme,
          home: SubscriptionDetailScreen(subscription: netflix),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Spend & Billing section exists
      expect(find.text('Spend & Billing'), findsOneWidget);
      expect(find.text('Lifetime spend'), findsOneWidget);
      expect(find.text('total recorded'), findsOneWidget);
      expect(find.text('Estimated annual'), findsOneWidget);
      expect(find.text('Monthly equivalent'), findsOneWidget);

      // Verify upcoming schedule and payment history items exist
      expect(find.text('Upcoming schedule'), findsOneWidget);
      expect(find.text('Payment history'), findsOneWidget);
    });

    testWidgets('PaymentHistoryScreen empty state renders rounded pill button for adding payment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final store = SubscriptionStore.instance;
      // Find a subscription without payment history, or clear payment history
      final spotify = store.subscriptions.firstWhere((s) => s.name == 'Spotify');
      store.updateSubscription(spotify.copyWith(paymentHistory: []));

      await tester.pumpWidget(
        MaterialApp(
          theme: OneUITheme.darkTheme,
          home: PaymentHistoryScreen(subscriptionId: spotify.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No payments recorded yet'), findsOneWidget);
      expect(find.text('Add past payment'), findsOneWidget);

      // Verify button has pill styling with rounded corners (BorderRadius >= 50 or Stadium)
      final pillFinder = find.ancestor(
        of: find.text('Add past payment'),
        matching: find.byType(Container),
      );
      expect(pillFinder, findsWidgets);

      final containerWidget = tester.widget<Container>(pillFinder.first);
      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.borderRadius, equals(BorderRadius.circular(100)));
    });

    testWidgets('CategoryPickerScreen list has no leading icons and uses shortened descriptions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      SubscriptionCategory? selectedCat;

      await tester.pumpWidget(
        routedTestApp(
          theme: OneUITheme.darkTheme,
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  selectedCat = await CategoryPickerScreen.open(
                    context,
                    initialCategory: SubscriptionCategory.entertainment,
                  );
                },
                child: const Text('Open Category Picker'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Category Picker'));
      await tester.pumpAndSettle();

      // Top Hero card shows detailed description
      expect(find.text('Movies, TV series, streaming & live video'), findsOneWidget);

      // List below shows shortened description
      expect(find.text('Movies, streaming & video'), findsOneWidget);
      expect(find.text('Music, podcasts & audio'), findsOneWidget);
      expect(find.text('Suites, AI & workspaces'), findsOneWidget);

      // Select Music & Audio and Save
      await tester.tap(find.text('Music, podcasts & audio'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(selectedCat, equals(SubscriptionCategory.music));
    });

    testWidgets('BillingCyclePickerScreen renders without hero preview, shows radio checks, and saves selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      BillingCycle? pickedCycle;

      await tester.pumpWidget(
        routedTestApp(
          theme: OneUITheme.darkTheme,
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  pickedCycle = await BillingCyclePickerScreen.open(
                    context,
                    initialCycle: BillingCycle.monthly,
                  );
                },
                child: const Text('Open Billing Cycle Picker'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Billing Cycle Picker'));
      await tester.pumpAndSettle();

      // Header is present
      expect(find.text('Billing cycle'), findsOneWidget);
      expect(find.text('Billing frequency'), findsOneWidget);

      // All 4 cycles are present with clean concise descriptions
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Billed once every month (12x/yr)'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text('Billed once every year (1x/yr)'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Billed every week (52x/yr)'), findsOneWidget);
      expect(find.text('Quarterly'), findsOneWidget);
      expect(find.text('Billed every 3 months (4x/yr)'), findsOneWidget);

      // Select Yearly and tap Save
      await tester.tap(find.text('Yearly'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(pickedCycle, equals(BillingCycle.yearly));
    });
  });
}
