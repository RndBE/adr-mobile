import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/dashboard_widgets.dart';
import '../../../shared/widgets/skeleton.dart';
import '../models/adr_classic_layout.dart';
import '../models/adr_dashboard_metric.dart';
import '../models/adr_content_selection.dart';
import '../models/adr_selector_chip_style.dart';
import '../../beranda/data/beranda_repository.dart';

class AdrScreen extends StatefulWidget {
  const AdrScreen({super.key});

  @override
  State<AdrScreen> createState() => _AdrScreenState();
}

class _AdrScreenState extends State<AdrScreen> {
  final _repo = BerandaRepository();
  final _searchController = TextEditingController();

  RtsTempData? _rtsData;
  PrismaLatest? _latestPrisma;
  LoggerInfo? _loggerInfo;
  List<PrismaLatest> _prismaList = [];
  List<String> _allPrismaNames = [];
  AdrContentSelection _selection = const AdrContentSelection.prisma();
  bool _loading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _refreshTimer;

  bool get _showLegacyAdrContent => false;

  List<String> get _visiblePrismaNames {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _allPrismaNames;
    return _allPrismaNames
        .where((name) => name.toLowerCase().contains(query))
        .toList();
  }

  String? get _activePrismaName {
    if (_allPrismaNames.isEmpty) return null;
    final index = _selection.activePrismaIndex
        .clamp(0, _allPrismaNames.length - 1)
        .toInt();
    return _allPrismaNames[index];
  }

