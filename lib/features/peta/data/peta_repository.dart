import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class PetaMarker {
  final String id;
  final String nama;
  final double lat;
  final double lon;
  final String kategori;
  final String status;
  final String site;

  const PetaMarker({
    required this.id,
    required this.nama,
    required this.lat,
    required this.lon,
    required this.kategori,
    required this.status,
    required this.site,
  });

  factory PetaMarker.fromJson(Map<String, dynamic> j) => PetaMarker(
        id: j['id_prisma']?.toString() ?? j['id_logger']?.toString() ?? '',
        nama: j['nama_prisma'] ?? j['nama_logger'] ?? '',
        lat: double.tryParse(j['map_lat0']?.toString() ??
                j['latitude']?.toString() ?? '0') ??
            0,
        lon: double.tryParse(j['map_lon0']?.toString() ??
                j['longitude']?.toString() ?? '0') ??
            0,
        kategori: j['kategori'] ?? 'RTS',
        status: j['status'] ?? 'unknown',
        site: j['site'] ?? '',
      );
}

class PetaRepository {
  final _client = ApiClient.instance;

  Future<List<PetaMarker>> getMarkers() async {
    try {
      final res = await _client.get(ApiConstants.prismaData);
      final list = res.data as List<dynamic>? ?? [];
      return list
          .where((e) {
            final m = e as Map<String, dynamic>;
            final t = m['temp_tembak'] as Map<String, dynamic>? ?? {};
            return t['map_lat0'] != null;
          })
          .map((e) {
            final m = e as Map<String, dynamic>;
            final t = m['temp_tembak'] as Map<String, dynamic>? ?? {};
            return PetaMarker(
              id: m['id_prisma']?.toString() ?? '',
              nama: m['nama_prisma'] ?? '',
              lat: double.tryParse(t['map_lat0']?.toString() ?? '0') ?? 0,
              lon: double.tryParse(t['map_lon0']?.toString() ?? '0') ?? 0,
              kategori: 'RTS',
              status: m['status'] ?? 'unknown',
              site: m['site'] ?? '',
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
  }
}
