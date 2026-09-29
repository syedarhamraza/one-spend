import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
  int get schemaVersion => 1;

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
