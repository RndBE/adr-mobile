import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/theme/app_theme.dart';
import '../data/peta_repository.dart';
import '../models/peta_camera_motion.dart';

class PetaScreen extends StatefulWidget {
  const PetaScreen({super.key});

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> with TickerProviderStateMixin {
  final _repo = PetaRepository();
  final _mapCtrl = MapController();

  List<PetaMarker> _markers = [];
  PetaMarker? _selected;
  bool _loading = true;
  bool _isSatellite = false;
  bool _mapReady = false;

  late final AnimationController _cameraCtrl;
  Animation<double>? _latAnimation;
  Animation<double>? _lonAnimation;
  Animation<double>? _zoomAnimation;

  static const _defaultCenter = LatLng(-7.5, 110.0);

  @override
  void initState() {
    super.initState();
    _cameraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addListener(_handleCameraTick);
    _fetchMarkers();
  }

  Future<void> _fetchMarkers() async {
    final markers = await _repo.getMarkers();
    if (!mounted) return;
    setState(() {
      _markers = markers;
      _loading = false;
    });
    if (markers.isNotEmpty) {
      _animateCameraTo(LatLng(markers.first.lat, markers.first.lon), 14);
    }
  }

  void _handleMapReady() {
    _mapReady = true;
    if (_markers.isNotEmpty) {
      _animateCameraTo(LatLng(_markers.first.lat, _markers.first.lon), 14);
    }
  }

  void _handleCameraTick() {
    final lat = _latAnimation;
    final lon = _lonAnimation;
    final zoom = _zoomAnimation;
    if (!_mapReady || lat == null || lon == null || zoom == null) return;

    _mapCtrl.move(LatLng(lat.value, lon.value), zoom.value);
  }

  void _animateCameraTo(LatLng center, double zoom) {
    if (!_mapReady) return;

    final currentCenter = _mapCtrl.camera.center;
    final currentZoom = _mapCtrl.camera.zoom;
    final curved = CurvedAnimation(
      parent: _cameraCtrl,
      curve: Curves.easeOutCubic,
    );

    _latAnimation = Tween<double>(
      begin: currentCenter.latitude,
      end: center.latitude,
    ).animate(curved);
    _lonAnimation = Tween<double>(
      begin: currentCenter.longitude,
      end: center.longitude,
    ).animate(curved);
    _zoomAnimation = Tween<double>(
      begin: currentZoom,
      end: clampPetaZoom(zoom),
    ).animate(curved);

    _cameraCtrl.forward(from: 0);
  }

  void _selectMarker(PetaMarker marker) {
    setState(() => _selected = marker);
    _animateCameraTo(LatLng(marker.lat, marker.lon), _mapCtrl.camera.zoom);
  }

  void _zoomBy(double delta) {
    _animateCameraTo(
      _mapCtrl.camera.center,
      clampPetaZoom(_mapCtrl.camera.zoom + delta),
    );
  }

  Color _markerColor(String status) {
    switch (status) {
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
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Lokasi Prism'),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
            tooltip: 'Ganti tampilan peta',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12,
              minZoom: minPetaZoom,
              maxZoom: maxPetaZoom,
              onMapReady: _handleMapReady,
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bejogja.adr_mobile',
              ),
              MarkerLayer(
                markers: _markers.map((m) {
                  final color = _markerColor(m.status);
                  final isSelected = _selected?.id == m.id;
                  return Marker(
                    point: LatLng(m.lat, m.lon),
                    width: 46,
                    height: 46,
                    child: GestureDetector(
                      onTap: () => _selectMarker(m),
                      child: AnimatedScale(
                        scale: isSelected ? 1.18 : 1,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3.2 : 2.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(
                                  alpha: isSelected ? 0.52 : 0.34,
                                ),
                                blurRadius: isSelected ? 12 : 7,
                                spreadRadius: isSelected ? 2 : 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Loading overlay
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // Zoom controls
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            right: 16,
            bottom: _selected != null ? 200 : 80,
            child: Column(
              children: [
                _ZoomBtn(icon: Icons.add, onTap: () => _zoomBy(1)),
                const SizedBox(height: 8),
                _ZoomBtn(icon: Icons.remove, onTap: () => _zoomBy(-1)),
              ],
            ),
          ),

          // Selected marker info card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AnimatedSlide(
              offset: _selected == null ? const Offset(0, 0.16) : Offset.zero,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _selected == null ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: _selected == null,
                  child: _selected == null
                      ? const SizedBox.shrink()
                      : _InfoCard(
                          key: ValueKey(_selected!.id),
                          marker: _selected!,
                          onClose: () => setState(() => _selected = null),
                        ),
                ),
              ),
            ),
          ),

          // Legend
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem('Sukses', AppColors.success),
                  _LegendItem('Failed', AppColors.danger),
                  _LegendItem('Running', AppColors.running),
                  _LegendItem('Unknown', AppColors.textHint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  State<_ZoomBtn> createState() => _ZoomBtnState();
}

class _ZoomBtnState extends State<_ZoomBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : cardShadow,
          ),
          child: Icon(widget.icon, size: 22, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final PetaMarker marker;
  final VoidCallback onClose;
  const _InfoCard({super.key, required this.marker, required this.onClose});

  Color get _statusColor {
    switch (marker.status) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardShadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: _statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      marker.kategori,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textHint,
                ),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CoordBadge('Lat', marker.lat.toStringAsFixed(6)),
              const SizedBox(width: 8),
              _CoordBadge('Lon', marker.lon.toStringAsFixed(6)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  marker.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (marker.site.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Site: ${marker.site.toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoordBadge extends StatelessWidget {
  final String label;
  final String value;
  const _CoordBadge(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
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

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
