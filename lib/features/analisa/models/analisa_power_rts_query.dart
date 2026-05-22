import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PowerRtsQuery {
  final String date;
  final String period;

  const PowerRtsQuery({required this.date, required this.period});
}

final _dateFormat = DateFormat('yyyy-MM-dd');

PowerRtsQuery buildPowerRtsPeriodQuery(int periodIndex, DateTime selectedDate) {
  return PowerRtsQuery(
    date: _dateFormat.format(selectedDate),
    period: periodIndex == 1 ? 'bulan' : 'hari',
  );
}

List<PowerRtsQuery> buildPowerRtsRangeQueries(DateTimeRange range) {
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final end = DateTime(range.end.year, range.end.month, range.end.day);
  final queries = <PowerRtsQuery>[];

  for (
    var cursor = start;
    !cursor.isAfter(end);
    cursor = cursor.add(const Duration(days: 1))
  ) {
    queries.add(
      PowerRtsQuery(date: _dateFormat.format(cursor), period: 'hari'),
    );
  }

  return queries;
}
