import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/storage/secure_storage.dart';
import 'shared/theme/app_theme.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/beranda/screens/beranda_screen.dart';
import 'features/monitoring/screens/monitoring_screen.dart';
import 'features/hasil_pengukuran/screens/hasil_pengukuran_screen.dart';
import 'features/hasil_pengukuran/screens/detail_hasil_screen.dart';
import 'features/analisa/screens/analisa_screen.dart';
import 'features/adr/screens/adr_screen.dart';
import 'features/peta/screens/peta_screen.dart';
import 'features/kontrol_adr/screens/kontrol_adr_screen.dart';
import 'features/visualisasi/screens/visualisasi_3d_screen.dart';
import 'features/power_rts/screens/power_rts_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyleDark);

  runApp(const ProviderScope(child: AdrMobileApp()));
}

final _router = GoRouter(
  navigatorKey: _navigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/beranda', builder: (_, _) => const BerandaScreen()),
    GoRoute(path: '/monitoring', builder: (_, _) => const MonitoringScreen()),
    GoRoute(
      path: '/hasil-pengukuran',
      builder: (_, _) => const HasilPengukuranScreen(),
    ),
    GoRoute(
      path: '/detail-hasil',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DetailHasilScreen(
          idLog: extra?['id_log'] ?? '',
          tanggal: extra?['tanggal'] ?? '',
          site: extra?['site'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/analisa',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AnalisaScreen(
          mode: extra?['mode']?.toString(),
          initialParamKey: extra?['param']?.toString(),
          prismaName: extra?['prismaName']?.toString(),
          initialDate: extra?['date']?.toString(),
        );
      },
    ),
    GoRoute(path: '/adr', builder: (_, _) => const AdrScreen()),
    GoRoute(path: '/peta', builder: (_, _) => const PetaScreen()),
    GoRoute(path: '/kontrol-adr', builder: (_, _) => const KontrolAdrScreen()),
    GoRoute(
      path: '/visualisasi-3d',
      builder: (_, _) => const Visualisasi3DScreen(),
    ),
    GoRoute(path: '/power-rts', builder: (_, _) => const PowerRtsScreen()),
  ],
);

class AdrMobileApp extends StatelessWidget {
  const AdrMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ADR Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

// ─── Splash Screen ───────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5)));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('isFirstTimeApp') ?? true;
    if (!mounted) return;

    if (isFirst) {
      context.go('/onboarding');
      return;
    }

    final isLoggedIn = await SecureStorage.isLoggedIn();
    if (!mounted) return;
    context.go(isLoggedIn ? '/beranda' : '/login');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'ADR Monitor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Automated Deformation Recording',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 56),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
