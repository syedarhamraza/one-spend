import 'package:flutter/foundation.dart';
import '../../../../core/di/injection.dart';
import '../../../../models/spending_trend.dart';
import '../../../payment_methods/data/fixtures/default_payment_methods.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../../payment_methods/domain/repositories/payment_method_repository.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../data/fixtures/popular_catalog.dart';
import '../../data/subscription_exporter.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/services/billing_schedule.dart';
import '../../domain/services/subscription_stats.dart';

/// Reactive Controller managing Subscriptions, Payment Methods, and Settings.
/// Injected via GetIt; depends on abstract repositories, not storage directly.
///
/// State is held in memory; each mutation persists only what it changed through
/// an ordered write queue, so writes land in the order they were made.
class SubscriptionController extends ChangeNotifier {
  final SubscriptionRepository subscriptionRepository;
  final PaymentMethodRepository paymentMethodRepository;
  final SettingsRepository settingsRepository;

  static SubscriptionController get instance {
    if (!sl.isRegistered<SubscriptionController>()) {
      setupDependencies();
    }
    return sl<SubscriptionController>();
  }

  SubscriptionController({
    required this.subscriptionRepository,
    required this.paymentMethodRepository,
    required this.settingsRepository,
  });

  static const double _defaultBudget = 150.0;
  static const String _defaultCurrency = '\$';
  static const int _defaultReminder = 2;
  static const int _defaultReminderTime = 9 * 60;

  final List<Subscription> _subscriptions = [];
  final List<PaymentMethod> _paymentMethods = [];
  final List<String> _recentSearches = [];

  /// Dismissed Analytics insight keys, oldest first (insertion ordered).
  final Set<String> _dismissedInsights = <String>{};
  double _monthlyBudget = _defaultBudget;
  String _currency = _defaultCurrency;
  String _userName = '';
  String _userEmail = '';
  int _defaultReminderDays = _defaultReminder;
  int _defaultReminderTimeMinutes = _defaultReminderTime;
  bool _notificationsEnabled = true;
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

  /// Seeds the demo catalog and default cards into memory and storage (test fixture only).
  void resetForTesting() {
    _subscriptions
      ..clear()
      ..addAll(popularCatalog.take(5)); // Netflix, Spotify, ChatGPT Plus, YouTube Premium, iCloud+
    _paymentMethods
      ..clear()
      ..addAll(defaultPaymentMethods);
    _monthlyBudget = _defaultBudget;
    _currency = _defaultCurrency;
    _userName = '';
    _userEmail = '';
    _defaultReminderDays = _defaultReminder;
    _defaultReminderTimeMinutes = _defaultReminderTime;
    _notificationsEnabled = true;
    _sortOption = SubscriptionSortOption.renewalAsc;
    _groupByDate = false;
    _recentSearches.clear();
    _dismissedInsights.clear();
    _prePauseStatus.clear();
    _isLoaded = true;
    notifyListeners();
    final subs = List<Subscription>.from(_subscriptions);
    final methods = List<PaymentMethod>.from(_paymentMethods);
    _persist(() async {
      await subscriptionRepository.replaceAll(subs);
      await paymentMethodRepository.replaceAll(methods);
    });
  }

  // Getters
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  List<PaymentMethod> get paymentMethods => List.unmodifiable(_paymentMethods);
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  Set<String> get dismissedInsights => Set.unmodifiable(_dismissedInsights);
  double get monthlyBudget => _monthlyBudget;
  String get currency => _currency;
  String get userName => _userName;
  String get userEmail => _userEmail;
  int get defaultReminderDays => _defaultReminderDays;

  /// Default reminder time of day, in minutes after midnight.
  int get defaultReminderTimeMinutes => _defaultReminderTimeMinutes;
  bool get notificationsEnabled => _notificationsEnabled;
  SubscriptionSortOption get sortOption => _sortOption;
  bool get groupByDate => _groupByDate;
  bool get isLoaded => _isLoaded;

  double get totalMonthlySpend =>
      _cachedTotalMonthlySpend ??= SubscriptionStats.totalMonthlySpend(_subscriptions);

  double get totalYearlySpend => totalMonthlySpend * 12;

  int get totalActiveCount => _cachedTotalActiveCount ??= SubscriptionStats.activeCount(_subscriptions);

  int get totalPausedCount => _cachedTotalPausedCount ??= SubscriptionStats.pausedCount(_subscriptions);

  List<Subscription> get upcomingDue => _cachedUpcomingDue ??= SubscriptionStats.upcomingDue(_subscriptions);

