import 'package:flutter/foundation.dart';
import '../../../backup/domain/backup_snapshot.dart';
import '../../../../core/di/injection.dart';
import '../../../../models/spending_trend.dart';
import '../../../currency/data/exchange_rate_repository.dart';
import '../../../currency/domain/currency.dart';
import '../../../currency/domain/exchange_rates.dart';
import '../../../currency/domain/money_format.dart';
import '../../../payment_methods/data/fixtures/default_payment_methods.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../../payment_methods/domain/repositories/payment_method_repository.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../data/fixtures/popular_catalog.dart';
import '../../data/subscription_exporter.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';
import '../../domain/repositories/custom_category_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/services/billing_schedule.dart';
import '../../domain/services/subscription_stats.dart';

/// Reactive Controller managing Subscriptions, Payment Methods, and Settings.
/// Injected via GetIt; depends on abstract repositories, not storage directly.
///
/// State is held in memory; each mutation persists only what it changed through
/// an ordered write queue, so writes land in the order they were made.
///
/// Each subscription is billed in its own currency; totals, budget and analytics are in
/// the main [currency], converted with [rates].
class SubscriptionController extends ChangeNotifier {
  final SubscriptionRepository subscriptionRepository;
  final PaymentMethodRepository paymentMethodRepository;
  final SettingsRepository settingsRepository;
  final ExchangeRateRepository rates;

