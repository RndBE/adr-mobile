import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class BerandaDashboardStatus {
  final String label;
  final String shortLabel;
  final String title;
  final Color color;
  final IconData icon;

  const BerandaDashboardStatus({
    required this.label,
    required this.shortLabel,
    required this.title,
    required this.color,
    required this.icon,
  });

  factory BerandaDashboardStatus.loggerFromState({
    required bool isLoggerOnline,
  }) {
    if (isLoggerOnline) {
      return const BerandaDashboardStatus(
        label: 'Logger Online',
        shortLabel: 'Online',
        title: 'Logger Terhubung',
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    }

    return const BerandaDashboardStatus(
      label: 'Logger Offline',
      shortLabel: 'Offline',
      title: 'Logger Tidak Terhubung',
      color: AppColors.danger,
      icon: Icons.power_settings_new_rounded,
    );
  }

  factory BerandaDashboardStatus.fromState({
    required bool isRtsPowered,
    required bool isRunning,
  }) {
    if (isRunning) {
      return const BerandaDashboardStatus(
        label: 'RTS Running',
        shortLabel: 'Running',
        title: 'Pengukuran Berjalan',
        color: AppColors.running,
        icon: Icons.radar_rounded,
      );
    }

    if (isRtsPowered) {
      return const BerandaDashboardStatus(
        label: 'RTS Standby',
        shortLabel: 'Standby',
        title: 'RTS Connected',
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    }

    return const BerandaDashboardStatus(
      label: 'RTS Off',
      shortLabel: 'Off',
      title: 'RTS Disconnected',
      color: AppColors.danger,
      icon: Icons.power_settings_new_rounded,
    );
  }
}
