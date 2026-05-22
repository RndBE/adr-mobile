import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/dashboard_widgets.dart';
import '../../../shared/widgets/skeleton.dart';
import '../data/hasil_repository.dart';
import '../models/hasil_report_summary.dart';

class HasilPengukuranScreen extends StatefulWidget {
  const HasilPengukuranScreen({super.key});

  @override
  State<HasilPengukuranScreen> createState() => _HasilPengukuranScreenState();
}

class _HasilPengukuranScreenState extends State<HasilPengukuranScreen> {
  final _repo = HasilRepository();
  List<LogKontrol> _logs = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    final logs = await _repo.getLogList(limit: 100);
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  List<LogKontrol> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _logs
        .where(
          (l) =>
              q.isEmpty ||
              l.datetime.toLowerCase().contains(q) ||
              l.site.toLowerCase().contains(q) ||
              l.idLog.toLowerCase().contains(q),
        )
        .where(
          (l) =>
              _filter == 'Semua' ||
              (_filter == 'R0' && l.isBaseline) ||
              (_filter == 'Event' && !l.isBaseline) ||
              l.site.toLowerCase() == _filter.toLowerCase(),
        )
        .toList();
  }

  List<String> get _filters {
    final sites =
        _logs
            .map((log) => log.site.trim())
            .where((site) => site.isNotEmpty)
            .map((site) => site.toUpperCase())
            .toSet()
            .toList()
          ..sort();
    return ['Semua', 'R0', 'Event', ...sites];
  }

  Color _siteColor(String site) {
    switch (site.toLowerCase()) {
      case 'cpp3':
      case 'cpp':
        return AppColors.siteCpp;
      case 'wp':
        return AppColors.siteWp;
      default:
        return AppColors.siteRd;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy  HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatDay(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Pengukuran'),
        leading: const BackButton(color: Colors.white),
      ),
      backgroundColor: AppColors.bgLight,
      body: _loading
          ? const SkeletonHasilPengukuranPage()
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      _ReportSummaryCard(
                        summary: HasilReportSummary.fromLogs(_logs),
                        latestLabel: _logs.isEmpty
                            ? '-'
                            : _formatDate(
                                HasilReportSummary.fromLogs(
                                  _logs,
                                ).latestDatetime,
                              ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Cari tanggal, site, atau ID log...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _FilterStrip(
                        filters: _filters,
                        selected: _filter,
                        onSelected: (value) => setState(() => _filter = value),
                        siteColor: _siteColor,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  color: AppColors.primarySurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_filtered.length} report ditampilkan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _fetchLogs,
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final log = _filtered[i];
                              return _LogTile(
                                log: log,
                                siteColor: _siteColor(log.site),
                                dayLabel: _formatDay(log.datetime),
                                timeLabel: _formatTime(log.datetime),
                                onTap: () => context.push(
                                  '/detail-hasil',
                                  extra: {
                                    'id_log': log.idLog,
                                    'tanggal': _formatDate(log.datetime),
                                    'site': log.site,
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data pengukuran',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogKontrol log;
  final Color siteColor;
  final String dayLabel;
  final String timeLabel;
  final VoidCallback onTap;

  const _LogTile({
    required this.log,
    required this.siteColor,
    required this.dayLabel,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = log.isBaseline ? AppColors.accent : AppColors.primary;
    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: typeColor.withValues(alpha: 0.18)),
            ),
            child: Icon(
              log.isBaseline ? Icons.flag_rounded : Icons.timeline_rounded,
              color: typeColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _SmallBadge(
                      label: log.isBaseline ? 'R0' : 'EVENT',
                      color: typeColor,
                    ),
                    _SmallBadge(
                      label: log.site.toUpperCase(),
                      color: siteColor,
                    ),
                    _SmallBadge(
                      label: 'ID ${log.idLog}',
                      color: AppColors.textSecondary,
                      subtle: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  final HasilReportSummary summary;
  final String latestLabel;

  const _ReportSummaryCard({required this.summary, required this.latestLabel});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Pengukuran',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      latestLabel == '-' ? 'Belum ada update' : latestLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _SummaryMini(label: 'Total', value: '${summary.total}'),
              const SizedBox(width: 8),
              _SummaryMini(label: 'R0', value: '${summary.baseline}'),
              const SizedBox(width: 8),
              _SummaryMini(label: 'Event', value: '${summary.event}'),
              const SizedBox(width: 8),
              _SummaryMini(label: 'Site', value: '${summary.siteCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMini extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMini({required this.label, required this.value});

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

class _FilterStrip extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;
  final Color Function(String site) siteColor;

  const _FilterStrip({
    required this.filters,
    required this.selected,
    required this.onSelected,
    required this.siteColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selected;
          final color = switch (filter) {
            'Semua' => AppColors.primary,
            'R0' => AppColors.accent,
            'Event' => AppColors.primaryLight,
            _ => siteColor(filter),
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(filter),
              onSelected: (_) => onSelected(filter),
              selectedColor: color,
              backgroundColor: color.withValues(alpha: 0.10),
              showCheckmark: false,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool subtle;

  const _SmallBadge({
    required this.label,
    required this.color,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: subtle ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(7),
        border: subtle
            ? Border.all(color: color.withValues(alpha: 0.12))
            : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
