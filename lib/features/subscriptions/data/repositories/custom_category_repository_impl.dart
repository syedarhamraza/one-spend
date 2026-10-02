import '../../domain/entities/custom_category.dart';
import '../../domain/repositories/custom_category_repository.dart';
import '../datasources/custom_category_drift_datasource.dart';

class CustomCategoryRepositoryImpl implements CustomCategoryRepository {
  final CustomCategoryDriftDataSource _dataSource;

  const CustomCategoryRepositoryImpl(this._dataSource);

  @override
  Future<List<CustomCategory>> getCustomCategories() => _dataSource.load();

  @override
  Future<void> replaceAll(List<CustomCategory> categories) => _dataSource.replaceAll(categories);

  @override
  Future<void> upsert(Iterable<CustomCategory> categories) => _dataSource.upsert(categories.toList());

  @override
  Future<void> delete(Iterable<String> ids) => _dataSource.delete(ids.toList());
}
