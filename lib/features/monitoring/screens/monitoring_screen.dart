import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import '../data/monitoring_repository.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _repo = MonitoringRepository();

  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  List<HeatmapRow> _rows = [];

  // Tabs: ARR = rainfall, AWLR = water level
  static const _tabs = [
    _TabConfig('ARR / Hujan', 'ews', AppColors.info),
    _TabConfig('AWLR / Muka Air', 'awlr', AppColors.primary),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _fetchData();
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final tab = _tabs[_tabCtrl.index];
    final rows = await _repo.getHeatmapData(
      loggerId: '1',
      table: tab.table,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchData();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Sensor'),
        leading: const BackButton(color: Colors.white),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _tabs
              .map((t) => Tab(
                    child: Text(t.label,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                  label: const Text('Ganti Tanggal'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Heatmap legend
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Intensitas:',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                ...[
                  ('Tidak ada', Colors.grey.shade200),
                  ('Ringan', const Color(0xFFBBDEFB)),
                  ('Sedang', const Color(0xFF64B5F6)),
                  ('Deras', const Color(0xFF1565C0)),
                  ('Sangat deras', const Color(0xFF0D0D5F)),
                ].map((e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: e.$2,
                        ),
                        const SizedBox(width: 3),
                        Text(e.$1,
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary)),
                      ]),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),

          // Heatmap content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _rows.isEmpty
                    ? _buildEmpty()
                    : _buildHeatmap(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    final tab = _tabs[_tabCtrl.index];
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hour header
              Row(
                children: [
                  const SizedBox(width: 70),
                  ...List.generate(24, (h) => _HourHeader(hour: h)),
                ],
              ),
              const SizedBox(height: 4),

              // Rows
              ..._rows.map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            row.tanggal.length >= 10
                                ? row.tanggal.substring(5)
                                : row.tanggal,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        ...row.cells.map(
                          (cell) => _HeatCell(
                            cell: cell,
                            color: tab.color,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Tidak ada data untuk tanggal ini',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final String table;
  final Color color;
  const _TabConfig(this.label, this.table, this.color);
}

class _HourHeader extends StatelessWidget {
  final int hour;
  const _HourHeader({required this.hour});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      child: Text(
        '$hour',
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  final HeatmapCell cell;
  final Color color;

  const _HeatCell({required this.cell, required this.color});

  Color get _cellColor {
    if (cell.value < 0) return Colors.grey.shade100;
    if (cell.value == 0) return Colors.grey.shade200;
    if (cell.value < 5) return color.withValues(alpha: 0.2);
    if (cell.value < 20) return color.withValues(alpha: 0.45);
    if (cell.value < 50) return color.withValues(alpha: 0.7);
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: cell.value < 0 ? 'Tidak ada data' : cell.value.toStringAsFixed(1),
      child: Container(
        width: 26,
        height: 26,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _cellColor,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
