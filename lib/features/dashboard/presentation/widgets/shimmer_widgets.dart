import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// Shimmer loading effect widget for dashboard placeholders
/// Provides smooth loading animation while data is being fetched
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  /// Creates a rectangular shimmer
  ShimmerWidget.rectangular({
    super.key,
    required this.width,
    required this.height,
    double radius = 8,
  }) : borderRadius = BorderRadius.all(Radius.circular(radius)),
       baseColor = null,
       highlightColor = null;

  /// Creates a circular shimmer
  factory ShimmerWidget.circular({Key? key, required double size}) {
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
    final isDark = AppColors.isDark(context);
    final base =
        widget.baseColor ??
        (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));
    final highlight =
        widget.highlightColor ??
        (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer placeholder for a metric card
class MetricCardShimmer extends StatelessWidget {
  const MetricCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget.rectangular(width: 40, height: 40, radius: 10),
          const SizedBox(height: 12),
          ShimmerWidget.rectangular(width: 80, height: 12, radius: 4),
          const SizedBox(height: 8),
          ShimmerWidget.rectangular(width: 120, height: 20, radius: 4),
        ],
      ),
    );
  }
}

/// Full dashboard shimmer loading layout
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
          ShimmerWidget.rectangular(width: 160, height: 18, radius: 6),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: MetricCardShimmer()),
              const SizedBox(width: 12),
              Expanded(child: MetricCardShimmer()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: MetricCardShimmer()),
              const SizedBox(width: 12),
              Expanded(child: MetricCardShimmer()),
            ],
          ),
          const SizedBox(height: 28),
          ShimmerWidget.rectangular(width: 140, height: 18, radius: 6),
          const SizedBox(height: 16),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: i == 3 ? 0 : 12),
                  child: Row(
                    children: [
                      ShimmerWidget.circular(size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerWidget.rectangular(
                              width: double.infinity,
                              height: 12,
                              radius: 4,
                            ),
                            const SizedBox(height: 6),
                            ShimmerWidget.rectangular(
                              width: 100,
                              height: 10,
                              radius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
