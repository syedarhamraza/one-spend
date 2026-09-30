import 'dart:convert';

import '../../currency/data/exchange_rate_repository.dart';
import '../../currency/domain/currency.dart';
import '../../payment_methods/domain/entities/payment_method.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/domain/entities/subscription_enums.dart';
import 'backup_snapshot.dart';

/// A file that can't be restored, with a message fit to show the user.
class BackupFormatException implements Exception {
  final String message;

  const BackupFormatException(this.message);

  static const notABackup = BackupFormatException('This isn\'t a OneSpend backup');
  static const tooNew = BackupFormatException('This backup was made by a newer version of OneSpend. Update the app to restore it.');
  static const damaged = BackupFormatException('The backup file is damaged');

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Reads and writes the OneSpend backup file (JSON).
///
/// Format v1:
/// ```json
/// {"format": "onespend.backup", "version": 1, "createdAt": "…", "appVersion": "1.0.0 (1)",
///  "counts": {"subscriptions": 14, "paymentMethods": 3},
///  "data": {"subscriptions": [...], "paymentMethods": [...], "settings": {...}, "appearance": {...}}}
/// ```
/// A bare JSON list is read as the legacy subscriptions-only export.
class BackupCodec {
  const BackupCodec._();

  static const String formatId = 'onespend.backup';
  static const int currentVersion = 1;

  static String encode(BackupSnapshot snapshot) {
    final settings = snapshot.settings;
    return const JsonEncoder.withIndent('  ').convert({
      'format': formatId,
      'version': currentVersion,
      'createdAt': snapshot.createdAt.toIso8601String(),
      'appVersion': snapshot.appVersion,
      'counts': {
        'subscriptions': snapshot.subscriptions.length,
        'paymentMethods': snapshot.paymentMethods.length,
      },
      'data': {
        'subscriptions': [for (final s in snapshot.subscriptions) s.toJson()],
        'paymentMethods': [for (final m in snapshot.paymentMethods) m.toJson()],
        if (settings != null)
          'settings': {
            'monthlyBudget': settings.monthlyBudget,
            'currency': settings.currency,
            'defaultReminderDays': settings.defaultReminderDays,
            'defaultReminderTimeMinutes': settings.defaultReminderTimeMinutes,
            'notificationsEnabled': settings.notificationsEnabled,
            'sortOption': settings.sortOption.name,
            'groupByDate': settings.groupByDate,
          },
        'appearance': snapshot.appearance,
        if (snapshot.rateOverrides case final overrides?)
          'exchangeRateOverrides': ExchangeRateRepository.encodeOverrides(overrides),
      },
    });
  }

  /// Parses a backup file. Throws [BackupFormatException] for anything that can't be restored.
  static BackupSnapshot decode(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      throw BackupFormatException.damaged;
    }

    try {
      if (json is List) return _decodeLegacy(json);
      if (json is! Map<String, dynamic> || json['format'] != formatId) throw BackupFormatException.notABackup;

      final version = json['version'];
      if (version is! int) throw BackupFormatException.damaged;
      if (version > currentVersion) throw BackupFormatException.tooNew;

      final data = json['data'] as Map<String, dynamic>;
      final settings = data['settings'] as Map<String, dynamic>?;
      return BackupSnapshot(
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        appVersion: json['appVersion'] as String? ?? '',
        subscriptions: [
          for (final s in data['subscriptions'] as List<dynamic>? ?? const []) Subscription.fromJson(s as Map<String, dynamic>),
        ],
        paymentMethods: [
          for (final m in data['paymentMethods'] as List<dynamic>? ?? const [])
            PaymentMethod.fromJson(m as Map<String, dynamic>),
        ],
        settings: settings == null ? null : _decodeSettings(settings),
        appearance: {
          for (final e in (data['appearance'] as Map<String, dynamic>? ?? const {}).entries) e.key: e.value.toString(),
        },
        rateOverrides: data.containsKey('exchangeRateOverrides')
            ? ExchangeRateRepository.decodeOverrides(data['exchangeRateOverrides'])
            : null,
      );
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      // Wrong types or missing fields.
      throw BackupFormatException.damaged;
    }
  }

  static BackupSnapshot _decodeLegacy(List<dynamic> list) {
    // A legacy export is a list of subscription objects; anything else isn't ours.
    if (list.any((e) => e is! Map<String, dynamic> || e['name'] == null || e['billingCycle'] == null)) {
      throw BackupFormatException.notABackup;
    }
    return BackupSnapshot(
      createdAt: DateTime.now(),
      appVersion: '',
      subscriptions: [for (final s in list) Subscription.fromJson(s as Map<String, dynamic>)],
      paymentMethods: const [],
    );
  }

  static BackupSettings _decodeSettings(Map<String, dynamic> s) => (
        monthlyBudget: (s['monthlyBudget'] as num?)?.toDouble() ?? 0,
        currency: CurrencyCatalog.normalize(s['currency'] as String?),
        defaultReminderDays: s['defaultReminderDays'] as int? ?? 2,
        defaultReminderTimeMinutes: s['defaultReminderTimeMinutes'] as int? ?? 9 * 60,
        notificationsEnabled: s['notificationsEnabled'] as bool? ?? true,
        sortOption: SubscriptionSortOption.values.firstWhere(
          (o) => o.name == s['sortOption'],
          orElse: () => SubscriptionSortOption.renewalAsc,
        ),
        groupByDate: s['groupByDate'] as bool? ?? false,
      );
}
