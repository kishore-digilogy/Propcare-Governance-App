import 'package:flutter/material.dart';

/// Core Shimmer effect widget that sweeps a light gradient over its child widgets.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFF8FAFC),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              stops: const [0.1, 0.35, 0.55, 0.8],
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0,
      0,
    );
  }
}

/// Generic rounded placeholder container used within shimmer trees.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Reusable Shimmer list loading skeleton (ideal for All Sites, Renewals, Activities, Issues, etc.)
class ShimmerListLoading extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const ShimmerListLoading({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Title + Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerBox(width: 140, height: 18, borderRadius: 6),
                    const ShimmerBox(width: 70, height: 22, borderRadius: 12),
                  ],
                ),
                const SizedBox(height: 10),
                // Subtitle
                const ShimmerBox(width: 220, height: 13, borderRadius: 4),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                // Footer chips
                Row(
                  children: const [
                    ShimmerBox(width: 75, height: 20, borderRadius: 10),
                    SizedBox(width: 8),
                    ShimmerBox(width: 90, height: 20, borderRadius: 10),
                    SizedBox(width: 8),
                    ShimmerBox(width: 80, height: 20, borderRadius: 10),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer skeleton for Site Details Page.
class ShimmerSiteDetailLoading extends StatelessWidget {
  const ShimmerSiteDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Back button + Breadcrumb
            Row(
              children: const [
                ShimmerBox(width: 68, height: 32, borderRadius: 20),
                SizedBox(width: 12),
                ShimmerBox(width: 130, height: 16, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 18),

            // Site Title + Location
            const ShimmerBox(width: 200, height: 26, borderRadius: 6),
            const SizedBox(height: 8),
            const ShimmerBox(width: 160, height: 14, borderRadius: 4),
            const SizedBox(height: 16),

            // Badges row
            Row(
              children: const [
                ShimmerBox(width: 60, height: 24, borderRadius: 12),
                SizedBox(width: 8),
                ShimmerBox(width: 38, height: 24, borderRadius: 12),
                SizedBox(width: 8),
                ShimmerBox(width: 110, height: 24, borderRadius: 12),
                SizedBox(width: 8),
                ShimmerBox(width: 45, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 38, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 38, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 38, borderRadius: 10)),
              ],
            ),
            const SizedBox(height: 22),

            // 4 Stat Cards in 2x2 grid
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 96, borderRadius: 16)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 96, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 96, borderRadius: 16)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 96, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 24),

            // Governance Activities header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 170, height: 20, borderRadius: 6),
                ShimmerBox(width: 65, height: 22, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 14),

            // Activity Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 180, height: 18, borderRadius: 6),
                  SizedBox(height: 6),
                  ShimmerBox(width: 90, height: 12, borderRadius: 4),
                  SizedBox(height: 14),
                  Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SizedBox(height: 12),
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                  SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for Dashboard Page.
class ShimmerDashboardLoading extends StatelessWidget {
  const ShimmerDashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome Hero banner
            const ShimmerBox(width: double.infinity, height: 140, borderRadius: 18),
            const SizedBox(height: 20),

            // Metrics row
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 85, borderRadius: 14)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 85, borderRadius: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 85, borderRadius: 14)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 85, borderRadius: 14)),
              ],
            ),
            const SizedBox(height: 20),

            // Big Card (Charts / Map)
            const ShimmerBox(width: double.infinity, height: 200, borderRadius: 16),
            const SizedBox(height: 16),

            // List items
            const ShimmerBox(width: double.infinity, height: 75, borderRadius: 14),
            const SizedBox(height: 10),
            const ShimmerBox(width: double.infinity, height: 75, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for Governance Matrix Page.
class ShimmerMatrixLoading extends StatelessWidget {
  const ShimmerMatrixLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            const ShimmerBox(width: double.infinity, height: 100, borderRadius: 16),
            const SizedBox(height: 16),

            // Horizontal tabs
            Row(
              children: const [
                ShimmerBox(width: 100, height: 36, borderRadius: 18),
                SizedBox(width: 8),
                ShimmerBox(width: 75, height: 36, borderRadius: 18),
                SizedBox(width: 8),
                ShimmerBox(width: 90, height: 36, borderRadius: 18),
              ],
            ),
            const SizedBox(height: 20),

            // Tier Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 130, height: 24, borderRadius: 12),
                      ShimmerBox(width: 80, height: 22, borderRadius: 12),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(child: ShimmerBox(height: 64, borderRadius: 12)),
                      SizedBox(width: 10),
                      Expanded(child: ShimmerBox(height: 64, borderRadius: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Expanded(child: ShimmerBox(height: 64, borderRadius: 12)),
                      SizedBox(width: 10),
                      Expanded(child: ShimmerBox(height: 64, borderRadius: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for Activity Execution Page.
class ShimmerActivityExecutionLoading extends StatelessWidget {
  const ShimmerActivityExecutionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: const Color(0xFF0A1931),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        ShimmerBox(width: 80, height: 30, borderRadius: 15, color: Color(0xFF1E293B)),
                        ShimmerBox(width: 100, height: 28, borderRadius: 6, color: Color(0xFF1E293B)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const ShimmerBox(width: 220, height: 24, borderRadius: 6, color: Color(0xFF1E293B)),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: 180, height: 14, borderRadius: 4, color: Color(0xFF1E293B)),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(child: ShimmerBox(height: 38, borderRadius: 10, color: Color(0xFF1E293B))),
                        SizedBox(width: 12),
                        Expanded(child: ShimmerBox(height: 38, borderRadius: 10, color: Color(0xFF1E293B))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const ShimmerBox(width: double.infinity, height: 48, borderRadius: 24),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 150, height: 20, borderRadius: 6),
                        SizedBox(height: 20),
                        ShimmerBox(width: 100, height: 14, borderRadius: 4),
                        SizedBox(height: 8),
                        ShimmerBox(width: double.infinity, height: 44, borderRadius: 10),
                        SizedBox(height: 18),
                        ShimmerBox(width: 100, height: 14, borderRadius: 4),
                        SizedBox(height: 8),
                        ShimmerBox(width: 160, height: 36, borderRadius: 8),
                        SizedBox(height: 18),
                        ShimmerBox(width: double.infinity, height: 90, borderRadius: 10),
                        SizedBox(height: 20),
                        ShimmerBox(width: double.infinity, height: 44, borderRadius: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
