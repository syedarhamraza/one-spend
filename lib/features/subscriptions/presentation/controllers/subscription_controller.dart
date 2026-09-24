import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/di/injection.dart';
import '../../../../models/spending_trend.dart';
import '../../../payment_methods/data/fixtures/default_payment_methods.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../../payment_methods/domain/repositories/payment_method_repository.dart';
import '../../data/fixtures/popular_catalog.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';
import '../../domain/repositories/subscription_repository.dart';

/// Reactive Controller managing Subscriptions, Payment Methods, and Settings.
/// Injected via GetIt; depends on abstract repositories, not SharedPreferences directly.
class SubscriptionController extends ChangeNotifier {
  final SubscriptionRepository subscriptionRepository;
  final PaymentMethodRepository paymentMethodRepository;

  static SubscriptionController get instance {
    if (!sl.isRegistered<SubscriptionController>()) {
      setupDependencies();
    }
    return sl<SubscriptionController>();
  }

  SubscriptionController({
    required this.subscriptionRepository,
    required this.paymentMethodRepository,
  }) {
    _subscriptions.addAll([
      popularCatalog[0], // Netflix
      popularCatalog[1], // Spotify
      popularCatalog[2], // ChatGPT Plus
      popularCatalog[3], // YouTube Premium
      popularCatalog[4], // iCloud+
    ]);
    _paymentMethods.addAll(defaultPaymentMethods);
    _loadFromRepository();
  }

  final List<Subscription> _subscriptions = [];
  final List<PaymentMethod> _paymentMethods = [];
  double _monthlyBudget = 150.0;
  String _currency = '\$';
  String _userName = 'Syed Arham Raza';
  String _userEmail = 'syed@onespend.app';
  int _defaultReminderDays = 2;
  SubscriptionSortOption _sortOption = SubscriptionSortOption.renewalAsc;
  bool _groupByDate = false;
  bool _isLoaded = false;
  final Map<String, SubscriptionStatus> _prePauseStatus = {};

  // Computed properties cache
  double? _cachedTotalMonthlySpend;
  int? _cachedTotalActiveCount;
  int? _cachedTotalPausedCount;
  List<Subscription>? _cachedUpcomingDue;
  List<Subscription>? _cachedSortedSubscriptions;
  Subscription? _cachedHighestCostSubscription;
  bool _highestCostCalculated = false;
  Map<SubscriptionCategory, double>? _cachedCategorySpendMap;
  final Map<SpendingTrendHorizon, List<MonthlySpendPoint>> _cachedTrends = {};

  void _invalidateCache() {
    _cachedTotalMonthlySpend = null;
    _cachedTotalActiveCount = null;
    _cachedTotalPausedCount = null;
    _cachedUpcomingDue = null;
    _cachedSortedSubscriptions = null;
    _cachedHighestCostSubscription = null;
    _highestCostCalculated = false;
    _cachedCategorySpendMap = null;
    _cachedTrends.clear();
  }

  @override
  void notifyListeners() {
    _invalidateCache();
    super.notifyListeners();
  }

  void resetForTesting() {
    _subscriptions.clear();
    _subscriptions.addAll([
      popularCatalog[0], // Netflix
      popularCatalog[1], // Spotify
      popularCatalog[2], // ChatGPT Plus
      popularCatalog[3], // YouTube Premium
      popularCatalog[4], // iCloud+
    ]);
    _paymentMethods.clear();
    _paymentMethods.addAll(defaultPaymentMethods);
    _monthlyBudget = 150.0;
    _currency = '\$';
    _userName = 'Syed Arham Raza';
    _userEmail = 'syed@onespend.app';
    _defaultReminderDays = 2;
    _sortOption = SubscriptionSortOption.renewalAsc;
    _groupByDate = false;
    _prePauseStatus.clear();
    _invalidateCache();
    super.notifyListeners();
  }

  // Getters
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  List<PaymentMethod> get paymentMethods => List.unmodifiable(_paymentMethods);
  double get monthlyBudget => _monthlyBudget;
  String get currency => _currency;
  String get userName => _userName;
  String get userEmail => _userEmail;
  int get defaultReminderDays => _defaultReminderDays;
  SubscriptionSortOption get sortOption => _sortOption;
  bool get groupByDate => _groupByDate;
  bool get isLoaded => _isLoaded;

