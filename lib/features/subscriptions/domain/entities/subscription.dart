import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import '../../../currency/domain/currency.dart';
import 'logo_transform.dart';
import 'subscription_enums.dart';

export 'logo_transform.dart';

/// Pure Dart Subscription Domain Entity (Zero Flutter framework dependencies)
class Subscription extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final BillingCycle billingCycle;
  final SubscriptionCategory category;
  final int brandColorValue;
  final int? iconCodePoint;
  final String? iconFontFamily;
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

  /// Reminder time of day in minutes after midnight; null uses the global default.
  final int? reminderTimeMinutes;

  /// Framing of the custom [logoUrl] image (zoom and offset); null = fit as is.
  final LogoTransform? logoTransform;

  const Subscription.raw({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = CurrencyCatalog.defaultCode,
    required this.billingCycle,
    required this.category,
    required this.brandColorValue,
    this.iconCodePoint,
    this.iconFontFamily,
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
    this.reminderTimeMinutes,
    this.logoTransform,
  });

  Subscription({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = CurrencyCatalog.defaultCode,
    required this.billingCycle,
    required this.category,
    int? brandColorValue,
    dynamic brandColor,
    int? iconCodePoint,
    this.iconFontFamily,
    dynamic iconData,
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
    this.reminderTimeMinutes,
    this.logoTransform,
  })  : brandColorValue = brandColorValue ?? _extractColorValue(brandColor),
        iconCodePoint = iconCodePoint ?? _extractIconCodePoint(iconData);

  static int _extractColorValue(dynamic val) {
    if (val is int) return val;
    if (val != null) {
      try {
        final dynamic v = (val as dynamic).value;
        if (v is int) return v;
      } catch (_) {}
    }
    return 0xFF5390F5;
  }

  static int? _extractIconCodePoint(dynamic val) {
    if (val is int) return val;
    if (val != null) {
      try {
        final dynamic cp = (val as dynamic).codePoint;
        if (cp is int) return cp;
      } catch (_) {}
    }
    return null;
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    BillingCycle? billingCycle,
    SubscriptionCategory? category,
    int? brandColorValue,
    dynamic brandColor,
    int? iconCodePoint,
    String? iconFontFamily,
    dynamic iconData,
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
    bool clearLogoUrl = false,
    String? brandPresetId,
    bool clearBrandPresetId = false,
    bool? autoRenew,
    int? anchorDay,
    int? reminderTimeMinutes,
    bool clearReminderTime = false,
    LogoTransform? logoTransform,
    bool clearLogoTransform = false,
  }) {
    final resolvedColor = brandColorValue ?? (brandColor != null ? _extractColorValue(brandColor) : this.brandColorValue);
    final resolvedIcon = iconCodePoint ?? (iconData != null ? _extractIconCodePoint(iconData) : this.iconCodePoint);
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      category: category ?? this.category,
      brandColorValue: resolvedColor,
      iconCodePoint: resolvedIcon,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodId: (clearPaymentMethodId || paymentMethodId == '__none__') ? null : (paymentMethodId ?? this.paymentMethodId),
      reminderDays: reminderDays ?? this.reminderDays,
      isPopular: isPopular ?? this.isPopular,
      notes: notes ?? this.notes,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      accountUrl: accountUrl ?? this.accountUrl,
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
      brandPresetId: clearBrandPresetId ? null : (brandPresetId ?? this.brandPresetId),
      autoRenew: autoRenew ?? this.autoRenew,
      anchorDay: anchorDay ?? this.anchorDay,
      reminderTimeMinutes: clearReminderTime ? null : (reminderTimeMinutes ?? this.reminderTimeMinutes),
      logoTransform: clearLogoTransform ? null : (logoTransform ?? this.logoTransform),
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

  double get dailyCost {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return price / 7.0;
      case BillingCycle.monthly:
      case BillingCycle.quarterly:
      case BillingCycle.yearly:
        return yearlyCost / 365.0;
    }
  }

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

  static String generateUniqueId([String prefix = 'sub']) {
    final now = DateTime.now();
    final random = math.Random().nextInt(99999).toString().padLeft(5, '0');
    return '${prefix}_${now.microsecondsSinceEpoch}_$random';
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
      'brandColor': brandColorValue,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
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
      'reminderTimeMinutes': reminderTimeMinutes,
      'logoTransform': logoTransform?.encode(),
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final historyList = (json['paymentHistory'] as List<dynamic>?)
            ?.map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now())
            .toList() ??
        [];

    final colorVal = json['brandColor'] as int? ?? 0xFF5390F5;
    final category = SubscriptionCategory.fromString(json['category'] as String?);

    return Subscription(
      id: json['id'] as String? ?? Subscription.generateUniqueId('sub'),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: CurrencyCatalog.normalize(json['currency'] as String?),
      billingCycle: BillingCycle.fromString(json['billingCycle'] as String?),
      category: category,
      brandColorValue: colorVal,
      iconCodePoint: json['iconCodePoint'] as int?,
      iconFontFamily: json['iconFontFamily'] as String?,
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
      reminderTimeMinutes: json['reminderTimeMinutes'] as int?,
      logoTransform: LogoTransform.decode(json['logoTransform'] as String?),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        currency,
        billingCycle,
        category,
        brandColorValue,
        iconCodePoint,
        iconFontFamily,
        nextBillingDate,
        status,
        paymentMethod,
        paymentMethodId,
        reminderDays,
        isPopular,
        notes,
        paymentHistory,
        accountUrl,
        logoUrl,
        brandPresetId,
        autoRenew,
        anchorDay,
        reminderTimeMinutes,
        logoTransform,
      ];
}
