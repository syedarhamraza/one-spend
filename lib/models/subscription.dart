import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_method.dart';
export 'payment_method.dart';

enum BillingCycle {
  weekly('Weekly', 52),
  monthly('Monthly', 12),
  quarterly('Quarterly', 4),
  yearly('Yearly', 1);

  final String label;
  final int occurrencesPerYear;
  const BillingCycle(this.label, this.occurrencesPerYear);

  static BillingCycle fromString(String? val) {
    return BillingCycle.values.firstWhere(
      (e) => e.name == val,
      orElse: () => BillingCycle.monthly,
    );
  }
}

enum SubscriptionCategory {
  entertainment('Entertainment', Icons.movie_filter_rounded),
  music('Music & Audio', Icons.music_note_rounded),
  productivity('Productivity & AI', Icons.auto_awesome_rounded),
  cloud('Cloud & Backup', Icons.cloud_rounded),
  gaming('Gaming', Icons.sports_esports_rounded),
  design('Design & Media', Icons.palette_rounded),
  developer('Developer Tools', Icons.terminal_rounded),
  utilities('Utilities', Icons.build_rounded),
  finance('Finance & Banking', Icons.account_balance_wallet_rounded),
  health('Health & Fitness', Icons.fitness_center_rounded);

  final String label;
  final IconData icon;
  const SubscriptionCategory(this.label, this.icon);

  static SubscriptionCategory fromString(String? val) {
    return SubscriptionCategory.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SubscriptionCategory.entertainment,
    );
  }
}

enum SubscriptionStatus {
  active('Active', Color(0xFF00C05A)),
  trial('Free Trial', Color(0xFF5390F5)),
  dueSoon('Due Soon', Color(0xFFF07167)),
  paused('Paused', Color(0xFF9E9EA4));

  final String label;
  final Color color;
  const SubscriptionStatus(this.label, this.color);

  static SubscriptionStatus fromString(String? val) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SubscriptionStatus.active,
    );
  }
}

enum SubscriptionSortOption {
  renewalAsc('Next renewal (soonest)'),
  renewalDesc('Next renewal (latest)'),
  nameAsc('Name (A to Z)'),
  nameDesc('Name (Z to A)'),
  priceDesc('Price (High to low)'),
  priceAsc('Price (Low to high)');

  final String label;
  const SubscriptionSortOption(this.label);

  static SubscriptionSortOption fromString(String? val) {
    return SubscriptionSortOption.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SubscriptionSortOption.renewalAsc,
    );
  }
}

class Subscription {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final BillingCycle billingCycle;
  final SubscriptionCategory category;
  final Color brandColor;
  final IconData iconData;
  final DateTime nextBillingDate;
  final SubscriptionStatus status;
  final String paymentMethod;
  final String? paymentMethodId;
  final int reminderDays;
  final bool isPopular;
  final String notes;
  final List<DateTime> paymentHistory;
  final String accountUrl;
  final String? logoUrl;
  final String? brandPresetId;
  final bool autoRenew;
  final int? anchorDay;

  const Subscription({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = '\$',
    required this.billingCycle,
    required this.category,
    required this.brandColor,
    required this.iconData,
    required this.nextBillingDate,
    this.status = SubscriptionStatus.active,
    this.paymentMethod = 'Samsung Pay •••• 9124',
    this.paymentMethodId,
    this.reminderDays = 2,
    this.isPopular = false,
    this.notes = '',
    this.paymentHistory = const [],
    this.accountUrl = '',
    this.logoUrl,
    this.brandPresetId,
    this.autoRenew = true,
    this.anchorDay,
  });

