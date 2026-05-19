import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../shared/theme/app_theme.dart';
import '../data/analisa_repository.dart';

class AnalisaScreen extends StatefulWidget {
  const AnalisaScreen({super.key});

  @override
  State<AnalisaScreen> createState() => _AnalisaScreenState();
}

class _AnalisaScreenState extends State<AnalisaScreen> {
  final _repo = AnalisaRepository();

  static const _params = [
    _ParamConfig('Power RTS', 'sensor23', Icons.bolt_rounded, AppColors.accent),
    _ParamConfig('Humidity', 'sensor20', Icons.water_drop_rounded, AppColors.info),
    _ParamConfig('Battery', 'sensor21', Icons.battery_charging_full_rounded, AppColors.success),
    _ParamConfig('Temperatur', 'sensor22', Icons.thermostat_rounded, AppColors.danger),
  ];

  static const _periods = ['Hari', 'Bulan', 'Tahun', 'Rentang'];

  int _paramIdx = 0;
  int _periodIdx = 0;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customRange;

  SensorStats? _stats;
  bool _loading = false;

  String get _fromDate {
    switch (_periodIdx) {
      case 0:
        return DateFormat('yyyy-MM-dd').format(_selectedDate);
      case 1:
        return DateFormat('yyyy-MM-01').format(_selectedDate);
      case 2:
        return '${_selectedDate.year}-01-01';
      default:
        return _customRange != null
            ? DateFormat('yyyy-MM-dd').format(_customRange!.start)
            : DateFormat('yyyy-MM-dd').format(_selectedDate);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final param = _params[_paramIdx];
    final stats = await _repo.getPowerRts(
      loggerId: '1',
      param: param.key,
      date: _fromDate,
      period: _periods[_periodIdx].toLowerCase(),
    );
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    if (_periodIdx == 3) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _customRange,
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        ),
      );
      if (range != null) {
        setState(() => _customRange = range);
        _fetchData();
      }
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final param = _params[_paramIdx];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisa Data'),
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          // Controls
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Parameter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_params.length, (i) {
                      final p = _params[i];
                      final selected = i == _paramIdx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: selected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(p.icon,
                                  size: 14,
                                  color: selected ? Colors.white : p.color),
                              const SizedBox(width: 4),
                              Text(p.label),
                            ],
                          ),
                          onSelected: (_) {
                            setState(() => _paramIdx = i);
                            _fetchData();
                          },
                          selectedColor: p.color,
                          backgroundColor: p.color.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : p.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          showCheckmark: false,
                          side: BorderSide.none,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),

                // Period chips + date picker
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_periods.length, (i) {
                            final selected = i == _periodIdx;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(_periods[i]),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() => _periodIdx = i);
                                  _fetchData();
                                },
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.bgLight,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                side: BorderSide.none,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : _stats == null
                    ? _buildEmpty()
                    : _buildContent(param),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_ParamConfig param) {
    final stats = _stats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary cards
          Row(
            children: [
              _StatCard('Minimum', stats.min.toStringAsFixed(2), param.color),
              const SizedBox(width: 10),
              _StatCard('Rata-rata', stats.avg.toStringAsFixed(2), AppColors.primary),
              const SizedBox(width: 10),
              _StatCard('Maksimum', stats.max.toStringAsFixed(2), AppColors.accent),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          Container(
            padding: const EdgeInsets.all(16),
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
                    Icon(param.icon, color: param.color, size: 18),
                    const SizedBox(width: 8),
                    Text(param.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat('dd/MM'),
                      labelStyle: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      labelStyle: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                      majorGridLines: MajorGridLines(
                        color: AppColors.divider.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    plotAreaBorderWidth: 0,
                    trackballBehavior: TrackballBehavior(
                      enable: true,
                      activationMode: ActivationMode.singleTap,
                      tooltipSettings: const InteractiveTooltip(
                        format: 'point.x\npoint.y',
                        color: AppColors.primary,
                      ),
                    ),
                    series: [
                      AreaSeries<SensorPoint, DateTime>(
                        dataSource: stats.points,
                        xValueMapper: (p, _) => p.waktu,
                        yValueMapper: (p, _) => p.nilai,
                        color: param.color.withValues(alpha: 0.15),
                        borderColor: param.color,
                        borderWidth: 2,
                      ),
                      // Avg line
                      LineSeries<SensorPoint, DateTime>(
                        dataSource: stats.points,
                        xValueMapper: (p, _) => p.waktu,
                        yValueMapper: (_, _) => stats.avg,
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 1.5,
                        dashArray: const [4, 4],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Tabel Data',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                ),
                const Divider(height: 1),
                ...stats.points.take(20).map(
                      (p) => _DataRow(
                        time: DateFormat('dd/MM HH:mm').format(p.waktu),
                        value: p.nilai.toStringAsFixed(2),
                        color: param.color,
                      ),
                    ),
                if (stats.points.length > 20)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '... dan ${stats.points.length - 20} data lainnya',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
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
          Icon(Icons.show_chart_rounded, size: 56, color: AppColors.textHint),
          SizedBox(height: 16),
          Text('Tidak ada data untuk periode ini',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ParamConfig {
  final String label;
  final String key;
  final IconData icon;
  final Color color;
  const _ParamConfig(this.label, this.key, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String time;
  final String value;
  final Color color;
  const _DataRow({required this.time, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              size: 14, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(time,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
