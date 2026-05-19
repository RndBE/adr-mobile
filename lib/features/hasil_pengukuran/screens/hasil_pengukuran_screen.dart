import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import '../data/hasil_repository.dart';

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
    if (_searchQuery.isEmpty) return _logs;
    final q = _searchQuery.toLowerCase();
    return _logs.where((l) =>
        l.datetime.toLowerCase().contains(q) ||
        l.site.toLowerCase().contains(q)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Pengukuran'),
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari tanggal atau site...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),

          // Info bar
          Container(
            color: AppColors.primarySurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${_filtered.length} data pengukuran',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
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
                              formattedDate: _formatDate(log.datetime),
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
          Icon(Icons.table_chart_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum ada data pengukuran',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogKontrol log;
  final Color siteColor;
  final String formattedDate;
  final VoidCallback onTap;

  const _LogTile({
    required this.log,
    required this.siteColor,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: log.isBaseline
                    ? AppColors.accentLight
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                log.isBaseline
                    ? Icons.flag_rounded
                    : Icons.play_arrow_rounded,
                color: log.isBaseline
                    ? AppColors.accent
                    : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary),
                      ),
                      if (log.isBaseline) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('R0',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: siteColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.site.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: siteColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('ID: ${log.idLog}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
