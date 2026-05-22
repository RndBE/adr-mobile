import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry margin;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 8,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              SkeletonCircle(size: 42),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 180),
                    SizedBox(height: 10),
                    SkeletonBox(height: 10, width: 120),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonBox(height: 22, width: 52, radius: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonBerandaPage extends StatelessWidget {
  const SkeletonBerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonBerandaRtsCard(),
          SizedBox(height: 14),
          _SkeletonBerandaMetricGrid(),
          SizedBox(height: 22),
          SkeletonBox(width: 116, height: 16),
          SizedBox(height: 7),
          SkeletonBox(width: 162, height: 11),
          SizedBox(height: 12),
          _SkeletonBerandaMenuGrid(),
          SizedBox(height: 48),
        ],
      ),
    );
  }
}

class SkeletonAdrPage extends StatelessWidget {
  const SkeletonAdrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFF2B3377),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: const Row(
                children: [
                  SkeletonBox(width: 64, height: 34, radius: 18),
                  SizedBox(width: 10),
                  SkeletonBox(width: 64, height: 34, radius: 18),
                  SizedBox(width: 10),
                  SkeletonBox(width: 64, height: 34, radius: 18),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 150, height: 12),
                  SkeletonBox(width: 72, height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _SkeletonAdrSummary(),
                  SizedBox(height: 14),
                  SkeletonBox(width: 142, height: 16),
                  SizedBox(height: 7),
                  SkeletonBox(width: 210, height: 11),
                  SizedBox(height: 10),
                  _SkeletonAdrMetricGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonAnalysisPage extends StatelessWidget {
  final bool compactTable;

  const SkeletonAnalysisPage({super.key, this.compactTable = false});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                SkeletonCircle(size: 64),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 18, width: 140),
                      SizedBox(height: 8),
                      SkeletonBox(height: 14, width: 180),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SkeletonBox(height: 52, radius: 12),
            const SizedBox(height: 14),
            const SkeletonBox(height: 52, radius: 12),
            const SizedBox(height: 18),
            const _SkeletonChartCard(),
            const SizedBox(height: 18),
            _SkeletonTable(
              rows: compactTable ? 2 : 6,
              columns: compactTable ? 2 : 4,
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonHasilPengukuranPage extends StatelessWidget {
  const SkeletonHasilPengukuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: const Column(
              children: [
                _SkeletonHasilSummary(),
                SizedBox(height: 12),
                SkeletonBox(height: 44, radius: 12),
                SizedBox(height: 10),
                Row(
                  children: [
                    SkeletonBox(width: 72, height: 32, radius: 20),
                    SizedBox(width: 8),
                    SkeletonBox(width: 52, height: 32, radius: 20),
                    SizedBox(width: 8),
                    SkeletonBox(width: 72, height: 32, radius: 20),
                    SizedBox(width: 8),
                    SkeletonBox(width: 58, height: 32, radius: 20),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.primarySurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                SkeletonCircle(size: 14),
                SizedBox(width: 6),
                SkeletonBox(width: 132, height: 12),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, _) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SkeletonBox(width: 46, height: 46, radius: 13),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: SkeletonBox(height: 13)),
                              SizedBox(width: 14),
                              SkeletonBox(width: 38, height: 12),
                            ],
                          ),
                          SizedBox(height: 9),
                          Row(
                            children: [
                              SkeletonBox(width: 48, height: 18, radius: 7),
                              SizedBox(width: 7),
                              SkeletonBox(width: 52, height: 18, radius: 7),
                              SizedBox(width: 7),
                              SkeletonBox(width: 64, height: 18, radius: 7),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    SkeletonBox(width: 18, height: 18, radius: 9),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonKontrolAdrPage extends StatelessWidget {
  const SkeletonKontrolAdrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SkeletonKontrolStatusCard(),
            SizedBox(height: 14),
            _SkeletonKontrolSection(height: 116),
            SizedBox(height: 14),
            _SkeletonKontrolSection(height: 178),
            SizedBox(height: 14),
            SkeletonBox(width: 156, height: 16),
            SizedBox(height: 6),
            SkeletonBox(width: 118, height: 11),
            SizedBox(height: 10),
            _SkeletonPrismGrid(),
          ],
        ),
      ),
    );
  }
}

class SkeletonDetailPage extends StatelessWidget {
  const SkeletonDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          _SkeletonSection(rows: 4),
          SizedBox(height: 16),
          _SkeletonChartCard(),
          SizedBox(height: 16),
          _SkeletonSection(rows: 5),
        ],
      ),
    );
  }
}

