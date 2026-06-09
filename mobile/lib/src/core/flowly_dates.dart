String dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String displayDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime? parseDateKey(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value
      .substring(0, value.length < 10 ? value.length : 10)
      .split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

DateTime startOfWeek(DateTime date) {
  final current = dateOnly(date);
  return current.subtract(Duration(days: current.weekday - 1));
}

List<DateTime> monthCells(DateTime date) {
  final first = DateTime(date.year, date.month);
  final last = DateTime(date.year, date.month + 1, 0);
  final startOffset = first.weekday - 1;
  final start = first.subtract(Duration(days: startOffset));
  final endOffset = 7 - last.weekday;
  final end = last.add(Duration(days: endOffset == 7 ? 0 : endOffset));
  final count = end.difference(start).inDays + 1;
  return List.generate(count, (index) => start.add(Duration(days: index)));
}

bool isHolidayOrSunday(DateTime date) {
  if (date.weekday == DateTime.sunday) return true;

  return switch ((date.month, date.day)) {
    (1, 1) || (4, 30) || (5, 1) || (9, 2) => true,
    _ => false,
  };
}

String timeForDisplay(String? value) {
  final text = value ?? '09:00:00';
  final parts = text.split(':');
  final hour = int.tryParse(parts.first) ?? 9;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  if (minute == 0) return '$hour:00';
  return '$hour:${minute.toString().padLeft(2, '0')}';
}

String sqlTimeFromHour(int hour) {
  final safeHour = hour.clamp(0, 24);
  return '${safeHour.toString().padLeft(2, '0')}:00:00';
}

int hourFromSqlTime(String? value, int fallback) {
  if (value == null || value.isEmpty) return fallback;
  return int.tryParse(value.split(':').first) ?? fallback;
}