  Subscription copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    BillingCycle? billingCycle,
    SubscriptionCategory? category,
    Color? brandColor,
    IconData? iconData,
    DateTime? nextBillingDate,
    SubscriptionStatus? status,
    String? paymentMethod,
    String? paymentMethodId,
    bool clearPaymentMethodId = false,
    int? reminderDays,
    bool? isPopular,
    String? notes,
    List<DateTime>? paymentHistory,
    String? accountUrl,
    String? logoUrl,
    String? brandPresetId,
    bool? autoRenew,
    int? anchorDay,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      category: category ?? this.category,
      brandColor: brandColor ?? this.brandColor,
      iconData: iconData ?? this.iconData,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodId: clearPaymentMethodId ? null : (paymentMethodId ?? this.paymentMethodId),
      reminderDays: reminderDays ?? this.reminderDays,
      isPopular: isPopular ?? this.isPopular,
      notes: notes ?? this.notes,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      accountUrl: accountUrl ?? this.accountUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      brandPresetId: brandPresetId ?? this.brandPresetId,
      autoRenew: autoRenew ?? this.autoRenew,
      anchorDay: anchorDay ?? this.anchorDay,
    );
  }

  double get monthlyCost {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return (price * 52) / 12;
      case BillingCycle.monthly:
        return price;
      case BillingCycle.quarterly:
        return (price * 4) / 12;
      case BillingCycle.yearly:
        return price / 12;
    }
  }

  double get yearlyCost => monthlyCost * 12;

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextBillingDate.year, nextBillingDate.month, nextBillingDate.day);
    return target.difference(today).inDays;
  }

  /// Calculates the next sequential billing date based on the billing cycle
  DateTime calculateNextDateFrom(DateTime fromDate) {
    DateTime newDate;
    final anchor = anchorDay ?? nextBillingDate.day;
    switch (billingCycle) {
      case BillingCycle.weekly:
        // Use calendar arithmetic instead of Duration(days: 7) to avoid DST hour shift
        newDate = DateTime(fromDate.year, fromDate.month, fromDate.day + 7, fromDate.hour, fromDate.minute);
        break;
      case BillingCycle.monthly:
        final targetMonth = fromDate.month + 1;
        final targetYear = fromDate.year + (targetMonth > 12 ? 1 : 0);
        final normalizedMonth = ((targetMonth - 1) % 12) + 1;
        final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
        final clampedDay = anchor.clamp(1, lastDay);
        newDate = DateTime(targetYear, normalizedMonth, clampedDay, fromDate.hour, fromDate.minute);
        break;
      case BillingCycle.quarterly:
        final targetMonth = fromDate.month + 3;
        final targetYear = fromDate.year + ((targetMonth - 1) ~/ 12);
        final normalizedMonth = ((targetMonth - 1) % 12) + 1;
        final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
        final clampedDay = anchor.clamp(1, lastDay);
        newDate = DateTime(targetYear, normalizedMonth, clampedDay, fromDate.hour, fromDate.minute);
        break;
      case BillingCycle.yearly:
        final targetYear = fromDate.year + 1;
        final lastDay = DateTime(targetYear, fromDate.month + 1, 0).day;
        final clampedDay = anchor.clamp(1, lastDay);
        newDate = DateTime(targetYear, fromDate.month, clampedDay, fromDate.hour, fromDate.minute);
        break;
    }
    return newDate;
  }

  /// Returns the next projected billing dates starting from nextBillingDate
  List<DateTime> getUpcomingBillingDates([int count = 3]) {
    final list = <DateTime>[];
    DateTime current = nextBillingDate;
    for (int i = 0; i < count; i++) {
      list.add(current);
      current = calculateNextDateFrom(current);
    }
    return list;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'billingCycle': billingCycle.name,
      'category': category.name,
      'brandColor': brandColor.toARGB32(),
      'iconCodePoint': iconData.codePoint,
      'iconFontFamily': iconData.fontFamily,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'status': status.name,
      'paymentMethod': paymentMethod,
      'paymentMethodId': paymentMethodId,
      'reminderDays': reminderDays,
      'isPopular': isPopular,
      'notes': notes,
      'paymentHistory': paymentHistory.map((d) => d.toIso8601String()).toList(),
      'accountUrl': accountUrl,
      'logoUrl': logoUrl,
      'brandPresetId': brandPresetId,
      'autoRenew': autoRenew,
      'anchorDay': anchorDay ?? nextBillingDate.day,
    };
  }

  static const List<IconData> _supportedIcons = [
    Icons.movie_filter_rounded,
    Icons.movie_rounded,
    Icons.tv_rounded,
    Icons.play_arrow_rounded,
    Icons.music_note_rounded,
    Icons.album_rounded,
    Icons.headphones_rounded,
    Icons.auto_awesome_rounded,
    Icons.psychology_rounded,
    Icons.terminal_rounded,
    Icons.code_rounded,
    Icons.cloud_rounded,
    Icons.storage_rounded,
    Icons.sports_esports_rounded,
    Icons.videogame_asset_rounded,
    Icons.brush_rounded,
    Icons.palette_rounded,
    Icons.fitness_center_rounded,
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.newspaper_rounded,
    Icons.school_rounded,
    Icons.wifi_rounded,
    Icons.shield_rounded,
    Icons.attach_money_rounded,
    Icons.subscriptions_rounded,
    Icons.star_rounded,
    Icons.build_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.work_rounded,
    Icons.credit_card_rounded,
    Icons.payment_rounded,
    Icons.phone_android_rounded,
    Icons.laptop_rounded,
    Icons.book_rounded,
    Icons.pets_rounded,
    Icons.home_rounded,
    Icons.local_cafe_rounded,
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.flight_rounded,
    Icons.lock_rounded,
    Icons.security_rounded,
    Icons.email_rounded,
    Icons.chat_rounded,
    Icons.web_rounded,
    Icons.apps_rounded,
  ];

  static final Map<int, IconData> _knownIcons = {
    for (final icon in _supportedIcons) icon.codePoint: icon,
  };

  static IconData resolveIconData(int? codePoint, SubscriptionCategory category) {
    if (codePoint != null && _knownIcons.containsKey(codePoint)) {
      return _knownIcons[codePoint]!;
    }
    return category.icon;
  }

  static String generateUniqueId([String prefix = 'sub']) {
    final now = DateTime.now();
    final random = math.Random().nextInt(99999).toString().padLeft(5, '0');
    return '${prefix}_${now.microsecondsSinceEpoch}_$random';
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final historyList = (json['paymentHistory'] as List<dynamic>?)
            ?.map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now())
            .toList() ??
        [];

    final colorVal = json['brandColor'] as int? ?? 0xFF5390F5;
    final category = SubscriptionCategory.fromString(json['category'] as String?);
    final resolvedIcon = resolveIconData(json['iconCodePoint'] as int?, category);

    return Subscription(
      id: json['id'] as String? ?? generateUniqueId('sub'),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '\$',
      billingCycle: BillingCycle.fromString(json['billingCycle'] as String?),
      category: category,
      brandColor: Color(colorVal),
      iconData: resolvedIcon,
      nextBillingDate: DateTime.tryParse(json['nextBillingDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      status: SubscriptionStatus.fromString(json['status'] as String?),
      paymentMethod: json['paymentMethod'] as String? ?? 'Samsung Pay (Visa •••• 9124)',
      paymentMethodId: json['paymentMethodId'] as String?,
      reminderDays: json['reminderDays'] as int? ?? 2,
      isPopular: json['isPopular'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      paymentHistory: historyList,
      accountUrl: json['accountUrl'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      brandPresetId: json['brandPresetId'] as String?,
      autoRenew: json['autoRenew'] as bool? ?? true,
      anchorDay: json['anchorDay'] as int?,
    );
  }
}

/// Catalog of Popular Subscriptions for quick 1-tap addition
final List<Subscription> popularCatalog = [
  Subscription(
    id: 'pop_netflix',
    name: 'Netflix',
    description: 'Premium Ultra HD 4K + HDR, 4 simultaneous screens',
    price: 22.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.entertainment,
    brandColor: const Color(0xFFE50914),
    iconData: Icons.tv_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 4)),
    paymentMethod: 'Samsung Pay (Visa •••• 9124)',
    paymentMethodId: 'pay_samsung_visa',
    reminderDays: 2,
    isPopular: true,
    notes: 'Family 4K plan shared with household',
  ),
  Subscription(
    id: 'pop_spotify',
    name: 'Spotify',
    description: 'Family Plan • 6 accounts, ad-free music & podcasts',
    price: 16.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.music,
    brandColor: const Color(0xFF1DB954),
    iconData: Icons.music_note_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 9)),
    paymentMethod: 'Mastercard •••• 4242',
    paymentMethodId: 'pay_mastercard_4242',
    reminderDays: 3,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_chatgpt',
    name: 'ChatGPT Plus',
    description: 'Access to GPT-4o, DALL-E, advanced voice mode',
    price: 20.00,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.productivity,
    brandColor: const Color(0xFF10A37F),
    iconData: Icons.psychology_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 14)),
    paymentMethod: 'Samsung Pay (Visa •••• 9124)',
    paymentMethodId: 'pay_samsung_visa',
    reminderDays: 1,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_youtube',
    name: 'YouTube Premium',
    description: 'Ad-free playback, background play, YouTube Music',
    price: 13.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.entertainment,
    brandColor: const Color(0xFFFF0000),
    iconData: Icons.play_arrow_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 18)),
    paymentMethod: 'Google Pay •••• 7731',
    paymentMethodId: 'pay_google_7731',
    reminderDays: 2,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_icloud',
    name: 'iCloud+',
    description: '2TB Cloud storage, Private Relay, Hide My Email',
    price: 9.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.cloud,
    brandColor: const Color(0xFF34AADC),
    iconData: Icons.cloud_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 22)),
    paymentMethod: 'Samsung Pay (Visa •••• 9124)',
    paymentMethodId: 'pay_samsung_visa',
    reminderDays: 2,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_adobe',
    name: 'Adobe Creative Cloud',
    description: 'All Apps suite: Photoshop, Illustrator, Premiere Pro',
    price: 54.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.design,
    brandColor: const Color(0xFFFF4B4B),
    iconData: Icons.brush_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 27)),
    paymentMethod: 'Personal Meezan •••• 5519',
    paymentMethodId: 'pay_meezan_5519',
    reminderDays: 3,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_copilot',
    name: 'GitHub Copilot',
    description: 'Individual developer plan for AI code completions',
    price: 10.00,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.developer,
    brandColor: const Color(0xFF6E5494),
    iconData: Icons.terminal_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 11)),
    paymentMethod: 'PayPal • syed@onespend.app',
    paymentMethodId: 'pay_paypal_main',
    reminderDays: 2,
    isPopular: true,
  ),
  Subscription(
    id: 'pop_disney',
    name: 'Disney+',
    description: 'Standard with Ads: Disney, Pixar, Marvel, Star Wars',
    price: 9.99,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.entertainment,
    brandColor: const Color(0xFF113CCF),
    iconData: Icons.movie_rounded,
    nextBillingDate: DateTime.now().add(const Duration(days: 16)),
    paymentMethod: 'Mastercard •••• 4242',
    reminderDays: 2,
    isPopular: true,
  ),
];

