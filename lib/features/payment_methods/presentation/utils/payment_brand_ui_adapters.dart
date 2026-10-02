import 'package:flutter/material.dart';
import '../../domain/entities/payment_method.dart';

/// Presentation Layer UI Adapters for Payment Methods.
/// Resolves Material Icons and Colors for Pure Dart PaymentMethod entities.

extension CardBrandUIAdapter on CardBrand {
  Color get color => Color(defaultColorValue);
  Color get defaultColor => Color(defaultColorValue);

  /// A generic glyph: a wallet for payment apps, a card for card networks.
  /// (No company logos: those are third-party trademarks.)
  IconData get icon => isWallet ? Icons.account_balance_wallet_rounded : Icons.credit_card_rounded;
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
