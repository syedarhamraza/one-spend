import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/reports/data/pdf_report_builder.dart';
import 'package:onespend/features/reports/data/report_data.dart';
import 'package:onespend/features/reports/data/report_sharer.dart';
import 'package:onespend/features/subscriptions/data/subscription_exporter.dart';
import 'package:onespend/models/subscription.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  final now = DateTime(2026, 10, 15, 12);
  late SubscriptionController store;

  Subscription sub(
    String id, {
    double price = 10,
    BillingCycle cycle = BillingCycle.monthly,
    SubscriptionCategory category = SubscriptionCategory.entertainment,
    DateTime? next,
    List<DateTime> history = const [],
    SubscriptionStatus status = SubscriptionStatus.active,
    String currency = 'USD',
  }) =>
      Subscription(
        id: id,
        name: id,
        description: '',
        price: price,
        currency: currency,
        billingCycle: cycle,
        category: category,
        nextBillingDate: next ?? DateTime(2026, 10, 20),
        paymentHistory: history,
        status: status,
      );

  final fonts = (
    regular: pw.Font.ttf(File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync().buffer.asByteData()),
    bold: pw.Font.ttf(File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync().buffer.asByteData()),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    store = SubscriptionStore.instance;
    store.resetForTesting();
    store.clearAllData();
    store.batchAdd([
      sub('Stream', price: 20, history: [DateTime(2026, 9, 20), DateTime(2025, 8, 20)]),
      sub('Tunes', price: 12, category: SubscriptionCategory.music, next: DateTime(2026, 12, 1)),
      sub('Drive', price: 120, cycle: BillingCycle.yearly, category: SubscriptionCategory.cloud),
      sub('Old', price: 5, status: SubscriptionStatus.paused),
    ]);
  });

  group('SpendingReportData', () {
    test('totals, windows and ordering follow the app rules', () {
      final d = SpendingReportData.fromStore(store, now: now);
      expect(d.monthly, closeTo(20 + 12 + 10, 0.001)); // the yearly plan counts as $10 a month
      expect(d.yearly, closeTo(42 * 12, 0.001));
      expect(d.activeCount, 3);
      expect(d.pausedCount, 1);
      expect(d.subscriptions.first.name, 'Stream'); // most expensive first
      expect(d.subscriptions.last.name, 'Old'); // paused ones last
      // Next 30 days only: Tunes renews in December.
      expect(d.upcoming.map((c) => c.name), containsAll(['Stream', 'Drive']));
      expect(d.upcoming.map((c) => c.name), isNot(contains('Tunes')));
      // Last 12 months only: the 2025 payment is out of range.
      expect(d.payments, hasLength(1));
      expect(d.paymentsTotal, 20);
    });

    test('a category report covers only that category', () {
      final d = SpendingReportData.fromStore(store, category: SubscriptionCategory.music, now: now);
      expect(d.categoryLabel, SubscriptionCategory.music.label);
      expect(d.subscriptions.map((s) => s.name), ['Tunes']);
      expect(d.monthlyBudget, 0);
    });
  });

  group('PdfReportBuilder', () {
    bool isPdf(List<int> bytes) => utf8.decode(bytes.take(5).toList()) == '%PDF-';

    test('builds the spending report', () async {
      final bytes = await PdfReportBuilder.spendingReport(SpendingReportData.fromStore(store, now: now), fonts);
      expect(isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(5000));
    });

    test('a long payment history spills onto more pages', () async {
      store.updateSubscription(store.getSubscription('Stream')!.copyWith(
        paymentHistory: [for (var i = 0; i < 300; i++) DateTime(2026, 10, 1).subtract(Duration(days: i))],
      ));
      final bytes = await PdfReportBuilder.spendingReport(SpendingReportData.fromStore(store, now: now), fonts);
      final pages = RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(bytes)).length;
      expect(pages, greaterThan(3));
    });

    test('currencies whose symbol the font lacks still render (as codes)', () async {
      store.setCurrency('THB');
      store.addSubscription(sub('Baht', currency: 'THB', price: 99));
      final bytes = await PdfReportBuilder.spendingReport(SpendingReportData.fromStore(store, now: now), fonts);
      expect(isPdf(bytes), isTrue);
    });

    test('builds the one-page subscription sheet', () async {
      final s = store.getSubscription('Stream')!;
      final bytes = await PdfReportBuilder.subscriptionSheet(s, fonts, mainCurrency: 'USD', toMain: store.toMain, now: now);
      expect(isPdf(bytes), isTrue);
    });

    test('an empty report still builds', () async {
      store.clearAllData();
      final bytes = await PdfReportBuilder.spendingReport(SpendingReportData.fromStore(store, now: now), fonts);
      expect(isPdf(bytes), isTrue);
    });
  });

  test('payments CSV lists every payment, newest first', () {
    final csv = SubscriptionExporter.paymentsCsv(store.subscriptions).trim().split('\n');
    expect(csv.first, 'Date,Subscription,Category,Amount,Currency');
    expect(csv, hasLength(3));
    expect(csv[1], startsWith('"2026-09-20","Stream"'));
    expect(csv[2], startsWith('"2025-08-20","Stream"'));
  });

  test('file names are filesystem-safe', () {
    expect(ReportSharer.safeFileName('Disney+ / Hulu: Bundle'), 'Disney-Hulu-Bundle');
    expect(ReportSharer.safeFileName('???'), 'subscription');
  });
}
