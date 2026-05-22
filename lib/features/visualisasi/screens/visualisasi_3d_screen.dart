import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../core/constants/api_constants.dart';

class Visualisasi3DScreen extends StatefulWidget {
  const Visualisasi3DScreen({super.key});

  @override
  State<Visualisasi3DScreen> createState() => _Visualisasi3DScreenState();
}

class _Visualisasi3DScreenState extends State<Visualisasi3DScreen> {
  late final WebViewController _ctrl;
  bool _loading = true;
  bool _hasError = false;

  final String _url = '${ApiConstants.baseUrl}/visualisasi-3d';

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _loading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (_) => setState(() {
            _loading = false;
            _hasError = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualisasi 3D'),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _ctrl.reload(),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            _ErrorView(onRetry: () => _ctrl.reload())
          else
            WebViewWidget(controller: _ctrl),

          if (_loading && !_hasError)
            Container(color: AppColors.bgLight, child: const SkeletonWebView()),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tidak dapat memuat visualisasi',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan perangkat terhubung ke jaringan yang sama dengan server ADR.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
