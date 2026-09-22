import 'package:flutter/material.dart';

enum PaymentMethodType {
  creditCard('Credit Card', Icons.credit_card_rounded),
  debitCard('Debit Card', Icons.payment_rounded),
  digitalWallet('Digital Wallet', Icons.account_balance_wallet_rounded),
  bankTransfer('Bank Account', Icons.account_balance_rounded),
  paypal('PayPal', Icons.currency_exchange_rounded),
  other('Other', Icons.more_horiz_rounded);

  final String label;
  final IconData icon;
  const PaymentMethodType(this.label, this.icon);
}

enum CardBrand {
  visa('Visa', Icons.credit_card_rounded, Color(0xFF1A1F71)),
  mastercard('Mastercard', Icons.credit_card_rounded, Color(0xFFEB001B)),
  amex('American Express', Icons.credit_card_rounded, Color(0xFF006FCF)),
  discover('Discover', Icons.credit_card_rounded, Color(0xFFFF6000)),
  applePay('Apple Pay', Icons.apple_rounded, Color(0xFF000000)),
  googlePay('Google Pay', Icons.g_mobiledata_rounded, Color(0xFF4285F4)),
  samsungPay('Samsung Pay', Icons.smartphone_rounded, Color(0xFF1428A0)),
  paypal('PayPal', Icons.paypal_rounded, Color(0xFF003087)),
  bank('Bank / Direct Debit', Icons.account_balance_rounded, Color(0xFF00897B)),
  other('Custom Card', Icons.credit_card_rounded, Color(0xFF424242));

  final String label;
  final IconData icon;
  final Color defaultColor;
  const CardBrand(this.label, this.icon, this.defaultColor);
}

enum CardExpiryStatus {
  valid,
  expiresThisMonth,
  expiresNextMonth,
  expired,
}

class PaymentMethod {
  final String id;
  final String nickname; // e.g. "Personal Meezan", "Salary Account", "Work Card"
  final PaymentMethodType type;
  final CardBrand brand;
  final String last4; // Strictly last 4 digits (e.g. "9124")
  final String expiryDate; // "MM/YY" e.g. "12/28"
  final Color cardColor;
  final bool isDefault;
  final int? statementDay; // Optional statement closing day 1-31

  const PaymentMethod({
    required this.id,
    required this.nickname,
    this.type = PaymentMethodType.creditCard,
    this.brand = CardBrand.visa,
    this.last4 = '',
    this.expiryDate = '',
    this.cardColor = const Color(0xFF2C3440),
    this.isDefault = false,
    this.statementDay,
  });

  /// Sentinel representing explicit removal/clearing of a payment method
  static const none = PaymentMethod(
    id: '__none__',
    nickname: 'No payment method',
  );

  /// Display string for the card digits, e.g. "•••• 9124"
  String get maskedDisplay {
    if (last4.isNotEmpty) {
      return '•••• $last4';
    }
    if (type == PaymentMethodType.paypal) {
      return 'PayPal';
    }
    return brand.label;
  }

  /// Compact title for cards and subscriptions, e.g. "Personal Meezan (•••• 5519)"
  String get displayName {
    if (nickname.isNotEmpty) {
      return last4.isNotEmpty ? '$nickname (•••• $last4)' : nickname;
    }
    return '${brand.label} (•••• $last4)'.trim();
  }

  /// Expiry status calculation algorithm
  CardExpiryStatus get expiryStatus {
    if (expiryDate.isEmpty) return CardExpiryStatus.valid;
    final parts = expiryDate.split('/');
    if (parts.length != 2) return CardExpiryStatus.valid;

    final month = int.tryParse(parts[0].trim());
    var year = int.tryParse(parts[1].trim());
    if (month == null || year == null) return CardExpiryStatus.valid;

    // Convert 2-digit YY to 4-digit YYYY
    if (year < 100) {
      year += 2000;
    }

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return CardExpiryStatus.expired;
    }

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
    Color? cardColor,
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
      cardColor: cardColor ?? this.cardColor,
      isDefault: isDefault ?? this.isDefault,
      statementDay: statementDay ?? this.statementDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'type': type.name,
      'brand': brand.name,
      'last4': last4,
      'expiryDate': expiryDate,
      'cardColor': cardColor.toARGB32(),
      'isDefault': isDefault,
      'statementDay': statementDay,
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? '',
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentMethodType.creditCard,
      ),
      brand: CardBrand.values.firstWhere(
        (e) => e.name == json['brand'],
        orElse: () => CardBrand.visa,
      ),
      last4: json['last4'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      cardColor: json['cardColor'] != null
          ? Color(json['cardColor'] as int)
          : const Color(0xFF2C3440),
      isDefault: json['isDefault'] as bool? ?? false,
      statementDay: json['statementDay'] as int?,
    );
  }
}

/// Pre-seeded sample payment methods
final List<PaymentMethod> defaultPaymentMethods = [
  const PaymentMethod(
    id: 'pay_samsung_visa',
    nickname: 'Primary Samsung Pay',
    type: PaymentMethodType.digitalWallet,
    brand: CardBrand.samsungPay,
    last4: '9124',
    expiryDate: '12/28',
    cardColor: Color(0xFF1428A0),
    isDefault: true,
    statementDay: 15,
  ),
  const PaymentMethod(
    id: 'pay_mastercard_4242',
    nickname: 'Standard Chartered World',
    type: PaymentMethodType.creditCard,
    brand: CardBrand.mastercard,
    last4: '4242',
    expiryDate: '05/27',
    cardColor: Color(0xFF8B0000),
    isDefault: false,
    statementDay: 20,
  ),
  const PaymentMethod(
    id: 'pay_google_7731',
    nickname: 'Google Wallet Visa',
    type: PaymentMethodType.digitalWallet,
    brand: CardBrand.googlePay,
    last4: '7731',
    expiryDate: '08/26',
    cardColor: Color(0xFF1E3C72),
    isDefault: false,
  ),
  const PaymentMethod(
    id: 'pay_meezan_5519',
    nickname: 'Personal Meezan Debit',
    type: PaymentMethodType.debitCard,
    brand: CardBrand.visa,
    last4: '5519',
    expiryDate: '10/26',
    cardColor: Color(0xFF004D40),
    isDefault: false,
    statementDay: 1,
  ),
  const PaymentMethod(
    id: 'pay_paypal_main',
    nickname: 'Business PayPal',
    type: PaymentMethodType.paypal,
    brand: CardBrand.paypal,
    last4: '',
    expiryDate: '',
    cardColor: Color(0xFF003087),
    isDefault: false,
  ),
];
