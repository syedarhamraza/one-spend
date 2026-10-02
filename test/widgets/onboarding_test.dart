import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/settings/domain/repositories/settings_repository.dart';
import 'package:onespend/features/subscriptions/presentation/widgets/first_run_empty_state.dart';
import 'package:onespend/main.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/onboarding_screen.dart';
import 'package:onespend/screens/settings/backup_data_screen.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    SubscriptionStore.instance.resetForTesting();
    SubscriptionStore.instance.clearAllData();
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const OneSpendApp(showOnboarding: true));
    await tester.pumpAndSettle();
  }

  group('needsOnboarding', () {
    test('a fresh install needs it', () async {
      expect(await needsOnboarding(), isTrue);
    });

    test('an install that already has data skips it and is marked done', () async {
      SubscriptionStore.instance.resetForTesting(); // demo subscriptions
      expect(await needsOnboarding(), isFalse);
      expect(await sl<SettingsRepository>().getOnboardingDone(), isTrue);
    });

    test('not shown again once done', () async {
      await sl<SettingsRepository>().setOnboardingDone(true);
      expect(await needsOnboarding(), isFalse);
    });
  });

  testWidgets('walking through ends on the Subscriptions tab and marks it done', (tester) async {
    await pumpOnboarding(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Main currency'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn on reminders'));
    await tester.pumpAndSettle();
    expect(SubscriptionStore.instance.notificationsEnabled, isTrue);

    expect(find.text("You're all set"), findsOneWidget);
    await tester.tap(find.text('Start tracking'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(FirstRunEmptyState), findsOneWidget);
  });

  testWidgets('Skip goes straight to the app', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('system back steps back through the pages', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Restore from backup finishes and opens Backup & data', (tester) async {
    await pumpOnboarding(tester);
    for (final label in ['Get started', 'Continue', 'Not now']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();
    expect(find.byType(BackupDataScreen), findsOneWidget);
  });

  testWidgets('finishing or skipping saves that onboarding is done', (tester) async {
    await pumpOnboarding(tester);
    // Record the write instead of hitting the database inside the fake clock.
    final recording = _RecordingSettings();
    sl.unregister<SettingsRepository>();
    sl.registerSingleton<SettingsRepository>(recording);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(recording.onboardingDone, isTrue);
  });
}

class _RecordingSettings extends Fake implements SettingsRepository {
  bool? onboardingDone;

  @override
  Future<void> setOnboardingDone(bool value) async => onboardingDone = value;
}
