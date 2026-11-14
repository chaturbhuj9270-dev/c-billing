import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'desktop_canvas.dart';

/// Smooth scrolling for the whole app.
///
/// - Enables mouse / trackpad dragging (important on web & desktop)
/// - Uses clamping physics on Android / web / desktop (avoids rubber-band glitches)
/// - Keeps iOS bouncing feel
/// - [RangeMaintainingScrollPhysics] reduces jump when list content size changes
/// - Hides stretch/glow overscroll on web/desktop (often looks like a screen glitch)
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return AppScrollPhysics.platform();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (DesktopCanvas.isDesktopPlatform) {
      return child;
    }
    return super.buildOverscrollIndicator(context, child, details);
  }
}

/// Shared physics helpers for screens that set [ScrollView.physics] explicitly.
/// Prefer these over raw [BouncingScrollPhysics] so desktop/web stay smooth.
abstract final class AppScrollPhysics {
  static bool get _useClamping {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return false;
      case TargetPlatform.android:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return true;
    }
  }

  /// Default page / list scrolling.
  static ScrollPhysics platform() {
    if (_useClamping) {
      return const ClampingScrollPhysics(
        parent: RangeMaintainingScrollPhysics(),
      );
    }
    return const BouncingScrollPhysics(
      parent: RangeMaintainingScrollPhysics(),
    );
  }

  /// Pull-to-refresh and short lists that must always accept a drag.
  static ScrollPhysics alwaysScrollable() {
    return AlwaysScrollableScrollPhysics(parent: platform());
  }
}
