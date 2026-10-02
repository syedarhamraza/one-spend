import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/custom_category.dart';

/// Drift SQLite storage for custom categories (the `custom_categories` table).
class CustomCategoryDriftDataSource {
  final AppDatabase db;

  const CustomCategoryDriftDataSource(this.db);

  Future<List<CustomCategory>> load() async {
    try {
      final rows = await (db.select(db.customCategoriesTable)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
      return [
        for (final row in rows)
          CustomCategory(
            id: row.id,
            name: row.name,
            iconCodePoint: row.iconCodePoint,
            colorValue: row.colorValue,
            sortOrder: row.sortOrder,
          ),
      ];
    } catch (e) {
      throw StorageException('Failed to read custom categories from SQLite', e);
    }
  }

  CustomCategoriesTableCompanion _toCompanion(CustomCategory c) => CustomCategoriesTableCompanion.insert(
        id: c.id,
        name: c.name,
        iconCodePoint: c.iconCodePoint,
        colorValue: c.colorValue,
        sortOrder: Value(c.sortOrder),
      );

  Future<void> replaceAll(List<CustomCategory> categories) async {
    try {
      await db.transaction(() async {
        await db.delete(db.customCategoriesTable).go();
        if (categories.isNotEmpty) {
          await db.batch((batch) => batch.insertAll(db.customCategoriesTable, categories.map(_toCompanion).toList()));
        }
      });
    } catch (e) {
      throw StorageException('Failed to save custom categories to SQLite', e);
    }
  }

  Future<void> upsert(List<CustomCategory> categories) async {
    if (categories.isEmpty) return;
    try {
      await db.batch(
        (batch) => batch.insertAllOnConflictUpdate(db.customCategoriesTable, categories.map(_toCompanion).toList()),
      );
    } catch (e) {
      throw StorageException('Failed to upsert custom categories to SQLite', e);
    }
  }

  Future<void> delete(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await (db.delete(db.customCategoriesTable)..where((t) => t.id.isIn(ids))).go();
    } catch (e) {
      throw StorageException('Failed to delete custom categories from SQLite', e);
    }
  }
}
