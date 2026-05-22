class AnalisaDataCache<T> {
  final _values = <String, T>{};

  bool contains(String key) => _values.containsKey(key);

  T? get(String key) => _values[key];

  void set(String key, T value) => _values[key] = value;

  void remove(String key) => _values.remove(key);

  void clear() => _values.clear();
}

String buildSensorCacheKey({
  required String table,
  required String param,
  required String from,
  required String to,
}) {
  return 'sensor|$table|$param|$from|$to';
}

String buildPrismaCacheKey({
  required String prismaName,
  required String metric,
  required DateTime from,
  required DateTime to,
}) {
  return 'prisma|$prismaName|$metric|${from.toIso8601String()}|${to.toIso8601String()}';
}
