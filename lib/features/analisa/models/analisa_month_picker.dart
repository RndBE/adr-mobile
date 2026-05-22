const analisaMonthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Ags',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatAnalisaMonthTitle({required int year, required int month}) {
  return '${analisaMonthLabels[month - 1]} $year';
}

bool isAnalisaMonthEnabled({
  required int year,
  required int month,
  required DateTime maxDate,
}) {
  final selectedMonth = DateTime(year, month);
  final maxMonth = DateTime(maxDate.year, maxDate.month);
  return !selectedMonth.isAfter(maxMonth);
}

DateTime buildAnalisaMonthDate({required int year, required int month}) {
  return DateTime(year, month);
}
