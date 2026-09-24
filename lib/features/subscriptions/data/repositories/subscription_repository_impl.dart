import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_local_datasource.dart';
import '../models/subscription_model.dart';

/// Concrete Repository implementation mapping DataSource models to Domain entities.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionLocalDataSource _dataSource;

  const SubscriptionRepositoryImpl(this._dataSource);

  @override
  Future<List<Subscription>> getSubscriptions() async {
    final models = await _dataSource.loadSubscriptions();
    return models;
  }

  @override
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    final models = subscriptions.map((s) => s is SubscriptionModel ? s : SubscriptionModel.fromEntity(s)).toList();
    await _dataSource.saveSubscriptions(models);
  }

  @override
  Future<void> addSubscription(Subscription subscription) async {
    final current = await getSubscriptions();
    final updated = List<Subscription>.from(current)..add(subscription);
    await saveSubscriptions(updated);
  }

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    final current = await getSubscriptions();
    final index = current.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      final updated = List<Subscription>.from(current)..[index] = subscription;
      await saveSubscriptions(updated);
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    final current = await getSubscriptions();
    final updated = current.where((s) => s.id != id).toList();
    await saveSubscriptions(updated);
  }

  @override
  Future<double> getMonthlyBudget() => _dataSource.getMonthlyBudget();

  @override
  Future<void> setMonthlyBudget(double budget) => _dataSource.setMonthlyBudget(budget);

  @override
  Future<String> getCurrency() => _dataSource.getCurrency();

  @override
  Future<void> setCurrency(String currency) => _dataSource.setCurrency(currency);

  @override
  Future<({String name, String email})> getUserProfile() => _dataSource.getUserProfile();

  @override
  Future<void> setUserProfile(String name, String email) => _dataSource.setUserProfile(name, email);

  @override
  Future<int> getDefaultReminderDays() => _dataSource.getDefaultReminderDays();

  @override
  Future<void> setDefaultReminderDays(int days) => _dataSource.setDefaultReminderDays(days);

  @override
  Future<SubscriptionSortOption> getSortOption() async {
    final name = await _dataSource.getSortOptionName();
    if (name != null) return SubscriptionSortOption.fromString(name);
    return SubscriptionSortOption.renewalAsc;
  }

  @override
  Future<void> setSortOption(SubscriptionSortOption option) => _dataSource.setSortOptionName(option.name);

  @override
  Future<bool> getGroupByDate() => _dataSource.getGroupByDate();

  @override
  Future<void> setGroupByDate(bool value) => _dataSource.setGroupByDate(value);
}
