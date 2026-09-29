import '../models/subscription_model.dart';

/// Abstract Local DataSource contract for Subscription data.
abstract class SubscriptionLocalDataSource {
  Future<List<SubscriptionModel>> loadSubscriptions();

  /// Replaces every stored subscription with [subscriptions].
  Future<void> saveSubscriptions(List<SubscriptionModel> subscriptions);

  /// Inserts or updates [subscriptions] by id, leaving other rows untouched.
  Future<void> upsertSubscriptions(List<SubscriptionModel> subscriptions);

  Future<void> deleteSubscriptions(List<String> ids);
}
