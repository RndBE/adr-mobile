import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/beranda_repository.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final _repo = BerandaRepository();

  RtsTempData? _rtsData;
  List<PrismaLatest> _prismaList = [];
  bool _loading = true;
  String _username = '';
  String _nama = '';
  Timer? _refreshTimer;

  static const _menus = [
    _MenuData('Monitoring', Icons.grid_view_rounded, '/monitoring', AppColors.primary),
    _MenuData('Hasil Ukur', Icons.table_chart_rounded, '/hasil-pengukuran', AppColors.primaryLight),
    _MenuData('Analisa', Icons.show_chart_rounded, '/analisa', AppColors.info),
    _MenuData('Peta', Icons.map_rounded, '/peta', AppColors.success),
    _MenuData('Kontrol ADR', Icons.settings_remote_rounded, '/kontrol-adr', AppColors.accent),
    _MenuData('Visualisasi 3D', Icons.view_in_ar_rounded, '/visualisasi-3d', Color(0xFF7B1FA2)),
    _MenuData('Power RTS', Icons.bolt_rounded, '/power-rts', AppColors.warning),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchData(),
    );
  }

  Future<void> _loadUser() async {
    final username = await SecureStorage.getUsername();
    final nama = await SecureStorage.getNama();
    if (mounted) {
      setState(() {
        _username = username ?? '';
        _nama = nama ?? '';
      });
    }
  }

  Future<void> _fetchData() async {
    final results = await Future.wait([
      _repo.getRtsTempData(),
      _repo.getPrismaLatest(),
    ]);
    if (!mounted) return;
    setState(() {
      _rtsData = results[0] as RtsTempData?;
      _prismaList = results[1] as List<PrismaLatest>;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Anda akan keluar dari sesi ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await SecureStorage.clearSession();
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _rtsData?.isOnline ?? false;
    final isRunning = _rtsData?.isRunning ?? false;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchData,
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: _logout,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.radar_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ADR Monitor',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                    _nama.isNotEmpty ? _nama : _username,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // RTS status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? AppColors.success.withValues(alpha: 0.2)
                                      : AppColors.danger.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isOnline
                                        ? AppColors.success.withValues(alpha: 0.5)
                                        : AppColors.danger.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _PulseDot(color: isOnline
                                        ? AppColors.success
                                        : AppColors.danger),
                                    const SizedBox(width: 5),
                                    Text(
                                      isRunning
                                          ? 'Running'
                                          : isOnline
                                              ? 'Online'
                                              : 'Offline',
                                      style: TextStyle(
                                        color: isOnline
                                            ? AppColors.success
                                            : AppColors.danger,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── RTS Metric Cards ───────────────────────────
                    _loading
                        ? _MetricShimmer()
                        : GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.0,
                            children: [
                              _MetricCard(
                                label: 'Power RTS',
                                value: _rtsData != null
                                    ? '${_rtsData!.powerRts.toStringAsFixed(1)} V'
                                    : '-- V',
                                icon: Icons.bolt_rounded,
                                color: AppColors.accent,
                              ),
                              _MetricCard(
                                label: 'Humidity',
                                value: _rtsData != null
                                    ? '${_rtsData!.humidity.toStringAsFixed(1)}%'
                                    : '--%',
                                icon: Icons.water_drop_rounded,
                                color: AppColors.info,
                              ),
                              _MetricCard(
                                label: 'Battery',
                                value: _rtsData != null
                                    ? '${_rtsData!.battery.toStringAsFixed(1)} V'
                                    : '-- V',
                                icon: Icons.battery_charging_full_rounded,
                                color: AppColors.success,
                              ),
                              _MetricCard(
                                label: 'Temperatur',
                                value: _rtsData != null
                                    ? '${_rtsData!.temperature.toStringAsFixed(1)}°C'
                                    : '--°C',
                                icon: Icons.thermostat_rounded,
                                color: AppColors.danger,
                              ),
                            ],
                          ),

                    const SizedBox(height: 20),

                    // ── Menu Grid ─────────────────────────────────
                    const Text('Menu',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                      children: _menus
                          .map((m) => _MenuCard(
                                data: m,
                                onTap: () => context.push(m.route),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Prism Terbaru ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Data Prism Terbaru',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        TextButton(
                          onPressed: () => context.push('/hasil-pengukuran'),
                          child: const Text('Lihat Semua',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _loading
                        ? _PrismaShimmer()
                        : _prismaList.isEmpty
                            ? _EmptyState(
                                icon: Icons.scatter_plot_outlined,
                                label: 'Belum ada data prism',
                              )
                            : Column(
                                children: _prismaList
                                    .take(5)
                                    .map((p) => _PrismaTile(prisma: p))
                                    .toList(),
                              ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuData {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  const _MenuData(this.label, this.icon, this.route, this.color);
}

class _MenuCard extends StatelessWidget {
  final _MenuData data;
  final VoidCallback onTap;
  const _MenuCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: data.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
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

class _PrismaTile extends StatelessWidget {
  final PrismaLatest prisma;
  const _PrismaTile({required this.prisma});

  Color get _statusColor {
    switch (prisma.status) {
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.my_location_rounded,
                color: _statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prisma.nama,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _CoordChip('N', prisma.n),
                    const SizedBox(width: 6),
                    _CoordChip('E', prisma.e),
                    const SizedBox(width: 6),
                    _CoordChip('Z', prisma.z),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              prisma.status.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordChip extends StatelessWidget {
  final String label;
  final double value;
  const _CoordChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(3)}',
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.primary),
      ),
    );
  }
}

class _MetricShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _PrismaShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
