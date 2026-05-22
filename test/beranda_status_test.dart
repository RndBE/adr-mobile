import 'package:adr_mobile/features/beranda/models/beranda_dashboard_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows logger status for dashboard header', () {
    final status = BerandaDashboardStatus.loggerFromState(isLoggerOnline: true);

    expect(status.label, 'Logger Online');
    expect(status.shortLabel, 'Online');
    expect(status.title, 'Logger Terhubung');
  });

  test('shows offline logger status for dashboard header', () {
    final status = BerandaDashboardStatus.loggerFromState(isLoggerOnline: false);

    expect(status.label, 'Logger Offline');
    expect(status.shortLabel, 'Offline');
    expect(status.title, 'Logger Tidak Terhubung');
  });

  test(
    'shows RTS standby when sensor14 is on but measurement is not running',
    () {
      final status = BerandaDashboardStatus.fromState(
        isRtsPowered: true,
        isRunning: false,
      );

      expect(status.label, 'RTS Standby');
      expect(status.shortLabel, 'Standby');
      expect(status.title, 'RTS Siap');
    },
  );

  test('shows RTS off when sensor14 is off', () {
    final status = BerandaDashboardStatus.fromState(
      isRtsPowered: false,
      isRunning: false,
    );

    expect(status.label, 'RTS Off');
    expect(status.shortLabel, 'Off');
    expect(status.title, 'RTS Mati');
  });

  test('shows RTS running only when measurement is running', () {
    final status = BerandaDashboardStatus.fromState(
      isRtsPowered: true,
      isRunning: true,
    );

    expect(status.label, 'RTS Running');
    expect(status.shortLabel, 'Running');
    expect(status.title, 'Pengukuran Berjalan');
  });
}
