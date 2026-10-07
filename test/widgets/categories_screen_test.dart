import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/category_editor_screen.dart';
import 'package:onespend/screens/category_picker_screen.dart';
import 'package:onespend/widgets/one_ui_category_hero.dart';
import 'package:onespend/widgets/one_ui_radio.dart';
import 'package:onespend/widgets/one_ui_subpage.dart';
import 'package:onespend/screens/settings/categories_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_card.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';

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

  testWidgets('editor: hero on the left; Colour and Icon are radio lists with Cancel | Save', (tester) async {
    await pump(tester, const CategoriesScreen());
    await tester.tap(find.byTooltip('New category'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUICategoryHero), findsOneWidget);
    expect(find.text('Coral'), findsOneWidget); // the Colour row shows the current colour

    // Colour: pick Mocha, Save.
    await tester.tap(find.text('Colour'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUIRadio), findsNWidgets(OneUITheme.categorySwatches.length));
    await tester.scrollUntilVisible(find.text('Mocha'), 200);
    await tester.tap(find.text('Mocha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Mocha'), findsOneWidget);

    // Icon: pick Pets, then Cancel keeps the old icon.
    await tester.tap(find.text('Icon'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pets'), 300);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250)); // clear of the pill
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pets'));
    await tester.pumpAndSettle();
    final petsRow = find.ancestor(of: find.text('Pets'), matching: find.byType(OneUIGroupItemTile));
    expect(tester.widget<OneUIRadio>(find.descendant(of: petsRow, matching: find.byType(OneUIRadio))).isSelected, isTrue);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Pets'), findsNothing);
    expect(find.text('Home'), findsOneWidget); // the default icon

    await tester.enterText(find.byType(TextField), 'Coffee');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = SubscriptionStore.instance.customCategories.single;
    expect(saved.colorValue, OneUITheme.categorySwatches.last.toARGB32());
    expect(saved.iconCodePoint, Icons.home_rounded.codePoint);
  });

  testWidgets('Settings: a summary hero and rows without icons or radios', (tester) async {
    add('Kids');
    await pump(tester, const CategoriesScreen());
    expect(find.text('10 built in · 1 of your own'), findsOneWidget);
    expect(find.byType(OneUIRadio), findsNothing);
    expect(find.byType(OneUIIconBadge), findsNothing);
  });

  testWidgets('picking: radios, the hero follows the choice, Save returns it, exclude hides', (tester) async {
    final kids = add('Kids');
    final home = add('Home');
    SubscriptionCategory? result;
    await tester.pumpWidget(routedTestApp(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async => result = await CategoryPickerScreen.open(
          context,
          initialCategory: SubscriptionCategory.music,
          exclude: {home},
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Music streaming, podcasts & audiobooks'), findsOneWidget); // hero, long description
    expect(find.text('Home'), findsNothing);
    expect(find.byType(OneUIIconBadge), findsNothing);
    await tester.tap(find.text('Kids'));
    await tester.pumpAndSettle();
    expect(find.text('Kids'), findsNWidgets(2)); // the row and the hero
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, same(kids));
  });

  test('every colour and icon has a name', () {
    expect(OneUITheme.categorySwatchNames, hasLength(OneUITheme.categorySwatches.length));
    expect(subscriptionIconNames, hasLength(supportedSubscriptionIcons.length));
  });
}
