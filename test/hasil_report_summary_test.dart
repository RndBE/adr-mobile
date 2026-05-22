import 'package:adr_mobile/features/hasil_pengukuran/data/hasil_repository.dart';
import 'package:adr_mobile/features/hasil_pengukuran/models/hasil_report_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summarizes hasil pengukuran logs', () {
    const logs = [
      LogKontrol(
        idLog: '1',
        datetime: '2026-05-21T08:00:00',
        site: 'cpp',
        isBaseline: true,
      ),
      LogKontrol(
        idLog: '2',
        datetime: '2026-05-21T09:00:00',
        site: 'wp',
        isBaseline: false,
      ),
      LogKontrol(
        idLog: '3',
        datetime: '2026-05-20T09:00:00',
        site: 'cpp',
        isBaseline: false,
      ),
    ];

    final summary = HasilReportSummary.fromLogs(logs);

    expect(summary.total, 3);
    expect(summary.baseline, 1);
    expect(summary.event, 2);
    expect(summary.siteCount, 2);
    expect(summary.latestDatetime, '2026-05-21T09:00:00');
  });

  test('summarizes detail pengukuran prism status', () {
    final data = [
      _prisma('P1', 'success'),
      _prisma('P2', 'failed'),
      _prisma('P3', 'success'),
    ];

    final summary = DetailHasilReportSummary.fromPrismas(data);

    expect(summary.totalPrism, 3);
    expect(summary.success, 2);
    expect(summary.failed, 1);
  });
}

PrismaDeformasi _prisma(String name, String status) {
  return PrismaDeformasi(
    idPrisma: name,
    namaPrisma: name,
    n0: 0,
    e0: 0,
    z0: 0,
    n1: 0,
    e1: 0,
    z1: 0,
    dn: 0,
    de: 0,
    dz: 0,
    linear: 0,
    arahPergeseran: '-',
    status: status,
    pergeseranMm: 0,
    kecepatanMmd: 0,
    statusPergeseran: '-',
    statusKecepatan: '-',
    series: const [],
  );
}
