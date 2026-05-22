import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../beranda/data/beranda_repository.dart';
import '../data/analisa_repository.dart';
import '../models/analisa_data_cache.dart';
import '../models/analisa_dashboard_summary.dart';
import '../models/analisa_dialog_layout.dart';
import '../models/analisa_month_picker.dart';
import '../models/analisa_range_picker.dart';
import '../models/analisa_sensor_history_query.dart';

class AnalisaScreen extends StatefulWidget {
  final String? mode;
  final String? initialParamKey;
  final String? prismaName;
  final String? initialDate;

  const AnalisaScreen({
    super.key,
    this.mode,
    this.initialParamKey,
    this.prismaName,
    this.initialDate,
  });

  @override
  State<AnalisaScreen> createState() => _AnalisaScreenState();
}

class _AnalisaScreenState extends State<AnalisaScreen> {
  final _repo = AnalisaRepository();
  final _loggerRepo = BerandaRepository();
  final _sensorCache = AnalisaDataCache<SensorStats>();
  final _prismaCache = AnalisaDataCache<PrismaStats>();

  static const _params = [
    _ParamConfig(
      'Humidity Logger',
      'sensor20',
      Icons.water_drop_outlined,
      AppColors.info,
      '%',
    ),
    _ParamConfig(
      'Battery Logger',
      'sensor21',
      Icons.battery_full_rounded,
      AppColors.success,
      'Volt',
    ),
    _ParamConfig(
      'Temperature Logger',
      'sensor22',
      Icons.thermostat_rounded,
      AppColors.danger,
      '°C',
    ),
    _ParamConfig(
      'Power RTS',
      'sensor23',
      Icons.bolt_rounded,
      AppColors.accent,
      'Volt',
    ),
  ];

  static const _periods = ['Hari', 'Bulan', 'Rentang'];
  static const _prismaParams = [
    _PrismaParamConfig('Northing Y', 'n', 'Y'),
    _PrismaParamConfig('Easting X', 'e', 'X'),
    _PrismaParamConfig('Elevation', 'z', 'Z'),
  ];

  int _paramIdx = 0;
  int _prismaParamIdx = 0;
  int _periodIdx = 0;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customRange;

  SensorStats? _stats;
  PrismaStats? _prismaStats;
  LoggerInfo? _loggerInfo;
  Future<LoggerInfo?>? _loggerInfoRequest;
  String? _activeSensorCacheKey;
  String? _activePrismaCacheKey;
  int _fetchToken = 0;
  bool _loading = false;

  bool get _isPrismaMode => widget.mode == 'prisma';

