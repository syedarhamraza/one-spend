import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/payment_method_model.dart';

/// Abstract Local DataSource contract for Payment Methods.
abstract class PaymentMethodLocalDataSource {
  Future<List<PaymentMethodModel>> loadPaymentMethods();
  Future<void> savePaymentMethods(List<PaymentMethodModel> methods);
}

/// SharedPreferences implementation of PaymentMethodLocalDataSource
class PaymentMethodPreferencesDataSource implements PaymentMethodLocalDataSource {
  SharedPreferences? _prefs;

  static const String keyPaymentMethods = 'onespend_payment_methods';

  PaymentMethodPreferencesDataSource([this._prefs]);

  Future<SharedPreferences> get _getPrefs async => _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<List<PaymentMethodModel>> loadPaymentMethods() async {
    try {
      final prefs = await _getPrefs;
      final methodsJson = prefs.getString(keyPaymentMethods);
      if (methodsJson == null || methodsJson.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(methodsJson) as List<dynamic>;
      return decoded.map((item) => PaymentMethodModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw StorageException('Failed to read payment methods from storage', e);
    }
  }

  @override
  Future<void> savePaymentMethods(List<PaymentMethodModel> methods) async {
    try {
      final prefs = await _getPrefs;
      final jsonStr = jsonEncode(methods.map((m) => m.toJson()).toList());
      await prefs.setString(keyPaymentMethods, jsonStr);
    } catch (e) {
      throw StorageException('Failed to save payment methods to storage', e);
    }
  }
}
