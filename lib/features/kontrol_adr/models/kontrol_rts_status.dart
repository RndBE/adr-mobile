import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class KontrolRtsStatus {
  final String label;
  final String actionLabel;
  final String pillLabel;
  final Color color;
  final IconData icon;

  const KontrolRtsStatus({
    required this.label,
    required this.actionLabel,
    required this.pillLabel,
    required this.color,
    required this.icon,
  });

  factory KontrolRtsStatus.fromSensors({
    required bool isPowered,
    required bool isRunning,
  }) {
    if (isRunning) {
      return const KontrolRtsStatus(
        label: 'RTS Running',
        actionLabel: 'Pengukuran berjalan',
        pillLabel: 'Running',
        color: AppColors.running,
        icon: Icons.radar_rounded,
      );
    }

    if (isPowered) {
      return const KontrolRtsStatus(
        label: 'RTS Standby',
        actionLabel: 'Siap kontrol dari mobile',
        pillLabel: 'Standby',
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    }

    return const KontrolRtsStatus(
      label: 'RTS Off',
      actionLabel: 'Power RTS belum aktif',
      pillLabel: 'Off',
      color: AppColors.danger,
      icon: Icons.power_settings_new_rounded,
    );
  }
}
