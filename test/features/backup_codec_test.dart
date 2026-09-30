import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/backup/domain/backup_codec.dart';
import 'package:onespend/features/backup/domain/backup_merge.dart';
import 'package:onespend/features/backup/domain/backup_snapshot.dart';
import 'package:onespend/models/subscription.dart';

void main() {
  Subscription sub(String id, {double price = 10}) => Subscription(
        id: id,
        name: 'Sub $id',
        description: '',
        price: price,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.music,
        nextBillingDate: DateTime(2026, 10, 5),
        paymentMethodId: 'card1',
        paymentHistory: [DateTime(2026, 9, 5)],
        reminderTimeMinutes: 8 * 60,
        anchorDay: 5, // toJson always writes the anchor day
      );

  PaymentMethod card(String id) => PaymentMethod(
        id: id,
        nickname: 'Card $id',
        type: PaymentMethodType.creditCard,
        brand: CardBrand.visa,
        last4: '4242',
        expiryDate: '12/28',
        cardColorValue: 0xFF112233,
        isDefault: false,
      );

  final snapshot = BackupSnapshot(
    createdAt: DateTime(2026, 9, 30, 10, 15),
    appVersion: '1.0.0 (1)',
    subscriptions: [sub('a'), sub('b', price: 99)],
    paymentMethods: [card('card1')],
    settings: (
      monthlyBudget: 120,
      currency: 'EUR',
      defaultReminderDays: 3,
      defaultReminderTimeMinutes: 20 * 60,
      notificationsEnabled: false,
      sortOption: SubscriptionSortOption.priceDesc,
      groupByDate: true,
    ),
    appearance: {'floating3dEffect': 'true', 'priceMode': 'dailyCost'},
  );

  group('BackupCodec', () {
    test('round-trips subscriptions, cards, settings and appearance', () {
      final decoded = BackupCodec.decode(BackupCodec.encode(snapshot));
      expect(decoded.isLegacy, isFalse);
      expect(decoded.createdAt, snapshot.createdAt);
      expect(decoded.appVersion, '1.0.0 (1)');
      expect(decoded.subscriptions, snapshot.subscriptions);
      expect(decoded.subscriptions.first.paymentHistory, [DateTime(2026, 9, 5)]);
      expect(decoded.subscriptions.first.reminderTimeMinutes, 8 * 60);
      expect(decoded.paymentMethods, snapshot.paymentMethods);
      expect(decoded.settings, snapshot.settings);
      expect(decoded.appearance, snapshot.appearance);
    });

    test('writes the format header and counts', () {
      final json = jsonDecode(BackupCodec.encode(snapshot)) as Map<String, dynamic>;
      expect(json['format'], BackupCodec.formatId);
      expect(json['version'], BackupCodec.currentVersion);
      expect(json['counts'], {'subscriptions': 2, 'paymentMethods': 1});
    });

    test('reads the old subscriptions-only export', () {
      final legacy = jsonEncode([sub('a').toJson(), sub('b').toJson()]);
      final decoded = BackupCodec.decode(legacy);
      expect(decoded.isLegacy, isTrue);
      expect(decoded.subscriptions.map((s) => s.id), ['a', 'b']);
      expect(decoded.paymentMethods, isEmpty);
    });

    test('rejects files that are not OneSpend backups', () {
      expect(() => BackupCodec.decode('{"hello": "world"}'), throwsA(BackupFormatException.notABackup));
      expect(() => BackupCodec.decode('[{"foo": 1}]'), throwsA(BackupFormatException.notABackup));
    });

    test('rejects newer versions and damaged files', () {
      final newer = jsonEncode({'format': BackupCodec.formatId, 'version': 99, 'data': {}});
      expect(() => BackupCodec.decode(newer), throwsA(BackupFormatException.tooNew));
      expect(() => BackupCodec.decode('{not json'), throwsA(BackupFormatException.damaged));
      final wrongTypes = jsonEncode({
        'format': BackupCodec.formatId,
        'version': 1,
        'data': {'subscriptions': 'nope'},
      });
      expect(() => BackupCodec.decode(wrongTypes), throwsA(BackupFormatException.damaged));
    });
  });

  group('BackupMerge', () {
    test('adds only items whose id is missing and never touches existing ones', () {
      final existing = sub('a', price: 1); // same id as the backup's "a", different price
      final missing = BackupMerge.missingItems(
        currentSubscriptions: [existing],
        currentPaymentMethods: const [],
        backup: snapshot,
      );
      expect(missing.subscriptions.map((s) => s.id), ['b']);
      expect(missing.paymentMethods.map((m) => m.id), ['card1']);
    });

    test('plan counts what the backup holds and what would be added', () {
      final plan = BackupMerge.plan(
        currentSubscriptions: [sub('a')],
        currentPaymentMethods: [card('card1')],
        backup: snapshot,
      );
      expect(plan.backupSubscriptions, 2);
      expect(plan.backupPaymentMethods, 1);
      expect(plan.newSubscriptions, 1);
      expect(plan.newPaymentMethods, 0);
      expect(plan.currentSubscriptions, 1);
      expect(plan.currentPaymentMethods, 1);
    });
  });
}