class SkeletonHeatmap extends StatelessWidget {
  const SkeletonHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: List.generate(
            9,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: List.generate(
                  8,
                  (_) => const Expanded(
                    child: SkeletonBox(
                      height: 34,
                      radius: 4,
                      margin: EdgeInsets.only(right: 6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonWebView extends StatelessWidget {
  const SkeletonWebView({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SkeletonBox(height: 220, radius: 12),
            SizedBox(height: 16),
            SkeletonBox(height: 18, width: 180),
            SizedBox(height: 10),
            SkeletonBox(height: 14),
            SizedBox(height: 8),
            SkeletonBox(height: 14, width: 240),
          ],
        ),
      ),
    );
  }
}

class _SkeletonAdrSummary extends StatelessWidget {
  const _SkeletonAdrSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 46, height: 46, radius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 112, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 156, height: 18),
                  ],
                ),
              ),
              SkeletonBox(width: 78, height: 28, radius: 20),
            ],
          ),
          SizedBox(height: 14),
          SkeletonBox(height: 38, radius: 12),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 46, radius: 12)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 46, radius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBerandaRtsCard extends StatelessWidget {
  const _SkeletonBerandaRtsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 46, height: 46, radius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 82, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 130, height: 18),
                  ],
                ),
              ),
              SkeletonBox(width: 64, height: 28, radius: 20),
            ],
          ),
          SizedBox(height: 14),
          SkeletonBox(height: 38, radius: 12),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 70, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 70, radius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBerandaMetricGrid extends StatelessWidget {
  const _SkeletonBerandaMetricGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.28,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: List.generate(
        4,
        (_) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 32, height: 32, radius: 9),
                  Spacer(),
                  SkeletonBox(width: 30, height: 10),
                ],
              ),
              Spacer(),
              SkeletonBox(width: 72, height: 20),
              SizedBox(height: 8),
              SkeletonBox(width: 86, height: 11),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBerandaMenuGrid extends StatelessWidget {
  const _SkeletonBerandaMenuGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.72,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: List.generate(
        4,
        (_) => Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 46, height: 46, radius: 13),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 13, width: 82),
                    SizedBox(height: 8),
                    SkeletonBox(height: 10, width: 100),
                  ],
                ),
              ),
              SizedBox(width: 6),
              SkeletonBox(width: 18, height: 18, radius: 9),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonAdrMetricGrid extends StatelessWidget {
  const _SkeletonAdrMetricGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.12,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: List.generate(
        4,
        (_) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 34, height: 34, radius: 11),
                  Spacer(),
                  SkeletonBox(width: 24, height: 24, radius: 8),
                ],
              ),
              Spacer(),
              SkeletonBox(width: 96, height: 18),
              SizedBox(height: 8),
              SkeletonBox(width: 72, height: 11),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonSection extends StatelessWidget {
  final int rows;

  const _SkeletonSection({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 150, height: 16),
                SkeletonBox(width: 86, height: 12),
              ],
            ),
          ),
          ...List.generate(
            rows,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SkeletonCircle(size: 38),
                  SizedBox(width: 14),
                  Expanded(child: SkeletonBox(height: 14)),
                  SizedBox(width: 16),
                  SkeletonBox(width: 76, height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonHasilSummary extends StatelessWidget {
  const _SkeletonHasilSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              SkeletonBox(width: 42, height: 42, radius: 12),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 150, height: 15),
                    SizedBox(height: 8),
                    SkeletonBox(width: 190, height: 11),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 44, radius: 10)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 44, radius: 10)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 44, radius: 10)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 44, radius: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonKontrolStatusCard extends StatelessWidget {
  const _SkeletonKontrolStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonCircle(size: 50),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 116, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 168, height: 20),
                    SizedBox(height: 7),
                    SkeletonBox(width: 138, height: 12),
                  ],
                ),
              ),
              SkeletonBox(width: 72, height: 28, radius: 20),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 52, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 52, radius: 12)),
            ],
          ),
          SizedBox(height: 10),
          SkeletonBox(height: 38, radius: 12),
        ],
      ),
    );
  }
}

class _SkeletonKontrolSection extends StatelessWidget {
  final double height;

  const _SkeletonKontrolSection({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 124, height: 14),
          SizedBox(height: 7),
          SkeletonBox(width: 190, height: 11),
          Spacer(),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 48, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 48, radius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonPrismGrid extends StatelessWidget {
  const _SkeletonPrismGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.42,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: List.generate(
        4,
        (_) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 28, height: 28, radius: 9),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 12)),
                ],
              ),
              SizedBox(height: 12),
              SkeletonBox(width: 86, height: 10),
              SizedBox(height: 7),
              SkeletonBox(width: 78, height: 10),
              SizedBox(height: 7),
              SkeletonBox(width: 72, height: 10),
              Spacer(),
              SkeletonBox(width: 56, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonChartCard extends StatelessWidget {
  const _SkeletonChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          SkeletonBox(height: 16, width: 170),
          SizedBox(height: 8),
          SkeletonBox(height: 12, width: 220),
          SizedBox(height: 14),
          SkeletonBox(height: 240, radius: 6),
          SizedBox(height: 14),
          SkeletonBox(height: 12, width: 190),
        ],
      ),
    );
  }
}

class _SkeletonTable extends StatelessWidget {
  final int rows;
  final int columns;

  const _SkeletonTable({required this.rows, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(
          rows,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: List.generate(
                columns,
                (_) => const Expanded(
                  child: SkeletonBox(
                    height: 14,
                    margin: EdgeInsets.only(right: 12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