  String get _loggerChipLabel {
    final idLogger = _loggerInfo?.idLogger;
    if (idLogger != null && idLogger.trim().isNotEmpty && idLogger != '-') {
      return 'Logger $idLogger';
    }
    final sensor = _loggerInfo?.sensor;
    if (sensor != null && sensor.trim().isNotEmpty && sensor != '-') {
      return sensor;
    }
    return 'Logger';
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchData(),
    );
  }

  Future<void> _fetchData() async {
    final results = await Future.wait([
      _repo.getRtsTempData(),
      _repo.getPrismaLatest(),
      _repo.getAllPrismaNames(),
      _repo.getLoggerInfo(),
    ]);
    if (!mounted) return;
    setState(() {
      _rtsData = results[0] as RtsTempData?;
      _prismaList = results[1] as List<PrismaLatest>;
      _allPrismaNames = results[2] as List<String>;
      _loggerInfo = results[3] as LoggerInfo?;

      if (_allPrismaNames.isEmpty) {
        _allPrismaNames = _prismaList.map((e) => e.nama).toSet().toList();
      }
      if (_allPrismaNames.isEmpty) {
        _allPrismaNames = ['BS RTS', 'CMU 01', 'CMU 02'];
      }

      if (_allPrismaNames.isNotEmpty) {
        if (_selection.activePrismaIndex >= _allPrismaNames.length) {
          _selection = const AdrContentSelection.prisma();
        }
        final activeName = _allPrismaNames[_selection.activePrismaIndex];
        try {
          _latestPrisma = _prismaList.firstWhere((p) => p.nama == activeName);
        } catch (_) {
          _latestPrisma = null;
        }
      } else {
        _latestPrisma = null;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerTime = _parseDateTime(_latestPrisma?.waktu ?? _rtsData?.waktu);
    final dateText = headerTime == null
        ? '-'
        : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(headerTime);
    final timeText = headerTime == null
        ? '-'
        : DateFormat('HH:mm:ss').format(headerTime);
    final visiblePrismaNames = _visiblePrismaNames;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B3377), // Deep blue from mockup
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                cursorColor: Colors.white,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'Cari prisma...',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _searchQuery = value),
                onSubmitted: (_) => _selectFirstSearchResult(),
              )
            : const Text(
                'ADR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
        actions: [
          _AppBarActionIcon(
            icon: Icons.info_outline_rounded,
            onTap: () => _showLoggerInfo(context),
          ),
          const SizedBox(width: 8),
          _AppBarActionIcon(
            icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
            onTap: _toggleSearch,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const SkeletonAdrPage()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Blue background header with chips
                    Container(
                      color: const Color(0xFF2B3377),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _LoggerChip(
                                label: _loggerChipLabel,
                                isActive: _selection.isLoggerSelected,
                                onTap: _selectLogger,
                              ),
                            ),
                            if (visiblePrismaNames.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Prisma tidak ditemukan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              ...List.generate(visiblePrismaNames.length, (
                                index,
                              ) {
                                final name = visiblePrismaNames[index];
                                final isActive =
                                    !_selection.isLoggerSelected &&
                                    name == _activePrismaName;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () => _selectPrismaByName(name),
                                    child: _FilterChip(
                                      label: name,
                                      isActive: isActive,
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                    // Date Time Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      child: Column(
                        children: [
                          _AdrClassicContent(
                            latestPrisma: _latestPrisma,
                            rtsData: _rtsData,
                            prismaTime: _latestPrisma != null
                                ? _formatDate(_latestPrisma!.waktu)
                                : _formatDate(_rtsData?.waktu),
                            onOpenPrismaAnalysis: _openPrismaAnalysis,
                            onOpenLoggerAnalysis: _openLoggerAnalysis,
                          ),
                          if (_showLegacyAdrContent &&
                              _selection.isLoggerSelected) ...[
                            // Sensor Logger Card
                            _SectionCard(
                              title: 'Sensor Logger',
                              children: [
                                _SensorTile(
                                  icon: Icons.water_drop_outlined,
                                  label: 'Humidity Logger',
                                  value: _rtsData != null
                                      ? '${_rtsData!.humidity.toStringAsFixed(2)} %'
                                      : '0.00 %',
                                  onTap: () => context.push('/analisa'),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF0F0F0),
                                ),
                                _SensorTile(
                                  icon: Icons.battery_full_rounded,
                                  label: 'Battery Logger',
                                  value: _rtsData != null
                                      ? '${_rtsData!.battery.toStringAsFixed(2)} Volt'
                                      : '0.00 Volt',
                                  onTap: () => context.push('/analisa'),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF0F0F0),
                                ),
                                _SensorTile(
                                  icon: Icons.device_thermostat_rounded,
                                  label: 'Temperature Logger',
                                  value: _rtsData != null
                                      ? '${_rtsData!.temperature.toStringAsFixed(2)} °C'
                                      : '0.00 °C',
                                  onTap: () => context.push('/analisa'),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF0F0F0),
                                ),
                                _SensorTile(
                                  icon: Icons.bolt_rounded,
                                  label: 'Power RTS',
                                  value: _rtsData != null
                                      ? '${_rtsData!.powerRts.toStringAsFixed(2)} Volt'
                                      : '0.00 Volt',
                                  onTap: () => context.push('/analisa'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final dt = _parseDateTime(raw);
    if (dt != null) {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    }
    return raw.replaceAll('T', ' ').split('.').first;
  }

  String _formatInfoDate(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim() == '-') return '-';
    final dt = _parseDateTime(raw);
    if (dt != null) return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    return raw.replaceAll('T', ' ').split('.').first;
  }

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    final timestamp = int.tryParse(trimmed);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    return DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
  }

  void _selectPrismaByName(String name) {
    setState(() {
      final index = _allPrismaNames.indexOf(name);
      if (index >= 0) _selection = _selection.selectPrisma(index);
      try {
        _latestPrisma = _prismaList.firstWhere((p) => p.nama == name);
      } catch (_) {
        _latestPrisma = null;
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _selectFirstSearchResult() {
    if (_visiblePrismaNames.isEmpty) return;
    _selectPrismaByName(_visiblePrismaNames.first);
  }

  void _selectLogger() {
    setState(() => _selection = _selection.selectLogger());
  }

  void _openPrismaAnalysis(String metric) {
    final activeName = _latestPrisma?.nama.isNotEmpty == true
        ? _latestPrisma!.nama
        : (_allPrismaNames.isNotEmpty
              ? _allPrismaNames[_selection.activePrismaIndex]
              : '');
    context.push(
      '/analisa',
      extra: {
        'mode': 'prisma',
        'param': metric,
        'prismaName': activeName,
        'date': _latestPrisma?.waktu,
      },
    );
  }

  void _openLoggerAnalysis(String param) {
    context.push('/analisa', extra: {'param': param, 'date': _rtsData?.waktu});
  }

  void _showLoggerInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.78,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Informasi Logger',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'ID Logger',
                    value: _loggerInfo?.idLogger ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Seri', value: _loggerInfo?.seri ?? '-'),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Sensor', value: _loggerInfo?.sensor ?? '-'),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Status SD',
                    value: _loggerInfo?.statusSd ?? '-',
                    valueColor: _loggerInfo?.statusSd.toLowerCase() == 'ok'
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Awal Kontrak',
                    value: _formatInfoDate(_loggerInfo?.awalKontrak),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Akhir Garansi',
                    value: _formatInfoDate(_loggerInfo?.akhirGaransi),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Logger Aktif',
                    value: _loggerInfo?.loggerAktif ?? '-',
                    valueColor:
                        _loggerInfo?.loggerAktif.toLowerCase() == 'aktif'
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'No Seluler',
                    value: _loggerInfo?.noSeluler ?? '-',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdrClassicContent extends StatelessWidget {
  final PrismaLatest? latestPrisma;
  final RtsTempData? rtsData;
  final String prismaTime;
  final ValueChanged<String> onOpenPrismaAnalysis;
  final ValueChanged<String> onOpenLoggerAnalysis;

  const _AdrClassicContent({
    required this.latestPrisma,
    required this.rtsData,
    required this.prismaTime,
    required this.onOpenPrismaAnalysis,
    required this.onOpenLoggerAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final prismaRows = buildAdrPrismaRows(
      northing: latestPrisma?.n,
      easting: latestPrisma?.e,
      elevation: latestPrisma?.z,
    );
    final loggerRows = buildAdrLoggerRows(
      humidity: rtsData?.humidity,
      battery: rtsData?.battery,
      temperature: rtsData?.temperature,
      powerRts: rtsData?.powerRts,
    );

    return Column(
      children: [
        _AdrClassicSectionCard(
          title: 'Data Terakhir Prisma :',
          trailingText: prismaTime,
          children: [
            _AdrClassicMetricTile(
              iconLetter: 'Y',
              label: prismaRows[0].label,
              value: prismaRows[0].value,
              onTap: () => onOpenPrismaAnalysis(prismaRows[0].analysisParam),
            ),
            _AdrClassicMetricTile(
              iconLetter: 'X',
              label: prismaRows[1].label,
              value: prismaRows[1].value,
              onTap: () => onOpenPrismaAnalysis(prismaRows[1].analysisParam),
            ),
            _AdrClassicMetricTile(
              iconLetter: 'Z',
              label: prismaRows[2].label,
              value: prismaRows[2].value,
              onTap: () => onOpenPrismaAnalysis(prismaRows[2].analysisParam),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AdrClassicSectionCard(
          title: 'Sensor Logger',
          children: [
            _AdrClassicMetricTile(
              icon: Icons.water_drop_outlined,
              label: loggerRows[0].label,
              value: loggerRows[0].value,
              onTap: () => onOpenLoggerAnalysis(loggerRows[0].analysisParam),
            ),
            _AdrClassicMetricTile(
              icon: Icons.battery_full_rounded,
              label: loggerRows[1].label,
              value: loggerRows[1].value,
              onTap: () => onOpenLoggerAnalysis(loggerRows[1].analysisParam),
            ),
            _AdrClassicMetricTile(
              icon: Icons.device_thermostat_rounded,
              label: loggerRows[2].label,
              value: loggerRows[2].value,
              onTap: () => onOpenLoggerAnalysis(loggerRows[2].analysisParam),
            ),
            _AdrClassicMetricTile(
              icon: Icons.bolt_rounded,
              label: loggerRows[3].label,
              value: loggerRows[3].value,
              onTap: () => onOpenLoggerAnalysis(loggerRows[3].analysisParam),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdrClassicSectionCard extends StatelessWidget {
  final String title;
  final String? trailingText;
  final List<Widget> children;

  const _AdrClassicSectionCard({
    required this.title,
    this.trailingText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailingText != null) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      trailingText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E2E2)),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(
                height: 1,
                indent: 74,
                endIndent: 16,
                color: Color(0xFFF0F0F0),
              ),
          ],
        ],
      ),
    );
  }
}

class _AdrClassicMetricTile extends StatelessWidget {
  final IconData? icon;
  final String? iconLetter;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _AdrClassicMetricTile({
    this.icon,
    this.iconLetter,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFE1F0FB),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: iconLetter != null
                  ? Container(
                      width: 25,
                      height: 25,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF2B3377),
                          width: 1.6,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        iconLetter!,
                        style: const TextStyle(
                          color: Color(0xFF2B3377),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : Icon(icon, color: const Color(0xFF2B3377), size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              size: 25,
              color: Color(0xFF202124),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LoggerDashboardPanel extends StatelessWidget {
  final String title;
  final LoggerInfo? loggerInfo;
  final RtsTempData? rtsData;
  final String lastUpdate;
  final ValueChanged<String> onOpenAnalysis;

  const _LoggerDashboardPanel({
    required this.title,
    required this.loggerInfo,
    required this.rtsData,
    required this.lastUpdate,
    required this.onOpenAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final loggerStatus = AdrDashboardStatus.fromText(
      loggerInfo?.loggerAktif ??
          (rtsData?.isLoggerOnline == true ? 'aktif' : 'tidak aktif'),
    );
    final sdStatus = AdrDashboardStatus.fromText(loggerInfo?.statusSd);
    final statusColor = loggerStatus.isHealthy
        ? AppColors.success
        : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdrSummaryCard(
          icon: Icons.sensors_rounded,
          iconColor: AppColors.primary,
          title: 'Logger Health',
          subtitle: title,
          lastUpdate: lastUpdate,
          statusLabel: loggerStatus.label,
          statusColor: statusColor,
          footer: [
            _CompactFact(label: 'Sensor', value: loggerInfo?.sensor ?? '-'),
            _CompactFact(
              label: 'SD Card',
              value: loggerInfo?.statusSd ?? '-',
              valueColor: sdStatus.isHealthy
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _AdrSectionHeader(
          title: 'Sensor Logger',
          subtitle: 'Tap kartu untuk buka analisa parameter',
        ),
        const SizedBox(height: 10),
        GridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.12,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _AdrMetricActionCard(
              icon: Icons.water_drop_outlined,
              color: AppColors.info,
              label: 'Humidity',
              value: formatAdrMetric(rtsData?.humidity, unit: '%'),
              onTap: () => onOpenAnalysis('sensor20'),
            ),
            _AdrMetricActionCard(
              icon: Icons.battery_full_rounded,
              color: AppColors.success,
              label: 'Battery',
              value: formatAdrMetric(rtsData?.battery, unit: 'Volt'),
              onTap: () => onOpenAnalysis('sensor21'),
            ),
            _AdrMetricActionCard(
              icon: Icons.device_thermostat_rounded,
              color: AppColors.danger,
              label: 'Temperature',
              value: formatAdrMetric(rtsData?.temperature, unit: 'C'),
              onTap: () => onOpenAnalysis('sensor22'),
            ),
            _AdrMetricActionCard(
              icon: Icons.bolt_rounded,
              color: AppColors.accent,
              label: 'Power RTS',
              value: formatAdrMetric(rtsData?.powerRts, unit: 'Volt'),
              onTap: () => onOpenAnalysis('sensor23'),
            ),
          ],
        ),
      ],
    );
  }
}

// ignore: unused_element
class _PrismaDashboardPanel extends StatelessWidget {
  final String activeName;
  final PrismaLatest? latestPrisma;
  final String lastUpdate;
  final ValueChanged<String> onOpenAnalysis;

  const _PrismaDashboardPanel({
    required this.activeName,
    required this.latestPrisma,
    required this.lastUpdate,
    required this.onOpenAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final status = AdrDashboardStatus.fromText(latestPrisma?.status);
    final statusColor = status.isHealthy ? AppColors.success : AppColors.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdrSummaryCard(
          icon: Icons.track_changes_rounded,
          iconColor: AppColors.primary,
          title: 'Prisma Position',
          subtitle: activeName,
          lastUpdate: lastUpdate,
          statusLabel: latestPrisma == null ? 'Belum Ada Data' : status.label,
          statusColor: latestPrisma == null ? AppColors.warning : statusColor,
          footer: [
            _CompactFact(label: 'Mode', value: 'Koordinat'),
            _CompactFact(label: 'Source', value: 'Data terbaru'),
          ],
        ),
        const SizedBox(height: 14),
        const _AdrSectionHeader(
          title: 'Data Terakhir Prisma',
          subtitle: 'Pilih koordinat untuk melihat tren analisa',
        ),
        const SizedBox(height: 10),
        _AdrMetricActionCard(
          icon: Icons.north_rounded,
          color: AppColors.running,
          label: 'Northing Y',
          value: formatAdrMetric(latestPrisma?.n, fractionDigits: 3),
          onTap: () => onOpenAnalysis('n'),
          wide: true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _AdrMetricActionCard(
                icon: Icons.east_rounded,
                color: AppColors.info,
                label: 'Easting X',
                value: formatAdrMetric(latestPrisma?.e, fractionDigits: 3),
                onTap: () => onOpenAnalysis('e'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AdrMetricActionCard(
                icon: Icons.height_rounded,
                color: AppColors.accent,
                label: 'Elevation',
                value: formatAdrMetric(latestPrisma?.z, fractionDigits: 3),
                onTap: () => onOpenAnalysis('z'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdrSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String lastUpdate;
  final String statusLabel;
  final Color statusColor;
  final List<Widget> footer;

  const _AdrSummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.lastUpdate,
    required this.statusLabel,
    required this.statusColor,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withValues(alpha: 0.16)),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(label: statusLabel, color: statusColor, subtle: true),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lastUpdate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var index = 0; index < footer.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(child: footer[index]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactFact extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CompactFact({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdrSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AdrSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
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
    );
  }
}

class _AdrMetricActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool wide;

  const _AdrMetricActionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: onTap,
      radius: 14,
      padding: EdgeInsets.all(wide ? 14 : 12),
      child: SizedBox(
        height: wide ? 82 : 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: value == '-'
                    ? AppColors.textHint
                    : AppColors.textPrimary,
                fontSize: wide ? 19 : 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _AppBarActionIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _LoggerChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LoggerChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const chipStyle = AdrSelectorChipStyle.selector();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFCC00),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isActive ? Colors.blue : AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.check : Icons.sensors_rounded,
                color: isActive ? Colors.white : AppColors.primary,
                size: 13,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            if (chipStyle.showsRemoveAction) ...[
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5252),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _FilterChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    const chipStyle = AdrSelectorChipStyle.selector();

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC00), // Yellow
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if (chipStyle.showsRemoveAction) ...[
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailingText;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    // ignore: unused_element_parameter
    this.trailingText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.black87.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          ...children,
        ],
      ),
    );
  }
}

// ignore: unused_element
class _DataTile extends StatelessWidget {
  final String iconLetter;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DataTile({
    required this.iconLetter,
    required this.label,
    required this.value,
    // ignore: unused_element_parameter
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF2B3377),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  iconLetter,
                  style: const TextStyle(
                    color: Color(0xFF2B3377),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SensorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF2B3377), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.black54,
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
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
