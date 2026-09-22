import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import 'payment_method_picker_screen.dart';

/// Samsung One UI Payment Methods Screen.
/// Forwards to the unified PaymentMethodPickerScreen which contains all card management,
/// editing, hold-press selection mode, "Move subs", and deletion capabilities.
class PaymentMethodsScreen extends StatelessWidget {
  final bool isSelectMode;
  final String? currentMethodId;

  const PaymentMethodsScreen({
    super.key,
    this.isSelectMode = false,
    this.currentMethodId,
  });

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
    );
  }

  static Future<PaymentMethod?> select(BuildContext context, {String? currentMethodId}) {
    HapticFeedback.lightImpact();
    return PaymentMethodPickerScreen.open(context, currentMethodId: currentMethodId);
  }

  @override
  Widget build(BuildContext context) {
    return PaymentMethodPickerScreen(
      isManageOnly: !isSelectMode,
      initialMethodId: currentMethodId,
    );
  }
}
