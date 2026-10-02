import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import 'package:onespend/features/subscriptions/data/models/subscription_model.dart';
import 'package:onespend/models/subscription.dart';

void main() {
  Subscription sub({LogoTransform? transform}) => Subscription(
        id: 'logo_sub',
        name: 'Custom',
        description: '',
        price: 5,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.utilities,
        nextBillingDate: DateTime(2026, 11, 1),
        logoUrl: 'https://example.com/logo.png',
        logoTransform: transform,
      );

  group('LogoTransform', () {
    test('encodes and decodes', () {
      const t = LogoTransform(scale: 1.25, dx: 0.05, dy: -0.1);
      expect(t.encode(), '1.25,0.05,-0.1');
      expect(LogoTransform.decode(t.encode()), t);
    });

    test('rejects malformed values and clamps out-of-range ones', () {
      expect(LogoTransform.decode(null), isNull);
      expect(LogoTransform.decode(''), isNull);
      expect(LogoTransform.decode('1,2'), isNull);
      expect(LogoTransform.decode('a,b,c'), isNull);
      expect(LogoTransform.decode('99,5,-5'), const LogoTransform(scale: LogoTransform.maxScale, dx: 1, dy: -1));
    });

    test('identity', () {
      expect(LogoTransform.identity.isIdentity, isTrue);
      expect(const LogoTransform(scale: 1.2).isIdentity, isFalse);
    });

    test('survives a backup (JSON) round trip, and old backups load without it', () {
      const t = LogoTransform(scale: 2, dx: -0.2, dy: 0.3);
      final restored = Subscription.fromJson(sub(transform: t).toJson());
      expect(restored.logoTransform, t);

      final legacy = sub().toJson()..remove('logoTransform');
      expect(Subscription.fromJson(legacy).logoTransform, isNull);
    });

    test('copyWith can set and clear it', () {
      const t = LogoTransform(scale: 1.5);
      final withT = sub().copyWith(logoTransform: t);
      expect(withT.logoTransform, t);
      expect(withT.copyWith(clearLogoTransform: true).logoTransform, isNull);
    });
  });

  group('Schema v4 migration', () {
    test('upgrades a v3 database, keeps rows, and stores the framing', () async {
      final dir = Directory.systemTemp.createTempSync('onespend_v4');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/v3.sqlite');

      // A v3 database: current schema minus the new column, user_version 3.
      final v3 = AppDatabase.forTesting(NativeDatabase(file));
      await SubscriptionDriftDataSource(v3).saveSubscriptions([SubscriptionModel.fromEntity(sub())]);
      await v3.customStatement('ALTER TABLE subscriptions DROP COLUMN logo_transform');
      await v3.customStatement('PRAGMA user_version = 3');
      await v3.close();

      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(upgraded.close);
      final ds = SubscriptionDriftDataSource(upgraded);
      final loaded = await ds.loadSubscriptions();
      expect(loaded.single.id, 'logo_sub');
      expect(loaded.single.logoTransform, isNull);

      const t = LogoTransform(scale: 1.75, dx: 0.1, dy: -0.05);
      await ds.saveSubscriptions([SubscriptionModel.fromEntity(loaded.single.copyWith(logoTransform: t))]);
      expect((await ds.loadSubscriptions()).single.logoTransform, t);
    });
  });
}
