import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../../features/currency/domain/currency.dart';
import 'converters/date_time_list_converter.dart';
import 'tables/app_settings_table.dart';
import 'tables/payment_methods_table.dart';
import 'tables/subscriptions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SubscriptionsTable, PaymentMethodsTable, AppSettingsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2 && !await _hasColumn('subscriptions', 'reminder_time_minutes')) {
            await m.addColumn(subscriptionsTable, subscriptionsTable.reminderTimeMinutes);
          }
          if (from < 3) await _migrateCurrencySymbolsToCodes();
          if (from < 4 && !await _hasColumn('subscriptions', 'logo_transform')) {
            await m.addColumn(subscriptionsTable, subscriptionsTable.logoTransform);
          }
        },
      );

  /// v3: currencies are ISO codes instead of display symbols (`$` → `USD`, `Rs` → `PKR`).
  Future<void> _migrateCurrencySymbolsToCodes() async {
    final rows = await customSelect('SELECT DISTINCT currency FROM subscriptions').get();
    for (final row in rows) {
      final stored = row.read<String>('currency');
      final code = CurrencyCatalog.normalize(stored);
      if (code != stored) {
        await customUpdate(
          'UPDATE subscriptions SET currency = ? WHERE currency = ?',
          variables: [Variable.withString(code), Variable.withString(stored)],
          updates: {subscriptionsTable},
        );
      }
    }
    final setting = await getSetting('onespend_currency');
    if (setting != null) {
      final code = CurrencyCatalog.normalize(setting);
      if (code != setting) await setSetting('onespend_currency', code);
    }
  }

  /// Makes upgrades idempotent: a column may already exist if a previous upgrade was interrupted.
  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info("$table")').get();
    return rows.any((row) => row.read<String>('name') == column);
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'onespend');
  }

  /// Read an app setting by key
  Future<String?> getSetting(String key) async {
    final query = select(appSettingsTable)..where((tbl) => tbl.key.equals(key));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  /// Write or update an app setting by key
  Future<void> setSetting(String key, String value) async {
    await into(appSettingsTable).insertOnConflictUpdate(
      AppSettingsTableCompanion.insert(key: key, value: value),
    );
  }

  /// Read every app setting whose key starts with [prefix], keyed without the prefix
  Future<Map<String, String>> getSettingsWithPrefix(String prefix) async {
    final query = select(appSettingsTable)..where((tbl) => tbl.key.like('$prefix%'));
    final rows = await query.get();
    return {for (final row in rows) row.key.substring(prefix.length): row.value};
  }

  /// Wipe all data (useful for reset or clear)
  Future<void> clearAll() async {
    await transaction(() async {
      await delete(subscriptionsTable).go();
      await delete(paymentMethodsTable).go();
      await delete(appSettingsTable).go();
    });
  }
}