  double get totalMonthlySpend {
    if (_cachedTotalMonthlySpend != null) return _cachedTotalMonthlySpend!;
    final total = _subscriptions
        .where((s) => s.status != SubscriptionStatus.paused && s.status != SubscriptionStatus.trial)
        .fold<double>(0.0, (acc, sub) => acc + sub.monthlyCost);
    return _cachedTotalMonthlySpend = total;
  }

  double get totalYearlySpend => totalMonthlySpend * 12;

  int get totalActiveCount {
    if (_cachedTotalActiveCount != null) return _cachedTotalActiveCount!;
    return _cachedTotalActiveCount = _subscriptions
        .where((s) => s.status == SubscriptionStatus.active || s.status == SubscriptionStatus.dueSoon)
        .length;
  }

  int get totalPausedCount {
    if (_cachedTotalPausedCount != null) return _cachedTotalPausedCount!;
    return _cachedTotalPausedCount = _subscriptions.where((s) => s.status == SubscriptionStatus.paused).length;
  }

  List<Subscription> get upcomingDue {
    if (_cachedUpcomingDue != null) return _cachedUpcomingDue!;
    final list = List<Subscription>.from(_subscriptions.where((s) => s.status != SubscriptionStatus.paused));
    list.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return _cachedUpcomingDue = list;
  }