  /// Null keeps custom categories in memory only (controllers built directly in tests).
  final CustomCategoryRepository? customCategoryRepository;

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
    ExchangeRateRepository? rates,
    this.customCategoryRepository,
  }) : rates = rates ?? ExchangeRateRepository() {
    this.rates.addListener(notifyListeners);
  }

  @override
  void dispose() {
    rates.removeListener(notifyListeners);
    super.dispose();
  }

  static const double _defaultBudget = 150.0;

  /// Largest price or budget accepted (fits IDR/VND-sized amounts).
  static const double maxAmount = 999999999.0;
  static const String _defaultCurrency = CurrencyCatalog.defaultCode;
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
  DateTime? _lastBackupAt;
  DateTime? _trackingSince;
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
    _lastBackupAt = null;
    _trackingSince = null;
    _prePauseStatus.clear();
    CustomCategoryRegistry.replaceAll(const []);
    _isLoaded = true;
    notifyListeners();
    final subs = List<Subscription>.from(_subscriptions);
    final methods = List<PaymentMethod>.from(_paymentMethods);
    _persist(() async {
      await subscriptionRepository.replaceAll(subs);
      await paymentMethodRepository.replaceAll(methods);
      await customCategoryRepository?.replaceAll(const []);
    });
  }

  // Getters
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  List<PaymentMethod> get paymentMethods => List.unmodifiable(_paymentMethods);
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  Set<String> get dismissedInsights => Set.unmodifiable(_dismissedInsights);
  double get monthlyBudget => _monthlyBudget;

  /// The main currency (ISO code): totals, budget and analytics are shown in it.
  String get currency => _currency;
  String get userName => _userName;
  String get userEmail => _userEmail;
  int get defaultReminderDays => _defaultReminderDays;

  /// Default reminder time of day, in minutes after midnight.
  int get defaultReminderTimeMinutes => _defaultReminderTimeMinutes;
  bool get notificationsEnabled => _notificationsEnabled;
  SubscriptionSortOption get sortOption => _sortOption;
  bool get groupByDate => _groupByDate;

  /// When a backup was last saved to the device, if ever.
  DateTime? get lastBackupAt => _lastBackupAt;

  /// When the user started tracking: the first subscription was added (or, for data
  /// from before this was recorded, the oldest logged payment). The spending
  /// trajectory doesn't invent history before it. Null in fresh test fixtures.
  DateTime? get trackingSince => _trackingSince;

  /// Records today as the start of tracking the first time anything is added.
  void _markTrackingStarted() {
    if (_trackingSince != null) return;
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    _trackingSince = day;
    _persist(() => settingsRepository.setTrackingSince(day));
  }
  bool get isLoaded => _isLoaded;

  // --- Currency ---

  CurrencyConverter get converter => rates.converter;

  /// [amount] of [code] in the main currency, or null when no rate is known.
  double? toMainOrNull(double amount, String code) => converter.convert(amount, code, _currency);

  /// [amount] of [code] in the main currency; 0 when no rate is known (see [hasRate]).
  double toMain(double amount, String code) => toMainOrNull(amount, code) ?? 0;

  bool hasRate(String code) => code == _currency || toMainOrNull(1, code) != null;

  /// "≈ Rs 4,300" for an amount billed in another currency; null for the main currency or
  /// when no rate is known.
  String? approxInMain(double amount, String code) {
    if (code == _currency) return null;
    final converted = toMainOrNull(amount, code);
    return converted == null ? null : '≈ ${formatMoney(converted, _currency, style: MoneyStyle.approximate)}';
  }

  /// [sub]'s monthly cost in the main currency.
  double monthlyCostInMain(Subscription sub) => SubscriptionStats.monthlyCost(sub, toMain);

  /// Currencies used by subscriptions, main currency first, then by number of subscriptions.
  List<String> get currenciesInUse {
    final counts = <String, int>{};
    for (final s in _subscriptions) {
      counts[s.currency] = (counts[s.currency] ?? 0) + 1;
    }
    counts.remove(_currency);
    final others = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return [_currency, ...others];
  }

  /// Subscriptions left out of totals because their currency has no exchange rate.
  List<Subscription> get subscriptionsMissingRate =>
      _subscriptions.where((s) => !hasRate(s.currency)).toList();

  double get totalMonthlySpend =>
      _cachedTotalMonthlySpend ??= SubscriptionStats.totalMonthlySpend(_subscriptions, toMain);

  double get totalYearlySpend => totalMonthlySpend * 12;

  int get totalActiveCount => _cachedTotalActiveCount ??= SubscriptionStats.activeCount(_subscriptions);

  int get totalPausedCount => _cachedTotalPausedCount ??= SubscriptionStats.pausedCount(_subscriptions);

  List<Subscription> get upcomingDue => _cachedUpcomingDue ??= SubscriptionStats.upcomingDue(_subscriptions);

  List<Subscription> get sortedSubscriptions =>
      _cachedSortedSubscriptions ??= SubscriptionStats.sorted(_subscriptions, _sortOption, toMain);

  Subscription? get highestCostSubscription {
    if (_highestCostCalculated) return _cachedHighestCostSubscription;
    _highestCostCalculated = true;
    return _cachedHighestCostSubscription = SubscriptionStats.highestCost(_subscriptions, toMain);
  }

  Map<SubscriptionCategory, double> get categorySpendMap =>
      _cachedCategorySpendMap ??= SubscriptionStats.categorySpend(_subscriptions, toMain);

  List<MonthlySpendPoint> getSpendingTrends(SpendingTrendHorizon horizon, [DateTime? referenceDate]) {
    if (referenceDate == null && _cachedTrends.containsKey(horizon)) {
      return _cachedTrends[horizon]!;
    }
    final trends = SpendingTrendsEngine.calculateTrends(
      subscriptions: _subscriptions,
      horizon: horizon,
      referenceDate: referenceDate,
      toMain: toMain,
      trackingSince: _trackingSince,
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
      // Categories first, so subscriptions in custom categories resolve their names.
      CustomCategoryRegistry.replaceAll(await customCategoryRepository?.getCustomCategories() ?? const []);
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
      _lastBackupAt = await settingsRepository.getLastBackupAt();
      _trackingSince = await settingsRepository.getTrackingSince();
      if (_trackingSince == null && _subscriptions.isNotEmpty) {
        // Data from before this was recorded: start at the oldest logged payment
        // (or today), rather than estimating months that were never tracked.
        final payments = [for (final s in _subscriptions) ...s.paymentHistory];
        final now = DateTime.now();
        final oldest = payments.isEmpty ? now : payments.reduce((a, b) => a.isBefore(b) ? a : b);
        final day = DateTime(oldest.year, oldest.month, oldest.day);
        _trackingSince = day;
        _persist(() => settingsRepository.setTrackingSince(day));
      }
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
    _markTrackingStarted();
    _subscriptions.add(subscription);
    notifyListeners();
    _persistSubscriptions([subscription]);
  }

  void batchAdd(Iterable<Subscription> newSubscriptions) {
    _markTrackingStarted();
    final added = newSubscriptions.toList();
    _subscriptions.addAll(added);
    notifyListeners();
    _persistSubscriptions(added);
  }

  void removeSubscription(String id) => batchDelete([id]);

  void updateSubscription(Subscription updated) {
    _updateSubscriptionsWhere((s) => s.id == updated.id, (_) => updated);
  }

  /// What [renewSubscription] changed, per subscription id, so it can be undone.
  final Map<String, ({DateTime nextBillingDate, List<DateTime> paymentHistory})> _renewUndo = {};

  /// Marks [id] paid and advances it one cycle, remembering the previous renewal
  /// date and history so an accidental Renew can be reverted with [undoRenew].
  /// Returns false (and changes nothing) if it was already paid that day.
  bool renewSubscription(String id) {
    final before = getSubscription(id);
    if (before == null || !markSubscriptionPaid(id)) return false;
    _renewUndo[id] = (nextBillingDate: before.nextBillingDate, paymentHistory: before.paymentHistory);
    return true;
  }

  bool canUndoRenew(String id) => _renewUndo.containsKey(id);

  /// Reverts the last [renewSubscription] of [id]: restores its renewal date and
  /// payment history only, so other edits made since are kept.
  bool undoRenew(String id) {
    final snapshot = _renewUndo.remove(id);
    final sub = getSubscription(id);
    if (snapshot == null || sub == null) return false;
    updateSubscription(sub.copyWith(
      nextBillingDate: snapshot.nextBillingDate,
      paymentHistory: snapshot.paymentHistory,
    ));
    return true;
  }

  /// Forgets the undo for [id] (e.g. once the Undo affordance has expired).
  void discardRenewUndo(String id) => _renewUndo.remove(id);

  /// Logs a payment for [id] and advances it one cycle.
  ///
  /// Refuses (returns false, changes nothing) when a payment is already logged on
  /// that day, so repeated taps can't record the same payment twice.
  bool markSubscriptionPaid(String id, [DateTime? paymentDate]) {
    final sub = getSubscription(id);
    if (sub == null || BillingSchedule.isAlreadyPaid(sub, paymentDate: paymentDate)) return false;
    _updateSubscriptionsWhere((s) => s.id == id, (s) => BillingSchedule.markPaid(s, paymentDate: paymentDate));
    return true;
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
    _monthlyBudget = amount.clamp(0.0, maxAmount);
    notifyListeners();
    final value = _monthlyBudget;
    _persist(() => settingsRepository.setMonthlyBudget(value));
  }

  /// Changes the main currency. The budget is converted into it (when a rate is known);
  /// subscriptions keep their own currency.
  void setCurrency(String newCurrency) {
    final code = CurrencyCatalog.normalize(newCurrency);
    if (code == _currency) return;
    final converted = converter.convert(_monthlyBudget, _currency, code);
    _currency = code;
    if (converted != null) _monthlyBudget = _roundBudget(converted, code);
    notifyListeners();
    final budget = _monthlyBudget;
    _persist(() async {
      await settingsRepository.setCurrency(code);
      await settingsRepository.setMonthlyBudget(budget);
    });
  }

  /// Rounds a converted budget to a tidy figure: whole units below 1,000, otherwise two
  /// significant figures (41,873 → 42,000).
  static double _roundBudget(double amount, String code) {
    if (amount <= 0) return 0;
    if (amount < 1000) return amount.roundToDouble();
    var step = 1.0;
    while (amount / step >= 100) {
      step *= 10;
    }
    return ((amount / step).round() * step).clamp(0.0, maxAmount);
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

  // --- Backup & restore ---

  void markBackupSaved(DateTime at) {
    _lastBackupAt = at;
    notifyListeners();
    _persist(() => settingsRepository.setLastBackupAt(at));
  }

  /// Replaces all subscriptions and cards, and the settings when given (restoring a backup).
  void replaceAllData({
    required List<Subscription> subscriptions,
    required List<PaymentMethod> paymentMethods,
    BackupSettings? settings,
    Map<String, RateOverride>? rateOverrides,
    List<CustomCategory>? customCategories,
  }) {
    if (customCategories != null) CustomCategoryRegistry.replaceAll(customCategories);
    _subscriptions
      ..clear()
      ..addAll(subscriptions);
    _paymentMethods
      ..clear()
      ..addAll(paymentMethods);
    _prePauseStatus.clear();
    if (settings != null) {
      _monthlyBudget = settings.monthlyBudget.clamp(0.0, maxAmount);
      _currency = CurrencyCatalog.normalize(settings.currency);
      _defaultReminderDays = settings.defaultReminderDays;
      _defaultReminderTimeMinutes = settings.defaultReminderTimeMinutes.clamp(0, 24 * 60 - 1);
      _notificationsEnabled = settings.notificationsEnabled;
      _sortOption = settings.sortOption;
      _groupByDate = settings.groupByDate;
    }
    notifyListeners();

    final subs = List<Subscription>.from(_subscriptions);
    final methods = List<PaymentMethod>.from(_paymentMethods);
    final budget = _monthlyBudget, currency = _currency, days = _defaultReminderDays;
    final time = _defaultReminderTimeMinutes, notify = _notificationsEnabled;
    final sort = _sortOption, group = _groupByDate;
    _persist(() async {
      await subscriptionRepository.replaceAll(subs);
      await paymentMethodRepository.replaceAll(methods);
      if (customCategories != null) await customCategoryRepository?.replaceAll(customCategories);
      if (settings != null) {
        await settingsRepository.setMonthlyBudget(budget);
        await settingsRepository.setCurrency(currency);
        await settingsRepository.setDefaultReminderDays(days);
        await settingsRepository.setDefaultReminderTimeMinutes(time);
        await settingsRepository.setNotificationsEnabled(notify);
        await settingsRepository.setSortOption(sort);
        await settingsRepository.setGroupByDate(group);
      }
      if (rateOverrides != null) await rates.replaceOverrides(rateOverrides);
    });
  }

  /// Appends subscriptions and cards (restoring a backup with "Add missing items").
  void addItems({
    required List<Subscription> subscriptions,
    required List<PaymentMethod> paymentMethods,
    List<CustomCategory> customCategories = const [],
  }) {
    _markTrackingStarted();
    if (customCategories.isNotEmpty) {
      CustomCategoryRegistry.replaceAll([...CustomCategoryRegistry.categories, ...customCategories]);
      final snapshot = List<CustomCategory>.from(customCategories);
      _persist(() async => customCategoryRepository?.upsert(snapshot));
    }
    if (subscriptions.isEmpty && paymentMethods.isEmpty) {
      if (customCategories.isNotEmpty) notifyListeners();
      return;
    }
    _subscriptions.addAll(subscriptions);
    _paymentMethods.addAll(paymentMethods);
    notifyListeners();
    _persistSubscriptions(subscriptions);
    _persistPaymentMethods(paymentMethods);
  }

  // --- Custom categories ---

  /// The user's categories, in display order.
  List<CustomCategory> get customCategories => CustomCategoryRegistry.categories;

  /// How many subscriptions are in [category].
  int subscriptionCountIn(SubscriptionCategory category) => _subscriptions.where((s) => s.category == category).length;

  /// Adds a category at the end of the list and returns it as a [SubscriptionCategory].
  SubscriptionCategory addCustomCategory({required String name, required int iconCodePoint, required int colorValue}) {
    final existing = CustomCategoryRegistry.categories;
    final category = CustomCategory(
      id: CustomCategory.newId(),
      name: name.trim(),
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      sortOrder: existing.isEmpty ? 0 : existing.last.sortOrder + 1,
    );
    CustomCategoryRegistry.replaceAll([...existing, category]);
    notifyListeners();
    _persist(() async => customCategoryRepository?.upsert([category]));
    return SubscriptionCategory.custom(category.id);
  }

  void updateCustomCategory(CustomCategory category) {
    final updated = category.copyWith(name: category.name.trim());
    CustomCategoryRegistry.replaceAll([
      for (final c in CustomCategoryRegistry.categories) c.id == updated.id ? updated : c,
    ]);
    notifyListeners();
    _persist(() async => customCategoryRepository?.upsert([updated]));
  }

  /// Deletes a custom category and moves its subscriptions to [moveTo].
  void deleteCustomCategory(String id, {required SubscriptionCategory moveTo}) {
    final from = SubscriptionCategory.custom(id);
    final target = moveTo == from ? SubscriptionCategory.utilities : moveTo;
    final moved = <Subscription>[];
    for (int i = 0; i < _subscriptions.length; i++) {
      if (_subscriptions[i].category != from) continue;
      _subscriptions[i] = _subscriptions[i].copyWith(category: target);
      moved.add(_subscriptions[i]);
    }
    CustomCategoryRegistry.replaceAll([
      for (final c in CustomCategoryRegistry.categories)
        if (c.id != id) c,
    ]);
    notifyListeners();
    _persistSubscriptions(moved);
    _persist(() async => customCategoryRepository?.delete([id]));
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
    _markTrackingStarted();
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
