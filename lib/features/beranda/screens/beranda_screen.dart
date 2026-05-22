import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/dashboard_widgets.dart';
import '../../../shared/widgets/fixed_pinned_header_delegate.dart';
import '../../../shared/widgets/skeleton.dart';
import '../data/beranda_repository.dart';
import '../models/beranda_dashboard_status.dart';
import '../models/beranda_header_layout.dart';
import '../models/beranda_metric_formatter.dart';
import '../widgets/rts_status_summary_card.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final _repo = BerandaRepository();

  RtsTempData? _rtsData;
  String _username = '';
  String _nama = '';
  String _level = '';
  bool _loadingDashboard = true;
  Timer? _refreshTimer;

  static const _menus = [
    _MenuData(
      'Hasil Ukur',
      Icons.query_stats_rounded,
      '/hasil-pengukuran',
      AppColors.primaryLight,
      'Riwayat pengukuran',
    ),
    _MenuData(
      'ADR',
      Icons.radar_rounded,
      '/adr',
      AppColors.info,
      'Data prism dan RTS',
    ),
    _MenuData(
      'Peta',
      Icons.location_on_rounded,
      '/peta',
      AppColors.success,
      'Lokasi prism',
    ),
    _MenuData(
      'Kontrol ADR',
      Icons.settings_remote_rounded,
      '/kontrol-adr',
      AppColors.accent,
      'Power dan ukur',
    ),
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
    final level = await SecureStorage.getLevel();
    if (!mounted) return;
    setState(() {
      _username = username ?? '';
      _nama = nama ?? '';
      _level = level ?? '';
    });
  }

  Future<void> _fetchData() async {
    final rtsData = await _repo.getRtsTempData();
    if (!mounted) return;
    setState(() {
      _rtsData = rtsData;
      _loadingDashboard = false;
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Keluar Aplikasi?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apakah Anda yakin ingin keluar dari sesi ini? Anda perlu login kembali untuk masuk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: AppColors.textHint.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.danger,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  String _formatLevel(String level) {
    final normalized = level.trim().toLowerCase();
    if (normalized.isEmpty) return 'User';
    if (normalized == 'superadmin') return 'Super Admin';
    return normalized
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get _displayName {
    if (_nama.trim().isNotEmpty) return _nama.trim();
    if (_username.trim().isNotEmpty) return _username.trim();
    return 'User';
  }

  String _metric(double value, {int fraction = 1}) {
    return value == 0 ? '-' : value.toStringAsFixed(fraction);
  }

  @override
  Widget build(BuildContext context) {
    final rts = _rtsData;
    final isOnline = rts?.isOnline ?? false;
    final isRunning = rts?.isRunning ?? false;
    final rtsStatus = BerandaDashboardStatus.fromState(
      isRtsPowered: isOnline,
      isRunning: isRunning,
    );
    final loggerStatus = BerandaDashboardStatus.loggerFromState(
      isLoggerOnline: rts?.isLoggerOnline ?? false,
    );
    final dateText = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());
    final headerHeight = berandaHeaderHeight(MediaQuery.paddingOf(context).top);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: FixedPinnedHeaderDelegate(
                height: headerHeight,
                child: _DashboardHeader(
                  name: _displayName,
                  role: _formatLevel(_level),
                  dateText: dateText,
                  status: loggerStatus,
                  onLogout: _logout,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loadingDashboard && rts == null)
                      const SkeletonBerandaPage()
                    else if (rts == null)
                      const EmptyPanel(
                        title: 'Data RTS belum tersedia',
                        message:
                            'Tarik ke bawah untuk memuat ulang status perangkat.',
                        icon: Icons.radar_rounded,
                      )
                    else ...[
                      RtsStatusSummaryCard(
                        status: rtsStatus,
                        waktu: rts.waktu,
                        tiltXText: _metric(rts.tiltX, fraction: 2),
                        tiltYText: _metric(rts.tiltY, fraction: 2),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        padding: EdgeInsets.zero,
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.28,
                        children: [
                          MetricTile(
                            label: 'Humidity',
                            value: formatBerandaSensorMetric(rts.humidity),
                            unit: '%',
                            icon: Icons.water_drop_outlined,
                            color: AppColors.info,
                          ),
                          MetricTile(
                            label: 'Battery',
                            value: formatBerandaSensorMetric(rts.battery),
                            unit: 'Volt',
                            icon: Icons.battery_full_rounded,
                            color: AppColors.success,
                          ),
                          MetricTile(
                            label: 'Temperature',
                            value: formatBerandaSensorMetric(rts.temperature),
                            unit: 'C',
                            icon: Icons.thermostat_rounded,
                            color: AppColors.danger,
                          ),
                          MetricTile(
                            label: 'Power RTS',
                            value: formatBerandaSensorMetric(rts.powerRts),
                            unit: 'Volt',
                            icon: Icons.bolt_rounded,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    const _SectionHeader(
                      title: 'Menu Utama',
                      subtitle: 'Akses fitur monitoring ADR',
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.72,
                      children: _menus
                          .map(
                            (menu) => _MenuCard(
                              data: menu,
                              onTap: () => context.push(menu.route),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 48),
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

class _DashboardHeader extends StatelessWidget {
  final String name;
  final String role;
  final String dateText;
  final BerandaDashboardStatus status;
  final VoidCallback onLogout;

  const _DashboardHeader({
    required this.name,
    required this.role,
    required this.dateText,
    required this.status,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                    onPressed: onLogout,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(
                    label: status.label,
                    color: status.color,
                    icon: status.icon,
                  ),
                  StatusPill(
                    label: role,
                    color: Colors.white,
                    icon: Icons.verified_user_outlined,
                    subtle: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white.withValues(alpha: 0.78),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MenuData {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  final String subtitle;

  const _MenuData(this.label, this.icon, this.route, this.color, this.subtitle);
}

class _MenuCard extends StatelessWidget {
  final _MenuData data;
  final VoidCallback onTap;

  const _MenuCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          MenuIconBadge(icon: data.icon, color: data.color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
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
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: data.color.withValues(alpha: 0.55),
            size: 18,
          ),
        ],
      ),
    );
  }
}
