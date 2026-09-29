import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_local_datasource.dart';
import '../models/subscription_model.dart';

/// Concrete Repository implementation mapping DataSource models to Domain entities.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionLocalDataSource _dataSource;

  const SubscriptionRepositoryImpl(this._dataSource);

  static SubscriptionModel _toModel(Subscription s) =>
      s is SubscriptionModel ? s : SubscriptionModel.fromEntity(s);

  @override
  Future<List<Subscription>> getSubscriptions() async {
    final models = await _dataSource.loadSubscriptions();
    return models;
  }

  @override
  Future<void> replaceAll(List<Subscription> subscriptions) {
    return _dataSource.saveSubscriptions(subscriptions.map(_toModel).toList());
  }

  @override
  Future<void> upsert(Iterable<Subscription> subscriptions) {
    return _dataSource.upsertSubscriptions(subscriptions.map(_toModel).toList());
  }

  @override
  Future<void> delete(Iterable<String> ids) {
    return _dataSource.deleteSubscriptions(ids.toList());
  }
}
