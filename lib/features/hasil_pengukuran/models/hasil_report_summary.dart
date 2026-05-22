import '../data/hasil_repository.dart';

class HasilReportSummary {
  final int total;
  final int baseline;
  final int event;
  final int siteCount;
  final String latestDatetime;

  const HasilReportSummary({
    required this.total,
    required this.baseline,
    required this.event,
    required this.siteCount,
    required this.latestDatetime,
  });

  factory HasilReportSummary.fromLogs(List<LogKontrol> logs) {
    final sites = <String>{};
    var baseline = 0;
    var latest = '';

    for (final log in logs) {
      final site = log.site.trim().toLowerCase();
      if (site.isNotEmpty) sites.add(site);
      if (log.isBaseline) baseline++;
      if (latest.isEmpty || log.datetime.compareTo(latest) > 0) {
        latest = log.datetime;
      }
    }

    return HasilReportSummary(
      total: logs.length,
      baseline: baseline,
      event: logs.length - baseline,
      siteCount: sites.length,
      latestDatetime: latest,
    );
  }
}

class DetailHasilReportSummary {
  final int totalPrism;
  final int success;
  final int failed;

  const DetailHasilReportSummary({
    required this.totalPrism,
    required this.success,
    required this.failed,
  });

  factory DetailHasilReportSummary.fromPrismas(List<PrismaDeformasi> data) {
    var success = 0;
    var failed = 0;

    for (final prisma in data) {
      switch (prisma.status.toLowerCase()) {
        case 'success':
          success++;
        case 'failed':
          failed++;
      }
    }

    return DetailHasilReportSummary(
      totalPrism: data.length,
      success: success,
      failed: failed,
    );
  }
}
