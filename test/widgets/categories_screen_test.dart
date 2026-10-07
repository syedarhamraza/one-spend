import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/category_editor_screen.dart';
import 'package:onespend/screens/settings/categories_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_card.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    SubscriptionStore.instance.resetForTesting();
    OneUIFloatingModal.isModalOpen.value = false;
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(screen));
    await tester.pumpAndSettle();
  }

  SubscriptionCategory add(String name) => SubscriptionStore.instance
      .addCustomCategory(name: name, iconCodePoint: Icons.pets_rounded.codePoint, colorValue: 0xFF5390F5);

  testWidgets('no categories yet: an empty card, and + in the header makes one', (tester) async {
    await pump(tester, const CategoriesScreen());
    expect(find.byType(OneUIEmptyCard), findsOneWidget);
    expect(find.text('Built in'), findsOneWidget);

    await tester.tap(find.byTooltip('New category'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryEditorScreen), findsOneWidget);
  });

  testWidgets('long-press selects; Delete moves their subscriptions after asking', (tester) async {
    final kids = add('Kids');
    add('Home');
    SubscriptionStore.instance.addSubscription(
      SubscriptionStore.instance.subscriptions.first.copyWith(id: 'kid-sub', category: kids),
    );
    await pump(tester, const CategoriesScreen());

    await tester.longPress(find.text('Kids'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets); // the count pill
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    // Kids has a subscription, so a category to move it to comes first.
    await tester.tap(find.text('Health & Fitness'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 categories?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(SubscriptionStore.instance.customCategories, isEmpty);
    final moved = SubscriptionStore.instance.subscriptions.firstWhere((s) => s.id == 'kid-sub');
    expect(moved.category, same(SubscriptionCategory.health));
    expect(find.byType(OneUIEmptyCard), findsOneWidget);
  });

  testWidgets('⋮ › Reorder saves the new order', (tester) async {
    add('A');
    add('B');
    await pump(tester, const CategoriesScreen());

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reorder'));
    await tester.pumpAndSettle();

    // Drag A's handle below B, in small steps like a finger.
    final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.drag_handle_rounded).first));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(SubscriptionStore.instance.customCategories.map((c) => c.name), ['B', 'A']);
  });

  testWidgets('editor: a palette colour picked under More colours stays in the row', (tester) async {
    await pump(tester, const CategoriesScreen());
    await tester.tap(find.byTooltip('New category'));
    await tester.pumpAndSettle();
    final last = OneUITheme.categorySwatches.last;
    Finder dotOf(Color c) => find.byWidgetPredicate(
          (w) => w is AnimatedContainer && (w.decoration as BoxDecoration?)?.color?.toARGB32() == c.toARGB32(),
        );
    expect(dotOf(last), findsNothing);

    await tester.tap(find.bySemanticsLabel('More colours'));
    await tester.pumpAndSettle();
    await tester.tap(dotOf(last).last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Fewer colours'));
    await tester.pumpAndSettle();
    // The row's last colour is now the picked one (plus the hero showing it).
    expect(dotOf(last), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Pets');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(SubscriptionStore.instance.customCategories.single.colorValue, last.toARGB32());
  });
}
