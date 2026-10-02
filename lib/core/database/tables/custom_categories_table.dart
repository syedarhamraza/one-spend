import 'package:drift/drift.dart';

/// User-made subscription categories (a Pro feature). Added in schema v5.
@DataClassName('CustomCategoryEntry')
class CustomCategoriesTable extends Table {
  @override
  String get tableName => 'custom_categories';

  /// `c_…`; stored in `subscriptions.category` like the built-in names.
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorValue => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
