import 'package:flutter/material.dart';

class FixedPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const FixedPinnedHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant FixedPinnedHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
