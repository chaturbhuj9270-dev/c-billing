import 'package:flutter/widgets.dart';

import 'live_sync_service.dart';

/// Keeps a screen's data fresh while it is open.
///
/// While the screen is mounted and the app is in the foreground, the entities
/// returned by [liveRefreshEntities] are pulled from Firestore about every
/// 45 seconds (cheap incremental query) and checked for deletions made on other
/// devices. The screen keeps reading from the local database, so it updates
/// through its existing streams. Nothing runs when the screen is closed.
///
/// Entity names: customers, customer_transactions, suppliers, companies,
/// products, purchases, purchaseBatches, bills, eventOrders, expenses.
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with LiveRefreshMixin<MyPage> {
///   @override
///   Set<String> get liveRefreshEntities => const {'customers'};
/// }
/// ```
mixin LiveRefreshMixin<T extends StatefulWidget> on State<T> {
  Set<String> get liveRefreshEntities;

  VoidCallback? _releaseLiveRefresh;

  @override
  void initState() {
    super.initState();
    _releaseLiveRefresh = LiveSyncService.instance.watchScreen(
      liveRefreshEntities,
    );
  }

  @override
  void dispose() {
    _releaseLiveRefresh?.call();
    _releaseLiveRefresh = null;
    super.dispose();
  }
}
