class AdrDashboardStatus {
  final String label;
  final bool isHealthy;

  const AdrDashboardStatus._({required this.label, required this.isHealthy});

  factory AdrDashboardStatus.fromText(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    final healthyValues = {
      '1',
      'aktif',
      'active',
      'ok',
      'online',
      'running',
      'success',
      'normal',
    };

    if (healthyValues.contains(value)) {
      return const AdrDashboardStatus._(label: 'Normal', isHealthy: true);
    }
    return const AdrDashboardStatus._(label: 'Perlu Cek', isHealthy: false);
  }
}

String formatAdrMetric(num? value, {String unit = '', int fractionDigits = 2}) {
  if (value == null) return '-';

  final formatted = value.toDouble().toStringAsFixed(fractionDigits);
  if (unit.trim().isEmpty) return formatted;
  return '$formatted ${unit.trim()}';
}
