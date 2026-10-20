import 'package:flutter/material.dart';

import '../../../../common_widgets/glass_bottom_sheet.dart';

// Switches the web app's content pane without pushing a new route.
class WebShell {
  static const int dashboard = 0;
  static const int customers = 1;
  static const int billing = 2;
  static const int availability = 3;
  static const int purchase = 4;
  static const int invoices = 5;
  static const int products = 6;
  static const int suppliers = 7;
  static const int companies = 8;
  static const int purchaseReturn = 9;
  static const int events = 10;
  static const int quotations = 11;
  static const int barcode = 12;
  static const int expenses = 13;
  static const int shop = 14;
  static const int profile = 15;
  static const int password = 16;
  static const int employees = 17;
  static const int count = 18;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void Function(int index)? _select;

  static void register(void Function(int index)? select) {
    _select = select;
  }

  // Returns true when the web shell handled the section.
  static bool open(int index) {
    final select = _select;
    if (select == null) return false;
    popToRoot();
    select(index);
    return true;
  }

  // Close any page opened inside the web content area.
  static void popToRoot() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.popUntil((route) => route.isFirst);
  }

  // Open [page] in the right-hand drawer. The sidebar stays put.
  static Future<T?> push<T>(Widget page) {
    final context = navigatorKey.currentContext;
    if (context == null) return Future<T?>.value();
    return showAppPage<T>(context, page);
  }
}

class WebShellRouteObserver extends NavigatorObserver {
  WebShellRouteObserver(this.onChanged);

  final VoidCallback onChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChanged();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChanged();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChanged();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onChanged();
}

// Swaps web content in place, without a route slide.
class InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
