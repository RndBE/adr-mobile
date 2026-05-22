import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/dashboard_widgets.dart';
import '../../../shared/widgets/skeleton.dart';
import '../data/kontrol_repository.dart';
import '../models/kontrol_rts_status.dart';

class KontrolAdrScreen extends StatefulWidget {
  const KontrolAdrScreen({super.key});

  @override
  State<KontrolAdrScreen> createState() => _KontrolAdrScreenState();
}

class _KontrolAdrScreenState extends State<KontrolAdrScreen>
    with TickerProviderStateMixin {
  final _repo = KontrolRepository();
  final _codeCtrl = TextEditingController();

  bool _isRunning = false;
  bool _isPowered = false;
  bool _loadingAction = false;
  bool _loadingStatus = true;
  String? _errorMsg;

  Map<String, dynamic>? _liveStatus;
  List<Map<String, dynamic>> _prismaList = [];
  final List<_LogStep> _logSteps = [];

  static const _steps = [
    'Directing to Target',
    'Search Target',
    'Measuring',
    'Recording',
  ];

  Timer? _pollTimer;
  late AnimationController _radarCtrl;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fetchStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isRunning) _fetchStatus();
    });
  }

  Future<void> _fetchStatus() async {
    final results = await Future.wait([
      _repo.getLiveStatus(),
      _repo.getPrismaLive(),
    ]);
    if (!mounted) return;

    final status = results[0] as Map<String, dynamic>?;
    final prismas = results[1] as List<Map<String, dynamic>>;
    final powered = _intValue(status?['sensor14']) == 1;
    final nowRunning = _intValue(status?['sensor16']) == 1;

    setState(() {
      _liveStatus = status;
      _prismaList = prismas;
      _isPowered = powered;
      _loadingStatus = false;
      if (nowRunning && !_isRunning) {
        _startProgressAnimation();
      } else if (!nowRunning && _isRunning) {
        _stopProgressAnimation();
      }
      _isRunning = nowRunning;
    });
  }

  void _startProgressAnimation() {
    _radarCtrl.repeat();
    _logSteps
      ..clear()
      ..addAll(
        _steps.map(
          (label) => _LogStep(label: label, status: _StepStatus.pending),
        ),
      );
    _advanceSteps();
  }

  void _advanceSteps() async {
    for (var i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || !_isRunning || i >= _logSteps.length) break;
      setState(() {
        if (i > 0) {
          _logSteps[i - 1] = _logSteps[i - 1].copyWith(_StepStatus.done);
        }
        _logSteps[i] = _logSteps[i].copyWith(_StepStatus.running);
      });
    }
  }

  void _stopProgressAnimation() {
    _radarCtrl.stop();
    for (var i = 0; i < _logSteps.length; i++) {
      _logSteps[i] = _logSteps[i].copyWith(_StepStatus.done);
    }
  }

  Future<void> _startMeasurement() async {
    if (_codeCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Masukkan kode akses terlebih dahulu');
      return;
    }

    setState(() {
      _loadingAction = true;
      _errorMsg = null;
    });
    final ok = await _repo.startMeasurement(_codeCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loadingAction = false);
    if (!ok) {
      setState(() {
        _errorMsg = 'Gagal memulai pengukuran. Periksa kode akses.';
      });
      return;
    }
    _fetchStatus();
  }

  Future<void> _stopMeasurement() async {
    setState(() => _loadingAction = true);
    await _repo.stopMeasurement();
    if (!mounted) return;
    setState(() => _loadingAction = false);
    _fetchStatus();
  }

  Future<void> _setPower(bool on) async {
    setState(() {
      _loadingAction = true;
      _errorMsg = null;
    });
    await _repo.setPower(on);
    if (!mounted) return;
    setState(() => _loadingAction = false);
    _fetchStatus();
  }

  String get _updatedAt {
    final status = _liveStatus;
    if (status == null) return '-';
    for (final key in const [
      'waktu',
      'created_at',
      'updated_at',
      'timestamp',
      'time',
    ]) {
      final value = status[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '-';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _radarCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = KontrolRtsStatus.fromSensors(
      isPowered: _isPowered,
      isRunning: _isRunning,
    );

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Kontrol ADR'),
        leading: const BackButton(color: Colors.white),
      ),
      body: _loadingStatus
          ? const SkeletonKontrolAdrPage()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ControlStatusCard(
                      status: status,
                      isLoading: _loadingStatus,
                      sdOk: _intValue(_liveStatus?['sensor17']) == 1,
                      updatedAt: _updatedAt,
                      prismCount: _prismaList.length,
                    ),
                    const SizedBox(height: 14),
                    _PowerControlCard(
                      isPowered: _isPowered,
                      isLoading: _loadingAction,
                      onPowerOn: () => _setPower(true),
                      onPowerOff: () => _setPower(false),
                    ),
                    const SizedBox(height: 14),
                    _MeasurementControlCard(
                      codeController: _codeCtrl,
                      errorMessage: _errorMsg,
                      isRunning: _isRunning,
                      isLoading: _loadingAction,
                      onStart: _startMeasurement,
                      onStop: _stopMeasurement,
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: (_isRunning || _logSteps.isNotEmpty)
                          ? _MeasurementProgressCard(
                              key: const ValueKey('progress'),
                              controller: _radarCtrl,
                              steps: _logSteps,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('empty-progress'),
                            ),
                    ),
                    if (_isRunning || _logSteps.isNotEmpty)
                      const SizedBox(height: 14),
                    _SectionHeader(
                      title: 'Data Prism Real-time',
                      subtitle: '${_prismaList.length} prism terpantau',
                    ),
                    const SizedBox(height: 10),
                    _prismaList.isEmpty
                        ? const EmptyPanel(
                            title: 'Belum ada data prism',
                            message: 'Tarik ke bawah untuk memuat ulang data.',
                            icon: Icons.my_location_rounded,
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.42,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: _prismaList.length,
                            itemBuilder: (_, i) =>
                                _PrismaLiveCard(data: _prismaList[i]),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ControlStatusCard extends StatelessWidget {
  final KontrolRtsStatus status;
  final bool isLoading;
  final bool sdOk;
  final String updatedAt;
  final int prismCount;

  const _ControlStatusCard({
    required this.status,
    required this.isLoading,
    required this.sdOk,
    required this.updatedAt,
    required this.prismCount,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(status.icon, color: status.color, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Perangkat',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? 'Memuat status...' : status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status.actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: status.pillLabel,
                color: status.color,
                subtle: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatusMiniTile(
                  label: 'SD Card',
                  value: sdOk ? 'OK' : 'Error',
                  icon: Icons.sd_card_rounded,
                  color: sdOk ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusMiniTile(
                  label: 'Prism',
                  value: prismCount.toString(),
                  icon: Icons.my_location_rounded,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    updatedAt == '-'
                        ? 'Waktu update belum tersedia'
                        : updatedAt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

class _StatusMiniTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusMiniTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
        ],
      ),
    );
  }
}

class _PowerControlCard extends StatelessWidget {
  final bool isPowered;
  final bool isLoading;
  final VoidCallback onPowerOn;
  final VoidCallback onPowerOff;

  const _PowerControlCard({
    required this.isPowered,
    required this.isLoading,
    required this.onPowerOn,
    required this.onPowerOff,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Power RTS',
            subtitle: 'Kontrol daya perangkat',
            dense: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SegmentAction(
                  label: 'ON',
                  icon: Icons.power_settings_new_rounded,
                  color: AppColors.success,
                  selected: isPowered,
                  disabled: isLoading,
                  onTap: onPowerOn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SegmentAction(
                  label: 'OFF',
                  icon: Icons.power_off_rounded,
                  color: AppColors.danger,
                  selected: !isPowered,
                  disabled: isLoading,
                  onTap: onPowerOff,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _SegmentAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = disabled ? AppColors.textHint : color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? effectiveColor.withValues(alpha: 0.14)
                : AppColors.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? effectiveColor.withValues(alpha: 0.42)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: effectiveColor, size: 19),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasurementControlCard extends StatelessWidget {
  final TextEditingController codeController;
  final String? errorMessage;
  final bool isRunning;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _MeasurementControlCard({
    required this.codeController,
    required this.errorMessage,
    required this.isRunning,
    required this.isLoading,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Pengukuran',
            subtitle: 'Mulai atau hentikan proses dari mobile',
            dense: true,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: codeController,
            obscureText: true,
            enabled: !isRunning && !isLoading,
            decoration: const InputDecoration(
              labelText: 'Kode Akses',
              prefixIcon: Icon(Icons.key_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isLoading || isRunning) ? null : onStart,
                  icon: isLoading && !isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('Mulai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 46),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isLoading || !isRunning) ? null : onStop,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size(0, 46),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeasurementProgressCard extends StatelessWidget {
  final AnimationController controller;
  final List<_LogStep> steps;

  const _MeasurementProgressCard({
    super.key,
    required this.controller,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: controller,
                  builder: (_, _) => CustomPaint(
                    size: const Size(92, 92),
                    painter: _RadarPainter(angle: controller.value * 360),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'RTS Aktif',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'Progress Ukur',
                  subtitle: 'Urutan proses perangkat',
                  dense: true,
                ),
                const SizedBox(height: 10),
                ...steps.map((step) => _TimelineStep(step: step)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;

  _RadarPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final circlePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, circlePaint);
    }

    final rad = angle * math.pi / 180;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.0),
          AppColors.primary.withValues(alpha: 0.42),
        ],
        startAngle: 0,
        endAngle: math.pi / 2,
        transform: GradientRotation(rad - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, sweepPaint);

    final dotPaint = Paint()..color = AppColors.primary;
    final dotPos = Offset(
      center.dx + radius * 0.85 * math.cos(rad),
      center.dy + radius * 0.85 * math.sin(rad),
    );
    canvas.drawCircle(dotPos, 4, dotPaint);
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) => angle != oldDelegate.angle;
}

enum _StepStatus { pending, running, done }

class _LogStep {
  final String label;
  final _StepStatus status;

  const _LogStep({required this.label, required this.status});

  _LogStep copyWith(_StepStatus status) {
    return _LogStep(label: label, status: status);
  }
}

class _TimelineStep extends StatelessWidget {
  final _LogStep step;

  const _TimelineStep({required this.step});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (step.status) {
      _StepStatus.done => (AppColors.success, Icons.check_rounded),
      _StepStatus.running => (AppColors.running, Icons.sync_rounded),
      _StepStatus.pending => (AppColors.textHint, Icons.more_horiz_rounded),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              step.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: step.status == _StepStatus.pending
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: step.status == _StepStatus.running
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrismaLiveCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PrismaLiveCard({required this.data});

  Color get _statusColor {
    switch (data['status']?.toString().toLowerCase()) {
      case 'success':
        return AppColors.success;
      case 'failed':
        return AppColors.danger;
      case 'running':
        return AppColors.running;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = data['temp_tembak'] as Map<String, dynamic>? ?? {};
    final n1 = _doubleValue(t['N1']);
    final e1 = _doubleValue(t['E1']);
    final z1 = _doubleValue(t['Z1']);
    final name = data['nama_prisma']?.toString().trim();
    final status = data['status']?.toString().toUpperCase() ?? 'UNKNOWN';

    return AppSurfaceCard(
      padding: const EdgeInsets.all(12),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: _statusColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name == null || name.isEmpty ? '-' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MiniCoord('N', n1),
          _MiniCoord('E', e1),
          _MiniCoord('Z', z1),
          const Spacer(),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCoord extends StatelessWidget {
  final String label;
  final double value;

  const _MiniCoord(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.toStringAsFixed(3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool dense;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: dense ? 14 : 16,
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
    );
  }
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleValue(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
