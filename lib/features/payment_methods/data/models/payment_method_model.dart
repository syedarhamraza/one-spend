import '../../domain/entities/payment_method.dart';

/// Data Model mapping PaymentMethod entity to/from raw JSON storage
class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.nickname,
    super.type = PaymentMethodType.creditCard,
    super.brand = CardBrand.visa,
    super.last4 = '',
    super.expiryDate = '',
    super.cardColorValue = 0xFF2C3440,
    super.isDefault = false,
    super.statementDay,
  });

  factory PaymentMethodModel.fromEntity(PaymentMethod entity) {
    return PaymentMethodModel(
      id: entity.id,
      nickname: entity.nickname,
      type: entity.type,
      brand: entity.brand,
      last4: entity.last4,
      expiryDate: entity.expiryDate,
      cardColorValue: entity.cardColorValue,
      isDefault: entity.isDefault,
      statementDay: entity.statementDay,
    );
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    final clampedDay = (json['statementDay'] as int?)?.clamp(1, 31);

    final typeStr = json['type'] as String?;
    final brandStr = json['brand'] as String?;

    return PaymentMethodModel(
      id: json['id'] as String? ?? PaymentMethod.generateId('pay'),
      nickname: json['nickname'] as String? ?? '',
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => PaymentMethodType.creditCard,
      ),
      brand: CardBrand.values.firstWhere(
        (e) => e.name == brandStr,
        orElse: () => CardBrand.visa,
      ),
      last4: json['last4'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      cardColorValue: json['cardColor'] as int? ?? 0xFF2C3440,
      isDefault: json['isDefault'] as bool? ?? false,
      statementDay: clampedDay,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'type': type.name,
      'brand': brand.name,
      'last4': last4,
      'expiryDate': expiryDate,
      'cardColor': cardColorValue,
      'isDefault': isDefault,
      'statementDay': statementDay,
    };
  }
}
