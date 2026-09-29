import 'package:equatable/equatable.dart';

enum NotificationKind { renewal, card, budget, developer }

/// A local notification the app intends to show at [fireAt] (device-local time).
class PlannedNotification extends Equatable {
  final int id;
  final NotificationKind kind;
  final DateTime fireAt;
  final String title;
  final String body;

  /// Subscription id (renewal), payment method id (card), or month key (budget).
  final String? subjectId;

  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.fireAt,
    required this.title,
    required this.body,
    this.subjectId,
  });

  /// Ids at or below this value are reserved for developer test notifications.
  static const int maxReservedId = 999;

  /// Stable, platform-safe (31-bit) id derived from [key] via FNV-1a, never in the reserved range.
  static int stableId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final id = hash & 0x7FFFFFFF;
    return id <= maxReservedId ? id + maxReservedId + 1 : id;
  }

  @override
  List<Object?> get props => [id, kind, fireAt, title, body, subjectId];
}
