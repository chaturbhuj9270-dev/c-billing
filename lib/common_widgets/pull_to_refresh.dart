import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// Standard pull-to-refresh wrapper used across list screens.
///
/// Pass a [ScrollView] (ListView / CustomScrollView) as [child] when possible.
/// For non-scrollable empty/error bodies, wrap with [scrollableEmpty] so pull
/// still works when the list is empty.
class PullToRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;

  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  /// Empty / centered content that must still accept a pull gesture.
  static Widget scrollableEmpty({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: color ?? AppColors.accent(context),
      onRefresh: onRefresh,
      child: child,
    );
  }
}