  List<Subscription> get sortedSubscriptions =>
      _cachedSortedSubscriptions ??= SubscriptionStats.sorted(_subscriptions, _sortOption);

  Subscription? get highestCostSubscription {
    if (_highestCostCalculated) return _cachedHighestCostSubscription;
    _highestCostCalculated = true;
    return _cachedHighestCostSubscription = SubscriptionStats.highestCost(_subscriptions);
  }

  Map<SubscriptionCategory, double> get categorySpendMap =>
      _cachedCategorySpendMap ??= SubscriptionStats.categorySpend(_subscriptions);

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
    return SpendingTrendsEngine.calculateSummary(trends, monthlyBudget: _monthlyBudget);
  }

  // --- Persistence Integration ---

  /// Loads all state from storage, replacing whatever is in memory.
  /// Awaited once at startup, before the first frame.
  Future<void> load() async {
    try {
      final loadedSubs = await subscriptionRepository.getSubscriptions();
      final loadedMethods = await paymentMethodRepository.getPaymentMethods();
      _subscriptions
        ..clear()
        ..addAll(loadedSubs);
      _paymentMethods
        ..clear()
        ..addAll(loadedMethods);

      _monthlyBudget = await settingsRepository.getMonthlyBudget();
      _currency = await settingsRepository.getCurrency();
      final profile = await settingsRepository.getUserProfile();
      _userName = profile.name;
      _userEmail = profile.email;
      _defaultReminderDays = await settingsRepository.getDefaultReminderDays();
      _defaultReminderTimeMinutes = await settingsRepository.getDefaultReminderTimeMinutes();
      _notificationsEnabled = await settingsRepository.getNotificationsEnabled();
      _sortOption = await settingsRepository.getSortOption();
      _groupByDate = await settingsRepository.getGroupByDate();
      _recentSearches
        ..clear()
        ..addAll(await settingsRepository.getRecentSearches());
      _dismissedInsights
        ..clear()
        ..addAll(await settingsRepository.getDismissedInsights());
    } catch (e) {
      debugPrint('OneSpend: Failed to load data from repository: $e');
    }
    _isLoaded = true;
    checkAndProcessAutoRenewals();
    notifyListeners();
  }

  Future<void> _writeQueue = Future.value();

  /// Completes once every write queued so far has finished.
  Future<void> get pendingWrites => _writeQueue;

  void _persist(Future<void> Function() write) {
    _writeQueue = _writeQueue.then((_) => write()).catchError((Object e) {
      debugPrint('OneSpend: Failed to save data to repository: $e');
    });
  }

  void _persistSubscriptions(Iterable<Subscription> subs) {
    final snapshot = List<Subscription>.from(subs);
    if (snapshot.isEmpty) return;
    _persist(() => subscriptionRepository.upsert(snapshot));
  }

  void _persistPaymentMethods(Iterable<PaymentMethod> methods) {
    final snapshot = List<PaymentMethod>.from(methods);
    if (snapshot.isEmpty) return;
    _persist(() => paymentMethodRepository.upsert(snapshot));
  }

  /// Applies [update] to every subscription matching [test], then notifies and
  /// persists only those rows.
  void _updateSubscriptionsWhere(bool Function(Subscription s) test, Subscription Function(Subscription s) update) {
    final changed = <Subscription>[];
    for (int i = 0; i < _subscriptions.length; i++) {
      if (test(_subscriptions[i])) {
        _subscriptions[i] = update(_subscriptions[i]);
        changed.add(_subscriptions[i]);
      }
    }
    if (changed.isEmpty) return;
    notifyListeners();
    _persistSubscriptions(changed);
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

  /// Clears the default flag on every method except [keepId]; returns the demoted methods.
  List<PaymentMethod> _demoteOtherDefaults(String keepId) {
    final demoted = <PaymentMethod>[];
    for (int i = 0; i < _paymentMethods.length; i++) {
      if (_paymentMethods[i].id != keepId && _paymentMethods[i].isDefault) {
        _paymentMethods[i] = _paymentMethods[i].copyWith(isDefault: false);
        demoted.add(_paymentMethods[i]);
      }
    }
    return demoted;
  }

  void addPaymentMethod(PaymentMethod method) {
    final demoted = method.isDefault ? _demoteOtherDefaults(method.id) : const <PaymentMethod>[];
    _paymentMethods.add(method);
    notifyListeners();
    _persistPaymentMethods([...demoted, method]);
  }

  void updatePaymentMethod(PaymentMethod method) {
    final index = _paymentMethods.indexWhere((m) => m.id == method.id);
    if (index == -1) return;
    final demoted = method.isDefault ? _demoteOtherDefaults(method.id) : const <PaymentMethod>[];
    _paymentMethods[index] = method;
    notifyListeners();
    _persistPaymentMethods([...demoted, method]);
  }

  void deletePaymentMethod(String methodId, {String? replacementMethodId}) {
    final hasReplacement = replacementMethodId != null && replacementMethodId.isNotEmpty;
    final replacementName = hasReplacement ? (getPaymentMethod(replacementMethodId)?.displayName ?? '') : '';
    final relinked = <Subscription>[];
    for (int i = 0; i < _subscriptions.length; i++) {
      final sub = _subscriptions[i];
      if (sub.paymentMethodId != methodId) continue;
      _subscriptions[i] = hasReplacement
          ? sub.copyWith(
              paymentMethodId: replacementMethodId,
              paymentMethod: replacementName.isNotEmpty ? replacementName : sub.paymentMethod,
            )
          : sub.copyWith(clearPaymentMethodId: true, paymentMethod: '');
      relinked.add(_subscriptions[i]);
    }

    _paymentMethods.removeWhere((m) => m.id == methodId);
    notifyListeners();
    _persistSubscriptions(relinked);
    _persist(() => paymentMethodRepository.delete([methodId]));
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
    final replacementName = getPaymentMethod(toMethodId)?.displayName ?? '';
    _updateSubscriptionsWhere(
      (s) => s.paymentMethodId == fromMethodId,
      (s) => s.copyWith(
        paymentMethodId: toMethodId,
        paymentMethod: replacementName.isNotEmpty ? replacementName : s.paymentMethod,
      ),
    );
  }

  // --- Subscriptions Actions ---
  void addSubscription(Subscription subscription) {
    _subscriptions.add(subscription);
    notifyListeners();
    _persistSubscriptions([subscription]);
  }

  void batchAdd(Iterable<Subscription> newSubscriptions) {
    final added = newSubscriptions.toList();
    _subscriptions.addAll(added);
    notifyListeners();
    _persistSubscriptions(added);
  }

  void removeSubscription(String id) => batchDelete([id]);

  void updateSubscription(Subscription updated) {
    _updateSubscriptionsWhere((s) => s.id == updated.id, (_) => updated);
  }

  void renewSubscription(String id) {
    markSubscriptionPaid(id);
  }

  void markSubscriptionPaid(String id, [DateTime? paymentDate]) {
    _updateSubscriptionsWhere((s) => s.id == id, (s) => BillingSchedule.markPaid(s, paymentDate: paymentDate));
  }

  void skipSubscriptionCycle(String id) {
    _updateSubscriptionsWhere((s) => s.id == id, BillingSchedule.skipCycle);
  }

  bool addPaymentRecord(String id, DateTime date) {
    final sub = getSubscription(id);
    if (sub == null) return false;
    final alreadyExists = sub.paymentHistory.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
    if (alreadyExists) return false;
    final updatedHistory = List<DateTime>.from(sub.paymentHistory)
      ..add(date)
      ..sort((a, b) => b.compareTo(a));
    updateSubscription(sub.copyWith(paymentHistory: updatedHistory));
    return true;
  }

  void deletePaymentRecord(String id, int historyIndex) {
    final sub = getSubscription(id);
    if (sub == null || historyIndex < 0 || historyIndex >= sub.paymentHistory.length) return;
    final updatedHistory = List<DateTime>.from(sub.paymentHistory)..removeAt(historyIndex);
    updateSubscription(sub.copyWith(paymentHistory: updatedHistory));
  }

  /// Logs one payment per elapsed cycle for every overdue auto-renewing subscription.
  void checkAndProcessAutoRenewals() {
    _updateSubscriptionsWhere(BillingSchedule.isAutoRenewDue, BillingSchedule.applyAutoRenewal);
  }

  SubscriptionStatus _toggledStatus(Subscription sub) {
    if (sub.status == SubscriptionStatus.paused) {
      return _prePauseStatus.remove(sub.id) ?? SubscriptionStatus.active;
    }
    _prePauseStatus[sub.id] = sub.status;
    return SubscriptionStatus.paused;
  }

  void togglePauseSubscription(String id) => batchTogglePause([id]);

  void batchDelete(Iterable<String> ids) {
    final idSet = ids.toSet();
    _subscriptions.removeWhere((item) => idSet.contains(item.id));
    notifyListeners();
    _persist(() => subscriptionRepository.delete(idSet));
  }

  void batchTogglePause(Iterable<String> ids) {
    final idSet = ids.toSet();
    _updateSubscriptionsWhere((s) => idSet.contains(s.id), (s) => s.copyWith(status: _toggledStatus(s)));
  }

  void batchChangeCategory(Iterable<String> ids, SubscriptionCategory category) {
    final idSet = ids.toSet();
    _updateSubscriptionsWhere((s) => idSet.contains(s.id), (s) => s.copyWith(category: category));
  }

  void setMonthlyBudget(double amount) {
    _monthlyBudget = amount.clamp(0.0, 999999.0);
    notifyListeners();
    final value = _monthlyBudget;
    _persist(() => settingsRepository.setMonthlyBudget(value));
  }

  void setCurrency(String newCurrency) {
    _currency = newCurrency;
    notifyListeners();
    _persist(() => settingsRepository.setCurrency(newCurrency));
  }

  void setUserProfile(String name, String email) {
    _userName = name;
    _userEmail = email;
    notifyListeners();
    _persist(() => settingsRepository.setUserProfile(name, email));
  }

  void setDefaultReminderDays(int days) {
    _defaultReminderDays = days;
    notifyListeners();
    _persist(() => settingsRepository.setDefaultReminderDays(days));
  }

  void setDefaultReminderTimeMinutes(int minutes) {
    _defaultReminderTimeMinutes = minutes.clamp(0, 24 * 60 - 1);
    notifyListeners();
    final value = _defaultReminderTimeMinutes;
    _persist(() => settingsRepository.setDefaultReminderTimeMinutes(value));
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
    _persist(() => settingsRepository.setNotificationsEnabled(value));
  }

  void setSortOption(SubscriptionSortOption option) {
    _sortOption = option;
    notifyListeners();
    _persist(() => settingsRepository.setSortOption(option));
  }

  void setGroupByDate(bool value) {
    _groupByDate = value;
    notifyListeners();
    _persist(() => settingsRepository.setGroupByDate(value));
  }

  // --- Recent Searches ---
  void _saveRecentSearches() {
    final snapshot = List<String>.from(_recentSearches);
    _persist(() => settingsRepository.saveRecentSearches(snapshot));
  }

  void addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _recentSearches.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 10) {
      _recentSearches.removeRange(10, _recentSearches.length);
    }
    notifyListeners();
    _saveRecentSearches();
  }

  void removeRecentSearch(String query) {
    final trimmed = query.trim().toLowerCase();
    final beforeCount = _recentSearches.length;
    _recentSearches.removeWhere((q) => q.toLowerCase() == trimmed);
    if (_recentSearches.length != beforeCount) {
      notifyListeners();
      _saveRecentSearches();
    }
  }

  void clearRecentSearches() {
    if (_recentSearches.isEmpty) return;
    _recentSearches.clear();
    notifyListeners();
    _saveRecentSearches();
  }

  // --- Dismissed insights ---
  static const int _maxDismissedInsights = 100;

  void _saveDismissedInsights() {
    final snapshot = List<String>.from(_dismissedInsights);
    _persist(() => settingsRepository.setDismissedInsights(snapshot));
  }

  void dismissInsight(String key) {
    if (!_dismissedInsights.add(key)) return;
    while (_dismissedInsights.length > _maxDismissedInsights) {
      _dismissedInsights.remove(_dismissedInsights.first);
    }
    notifyListeners();
    _saveDismissedInsights();
  }

  void undismissInsight(String key) {
    if (!_dismissedInsights.remove(key)) return;
    notifyListeners();
    _saveDismissedInsights();
  }

  void restoreDismissedInsights() {
    if (_dismissedInsights.isEmpty) return;
    _dismissedInsights.clear();
    notifyListeners();
    _saveDismissedInsights();
  }

  void restoreDefaultCatalog() {
    _subscriptions
      ..clear()
      ..addAll(popularCatalog);
    notifyListeners();
    final snapshot = List<Subscription>.from(_subscriptions);
    _persist(() => subscriptionRepository.replaceAll(snapshot));
  }

  void clearAllData() {
    _subscriptions.clear();
    _prePauseStatus.clear();
    notifyListeners();
    _persist(() => subscriptionRepository.replaceAll(const []));
  }

  String exportDataAsJson() => SubscriptionExporter.toJson(_subscriptions);

  String exportDataAsCsv() => SubscriptionExporter.toCsv(_subscriptions);
}
