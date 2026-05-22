import 'package:adr_mobile/features/peta/models/peta_camera_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clamps peta zoom to supported mobile range', () {
    expect(clampPetaZoom(2), 5);
    expect(clampPetaZoom(12.5), 12.5);
    expect(clampPetaZoom(23), 19);
  });
}
