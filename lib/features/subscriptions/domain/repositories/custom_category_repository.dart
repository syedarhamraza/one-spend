import '../entities/custom_category.dart';

/// Storage for user-made categories.
abstract class CustomCategoryRepository {
  Future<List<CustomCategory>> getCustomCategories();

  /// Replaces every stored custom category with [categories].
  Future<void> replaceAll(List<CustomCategory> categories);

  /// Inserts or updates [categories] by id.
  Future<void> upsert(Iterable<CustomCategory> categories);

  Future<void> delete(Iterable<String> ids);
}
