import 'package:adr_mobile/features/beranda/models/beranda_header_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('header height leaves room for fixed mobile header content', () {
    expect(berandaHeaderHeight(24), 194);
    expect(berandaHeaderBaseHeight, greaterThanOrEqualTo(170));
  });
}
