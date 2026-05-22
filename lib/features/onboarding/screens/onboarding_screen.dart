import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      asset: 'assets/images/mobile.png',
      scene: _OnboardingScene.monitoring,
      title: 'Monitor Deformasi',
      highlightedWord: 'Deformasi',
      subtitle: 'Pantau kondisi dari sensor RTS secara real-time.',
    ),
    _OnboardingData(
      asset: 'assets/images/mobile.png',
      scene: _OnboardingScene.analytics,
      title: 'Pantau dengan Lebih Cepat',
      highlightedWord: 'Cepat',
      subtitle: 'Dapatkan ringkasan grafik, tabel, dan status lapangan.',
    ),
    _OnboardingData(
      asset: 'assets/images/mobile.png',
      scene: _OnboardingScene.map,
      title: 'Akses dari Mana Saja',
      highlightedWord: 'Mana Saja',
      subtitle:
          'Tetap terhubung dengan kebutuhan monitoring langsung dari genggaman.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimeApp', false);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final currentData = _pages[_currentPage];
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: _ProgressDots(
                  length: _pages.length,
                  currentIndex: _currentPage,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),
            Container(
              key: const Key('onboarding-bottom-panel'),
              width: double.infinity,
              alignment: Alignment.topCenter,
              constraints: const BoxConstraints(minHeight: 232),
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                child: SizedBox(
                  height: 148,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HighlightedTitle(
                            title: currentData.title,
                            highlightedWord: currentData.highlightedWord,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentData.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        key: const Key('onboarding-actions-row'),
                        children: [
                          TextButton(
                            onPressed: _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(54, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              isLastPage ? 'Keluar' : 'Lewati',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: isLastPage
                                  ? _finish
                                  : () => _pageCtrl.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(108, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isLastPage ? 'Mulai' : 'Lanjut ->',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String asset;
  final _OnboardingScene scene;
  final String title;
  final String highlightedWord;
  final String subtitle;

  const _OnboardingData({
    required this.asset,
    required this.scene,
    required this.title,
    required this.highlightedWord,
    required this.subtitle,
  });
}

enum _OnboardingScene { monitoring, analytics, map }

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 610;

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, compact ? 10 : 22, 28, 0),
                child: Center(
                  child: _OnboardingVisual(
                    data: data,
                    height: compact ? 255 : 345,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OnboardingVisual extends StatelessWidget {
  final _OnboardingData data;
  final double height;

  const _OnboardingVisual({required this.data, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('onboarding-visual-${data.scene.name}'),
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(data.asset, fit: BoxFit.contain, height: height),
          if (data.scene == _OnboardingScene.monitoring) ...[
            const Positioned(
              left: 12,
              top: 42,
              child: _MetricBubble(
                icon: Icons.battery_charging_full_rounded,
                label: '85%',
                color: AppColors.success,
              ),
            ),
            const Positioned(
              right: 12,
              top: 58,
              child: _MetricBubble(
                icon: Icons.notifications_active_rounded,
                label: 'RTS',
                color: AppColors.accent,
              ),
            ),
            const Positioned(
              left: 18,
              bottom: 62,
              child: _MetricBubble(
                icon: Icons.thermostat_rounded,
                label: '31C',
                color: AppColors.warning,
              ),
            ),
          ] else if (data.scene == _OnboardingScene.analytics) ...[
            const Positioned(
              left: 10,
              top: 30,
              child: _ChartBubble(label: 'Grafik Sensor'),
            ),
            const Positioned(
              right: 8,
              top: 118,
              child: _MetricBubble(
                icon: Icons.trending_up_rounded,
                label: '+2.4',
                color: AppColors.info,
              ),
            ),
            const Positioned(
              left: 28,
              bottom: 48,
              child: _MetricBubble(
                icon: Icons.table_chart_rounded,
                label: 'Tabel',
                color: AppColors.primary,
              ),
            ),
          ] else ...[
            const Positioned(
              left: 10,
              top: 44,
              child: _MetricBubble(
                icon: Icons.location_on_rounded,
                label: 'Prism',
                color: AppColors.danger,
              ),
            ),
            const Positioned(
              right: 16,
              top: 44,
              child: _MetricBubble(
                icon: Icons.wifi_rounded,
                label: 'Online',
                color: AppColors.running,
              ),
            ),
            const Positioned(
              right: 20,
              bottom: 56,
              child: _MetricBubble(
                icon: Icons.public_rounded,
                label: 'Map',
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricBubble({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBubble extends StatelessWidget {
  final String label;

  const _ChartBubble({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: CustomPaint(
              painter: _MiniChartPainter(),
              size: const Size(double.infinity, 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    final path = Path()
      ..moveTo(0, size.height * 0.68)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.25,
        size.width * 0.34,
        size.height * 0.9,
        size.width * 0.52,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.05,
        size.width * 0.82,
        size.height * 0.75,
        size.width,
        size.height * 0.28,
      );
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HighlightedTitle extends StatelessWidget {
  final String title;
  final String highlightedWord;

  const _HighlightedTitle({required this.title, required this.highlightedWord});

  @override
  Widget build(BuildContext context) {
    final parts = title.split(highlightedWord);
    final before = parts.first;
    final after = parts.length > 1 ? parts.last : '';

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: before),
          TextSpan(
            text: highlightedWord,
            style: const TextStyle(color: AppColors.primary),
          ),
          TextSpan(text: after),
        ],
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 21,
        height: 1.2,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int length;
  final int currentIndex;

  const _ProgressDots({required this.length, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(left: 3),
          width: index == currentIndex ? 22 : 4,
          height: 4,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
