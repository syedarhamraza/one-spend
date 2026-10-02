import 'dart:math' as math;
import 'package:equatable/equatable.dart';

enum PaymentMethodType {
  creditCard('Credit Card'),
  debitCard('Debit Card'),
  digitalWallet('Digital Wallet'),
  bankTransfer('Bank Account'),
  paypal('PayPal'),
  other('Other');

  final String label;
  const PaymentMethodType(this.label);
}

enum CardBrand {
  visa('Visa', 0xFF1A1F71),
  mastercard('Mastercard', 0xFFEB001B),
  applePay('Apple Pay', 0xFF000000, isWallet: true),
  googlePay('Google Pay', 0xFF4285F4, isWallet: true),
  samsungPay('Samsung Pay', 0xFF1428A0, isWallet: true),
  paypal('PayPal', 0xFF003087, isWallet: true),
  skrill('Skrill', 0xFF811963, isWallet: true),
  unionPay('UnionPay', 0xFF007B80),
  jcb('JCB', 0xFF0E4C92),
  maestro('Maestro', 0xFF00A2E5),
  alipay('Alipay', 0xFF1677FF, isWallet: true),
  wechatPay('WeChat Pay', 0xFF07C160, isWallet: true);

  final String label;
  final int defaultColorValue;

  /// A payment app or wallet rather than a card network.
  final bool isWallet;
  const CardBrand(this.label, this.defaultColorValue, {this.isWallet = false});

  static CardBrand fromString(String? val) {
    return CardBrand.values.firstWhere(
      (e) => e.name == val,
      orElse: () => CardBrand.visa,
    );
  }
}

enum CardExpiryStatus {
  valid,
  expiresThisMonth,
  expiresNextMonth,
  expired,
}

/// Pure Dart PaymentMethod domain entity (Zero Flutter framework dependencies)
class PaymentMethod extends Equatable {
  final String id;
  final String nickname;
  final PaymentMethodType type;
  final CardBrand brand;
  final String last4;
  final String expiryDate; // e.g. "12/28"
  final int cardColorValue;
  final bool isDefault;
  final int? statementDay;

  const PaymentMethod({
    required this.id,
    required this.nickname,
    this.type = PaymentMethodType.creditCard,
    this.brand = CardBrand.visa,
    this.last4 = '',
    this.expiryDate = '',
    this.cardColorValue = 0xFF2C3440,
    this.isDefault = false,
    this.statementDay,
  });

  /// Sentinel representing explicit removal/clearing of a payment method
  static const none = PaymentMethod(
    id: '__none__',
    nickname: 'No payment method',
  );

  /// Display string for the card digits or type, e.g. "•••• 9124"
  String get maskedDisplay {
    if (last4.isNotEmpty) {
      return '•••• $last4';
    }
    if (type == PaymentMethodType.paypal || brand == CardBrand.paypal) {
      return 'Digital Wallet';
    }
    return brand.label;
  }

  /// Single cohesive subtitle for cards and list views (avoids "PayPal PayPal" duplicates)
  String get subtitleDisplay {
    if (last4.isNotEmpty) {
      return '${brand.label} •••• $last4';
    }
    if (type == PaymentMethodType.paypal || brand == CardBrand.paypal) {
      return 'PayPal • Digital Wallet';
    }
    if (brand == CardBrand.applePay) {
      return 'Apple Pay • Digital Wallet';
    }
    if (brand == CardBrand.googlePay) {
      return 'Google Pay • Digital Wallet';
    }
    if (brand == CardBrand.samsungPay) {
      return 'Samsung Pay • Digital Wallet';
    }
    if (brand == CardBrand.alipay) {
      return 'Alipay • Digital Wallet';
    }
    if (brand == CardBrand.wechatPay) {
      return 'WeChat Pay • Digital Wallet';
    }
    if (brand == CardBrand.skrill) {
      return 'Skrill • Digital Wallet';
    }
    if (type == PaymentMethodType.digitalWallet) {
      return '${brand.label} • Digital Wallet';
    }
    return brand.label;
  }

  /// Compact title for cards and subscriptions, e.g. "Personal Meezan (•••• 5519)"
  String get displayName {
    if (nickname.isNotEmpty) {
      return last4.isNotEmpty ? '$nickname (•••• $last4)' : nickname;
    }
    return last4.isNotEmpty ? '${brand.label} (•••• $last4)' : brand.label;
  }

  int? get expiryMonth {
    if (!expiryDate.contains('/')) return null;
    final parts = expiryDate.split('/');
    if (parts.length != 2) return null;
    return int.tryParse(parts[0].trim());
  }

  int? get expiryYear {
    if (!expiryDate.contains('/')) return null;
    final parts = expiryDate.split('/');
    if (parts.length != 2) return null;
    final rawYear = int.tryParse(parts[1].trim());
    if (rawYear == null) return null;
    return rawYear < 100 ? 2000 + rawYear : rawYear;
  }

  CardExpiryStatus get expiryStatus {
    final month = expiryMonth;
    final year = expiryYear;
    if (month == null || year == null || month < 1 || month > 12) {
      return CardExpiryStatus.valid;
    }

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Check if expired
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return CardExpiryStatus.expired;
    }

    // Check if expires this month
    if (year == currentYear && month == currentMonth) {
      return CardExpiryStatus.expiresThisMonth;
    }

    // Check if next month
    final nextMonthDate = DateTime(currentYear, currentMonth + 1, 1);
    if (year == nextMonthDate.year && month == nextMonthDate.month) {
      return CardExpiryStatus.expiresNextMonth;
    }

    return CardExpiryStatus.valid;
  }

  bool get isExpiringSoon =>
      expiryStatus == CardExpiryStatus.expiresThisMonth ||
      expiryStatus == CardExpiryStatus.expiresNextMonth;

  bool get isExpired => expiryStatus == CardExpiryStatus.expired;

  String? get expiryStatusText {
    switch (expiryStatus) {
      case CardExpiryStatus.expired:
        return 'Card expired';
      case CardExpiryStatus.expiresThisMonth:
        return 'Expires this month';
      case CardExpiryStatus.expiresNextMonth:
        return 'Expires next month';
      case CardExpiryStatus.valid:
        return null;
    }
  }

  PaymentMethod copyWith({
    String? id,
    String? nickname,
    PaymentMethodType? type,
    CardBrand? brand,
    String? last4,
    String? expiryDate,
    int? cardColorValue,
    bool? isDefault,
    int? statementDay,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiryDate: expiryDate ?? this.expiryDate,
      cardColorValue: cardColorValue ?? this.cardColorValue,
      isDefault: isDefault ?? this.isDefault,
      statementDay: statementDay ?? this.statementDay,
    );
  }

  static String generateId([String prefix = 'pay']) {
    final now = DateTime.now();
    final random = math.Random().nextInt(99999).toString().padLeft(5, '0');
    return '${prefix}_${now.microsecondsSinceEpoch}_$random';
  }

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

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final rawDay = json['statementDay'] as int?;
    final clampedDay = rawDay?.clamp(1, 31);

    final typeStr = json['type'] as String?;
    final brandStr = json['brand'] as String?;

    return PaymentMethod(
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
  List<Object?> get props => [
        id,
        nickname,
        type,
        brand,
        last4,
        expiryDate,
        cardColorValue,
        isDefault,
        statementDay,
      ];
}
