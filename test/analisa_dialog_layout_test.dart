import 'package:adr_mobile/features/analisa/models/analisa_dialog_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('caps analisa dialog width to the configured maximum', () {
    expect(
      resolveAnalisaDialogWidth(
        screenWidth: 390,
        horizontalInset: 48,
        maxWidth: 280,
      ),
      280,
    );
  });

  test('keeps analisa dialog width usable when available width is invalid', () {
    expect(
      resolveAnalisaDialogWidth(
        screenWidth: 40,
        horizontalInset: 48,
        maxWidth: 280,
      ),
      280,
    );
  });
}
