import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../analisa/data/analisa_repository.dart';

class PowerRtsScreen extends StatefulWidget {
  const PowerRtsScreen({super.key});

  @override
  State<PowerRtsScreen> createState() => _PowerRtsScreenState();
}

class _PowerRtsScreenState extends State<PowerRtsScreen> {
  final _repo = AnalisaRepository();

  static const _params = [
    _ParamCfg('Power RTS', 'sensor23', Icons.bolt_rounded, AppColors.accent),
    _ParamCfg('Humidity', 'sensor20', Icons.water_drop_rounded, AppColors.info),
    _ParamCfg(
      'Battery',
      'sensor21',
      Icons.battery_charging_full_rounded,
      AppColors.success,
    ),
    _ParamCfg(
      'Temperatur',
      'sensor22',
      Icons.thermostat_rounded,
      AppColors.danger,
    ),
  ];

  static const _periods = ['Hari', 'Bulan', 'Tahun'];

  int _paramIdx = 0;
  int _periodIdx = 0;
  DateTime _date = DateTime.now();
  SensorStats? _stats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final stats = await _repo.getPowerRts(
      loggerId: '1',
      param: _params[_paramIdx].key,
      date: _dateStr,
      period: _periods[_periodIdx].toLowerCase(),
    );
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
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
      setState(() => _date = picked);
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final param = _params[_paramIdx];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Power RTS'),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_params.length, (i) {
                      final p = _params[i];
                      final sel = i == _paramIdx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: sel,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                p.icon,
                                size: 13,
                                color: sel ? Colors.white : p.color,
                              ),
                              const SizedBox(width: 4),
                              Text(p.label),
                            ],
                          ),
                          onSelected: (_) {
                            setState(() => _paramIdx = i);
                            _fetch();
                          },
                          selectedColor: p.color,
                          backgroundColor: p.color.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: sel ? Colors.white : p.color,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(_periods.length, (i) {
                      final sel = i == _periodIdx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_periods[i]),
                          selected: sel,
                          onSelected: (_) {
                            setState(() => _periodIdx = i);
                            _fetch();
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.bgLight,
                          labelStyle: TextStyle(
                            color: sel ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide.none,
                        ),
                      );
                    }),
                    const Spacer(),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_date),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const SkeletonAnalysisPage()
                : _stats == null
                ? _buildEmpty()
                : _buildContent(param),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_ParamCfg param) {
    final s = _stats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary
          Row(
            children: [
              _SummaryCard('Min', s.min.toStringAsFixed(2), AppColors.success),
              const SizedBox(width: 10),
              _SummaryCard('Avg', s.avg.toStringAsFixed(2), AppColors.primary),
              const SizedBox(width: 10),
              _SummaryCard('Max', s.max.toStringAsFixed(2), AppColors.danger),
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
                    Icon(param.icon, color: param.color, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      param.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat('dd/MM HH:mm'),
                      labelStyle: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      labelStyle: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                      majorGridLines: MajorGridLines(
                        color: AppColors.divider.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    trackballBehavior: TrackballBehavior(
                      enable: true,
                      activationMode: ActivationMode.singleTap,
                      tooltipSettings: const InteractiveTooltip(
                        color: AppColors.primary,
                      ),
                    ),
                    series: [
                      AreaSeries<SensorPoint, DateTime>(
                        dataSource: s.points,
                        animationDuration: 0,
                        xValueMapper: (p, _) => p.waktu,
                        yValueMapper: (p, _) => p.nilai,
                        color: param.color.withValues(alpha: 0.12),
                        borderColor: param.color,
                        borderWidth: 2,
                      ),
                      LineSeries<SensorPoint, DateTime>(
                        dataSource: s.points,
                        animationDuration: 0,
                        xValueMapper: (p, _) => p.waktu,
                        yValueMapper: (_, _) => s.avg,
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                        dashArray: const [4, 4],
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

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_outlined, size: 56, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'Tidak ada data untuk periode ini',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ParamCfg {
  final String label;
  final String key;
  final IconData icon;
  final Color color;
  const _ParamCfg(this.label, this.key, this.icon, this.color);
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
