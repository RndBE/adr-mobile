import 'package:adr_mobile/shared/widgets/fixed_pinned_header_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the same min and max extent for a fixed pinned header', () {
    const delegate = FixedPinnedHeaderDelegate(height: 180, child: SizedBox());

    expect(delegate.minExtent, 180);
    expect(delegate.maxExtent, 180);
  });

  test('rebuilds when height changes', () {
    const oldDelegate = FixedPinnedHeaderDelegate(
      height: 180,
      child: SizedBox(),
    );
    const newDelegate = FixedPinnedHeaderDelegate(
      height: 190,
      child: SizedBox(),
    );

    expect(newDelegate.shouldRebuild(oldDelegate), isTrue);
  });
}