/// Reactive Global Store for Subscriptions & Preferences with SharedPreferences persistence
class SubscriptionStore extends ChangeNotifier {
  static final SubscriptionStore instance = SubscriptionStore._internal();
  factory SubscriptionStore() => instance;

  static const String _storageKeySubs = 'onespend_subscriptions';
  static const String _storageKeyBudget = 'onespend_monthly_budget';
  static const String _storageKeyCurrency = 'onespend_currency';
  static const String _storageKeyUserName = 'onespend_user_name';
  static const String _storageKeyUserEmail = 'onespend_user_email';
  static const String _storageKeyDefaultReminder = 'onespend_default_reminder';
  static const String _storageKeySortOption = 'onespend_sort_option';
  static const String _storageKeyGroupByDate = 'onespend_group_by_date';
  static const String _storageKeyPaymentMethods = 'onespend_payment_methods';

  SubscriptionStore._internal() {
    _subscriptions.addAll([
      popularCatalog[0], // Netflix
      popularCatalog[1], // Spotify
      popularCatalog[2], // ChatGPT Plus
      popularCatalog[3], // YouTube Premium
      popularCatalog[4], // iCloud+
    ]);
    _paymentMethods.addAll(defaultPaymentMethods);
    _loadFromStorage();
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

  void _invalidateCache() {
    _cachedTotalMonthlySpend = null;
    _cachedTotalActiveCount = null;
    _cachedTotalPausedCount = null;
    _cachedUpcomingDue = null;
    _cachedSortedSubscriptions = null;
    _cachedHighestCostSubscription = null;
    _highestCostCalculated = false;
    _cachedCategorySpendMap = null;
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

  // --- Persistence ---
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subsJson = prefs.getString(_storageKeySubs);
      if (subsJson != null && subsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(subsJson) as List<dynamic>;
        _subscriptions.clear();
        for (var item in decoded) {
          _subscriptions.add(Subscription.fromJson(item as Map<String, dynamic>));
        }
      }

      final methodsJson = prefs.getString(_storageKeyPaymentMethods);
      if (methodsJson != null && methodsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(methodsJson) as List<dynamic>;
        _paymentMethods.clear();
        for (var item in decoded) {
          _paymentMethods.add(PaymentMethod.fromJson(item as Map<String, dynamic>));
        }
      }

      _monthlyBudget = prefs.getDouble(_storageKeyBudget) ?? 150.0;
      _currency = prefs.getString(_storageKeyCurrency) ?? '\$';
      _userName = prefs.getString(_storageKeyUserName) ?? 'Syed Arham Raza';
      _userEmail = prefs.getString(_storageKeyUserEmail) ?? 'syed@onespend.app';
      _defaultReminderDays = prefs.getInt(_storageKeyDefaultReminder) ?? 2;
      final sortName = prefs.getString(_storageKeySortOption);
      if (sortName != null) {
        _sortOption = SubscriptionSortOption.fromString(sortName);
      }
      _groupByDate = prefs.getBool(_storageKeyGroupByDate) ?? false;

      _isLoaded = true;
      checkAndProcessAutoRenewals();
      notifyListeners();
    } catch (e) {
      debugPrint('OneSpend: Failed to load data from storage: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subsJson = jsonEncode(_subscriptions.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKeySubs, subsJson);
      final methodsJson = jsonEncode(_paymentMethods.map((m) => m.toJson()).toList());
      await prefs.setString(_storageKeyPaymentMethods, methodsJson);
      await prefs.setDouble(_storageKeyBudget, _monthlyBudget);
      await prefs.setString(_storageKeyCurrency, _currency);
      await prefs.setString(_storageKeyUserName, _userName);
      await prefs.setString(_storageKeyUserEmail, _userEmail);
      await prefs.setInt(_storageKeyDefaultReminder, _defaultReminderDays);
      await prefs.setString(_storageKeySortOption, _sortOption.name);
      await prefs.setBool(_storageKeyGroupByDate, _groupByDate);
    } catch (e) {
      debugPrint('OneSpend: Failed to save data to storage: $e');
    }
  }

  // --- Payment Methods ---
  List<PaymentMethod> get paymentMethods => List.unmodifiable(_paymentMethods);

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
    _saveToStorage();
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
      _saveToStorage();
    }
  }

  void deletePaymentMethod(String methodId, {String? replacementMethodId}) {
    // If replacement provided, migrate linked subscriptions
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
      // Non-forceful delete anyway: unassign payment method from linked subscriptions
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
    _saveToStorage();
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
    _saveToStorage();
  }

  // --- Actions ---
  void addSubscription(Subscription subscription) {
    _subscriptions.add(subscription);
    notifyListeners();
    _saveToStorage();
  }

  void batchAdd(Iterable<Subscription> newSubscriptions) {
    _subscriptions.addAll(newSubscriptions);
    notifyListeners();
    _saveToStorage();
  }

  void removeSubscription(String id) {
    _subscriptions.removeWhere((item) => item.id == id);
    notifyListeners();
    _saveToStorage();
  }

  void updateSubscription(Subscription updated) {
    final index = _subscriptions.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      _subscriptions[index] = updated;
      notifyListeners();
      _saveToStorage();
    }
  }

  /// Rolls renewal date forward according to the billing cycle and logs to paymentHistory
  void renewSubscription(String id) {
    markSubscriptionPaid(id);
  }

  /// Records a payment for the subscription, advances its next billing date, and updates history
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
      _saveToStorage();
    }
  }

  /// Advances next billing date to the next cycle without logging to payment history
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
      _saveToStorage();
    }
  }

  /// Manually adds a historical payment record to a subscription.
  /// Prevents accidental duplicate records on the same calendar day.
  /// Returns `true` if added, or `false` if a record on the same date already exists.
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
      _saveToStorage();
      return true;
    }
    return false;
  }

  /// Deletes a payment record at the specified index
  void deletePaymentRecord(String id, int historyIndex) {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index != -1) {
      final sub = _subscriptions[index];
      if (historyIndex >= 0 && historyIndex < sub.paymentHistory.length) {
        final updatedHistory = List<DateTime>.from(sub.paymentHistory)..removeAt(historyIndex);
        _subscriptions[index] = sub.copyWith(paymentHistory: updatedHistory);
        notifyListeners();
        _saveToStorage();
      }
    }
  }

  /// Automatically rolls past due dates forward and records payment for subscriptions with autoRenew enabled
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
      _saveToStorage();
    }
  }

  void togglePauseSubscription(String id) {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index != -1) {
      final sub = _subscriptions[index];
      SubscriptionStatus newStatus;
      if (sub.status == SubscriptionStatus.paused) {
        // Restore pre-pause status, default to active
        newStatus = _prePauseStatus.remove(id) ?? SubscriptionStatus.active;
      } else {
        // Store current status before pausing
        _prePauseStatus[id] = sub.status;
        newStatus = SubscriptionStatus.paused;
      }
      _subscriptions[index] = sub.copyWith(status: newStatus);
      notifyListeners();
      _saveToStorage();
    }
  }

  void batchDelete(Iterable<String> ids) {
    final idSet = ids.toSet();
    _subscriptions.removeWhere((item) => idSet.contains(item.id));
    notifyListeners();
    _saveToStorage();
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
    _saveToStorage();
  }

  void batchChangeCategory(Iterable<String> ids, SubscriptionCategory category) {
    final idSet = ids.toSet();
    for (int i = 0; i < _subscriptions.length; i++) {
      if (idSet.contains(_subscriptions[i].id)) {
        _subscriptions[i] = _subscriptions[i].copyWith(category: category);
      }
    }
    notifyListeners();
    _saveToStorage();
  }

  void setMonthlyBudget(double amount) {
    _monthlyBudget = amount.clamp(0.0, 999999.0);
    notifyListeners();
    _saveToStorage();
  }

  void setCurrency(String newCurrency) {
    _currency = newCurrency;
    notifyListeners();
    _saveToStorage();
  }

  void setUserProfile(String name, String email) {
    _userName = name;
    _userEmail = email;
    notifyListeners();
    _saveToStorage();
  }

  void setDefaultReminderDays(int days) {
    _defaultReminderDays = days;
    notifyListeners();
    _saveToStorage();
  }

  void setSortOption(SubscriptionSortOption option) {
    _sortOption = option;
    notifyListeners();
    _saveToStorage();
  }

  void setGroupByDate(bool value) {
    _groupByDate = value;
    notifyListeners();
    _saveToStorage();
  }

  void restoreDefaultCatalog() {
    _subscriptions.clear();
    _subscriptions.addAll(popularCatalog);
    notifyListeners();
    _saveToStorage();
  }

  void clearAllData() {
    _subscriptions.clear();
    notifyListeners();
    _saveToStorage();
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