  List<Subscription> get sortedSubscriptions {
    if (_cachedSortedSubscriptions != null) return _cachedSortedSubscriptions!;
    final list = List<Subscription>.from(_subscriptions);
    switch (_sortOption) {
      case SubscriptionSortOption.renewalAsc:
        list.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
        break;
      case SubscriptionSortOption.renewalDesc:
        list.sort((a, b) => b.nextBillingDate.compareTo(a.nextBillingDate));
        break;
      case SubscriptionSortOption.priceDesc:
        list.sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
        break;
      case SubscriptionSortOption.priceAsc:
        list.sort((a, b) => a.monthlyCost.compareTo(b.monthlyCost));
        break;
      case SubscriptionSortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SubscriptionSortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
    return _cachedSortedSubscriptions = list;
  }

  Subscription? get highestCostSubscription {
    if (_highestCostCalculated) return _cachedHighestCostSubscription;
    _highestCostCalculated = true;
    if (_subscriptions.isEmpty) return _cachedHighestCostSubscription = null;
    final active = _subscriptions
        .where((s) => s.status != SubscriptionStatus.paused && s.status != SubscriptionStatus.trial)
        .toList();
    if (active.isEmpty) return _cachedHighestCostSubscription = null;
    active.sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
    return _cachedHighestCostSubscription = active.first;
  }

  Map<SubscriptionCategory, double> get categorySpendMap {
    if (_cachedCategorySpendMap != null) return _cachedCategorySpendMap!;
    final Map<SubscriptionCategory, double> map = {};
    for (var sub in _subscriptions.where((s) => s.status != SubscriptionStatus.paused && s.status != SubscriptionStatus.trial)) {
      map[sub.category] = (map[sub.category] ?? 0.0) + sub.monthlyCost;
    }
    return _cachedCategorySpendMap = map;
  }

  List<MonthlySpendPoint> getSpendingTrends(SpendingTrendHorizon horizon, [DateTime? referenceDate]) {
    if (referenceDate == null && _cachedTrends.containsKey(horizon)) {
      return _cachedTrends[horizon]!;
    }
    final trends = SpendingTrendsEngine.calculateTrends(
      subscriptions: _subscriptions,
      horizon: horizon,
      referenceDate: referenceDate,
    );
    if (referenceDate == null) {
      _cachedTrends[horizon] = trends;
    }
    return trends;
  }

  TrendSummary getSpendingTrendSummary(SpendingTrendHorizon horizon, [DateTime? referenceDate]) {
    final trends = getSpendingTrends(horizon, referenceDate);
    return SpendingTrendsEngine.calculateSummary(trends);
  }

  // --- Persistence Integration ---
  Future<void> _loadFromRepository() async {
    try {
      final loadedSubs = await subscriptionRepository.getSubscriptions();
      if (loadedSubs.isNotEmpty) {
        _subscriptions.clear();
        _subscriptions.addAll(loadedSubs);
      }

      final loadedMethods = await paymentMethodRepository.getPaymentMethods();
      if (loadedMethods.isNotEmpty) {
        _paymentMethods.clear();
        _paymentMethods.addAll(loadedMethods);
      }

      _monthlyBudget = await subscriptionRepository.getMonthlyBudget();
      _currency = await subscriptionRepository.getCurrency();
      final profile = await subscriptionRepository.getUserProfile();
      _userName = profile.name;
      _userEmail = profile.email;
      _defaultReminderDays = await subscriptionRepository.getDefaultReminderDays();
      _sortOption = await subscriptionRepository.getSortOption();
      _groupByDate = await subscriptionRepository.getGroupByDate();

      _isLoaded = true;
      checkAndProcessAutoRenewals();
      notifyListeners();
    } catch (e) {
      debugPrint('OneSpend: Failed to load data from repository: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveToRepository() async {
    try {
      await subscriptionRepository.saveSubscriptions(_subscriptions);
      await paymentMethodRepository.savePaymentMethods(_paymentMethods);
      await subscriptionRepository.setMonthlyBudget(_monthlyBudget);
      await subscriptionRepository.setCurrency(_currency);
      await subscriptionRepository.setUserProfile(_userName, _userEmail);
      await subscriptionRepository.setDefaultReminderDays(_defaultReminderDays);
      await subscriptionRepository.setSortOption(_sortOption);
      await subscriptionRepository.setGroupByDate(_groupByDate);
    } catch (e) {
      debugPrint('OneSpend: Failed to save data to repository: $e');
    }
  }

  // --- Payment Methods ---
  PaymentMethod? get defaultPaymentMethod {
    for (final m in _paymentMethods) {
      if (m.isDefault) return m;
    }
    return _paymentMethods.isNotEmpty ? _paymentMethods.first : null;
  }

  PaymentMethod? getPaymentMethod(String? id) {
    if (id == null) return null;
    for (final m in _paymentMethods) {
      if (m.id == id) return m;
    }
    return null;
  }

  void addPaymentMethod(PaymentMethod method) {
    if (method.isDefault) {
      for (int i = 0; i < _paymentMethods.length; i++) {
        if (_paymentMethods[i].isDefault) {
          _paymentMethods[i] = _paymentMethods[i].copyWith(isDefault: false);
        }
      }
    }
    _paymentMethods.add(method);
    notifyListeners();
    _saveToRepository();
  }

  void updatePaymentMethod(PaymentMethod method) {
    final index = _paymentMethods.indexWhere((m) => m.id == method.id);
    if (index != -1) {
      if (method.isDefault) {
        for (int i = 0; i < _paymentMethods.length; i++) {
          if (_paymentMethods[i].id != method.id && _paymentMethods[i].isDefault) {
            _paymentMethods[i] = _paymentMethods[i].copyWith(isDefault: false);
          }
        }
      }
      _paymentMethods[index] = method;
      notifyListeners();
      _saveToRepository();
    }
  }

  void deletePaymentMethod(String methodId, {String? replacementMethodId}) {
    if (replacementMethodId != null && replacementMethodId.isNotEmpty) {
      final replacement = getPaymentMethod(replacementMethodId);
      final replacementName = replacement?.displayName ?? '';
      for (int i = 0; i < _subscriptions.length; i++) {
        if (_subscriptions[i].paymentMethodId == methodId) {
          _subscriptions[i] = _subscriptions[i].copyWith(
            paymentMethodId: replacementMethodId,
            paymentMethod: replacementName.isNotEmpty ? replacementName : _subscriptions[i].paymentMethod,
          );
        }
      }
    } else {
      for (int i = 0; i < _subscriptions.length; i++) {
        if (_subscriptions[i].paymentMethodId == methodId) {
          _subscriptions[i] = _subscriptions[i].copyWith(
            clearPaymentMethodId: true,
            paymentMethod: '',
          );
        }
      }
    }

    _paymentMethods.removeWhere((m) => m.id == methodId);
    notifyListeners();
    _saveToRepository();
  }

  Subscription? getSubscription(String id) {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index != -1) return _subscriptions[index];
    return null;
  }

  int getLinkedSubscriptionCount(String methodId) {
    return _subscriptions.where((s) => s.paymentMethodId == methodId).length;
  }

  List<Subscription> getSubscriptionsForMethod(String methodId) {
    return _subscriptions.where((s) => s.paymentMethodId == methodId).toList();
  }

  List<PaymentMethod> get expiringPaymentMethods {
    return _paymentMethods.where((m) => m.isExpiringSoon || m.isExpired).toList();
  }

  void reassignSubscriptions({required String fromMethodId, required String toMethodId}) {
    final replacement = getPaymentMethod(toMethodId);
    final replacementName = replacement?.displayName ?? '';
    for (int i = 0; i < _subscriptions.length; i++) {
      if (_subscriptions[i].paymentMethodId == fromMethodId) {
        _subscriptions[i] = _subscriptions[i].copyWith(
          paymentMethodId: toMethodId,
          paymentMethod: replacementName.isNotEmpty ? replacementName : _subscriptions[i].paymentMethod,
        );
      }
    }
    notifyListeners();
    _saveToRepository();
  }

  // --- Subscriptions Actions ---
  void addSubscription(Subscription subscription) {
    _subscriptions.add(subscription);
    notifyListeners();
    _saveToRepository();
  }

  void batchAdd(Iterable<Subscription> newSubscriptions) {
    _subscriptions.addAll(newSubscriptions);
    notifyListeners();
    _saveToRepository();
  }

  void removeSubscription(String id) {
    _subscriptions.removeWhere((item) => item.id == id);
    notifyListeners();
    _saveToRepository();
  }

  void updateSubscription(Subscription updated) {
    final index = _subscriptions.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      _subscriptions[index] = updated;
      notifyListeners();
      _saveToRepository();
    }
  }

  void renewSubscription(String id) {
    markSubscriptionPaid(id);
  }

  void markSubscriptionPaid(String id, [DateTime? paymentDate]) {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index != -1) {
      final sub = _subscriptions[index];
      DateTime newDate = sub.calculateNextDateFrom(sub.nextBillingDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      while (newDate.isBefore(today)) {
        newDate = sub.calculateNextDateFrom(newDate);
      }
      final dateToLog = paymentDate ?? (sub.nextBillingDate.isBefore(now) ? sub.nextBillingDate : now);
      final updatedHistory = List<DateTime>.from(sub.paymentHistory)..insert(0, dateToLog);
      updatedHistory.sort((a, b) => b.compareTo(a));

      _subscriptions[index] = sub.copyWith(
        nextBillingDate: newDate,
        paymentHistory: updatedHistory,
      );
      notifyListeners();
      _saveToRepository();
    }
  }

  void skipSubscriptionCycle(String id) {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index != -1) {
      final sub = _subscriptions[index];
      DateTime newDate = sub.calculateNextDateFrom(sub.nextBillingDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      while (newDate.isBefore(today)) {
        newDate = sub.calculateNextDateFrom(newDate);
      }
      _subscriptions[index] = sub.copyWith(nextBillingDate: newDate);
      notifyListeners();
      _saveToRepository();
    }
  }

  bool addPaymentRecord(String id, DateTime date) {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index != -1) {
      final sub = _subscriptions[index];
      final alreadyExists = sub.paymentHistory.any((d) =>
          d.year == date.year && d.month == date.month && d.day == date.day);
      if (alreadyExists) {
        return false;
      }
      final updatedHistory = List<DateTime>.from(sub.paymentHistory)..add(date);
      updatedHistory.sort((a, b) => b.compareTo(a));
      _subscriptions[index] = sub.copyWith(paymentHistory: updatedHistory);
      notifyListeners();
      _saveToRepository();
      return true;
    }
    return false;
  }

