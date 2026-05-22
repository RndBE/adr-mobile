class SensorHistoryQuery {
  final String table;
  final String from;
  final String to;

  const SensorHistoryQuery({
    required this.table,
    required this.from,
    required this.to,
  });
}

SensorHistoryQuery buildSensorHistoryQuery({
  required DateTime start,
  required DateTime end,
}) {
  return SensorHistoryQuery(
    table: 'rts',
    from: _formatDateTime(start),
    to: _formatDateTime(end),
  );
}

String _formatDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}
