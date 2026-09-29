/// A renewal reminder: how many days before the billing date, and at what time of day.
typedef ReminderSetting = ({int days, int timeMinutes});

/// Formats minutes after midnight as a 12-hour clock time, e.g. `9:00 AM`.
String formatReminderTime(int minutes) {
  final hour24 = (minutes ~/ 60) % 24;
  final minute = (minutes % 60).toString().padLeft(2, '0');
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:$minute ${hour24 < 12 ? 'AM' : 'PM'}';
}

/// Short description of a reminder, e.g. `2 days before · 9:00 AM` or `On renewal day · 8:30 PM`.
String describeReminder(int days, int timeMinutes) {
  final when = switch (days) {
    0 => 'On renewal day',
    1 => '1 day before',
    _ => '$days days before',
  };
  return '$when · ${formatReminderTime(timeMinutes)}';
}
