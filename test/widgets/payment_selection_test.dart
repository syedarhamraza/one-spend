import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/payment_method_picker_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_glass_surface.dart';
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

  Future<Finder> pumpPicker(WidgetTester tester, {required bool manage}) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(PaymentMethodPickerScreen(isManageOnly: manage), theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();
    final name = SubscriptionStore.instance.paymentMethods.last.displayName;
    return find.text(name).last;
  }

  for (final manage in [true, false]) {
    testWidgets('entering selection keeps the list in place (${manage ? 'manage' : 'picker'})', (tester) async {
      await pumpPicker(tester, manage: manage);
      // A phone-sized screen scrolled to the end, where removed content used to make the list jump.
      tester.view.physicalSize = const Size(1080, 2340);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await tester.pumpAndSettle();
      final card = find.text(SubscriptionStore.instance.paymentMethods.last.displayName).last;
      final before = tester.getTopLeft(card);

      await tester.longPress(card);
      await tester.pumpAndSettle();
      expect(find.text('Move subs'), findsOneWidget);
      expect(tester.getTopLeft(card).dy, before.dy);
    });
  }

  testWidgets('picker: Cancel | Save morphs into the selection actions inside one bar', (tester) async {
    final card = await pumpPicker(tester, manage: false);
    final barElement = tester.element(find.ancestor(of: find.text('Save'), matching: find.byType(OneUIGlassSurface)).first);

    await tester.longPress(card);
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsNothing);
    // The same glass surface element now holds the actions: reshaped, not replaced.
    final actionsElement = tester.element(find.ancestor(of: find.text('Move subs'), matching: find.byType(OneUIGlassSurface)).first);
    expect(actionsElement, same(barElement));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Move subs'), findsNothing);
  });
}
