import 'package:intl/intl.dart';

const analisaWeekdayLabels = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];

List<DateTime?> buildAnalisaCalendarCells({
  required int year,
  required int month,
}) {
  final firstDay = DateTime(year, month);
  final lastDay = DateTime(year, month + 1, 0);
  final leadingEmptyCells = firstDay.weekday % 7;
  final cells = [
    for (var i = 0; i < leadingEmptyCells; i++) null,
    for (var day = 1; day <= lastDay.day; day++) DateTime(year, month, day),
  ];
  return [...cells, for (var i = cells.length; i < 42; i++) null];
}

String formatAnalisaRangePill(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

bool isAnalisaRangeStart(DateTime date, DateTime start) {
  return _isSameDay(date, start);
}

bool isAnalisaRangeEnd(DateTime date, DateTime end) {
  return _isSameDay(date, end);
}

bool isAnalisaDateInsideRange(DateTime date, DateTime start, DateTime end) {
  final normalized = DateTime(date.year, date.month, date.day);
  final normalizedStart = DateTime(start.year, start.month, start.day);
  final normalizedEnd = DateTime(end.year, end.month, end.day);
  return !normalized.isBefore(normalizedStart) &&
      !normalized.isAfter(normalizedEnd);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
