import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/dashboard_widgets.dart';
import '../../../shared/widgets/skeleton.dart';
import '../data/hasil_repository.dart';
import '../models/hasil_report_summary.dart';

class DetailHasilScreen extends StatefulWidget {
  final String idLog;
  final String tanggal;
  final String site;

  const DetailHasilScreen({
    super.key,
    required this.idLog,
    required this.tanggal,
    required this.site,
  });

  @override
  State<DetailHasilScreen> createState() => _DetailHasilScreenState();
}

class _DetailHasilScreenState extends State<DetailHasilScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _repo = HasilRepository();

  List<PrismaDeformasi> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _repo.getDeformasi(widget.idLog);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pengukuran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.tanggal,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        leading: const BackButton(color: Colors.white),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Event'),
            Tab(text: 'Harian'),
          ],
        ),
      ),
      body: _loading
          ? const SkeletonDetailPage()
          : _data.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _DetailReportHeader(
                    idLog: widget.idLog,
                    tanggal: widget.tanggal,
                    site: widget.site,
                    summary: DetailHasilReportSummary.fromPrismas(_data),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _EventTab(data: _data),
                      _HarianTab(data: _data),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.scatter_plot_outlined,
            size: 56,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'Tidak ada data deformasi',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DetailReportHeader extends StatelessWidget {
  final String idLog;
  final String tanggal;
  final String site;
  final DetailHasilReportSummary summary;

  const _DetailReportHeader({
    required this.idLog,
    required this.tanggal,
    required this.site,
    required this.summary,
  });

  Color _siteColor(String value) {
    switch (value.toLowerCase()) {
      case 'cpp3':
      case 'cpp':
        return AppColors.siteCpp;
      case 'wp':
        return AppColors.siteWp;
      default:
        return AppColors.siteRd;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _siteColor(site);
    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tanggal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID $idLog',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: site.toUpperCase(), color: color, subtle: true),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _DetailMini(label: 'Prism', value: '${summary.totalPrism}'),
              const SizedBox(width: 8),
              _DetailMini(label: 'Success', value: '${summary.success}'),
              const SizedBox(width: 8),
              _DetailMini(label: 'Failed', value: '${summary.failed}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailMini extends StatelessWidget {
  final String label;
  final String value;

  const _DetailMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Event Tab ────────────────────────────────────────────────────────────────

class _EventTab extends StatelessWidget {
  final List<PrismaDeformasi> data;
  const _EventTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: data.map((p) => _EventCard(prisma: p)).toList()),
    );
  }
}

class _EventCard extends StatelessWidget {
  final PrismaDeformasi prisma;
  const _EventCard({required this.prisma});

  Color get _statusColor {
    switch (prisma.status) {
      case 'success':
        return AppColors.success;
      case 'failed':
        return AppColors.danger;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.my_location_rounded, color: _statusColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prisma.namaPrisma,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    prisma.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Coordinates section
                _SectionLabel('Koordinat Awal'),
                const SizedBox(height: 6),
                _CoordRow('N0', prisma.n0, 'E0', prisma.e0, 'Z0', prisma.z0),
                const SizedBox(height: 12),
                _SectionLabel('Koordinat Akhir'),
                const SizedBox(height: 6),
                _CoordRow('N1', prisma.n1, 'E1', prisma.e1, 'Z1', prisma.z1),
                const SizedBox(height: 12),

                // Displacement section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pergeseran',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _DeltaChip('dN', prisma.dn),
                          const SizedBox(width: 8),
                          _DeltaChip('dE', prisma.de),
                          const SizedBox(width: 8),
                          _DeltaChip('dZ', prisma.dz),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoRow(
                              'Linear',
                              '${prisma.linear.toStringAsFixed(3)} m',
                            ),
                          ),
                          Expanded(
                            child: _InfoRow('Arah', prisma.arahPergeseran),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Harian Tab ───────────────────────────────────────────────────────────────

class _HarianTab extends StatelessWidget {
  final List<PrismaDeformasi> data;
  const _HarianTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: data.map((p) => _HarianCard(prisma: p)).toList()),
    );
  }
}

class _HarianCard extends StatelessWidget {
  final PrismaDeformasi prisma;
  const _HarianCard({required this.prisma});

  Color _statusBadgeColor(String label) {
    if (label.contains('Normal') || label.contains('Aman')) {
      return AppColors.success;
    }
    if (label.contains('Waspada') || label.contains('Sedang')) {
      return AppColors.warning;
    }
    if (label.contains('Siaga') || label.contains('Cepat')) {
      return AppColors.danger;
    }
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                prisma.namaPrisma,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Pergeseran',
                  value: '${prisma.pergeseranMm.toStringAsFixed(2)} mm',
                  badge: prisma.statusPergeseran,
                  badgeColor: _statusBadgeColor(prisma.statusPergeseran),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Kecepatan',
                  value: '${prisma.kecepatanMmd.toStringAsFixed(2)} mm/d',
                  badge: prisma.statusKecepatan,
                  badgeColor: _statusBadgeColor(prisma.statusKecepatan),
                ),
              ),
            ],
          ),
          if (prisma.series.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SparklineWidget(series: prisma.series),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final Color badgeColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> series;
  const _SparklineWidget({required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();

    final values = series
        .map((e) => (e['mm'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, range: range, min: minVal),
        child: Container(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final double range;
  final double min;

  _SparklinePainter({
    required this.values,
    required this.range,
    required this.min,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => values != old.values;
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );
}

class _CoordRow extends StatelessWidget {
  final String l1, l2, l3;
  final double v1, v2, v3;
  const _CoordRow(this.l1, this.v1, this.l2, this.v2, this.l3, this.v3);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CoordCell(l1, v1),
        const SizedBox(width: 8),
        _CoordCell(l2, v2),
        const SizedBox(width: 8),
        _CoordCell(l3, v3),
      ],
    );
  }
}

class _CoordCell extends StatelessWidget {
  final String label;
  final double value;
  const _CoordCell(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.toStringAsFixed(4),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final String label;
  final double value;
  const _DeltaChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final isPos = value >= 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${isPos ? '+' : ''}${value.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPos ? AppColors.success : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
