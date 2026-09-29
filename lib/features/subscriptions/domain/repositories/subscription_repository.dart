import '../entities/subscription.dart';

/// Pure Domain Repository contract for Subscriptions.
/// Decoupled from any storage engine (Drift, SQLite, Cloud).
abstract class SubscriptionRepository {
  Future<List<Subscription>> getSubscriptions();

  /// Replaces every stored subscription with [subscriptions].
  Future<void> replaceAll(List<Subscription> subscriptions);

  /// Inserts or updates [subscriptions] by id.
  Future<void> upsert(Iterable<Subscription> subscriptions);

  Future<void> delete(Iterable<String> ids);
}
