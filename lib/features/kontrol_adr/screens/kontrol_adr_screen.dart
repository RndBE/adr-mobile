import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../data/kontrol_repository.dart';

class KontrolAdrScreen extends StatefulWidget {
  const KontrolAdrScreen({super.key});

  @override
  State<KontrolAdrScreen> createState() => _KontrolAdrScreenState();
}

class _KontrolAdrScreenState extends State<KontrolAdrScreen>
    with TickerProviderStateMixin {
  final _repo = KontrolRepository();
  final _codeCtrl = TextEditingController();

  // State
  bool _isRunning = false;
  bool _isOnline = false;
  bool _loadingAction = false;
  String? _errorMsg;

  Map<String, dynamic>? _liveStatus;
  List<Map<String, dynamic>> _prismaList = [];

  // Proses log steps
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
    setState(() {
      _liveStatus = status;
      _prismaList = prismas;
      _isOnline = status?['sensor14'] == 1;
      final nowRunning = status?['sensor16'] == 1;
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
    setState(() {
      _logSteps.clear();
      for (int i = 0; i < _steps.length; i++) {
        _logSteps.add(_LogStep(label: _steps[i], status: _StepStatus.pending));
      }
    });
    _advanceSteps();
  }

  void _advanceSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || !_isRunning) break;
      setState(() {
        if (i > 0) _logSteps[i - 1] = _logSteps[i - 1].copyWith(_StepStatus.done);
        _logSteps[i] = _logSteps[i].copyWith(_StepStatus.running);
      });
    }
  }

  void _stopProgressAnimation() {
    _radarCtrl.stop();
    setState(() {
      for (int i = 0; i < _logSteps.length; i++) {
        _logSteps[i] = _logSteps[i].copyWith(_StepStatus.done);
      }
    });
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
      setState(() => _errorMsg = 'Gagal memulai pengukuran. Periksa kode akses.');
    } else {
      _fetchStatus();
    }
  }

  Future<void> _stopMeasurement() async {
    setState(() => _loadingAction = true);
    await _repo.stopMeasurement();
    if (!mounted) return;
    setState(() => _loadingAction = false);
    _fetchStatus();
  }

  Future<void> _setPower(bool on) async {
    setState(() => _loadingAction = true);
    await _repo.setPower(on);
    if (!mounted) return;
    setState(() => _loadingAction = false);
    _fetchStatus();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontrol ADR'),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Bar ─────────────────────────────────────────
            _StatusBar(isOnline: _isOnline, isRunning: _isRunning, liveStatus: _liveStatus),
            const SizedBox(height: 16),

            // ── Power Controls ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Power ON',
                    icon: Icons.power_settings_new_rounded,
                    color: AppColors.success,
                    loading: _loadingAction,
                    onTap: () => _setPower(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Power OFF',
                    icon: Icons.power_off_rounded,
                    color: AppColors.danger,
                    loading: _loadingAction,
                    onTap: () => _setPower(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Access Code & Start/Stop ───────────────────────────
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
                  const Text('Mulai Pengukuran',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),

                  if (_errorMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMsg!,
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 12)),
                        ),
                      ]),
                    ),

                  TextField(
                    controller: _codeCtrl,
                    obscureText: true,
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
                          onPressed: (_loadingAction || _isRunning)
                              ? null
                              : _startMeasurement,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Mulai'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_loadingAction || !_isRunning)
                              ? null
                              : _stopMeasurement,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('Stop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── RTS Animation ──────────────────────────────────────
            if (_isRunning) ...[
              _RtsAnimationWidget(controller: _radarCtrl),
              const SizedBox(height: 16),
            ],

            // ── Proses Log ─────────────────────────────────────────
            if (_logSteps.isNotEmpty) ...[
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
                    const Text('Proses Log',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    ..._logSteps.map((s) => _StepTile(step: s)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Prisma Cards Grid ──────────────────────────────────
            const Text('Data Prism Real-time',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            _prismaList.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: cardShadow,
                    ),
                    child: const Center(
                      child: Text('Belum ada data prism',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _prismaList.length,
                    itemBuilder: (_, i) =>
                        _PrismaLiveCard(data: _prismaList[i]),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final bool isOnline;
  final bool isRunning;
  final Map<String, dynamic>? liveStatus;

  const _StatusBar({
    required this.isOnline,
    required this.isRunning,
    required this.liveStatus,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRunning
        ? AppColors.running
        : isOnline
            ? AppColors.success
            : AppColors.danger;
    final label = isRunning ? 'Sedang Mengukur' : isOnline ? 'RTS Online' : 'RTS Offline';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color)),
          const Spacer(),
          if (liveStatus != null) ...[
            _QuickStat('SD', liveStatus!['sensor17'] == 1 ? 'OK' : 'Error'),
          ],
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  const _QuickStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: loading ? AppColors.bgLight : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: loading ? AppColors.textHint : color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: loading ? AppColors.textHint : color)),
          ],
        ),
      ),
    );
  }
}

class _RtsAnimationWidget extends StatelessWidget {
  final AnimationController controller;
  const _RtsAnimationWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          const Text('RTS Aktif',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: controller,
            builder: (_, _) => CustomPaint(
              size: const Size(120, 120),
              painter: _RadarPainter(angle: controller.value * 360),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Sedang melakukan pengukuran...',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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

    // Concentric circles
    final circlePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, circlePaint);
    }

    // Sweep gradient
    final rad = angle * math.pi / 180;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.0),
          AppColors.primary.withValues(alpha: 0.4),
        ],
        startAngle: 0,
        endAngle: math.pi / 2,
        transform: GradientRotation(rad - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, sweepPaint);

    // Moving dot
    final dotPaint = Paint()..color = AppColors.primary;
    final dotPos = Offset(
      center.dx + radius * 0.85 * math.cos(rad),
      center.dy + radius * 0.85 * math.sin(rad),
    );
    canvas.drawCircle(dotPos, 4, dotPaint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => angle != old.angle;
}

enum _StepStatus { pending, running, done }

class _LogStep {
  final String label;
  final _StepStatus status;
  const _LogStep({required this.label, required this.status});
  _LogStep copyWith(_StepStatus s) => _LogStep(label: label, status: s);
}

class _StepTile extends StatelessWidget {
  final _LogStep step;
  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (step.status) {
      case _StepStatus.done:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
      case _StepStatus.running:
        color = AppColors.running;
        icon = Icons.radio_button_checked_rounded;
      case _StepStatus.pending:
        color = AppColors.textHint;
        icon = Icons.radio_button_unchecked_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            step.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: step.status == _StepStatus.running
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: step.status == _StepStatus.pending
                  ? AppColors.textHint
                  : AppColors.textPrimary,
            ),
          ),
          if (step.status == _StepStatus.running) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.running,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrismaLiveCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PrismaLiveCard({required this.data});

  Color get _statusColor {
    switch (data['status']) {
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
    final n1 = (t['N1'] as num?)?.toDouble() ?? 0;
    final e1 = (t['E1'] as num?)?.toDouble() ?? 0;
    final z1 = (t['Z1'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadow,
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location_rounded,
                  color: _statusColor, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  data['nama_prisma'] ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          _MiniCoord('N', n1),
          _MiniCoord('E', e1),
          _MiniCoord('Z', z1),
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
        Text('$label:',
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(width: 4),
        Text(
          value.toStringAsFixed(3),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
