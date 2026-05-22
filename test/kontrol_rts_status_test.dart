import 'package:adr_mobile/features/kontrol_adr/models/kontrol_rts_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows running when measurement sensor is active', () {
    final status = KontrolRtsStatus.fromSensors(
      isPowered: true,
      isRunning: true,
    );

    expect(status.label, 'RTS Running');
    expect(status.actionLabel, 'Pengukuran berjalan');
  });

  test('shows standby when RTS is powered but not measuring', () {
    final status = KontrolRtsStatus.fromSensors(
      isPowered: true,
      isRunning: false,
    );

    expect(status.label, 'RTS Standby');
    expect(status.actionLabel, 'Siap kontrol dari mobile');
  });

  test('shows off when RTS is not powered', () {
    final status = KontrolRtsStatus.fromSensors(
      isPowered: false,
      isRunning: false,
    );

    expect(status.label, 'RTS Off');
    expect(status.actionLabel, 'Power RTS belum aktif');
  });
}
