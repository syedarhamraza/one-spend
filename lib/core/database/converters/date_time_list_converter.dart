import 'dart:convert';
import 'package:drift/drift.dart';

/// TypeConverter to store `List<DateTime>` as a JSON string in SQLite
class DateTimeListConverter extends TypeConverter<List<DateTime>, String> {
  const DateTimeListConverter();

  @override
  List<DateTime> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    try {
      final List<dynamic> decoded = jsonDecode(fromDb) as List<dynamic>;
      return decoded
          .map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  String toSql(List<DateTime> value) {
    return jsonEncode(value.map((d) => d.toIso8601String()).toList());
  }
}
