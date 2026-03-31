import 'package:flutter/material.dart';

/// Shimmer loading effect widget for dashboard placeholders
/// Provides smooth loading animation while data is being fetched
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  /// Creates a rectangular shimmer
  const ShimmerWidget.rectangular({
    super.key,
    required this.width,
    required this.height,
    double radius = 8,
  })  : borderRadius = null,
        baseColor = const Color(0xFFE0E0E0),
        highlightColor = const Color(0xFFF5F5F5);

  /// Creates a circular shimmer
  factory ShimmerWidget.circular({
    Key? key,
    required double size,
  }) {
    return ShimmerWidget(
      key: key,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment((_animation.value - 1).clamp(-1.0, 1.0), 0),
              end: Alignment((_animation.value + 1).clamp(-1.0, 1.0), 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer card for dashboard metric cards
class ShimmerMetricCard extends StatelessWidget {
  final double? width;
  final double height;

  const ShimmerMetricCard({
    super.key,
    this.width,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerWidget(
                width: 80,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
              ShimmerWidget.circular(size: 28),
            ],
          ),
          const Spacer(),
          ShimmerWidget(
            width: 120,
            height: 28,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          ShimmerWidget(
            width: 100,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// Shimmer for quick stats section
class ShimmerQuickStats extends StatelessWidget {
  const ShimmerQuickStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(4, (index) => _buildStatItem()),
      ),
    );
  }

  Widget _buildStatItem() {
    return Column(
      children: [
        ShimmerWidget.circular(size: 40),
        const SizedBox(height: 8),
        ShimmerWidget(
          width: 40,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        ShimmerWidget(
          width: 60,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

/// Shimmer for profit card
class ShimmerProfitCard extends StatelessWidget {
  const ShimmerProfitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: 60,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),
                ShimmerWidget(
                  width: 140,
                  height: 32,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                ShimmerWidget(
                  width: 100,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          ShimmerWidget.circular(size: 80),
        ],
      ),
    );
  }
}

/// Full dashboard shimmer loading state
class DashboardShimmerLoading extends StatelessWidget {
  const DashboardShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          const ShimmerQuickStats(),
          const SizedBox(height: 20),

          // Filter chips shimmer
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ShimmerWidget(
                    width: 90,
                    height: 36,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Section header shimmer
          Row(
            children: [
              ShimmerWidget.circular(size: 44),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    width: 150,
                    height: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  ShimmerWidget(
                    width: 80,
                    height: 13,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Metric cards row
          Row(
            children: const [
              Expanded(child: ShimmerMetricCard()),
              SizedBox(width: 16),
              Expanded(child: ShimmerMetricCard()),
            ],
          ),
          const SizedBox(height: 16),

          // Profit card
          const ShimmerProfitCard(),
          const SizedBox(height: 28),

          // Another section header
          Row(
            children: [
              ShimmerWidget.circular(size: 44),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    width: 140,
                    height: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  ShimmerWidget(
                    width: 70,
                    height: 13,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Inventory card shimmer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerWidget(
                      width: 100,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    ShimmerWidget(
                      width: 80,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ShimmerWidget(
                        width: double.infinity,
                        height: 60,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ShimmerWidget(
                        width: double.infinity,
                        height: 60,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