  DateTimeRange get _sensorRange {
    switch (_periodIdx) {
      case 1:
        final start = DateTime(_selectedDate.year, _selectedDate.month);
        final end = DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          0,
          23,
          59,
          59,
        );
        return DateTimeRange(start: start, end: end);
      case 2:
        final range =
            _customRange ??
            DateTimeRange(start: _selectedDate, end: _selectedDate);
        return DateTimeRange(
          start: DateTime(range.start.year, range.start.month, range.start.day),
          end: DateTime(
            range.end.year,
            range.end.month,
            range.end.day,
            23,
            59,
            59,
          ),
        );
      default:
        return DateTimeRange(
          start: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          ),
          end: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            23,
            59,
            59,
          ),
        );
    }
  }

  String get _dateLabel {
    if (_periodIdx == 2 && _customRange != null) {
      final start = DateFormat(
        'd MMM yyyy',
        'id_ID',
      ).format(_customRange!.start);
      final end = DateFormat('d MMM yyyy', 'id_ID').format(_customRange!.end);
      return '$start - $end';
    }
    if (_periodIdx == 1) {
      return DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate);
    }
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate);
  }

  @override
  void initState() {
    super.initState();
    final initialDate = DateTime.tryParse(
      widget.initialDate?.replaceFirst(' ', 'T') ?? '',
    );
    if (initialDate != null) {
      _selectedDate = initialDate;
      _customRange = DateTimeRange(start: initialDate, end: initialDate);
    }
    final paramIndex = _params.indexWhere(
      (p) => p.key == widget.initialParamKey,
    );
    if (paramIndex >= 0) _paramIdx = paramIndex;
    final prismaParamIndex = _prismaParams.indexWhere(
      (p) => p.key == widget.initialParamKey,
    );
    if (prismaParamIndex >= 0) _prismaParamIdx = prismaParamIndex;
    _fetchData();
  }

  Future<void> _fetchData({bool forceRefresh = false}) async {
    if (_isPrismaMode) {
      await _fetchPrismaData(forceRefresh: forceRefresh);
      return;
    }

    await _fetchSensorData(forceRefresh: forceRefresh);
  }

  Future<void> _fetchSensorData({bool forceRefresh = false}) async {
    final token = ++_fetchToken;
    _ensureLoggerInfo();
    final param = _params[_paramIdx];
    final historyQuery = buildSensorHistoryQuery(
      start: _sensorRange.start,
      end: _sensorRange.end,
    );
    final cacheKey = buildSensorCacheKey(
      table: historyQuery.table,
      param: param.key,
      from: historyQuery.from,
      to: historyQuery.to,
    );
    _activeSensorCacheKey = cacheKey;

    if (!forceRefresh && _sensorCache.contains(cacheKey)) {
      setState(() {
        _stats = _sensorCache.get(cacheKey);
        _loading = false;
      });
      _refreshSensorCache(cacheKey, param.key, historyQuery);
      return;
    }

    setState(() => _loading = true);
    final stats = await _repo.getSensorData(
      loggerId: '1',
      table: historyQuery.table,
      param: param.key,
      from: historyQuery.from,
      to: historyQuery.to,
    );
    if (!mounted || token != _fetchToken) return;
    if (stats != null) _sensorCache.set(cacheKey, stats);
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _fetchPrismaData({bool forceRefresh = false}) async {
    final token = ++_fetchToken;
    _ensureLoggerInfo();
    final range = _prismaRange;
    final param = _prismaParams[_prismaParamIdx];
    final cacheKey = buildPrismaCacheKey(
      prismaName: widget.prismaName ?? '',
      metric: param.key,
      from: range.start,
      to: range.end,
    );
    _activePrismaCacheKey = cacheKey;

    if (!forceRefresh && _prismaCache.contains(cacheKey)) {
      setState(() {
        _prismaStats = _prismaCache.get(cacheKey);
        _loading = false;
      });
      _refreshPrismaCache(cacheKey, param.key, range);
      return;
    }

    setState(() => _loading = true);
    final stats = await _repo.getPrismaSeries(
      prismaName: widget.prismaName ?? '',
      metric: param.key,
      from: range.start,
      to: range.end,
    );
    if (!mounted || token != _fetchToken) return;
    if (stats != null) _prismaCache.set(cacheKey, stats);
    setState(() {
      _prismaStats = stats;
      _loading = false;
    });
  }

  void _ensureLoggerInfo() {
    if (_loggerInfo != null) return;
    _loggerInfoRequest ??= _loggerRepo.getLoggerInfo();
    _loggerInfoRequest!.then((info) {
      if (!mounted || info == null) return;
      setState(() => _loggerInfo = info);
    });
  }

  void _refreshSensorCache(
    String cacheKey,
    String paramKey,
    SensorHistoryQuery historyQuery,
  ) {
    Future<void>(() async {
      final stats = await _repo.getSensorData(
        loggerId: '1',
        table: historyQuery.table,
        param: paramKey,
        from: historyQuery.from,
        to: historyQuery.to,
      );
      if (!mounted || stats == null) return;
      _sensorCache.set(cacheKey, stats);
      if (_activeSensorCacheKey == cacheKey) {
        setState(() => _stats = stats);
      }
    });
  }

  void _refreshPrismaCache(
    String cacheKey,
    String metric,
    DateTimeRange range,
  ) {
    Future<void>(() async {
      final stats = await _repo.getPrismaSeries(
        prismaName: widget.prismaName ?? '',
        metric: metric,
        from: range.start,
        to: range.end,
      );
      if (!mounted || stats == null) return;
      _prismaCache.set(cacheKey, stats);
      if (_activePrismaCacheKey == cacheKey) {
        setState(() => _prismaStats = stats);
      }
    });
  }

  DateTimeRange get _prismaRange {
    final range =
        _customRange ?? DateTimeRange(start: _selectedDate, end: _selectedDate);
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    return DateTimeRange(start: start, end: end);
  }

  Future<DateTime?> _pickSingleDate() {
    return showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: _pickerTheme,
    );
  }

  Future<DateTime?> _pickMonth() {
    return showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (context) => _MonthPickerDialog(
        initialDate: _selectedDate,
        firstYear: 2020,
        maxDate: DateTime.now(),
      ),
    );
  }

  Future<DateTimeRange?> _pickDateRange() {
    return showDialog<DateTimeRange>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (context) => _RangePickerDialog(
        initialRange: _customRange,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        maxDate: DateTime.now(),
      ),
    );
  }

  Future<void> _pickPrismaRange() async {
    final range = await _pickDateRange();
    if (range != null) {
      setState(() {
        _customRange = range;
        _prismaStats = null;
      });
      _fetchData();
    }
  }

  Future<void> _selectPeriod(int index) async {
    if (index == 2) {
      final range = await _pickDateRange();
      if (range == null) return;
      setState(() {
        _periodIdx = index;
        _customRange = range;
        if (_isPrismaMode) {
          _prismaStats = null;
        } else {
          _stats = null;
        }
      });
      _fetchData();
      return;
    }

    final picked = index == 1 ? await _pickMonth() : await _pickSingleDate();
    if (picked != null) {
      setState(() {
        _periodIdx = index;
        _selectedDate = picked;
        if (_isPrismaMode) {
          _prismaStats = null;
        } else {
          _stats = null;
        }
      });
      _fetchData();
    }
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColors.primary),
      ),
      child: child!,
    );
  }

  void _selectParam(int index) {
    setState(() {
      _paramIdx = index;
      _stats = null;
    });
    _fetchData();
  }

  void _selectPrismaParam(int index) {
    setState(() {
      _prismaParamIdx = index;
      _prismaStats = null;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final param = _params[_paramIdx];
    final prismaParam = _prismaParams[_prismaParamIdx];
    final empty = _isPrismaMode ? _prismaStats == null : _stats == null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        toolbarHeight: 58,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Analisa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export belum tersedia')),
              );
            },
            icon: const Icon(
              Icons.file_download_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _fetchData(forceRefresh: true),
        child: _loading && empty
            ? SkeletonAnalysisPage(compactTable: _isPrismaMode)
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LoggerStatusHeader(
                      loggerInfo: _loggerInfo,
                      iconLetter: _isPrismaMode ? prismaParam.iconLetter : null,
                      title: _isPrismaMode ? widget.prismaName : null,
                    ),
                    const SizedBox(height: 18),
                    if (_isPrismaMode)
                      _PrismaDateRangeCard(
                        range: _prismaRange,
                        onTap: _pickPrismaRange,
                      )
                    else
                      _PeriodSwitcher(
                        periods: _periods,
                        selectedIndex: _periodIdx,
                        onSelected: _selectPeriod,
                      ),
                    const SizedBox(height: 14),
                    if (_isPrismaMode)
                      _PrismaParameterSelector(
                        params: _prismaParams,
                        selectedIndex: _prismaParamIdx,
                        onSelected: _selectPrismaParam,
                      )
                    else
                      _ParameterSelector(
                        params: _params,
                        selectedIndex: _paramIdx,
                        onSelected: _selectParam,
                      ),
                    const SizedBox(height: 18),
                    if (_isPrismaMode && _prismaStats != null) ...[
                      _PrismaChartCard(
                        param: prismaParam,
                        stats: _prismaStats!,
                        range: _prismaRange,
                      ),
                      const SizedBox(height: 18),
                      _PrismaDataTableCard(
                        param: prismaParam,
                        points: _prismaStats!.points,
                        range: _prismaRange,
                      ),
                    ] else if (_stats == null)
                      const _EmptyCard()
                    else ...[
                      _ChartCard(
                        param: param,
                        stats: _stats!,
                        dateLabel: _dateLabel,
                        range: _sensorRange,
                      ),
                      const SizedBox(height: 18),
                      _DataTableCard(
                        param: param,
                        points: _stats!.points,
                        range: _sensorRange,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _ParamConfig {
  final String label;
  final String key;
  final IconData icon;
  final Color color;
  final String unit;
  const _ParamConfig(this.label, this.key, this.icon, this.color, this.unit);
}

class _PrismaParamConfig {
  final String label;
  final String key;
  final String iconLetter;

  const _PrismaParamConfig(this.label, this.key, this.iconLetter);
}

class _LoggerStatusHeader extends StatelessWidget {
  final LoggerInfo? loggerInfo;
  final String? iconLetter;
  final String? title;
  const _LoggerStatusHeader({
    required this.loggerInfo,
    this.iconLetter,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = loggerInfo?.loggerAktif.toLowerCase() == 'aktif';
    final statusText = isActive ? 'Koneksi Terhubung' : 'Koneksi Terputus';
    final statusColor = isActive ? AppColors.success : AppColors.danger;

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFDDF0FB),
            shape: BoxShape.circle,
          ),
          child: iconLetter == null
              ? Icon(
                  isActive ? Icons.sensors_rounded : Icons.water_drop_outlined,
                  color: statusColor,
                  size: 30,
                )
              : Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.danger, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      iconLetter!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title?.isNotEmpty == true
                    ? title!
                    : (loggerInfo?.sensor ?? 'BS RTS'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final int firstYear;
  final DateTime maxDate;

  const _MonthPickerDialog({
    required this.initialDate,
    required this.firstYear,
    required this.maxDate,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  late int _month;

  int get _maxYear => widget.maxDate.year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year.clamp(widget.firstYear, _maxYear);
    _month = widget.initialDate.month;
    if (!isAnalisaMonthEnabled(
      year: _year,
      month: _month,
      maxDate: widget.maxDate,
    )) {
      _month = widget.maxDate.month;
    }
  }

  void _changeYear(int delta) {
    final nextYear = (_year + delta).clamp(widget.firstYear, _maxYear);
    if (nextYear == _year) return;
    setState(() {
      _year = nextYear;
      if (!isAnalisaMonthEnabled(
        year: _year,
        month: _month,
        maxDate: widget.maxDate,
      )) {
        _month = widget.maxDate.month;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = formatAnalisaMonthTitle(year: _year, month: _month);
    final dialogWidth = resolveAnalisaDialogWidth(
      screenWidth: MediaQuery.sizeOf(context).width,
      horizontalInset: 48,
      maxWidth: 280,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height - 48,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PILIH BULAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MonthYearButton(
                                icon: Icons.chevron_left_rounded,
                                enabled: _year > widget.firstYear,
                                onTap: () => _changeYear(-1),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F7),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  '$_year',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _MonthYearButton(
                                icon: Icons.chevron_right_rounded,
                                enabled: _year < _maxYear,
                                onTap: () => _changeYear(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _MonthGrid(
                            selectedMonth: _month,
                            enabledFor: (month) => isAnalisaMonthEnabled(
                              year: _year,
                              month: month,
                              maxDate: widget.maxDate,
                            ),
                            onSelected: (month) =>
                                setState(() => _month = month),
                          ),
                          const SizedBox(height: 18),
                          _DialogActionRow(
                            onCancel: () => Navigator.pop(context),
                            onConfirm: () => Navigator.pop(
                              context,
                              buildAnalisaMonthDate(year: _year, month: _month),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final int selectedMonth;
  final bool Function(int month) enabledFor;
  final ValueChanged<int> onSelected;

  const _MonthGrid({
    required this.selectedMonth,
    required this.enabledFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 162,
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Expanded(
              child: Row(
                children: [
                  for (var column = 0; column < 3; column++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Builder(
                          builder: (context) {
                            final index = row * 3 + column;
                            final month = index + 1;
                            final enabled = enabledFor(month);
                            return _MonthTile(
                              label: analisaMonthLabels[index],
                              selected: month == selectedMonth,
                              enabled: enabled,
                              onTap: enabled ? () => onSelected(month) : null,
                            );
                          },
                        ),
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

class _MonthYearButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _MonthYearButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: enabled ? onTap : null,
      icon: Icon(
        icon,
        color: enabled ? AppColors.textPrimary : AppColors.textHint,
        size: 20,
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _MonthTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF9694C5) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: !enabled
                ? AppColors.textHint
                : selected
                ? Colors.white
                : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DialogActionRow extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _DialogActionRow({required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE9EFF6),
                foregroundColor: AppColors.textSecondary,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Batal',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Pilih',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodSwitcher extends StatelessWidget {
  final List<String> periods;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PeriodSwitcher({
    required this.periods,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(periods.length, (index) {
        final selected = index == selectedIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == periods.length - 1 ? 0 : 8,
            ),
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => onSelected(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected
                      ? const Color(0xFFFFD600)
                      : AppColors.primary,
                  foregroundColor: selected
                      ? AppColors.textPrimary
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    periods[index],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ParameterSelector extends StatelessWidget {
  final List<_ParamConfig> params;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ParameterSelector({
    required this.params,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = params[selectedIndex];
    return InkWell(
      onTap: () => _showSensorSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: cardShadowLg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  void _showSensorSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Sensor',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(params.length, (index) {
                  final param = params[index];
                  final selected = index == selectedIndex;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: param.color.withValues(alpha: 0.12),
                      child: Icon(param.icon, color: param.color, size: 20),
                    ),
                    title: Text(
                      param.label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(index);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrismaDateRangeCard extends StatelessWidget {
  final DateTimeRange range;
  final VoidCallback onTap;

  const _PrismaDateRangeCard({required this.range, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('yyyy-MM-dd').format(range.start);
    final end = DateFormat('yyyy-MM-dd').format(range.end);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: cardShadowLg,
        ),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$start     s/d     $end',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.calendar_month_rounded,
              color: Colors.black,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _RangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime maxDate;

  const _RangePickerDialog({
    required this.initialRange,
    required this.initialDate,
    required this.firstDate,
    required this.maxDate,
  });

  @override
  State<_RangePickerDialog> createState() => _RangePickerDialogState();
}

class _RangePickerDialogState extends State<_RangePickerDialog> {
  late DateTime _start;
  late DateTime _end;
  late DateTime _visibleMonth;
  bool _selectingEnd = true;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start ?? widget.initialDate;
    _end = widget.initialRange?.end ?? widget.initialDate;
    if (_end.isBefore(_start)) _end = _start;
    _visibleMonth = DateTime(_start.year, _start.month);
  }

  void _moveMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final minMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final maxMonth = DateTime(widget.maxDate.year, widget.maxDate.month);
    if (next.isBefore(minMonth) || next.isAfter(maxMonth)) return;
    setState(() => _visibleMonth = next);
  }

  void _selectDate(DateTime date) {
    if (date.isBefore(_dateOnly(widget.firstDate)) ||
        date.isAfter(_dateOnly(widget.maxDate))) {
      return;
    }

    setState(() {
      if (!_selectingEnd) {
        _start = date;
        if (_end.isBefore(_start)) _end = _start;
        _selectingEnd = true;
        return;
      }

      if (date.isBefore(_start)) {
        _end = _start;
        _start = date;
      } else {
        _end = date;
      }
      _selectingEnd = false;
    });
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    final cells = buildAnalisaCalendarCells(
      year: _visibleMonth.year,
      month: _visibleMonth.month,
    );
    final monthLabel = formatAnalisaMonthTitle(
      year: _visibleMonth.year,
      month: _visibleMonth.month,
    );
    final dialogWidth = resolveAnalisaDialogWidth(
      screenWidth: MediaQuery.sizeOf(context).width,
      horizontalInset: 32,
      maxWidth: 330,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height - 48,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PILIH RENTANG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Flexible(
                                child: _RangePill(
                                  date: _start,
                                  active: !_selectingEnd,
                                  onTap: () =>
                                      setState(() => _selectingEnd = false),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: _RangePill(
                                  date: _end,
                                  active: _selectingEnd,
                                  onTap: () =>
                                      setState(() => _selectingEnd = true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _moveMonth(-1),
                                icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: AppColors.textPrimary,
                                  size: 22,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_rounded,
                                        color: AppColors.textPrimary,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        monthLabel,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _moveMonth(1),
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textPrimary,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final label in analisaWeekdayLabels)
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _RangeCalendarGrid(
                            cells: cells,
                            firstDate: _dateOnly(widget.firstDate),
                            maxDate: _dateOnly(widget.maxDate),
                            start: _start,
                            end: _end,
                            onSelected: _selectDate,
                          ),
                          const SizedBox(height: 16),
                          _DialogActionRow(
                            onCancel: () => Navigator.pop(context),
                            onConfirm: () => Navigator.pop(
                              context,
                              DateTimeRange(start: _start, end: _end),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeCalendarGrid extends StatelessWidget {
  final List<DateTime?> cells;
  final DateTime firstDate;
  final DateTime maxDate;
  final DateTime start;
  final DateTime end;
  final ValueChanged<DateTime> onSelected;

  const _RangeCalendarGrid({
    required this.cells,
    required this.firstDate,
    required this.maxDate,
    required this.start,
    required this.end,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216,
      child: Column(
        children: [
          for (var row = 0; row < 6; row++)
            Expanded(
              child: Row(
                children: [
                  for (var column = 0; column < 7; column++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final date = cells[row * 7 + column];
                          if (date == null) return const SizedBox.shrink();

                          final disabled =
                              date.isBefore(firstDate) || date.isAfter(maxDate);
                          return _RangeCalendarDay(
                            date: date,
                            selectedStart: isAnalisaRangeStart(date, start),
                            selectedEnd: isAnalisaRangeEnd(date, end),
                            inRange: isAnalisaDateInsideRange(date, start, end),
                            disabled: disabled,
                            onTap: disabled ? null : () => onSelected(date),
                          );
                        },
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

class _RangePill extends StatelessWidget {
  final DateTime date;
  final bool active;
  final VoidCallback onTap;

  const _RangePill({
    required this.date,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : const Color(0xFFE8EDFF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatAnalisaRangePill(date),
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeCalendarDay extends StatelessWidget {
  final DateTime date;
  final bool selectedStart;
  final bool selectedEnd;
  final bool inRange;
  final bool disabled;
  final VoidCallback? onTap;

  const _RangeCalendarDay({
    required this.date,
    required this.selectedStart,
    required this.selectedEnd,
    required this.inRange,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedStart || selectedEnd;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (inRange && !selected)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(color: const Color(0xFFE6E8F4)),
              ),
            ),
          if (selected)
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF9694C5),
                shape: BoxShape.circle,
              ),
            ),
          Text(
            '${date.day}',
            style: TextStyle(
              color: disabled
                  ? AppColors.textHint
                  : selected
                  ? Colors.white
                  : AppColors.textPrimary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrismaParameterSelector extends StatelessWidget {
  final List<_PrismaParamConfig> params;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PrismaParameterSelector({
    required this.params,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = params[selectedIndex];
    return InkWell(
      onTap: () => _showPrismaSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: cardShadowLg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  void _showPrismaSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Data Prisma',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(params.length, (index) {
                  final param = params[index];
                  final selected = index == selectedIndex;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        param.iconLetter,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(
                      param.label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(index);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final _ParamConfig param;
  final SensorStats stats;
  final String dateLabel;
  final DateTimeRange range;

  const _ChartCard({
    required this.param,
    required this.stats,
    required this.dateLabel,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final points = buildHourlySensorRangeSeries(
      points: stats.points,
      start: range.start,
      end: range.end,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadowLg,
      ),
      child: Column(
        children: [
          Text(
            '${param.label} (${param.unit})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            dateLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 280,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('HH:mm'),
                intervalType: DateTimeIntervalType.hours,
                interval: 5,
                labelRotation: 315,
                majorGridLines: MajorGridLines(
                  color: AppColors.divider.withValues(alpha: 0.9),
                  width: 1,
                ),
                axisLine: const AxisLine(color: AppColors.textHint),
                labelStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  color: AppColors.divider.withValues(alpha: 0.9),
                  width: 1,
                ),
                axisLine: const AxisLine(color: AppColors.textHint),
                labelStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              plotAreaBorderWidth: 0,
              legend: const Legend(isVisible: false),
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                tooltipSettings: const InteractiveTooltip(
                  color: AppColors.primary,
                ),
              ),
              series: [
                RangeAreaSeries<HourlySensorPoint, DateTime>(
                  name: 'Range',
                  dataSource: points,
                  animationDuration: 0,
                  xValueMapper: (p, _) => p.waktu,
                  lowValueMapper: (p, _) => p.low,
                  highValueMapper: (p, _) => p.high,
                  color: param.color.withValues(alpha: 0.28),
                  borderWidth: 0,
                ),
                LineSeries<HourlySensorPoint, DateTime>(
                  name: 'Rerata ${param.label}',
                  dataSource: points,
                  animationDuration: 0,
                  xValueMapper: (p, _) => p.waktu,
                  yValueMapper: (p, _) => p.nilai,
                  color: param.color,
                  width: 2.5,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    height: 8,
                    width: 8,
                    borderWidth: 2,
                    borderColor: param.color,
                    color: Colors.white,
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

class _DataTableCard extends StatelessWidget {
  final _ParamConfig param;
  final List<SensorPoint> points;
  final DateTimeRange range;

  const _DataTableCard({
    required this.param,
    required this.points,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final hourlyPoints = buildHourlySensorRangeSeries(
      points: points,
      start: range.start,
      end: range.end,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadowLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: _HourlySensorTable(param: param, points: hourlyPoints),
    );
  }
}

class _HourlySensorTable extends StatelessWidget {
  final _ParamConfig param;
  final List<HourlySensorPoint> points;

  const _HourlySensorTable({required this.param, required this.points});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(1.05),
        2: FlexColumnWidth(0.9),
        3: FlexColumnWidth(0.9),
      },
      border: TableBorder.all(color: AppColors.divider),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.white),
          children: [
            _TableHeaderCell('Waktu'),
            _TableHeaderCell('Rerata'),
            _TableHeaderCell('Low'),
            _TableHeaderCell('High'),
          ],
        ),
        ...points.map(
          (point) => TableRow(
            children: [
              _TableBodyCell(
                DateFormat('yyyy-MM-dd HH:mm:ss').format(point.waktu),
                alignStart: true,
              ),
              _TableBodyCell(formatAnalysisValue(point.nilai, digits: 3)),
              _TableBodyCell(formatAnalysisValue(point.low, digits: 2)),
              _TableBodyCell(formatAnalysisValue(point.high, digits: 2)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TableBodyCell extends StatelessWidget {
  final String text;
  final bool alignStart;

  const _TableBodyCell(this.text, {this.alignStart = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Text(
        text,
        textAlign: alignStart ? TextAlign.left : TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PrismaChartCard extends StatelessWidget {
  final _PrismaParamConfig param;
  final PrismaStats stats;
  final DateTimeRange range;

  const _PrismaChartCard({
    required this.param,
    required this.stats,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('d MMMM yyyy', 'id_ID').format(range.start);
    final end = DateFormat('d MMMM yyyy', 'id_ID').format(range.end);
    final points = buildHourlyPrismaRangeSeries(
      points: stats.points,
      start: range.start,
      end: range.end,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadowLg,
      ),
      child: Column(
        children: [
          Text(
            param.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$start sampai $end',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 280,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('HH:mm'),
                intervalType: DateTimeIntervalType.hours,
                interval: 5,
                labelRotation: 315,
                majorGridLines: MajorGridLines(
                  color: AppColors.divider.withValues(alpha: 0.9),
                  width: 1,
                ),
                axisLine: const AxisLine(color: AppColors.textHint),
                labelStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  color: AppColors.divider.withValues(alpha: 0.9),
                  width: 1,
                ),
                axisLine: const AxisLine(color: AppColors.textHint),
                labelStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              plotAreaBorderWidth: 0,
              legend: const Legend(isVisible: false),
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                tooltipSettings: const InteractiveTooltip(
                  color: AppColors.primary,
                ),
              ),
              series: [
                LineSeries<HourlyPrismaPoint, DateTime>(
                  name: 'Rerata ${param.label}',
                  dataSource: points,
                  animationDuration: 0,
                  xValueMapper: (p, _) => p.waktu,
                  yValueMapper: (p, _) => p.nilai,
                  color: const Color(0xFF1E9BE0),
                  width: 2.5,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 8,
                    width: 8,
                    borderWidth: 2,
                    borderColor: Color(0xFF1E9BE0),
                    color: Colors.white,
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

class _PrismaDataTableCard extends StatelessWidget {
  final _PrismaParamConfig param;
  final List<PrismaPoint> points;
  final DateTimeRange range;

  const _PrismaDataTableCard({
    required this.param,
    required this.points,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final hourlyPoints = buildHourlyPrismaRangeSeries(
      points: points,
      start: range.start,
      end: range.end,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadowLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: _HourlyPrismaTable(points: hourlyPoints),
    );
  }
}

class _HourlyPrismaTable extends StatelessWidget {
  final List<HourlyPrismaPoint> points;

  const _HourlyPrismaTable({required this.points});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(1.05),
        2: FlexColumnWidth(1.05),
      },
      border: TableBorder.all(color: AppColors.divider),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.white),
          children: [
            _TableHeaderCell('Waktu'),
            _TableHeaderCell('Data'),
            _TableHeaderCell('Delta'),
          ],
        ),
        ...List.generate(points.length, (index) {
          final point = points[index];
          final previous = index == 0 ? null : points[index - 1].nilai;
          final delta = point.nilai == null || previous == null
              ? null
              : point.nilai! - previous;
          return TableRow(
            children: [
              _TableBodyCell(
                DateFormat('yyyy-MM-dd HH:mm:ss').format(point.waktu),
                alignStart: true,
              ),
              _TableBodyCell(formatAnalysisValue(point.nilai, digits: 3)),
              _TableBodyCell(formatAnalysisValue(delta, digits: 3)),
            ],
          );
        }),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadowLg,
      ),
      child: const Column(
        children: [
          Icon(Icons.show_chart_rounded, size: 56, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'Tidak ada data untuk periode ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
