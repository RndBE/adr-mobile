import 'package:adr_mobile/features/adr/models/adr_selector_chip_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ADR selector chips are not removable filters', () {
    const style = AdrSelectorChipStyle.selector();

    expect(style.showsRemoveAction, isFalse);
  });
}
