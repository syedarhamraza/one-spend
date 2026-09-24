import 'package:flutter/material.dart';
import '../../domain/entities/payment_method.dart';

/// Presentation Layer UI Adapters for Payment Methods.
/// Resolves Material Icons and Colors for Pure Dart PaymentMethod entities.

extension CardBrandUIAdapter on CardBrand {
  Color get color => Color(defaultColorValue);
  Color get defaultColor => Color(defaultColorValue);

  IconData get icon {
    switch (this) {
      case CardBrand.applePay:
        return Icons.apple_rounded;
      case CardBrand.googlePay:
        return Icons.g_mobiledata_rounded;
      case CardBrand.samsungPay:
        return Icons.smartphone_rounded;
      case CardBrand.paypal:
        return Icons.paypal_rounded;
      case CardBrand.klarna:
        return Icons.shopping_bag_rounded;
      case CardBrand.alipay:
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }
}

extension PaymentMethodTypeUIAdapter on PaymentMethodType {
  IconData get icon {
    switch (this) {
      case PaymentMethodType.creditCard:
        return Icons.credit_card_rounded;
      case PaymentMethodType.debitCard:
        return Icons.payment_rounded;
      case PaymentMethodType.digitalWallet:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethodType.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethodType.paypal:
        return Icons.currency_exchange_rounded;
      case PaymentMethodType.other:
        return Icons.more_horiz_rounded;
    }
  }
}

extension PaymentMethodUIAdapter on PaymentMethod {
  Color get cardColor => Color(cardColorValue);
}
