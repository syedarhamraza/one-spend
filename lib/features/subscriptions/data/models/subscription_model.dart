import '../../../currency/domain/currency.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';

/// Data Model mapping Subscription entity to/from raw JSON storage
class SubscriptionModel extends Subscription {
  SubscriptionModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.currency = CurrencyCatalog.defaultCode,
    required super.billingCycle,
    required super.category,
    required super.brandColorValue,
    super.iconCodePoint,
    super.iconFontFamily,
    required super.nextBillingDate,
    super.status = SubscriptionStatus.active,
    super.paymentMethod = 'Samsung Pay •••• 9124',
    super.paymentMethodId,
    super.reminderDays = 2,
    super.isPopular = false,
    super.notes = '',
    super.paymentHistory = const [],
    super.accountUrl = '',
    super.logoUrl,
    super.brandPresetId,
    super.autoRenew = true,
    super.anchorDay,
    super.reminderTimeMinutes,
  });

  factory SubscriptionModel.fromEntity(Subscription entity) {
    return SubscriptionModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      currency: entity.currency,
      billingCycle: entity.billingCycle,
      category: entity.category,
      brandColorValue: entity.brandColorValue,
      iconCodePoint: entity.iconCodePoint,
      iconFontFamily: entity.iconFontFamily,
      nextBillingDate: entity.nextBillingDate,
      status: entity.status,
      paymentMethod: entity.paymentMethod,
      paymentMethodId: entity.paymentMethodId,
      reminderDays: entity.reminderDays,
      isPopular: entity.isPopular,
      notes: entity.notes,
      paymentHistory: entity.paymentHistory,
      accountUrl: entity.accountUrl,
      logoUrl: entity.logoUrl,
      brandPresetId: entity.brandPresetId,
      autoRenew: entity.autoRenew,
      anchorDay: entity.anchorDay,
      reminderTimeMinutes: entity.reminderTimeMinutes,
    );
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final historyList = (json['paymentHistory'] as List<dynamic>?)
            ?.map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now())
            .toList() ??
        [];

    final colorVal = json['brandColor'] as int? ?? 0xFF5390F5;
    final category = SubscriptionCategory.fromString(json['category'] as String?);

    return SubscriptionModel(
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
    );
  }

  @override
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
    };
  }
}