  void deletePaymentRecord(String id, int historyIndex) {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index != -1) {
      final sub = _subscriptions[index];
      if (historyIndex >= 0 && historyIndex < sub.paymentHistory.length) {
        final updatedHistory = List<DateTime>.from(sub.paymentHistory)..removeAt(historyIndex);
        _subscriptions[index] = sub.copyWith(paymentHistory: updatedHistory);
        notifyListeners();
        _saveToRepository();
      }
    }
  }

  void checkAndProcessAutoRenewals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool changed = false;

    for (int i = 0; i < _subscriptions.length; i++) {
      final sub = _subscriptions[i];
      if (sub.autoRenew && sub.status != SubscriptionStatus.paused) {
        final target = DateTime(sub.nextBillingDate.year, sub.nextBillingDate.month, sub.nextBillingDate.day);
        if (target.isBefore(today)) {
          renewSubscription(sub.id);
          changed = true;
        }
      }
    }

    if (changed) {
      notifyListeners();
      _saveToRepository();
    }
  }

  void togglePauseSubscription(String id) {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index != -1) {
      final sub = _subscriptions[index];
      SubscriptionStatus newStatus;
      if (sub.status == SubscriptionStatus.paused) {
        newStatus = _prePauseStatus.remove(id) ?? SubscriptionStatus.active;
      } else {
        _prePauseStatus[id] = sub.status;
        newStatus = SubscriptionStatus.paused;
      }
      _subscriptions[index] = sub.copyWith(status: newStatus);
      notifyListeners();
      _saveToRepository();
    }
  }

  void batchDelete(Iterable<String> ids) {
    final idSet = ids.toSet();
    _subscriptions.removeWhere((item) => idSet.contains(item.id));
    notifyListeners();
    _saveToRepository();
  }

  void batchTogglePause(Iterable<String> ids) {
    final idSet = ids.toSet();
    for (int i = 0; i < _subscriptions.length; i++) {
      if (idSet.contains(_subscriptions[i].id)) {
        final sub = _subscriptions[i];
        SubscriptionStatus newStatus;
        if (sub.status == SubscriptionStatus.paused) {
          newStatus = _prePauseStatus.remove(sub.id) ?? SubscriptionStatus.active;
        } else {
          _prePauseStatus[sub.id] = sub.status;
          newStatus = SubscriptionStatus.paused;
        }
        _subscriptions[i] = sub.copyWith(status: newStatus);
      }
    }
    notifyListeners();
    _saveToRepository();
  }

  void batchChangeCategory(Iterable<String> ids, SubscriptionCategory category) {
    final idSet = ids.toSet();
    for (int i = 0; i < _subscriptions.length; i++) {
      if (idSet.contains(_subscriptions[i].id)) {
        _subscriptions[i] = _subscriptions[i].copyWith(category: category);
      }
    }
    notifyListeners();
    _saveToRepository();
  }

  void setMonthlyBudget(double amount) {
    _monthlyBudget = amount.clamp(0.0, 999999.0);
    notifyListeners();
    _saveToRepository();
  }

  void setCurrency(String newCurrency) {
    _currency = newCurrency;
    notifyListeners();
    _saveToRepository();
  }

  void setUserProfile(String name, String email) {
    _userName = name;
    _userEmail = email;
    notifyListeners();
    _saveToRepository();
  }

  void setDefaultReminderDays(int days) {
    _defaultReminderDays = days;
    notifyListeners();
    _saveToRepository();
  }

  void setSortOption(SubscriptionSortOption option) {
    _sortOption = option;
    notifyListeners();
    _saveToRepository();
  }

  void setGroupByDate(bool value) {
    _groupByDate = value;
    notifyListeners();
    _saveToRepository();
  }

  void restoreDefaultCatalog() {
    _subscriptions.clear();
    _subscriptions.addAll(popularCatalog);
    notifyListeners();
    _saveToRepository();
  }

  void clearAllData() {
    _subscriptions.clear();
    notifyListeners();
    _saveToRepository();
  }

  String exportDataAsJson() {
    return const JsonEncoder.withIndent('  ').convert(
      _subscriptions.map((s) => s.toJson()).toList(),
    );
  }

  String exportDataAsCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Name,Category,Billing Cycle,Price,Currency,Next Renewal,Status,Payment Method');
    for (var sub in _subscriptions) {
      final dateStr = '${sub.nextBillingDate.year}-${sub.nextBillingDate.month.toString().padLeft(2, '0')}-${sub.nextBillingDate.day.toString().padLeft(2, '0')}';
      String escCsv(String val) => val.replaceAll('"', '""');
      buffer.writeln(
        '"${escCsv(sub.name)}","${escCsv(sub.category.label)}","${escCsv(sub.billingCycle.label)}",${sub.price},"${escCsv(sub.currency)}","$dateStr","${escCsv(sub.status.label)}","${escCsv(sub.paymentMethod)}"',
      );
    }
    return buffer.toString();
  }
}
