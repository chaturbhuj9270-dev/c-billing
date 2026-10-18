import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Web, Windows, and macOS share the wide app canvas. Phones stay on their own layout.
class DesktopCanvas {
  static bool get isDesktopPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  static bool wide(BuildContext context) =>
      isDesktopPlatform && MediaQuery.sizeOf(context).width >= 980;
}
