import 'package:flutter/foundation.dart';

import '../../features/billing/data/services/bill_sync_service.dart';
import '../../features/company/data/services/company_sync_service.dart';
import '../../features/customer/data/services/customer_sync_service.dart';
import '../../features/customer/data/services/customer_transaction_sync_service.dart';
import '../../features/event_order/data/services/event_order_sync_service.dart';
import '../../features/expense/data/services/expense_sync_service.dart';
import '../../features/inventory_management/data/services/purchase_batch_sync_service.dart';
import '../../features/inventory_management/data/services/purchase_sync_service.dart';
import '../../features/product/data/services/product_sync_service.dart';
import '../../features/supplier/data/services/supplier_sync_service.dart';
import 'dashboard_refresh_service.dart';
import 'local_user_data_guard.dart';

// Boots sync services after auth and forces a full server pull so desktop/mobile
// start with complete local data. Also clears in-memory sync cursors on logout
// (local DB is wiped, but singletons otherwise keep lastSyncTime).
class SyncBootstrap {
  SyncBootstrap._();

  static bool _initialized = false;
  static bool _syncInFlight = false;

  // Wire listeners/timers once. Safe to call repeatedly.
  // When [runInitialSync] is false, services only wire listeners — used by
  // startAfterLogin so forceFullRefresh is not raced by initialize syncs.
  static void initializeServices({bool runInitialSync = true}) {
    if (_initialized) {
      debugPrint('[SyncBootstrap] Services already initialized');
      return;
    }

    debugPrint('[SyncBootstrap] Initializing sync services...');
    CustomerSyncService.instance.initialize(runInitialSync: runInitialSync);
    CustomerTransactionSyncService.instance.initialize(
      runInitialSync: runInitialSync,
    );
    ProductSyncService.instance.initialize(runInitialSync: runInitialSync);
    SupplierSyncService.instance.initialize(runInitialSync: runInitialSync);
    CompanySyncService.instance.initialize(runInitialSync: runInitialSync);
    PurchaseSyncService.instance.initialize(runInitialSync: runInitialSync);
    PurchaseBatchSyncService.instance.initialize(
      runInitialSync: runInitialSync,
    );
    BillSyncService.instance.initialize(runInitialSync: runInitialSync);
    EventOrderSyncService.instance.initialize(runInitialSync: runInitialSync);
    ExpenseSyncService.instance.initialize(runInitialSync: runInitialSync);
    _initialized = true;
    debugPrint('[SyncBootstrap] Sync services initialized');
  }

  // Call after AccessControlService.loadForCurrentUser() on login / session restore.
  // Prefer awaiting SubscriptionService.isSubscriptionValid() first so Cloud
  // Functions can write trialExpiresAt before Firestore rules gate reads.
  // Safe to fire-and-forget so navigation is not blocked.
  static Future<void> startAfterLogin() async {
    if (_syncInFlight) {
      debugPrint('[SyncBootstrap] Post-login sync already running');
      return;
    }

    _syncInFlight = true;
    debugPrint('[SyncBootstrap] Starting full post-login sync...');

    try {
      // Wipe previous account's offline data before pulling this user's data.
      // (Wipe already clears sync cursors via LocalUserDataGuard.)
      await LocalUserDataGuard.ensureBoundToCurrentUser();

      // Wire listeners only — no competing initialize syncs.
      initializeServices(runInitialSync: false);

      // If services were already wired at app boot, wait for any in-flight
      // sync to finish. Never resetSyncCursors mid-flight (that cleared
      // _isSyncing and made forceFullRefresh race or no-op on macOS).
      await _waitForSyncIdle();

      final jobs = <String, Future<dynamic> Function()>{
        'customers': () => CustomerSyncService.instance.forceFullRefresh(),
        'customer_transactions': () =>
            CustomerTransactionSyncService.instance.forceFullRefresh(),
        'products': () => ProductSyncService.instance.forceFullRefresh(),
        'suppliers': () => SupplierSyncService.instance.forceFullSync(),
        'companies': () => CompanySyncService.instance.forceFullSync(),
        'purchases': () => PurchaseSyncService.instance.forceFullSync(),
        'purchase_batches': () =>
            PurchaseBatchSyncService.instance.forceFullSync(),
        'bills': () => BillSyncService.instance.forceFullRefresh(),
        'event_orders': () => EventOrderSyncService.instance.forceFullRefresh(),
        'expenses': () => ExpenseSyncService.instance.forceFullSync(),
      };

      final labels = jobs.keys.toList();
      final outcomes = await Future.wait(
        labels.map((label) => _safe(jobs[label]!, label)),
      );

      // One retry for soft failures (entitlement propagation / brief offline).
      final retryLabels = <String>[];
      for (var i = 0; i < labels.length; i++) {
        if (!outcomes[i]) retryLabels.add(labels[i]);
      }
      if (retryLabels.isNotEmpty) {
        debugPrint(
          '[SyncBootstrap] Retrying ${retryLabels.length} failed sync(s)...',
        );
        await Future.delayed(const Duration(seconds: 2));
        await Future.wait(
          retryLabels.map((label) => _safe(jobs[label]!, label)),
        );
      }

      // Always nudge UI — even empty shops need dashboards to leave "loading".
      DashboardRefreshService.instance.notifyDataChanged();

      debugPrint('[SyncBootstrap] Post-login sync finished');
    } finally {
      _syncInFlight = false;
    }
  }

  // Clear in-memory sync state when local data is wiped (logout / session expiry).
  static void resetOnLogout() {
    debugPrint('[SyncBootstrap] Resetting sync state for logout');
    resetSyncCursors();
    _syncInFlight = false;
    // Fire-and-forget binding clear; logout already awaits DB wipe.
    LocalUserDataGuard.clearBinding();
  }

  static void resetSyncCursors() {
    CustomerSyncService.instance.resetSyncState();
    CustomerTransactionSyncService.instance.resetSyncState();
    ProductSyncService.instance.resetSyncState();
    SupplierSyncService.instance.resetSyncState();
    CompanySyncService.instance.resetSyncState();
    PurchaseSyncService.instance.resetSyncState();
    PurchaseBatchSyncService.instance.resetSyncState();
    BillSyncService.instance.resetSyncState();
    EventOrderSyncService.instance.resetSyncState();
    ExpenseSyncService.instance.resetSyncState();
  }

  static bool _anySyncing() {
    return CustomerSyncService.instance.isSyncing ||
        CustomerTransactionSyncService.instance.isSyncing ||
        ProductSyncService.instance.isSyncing ||
        SupplierSyncService.instance.isSyncing ||
        CompanySyncService.instance.isSyncing ||
        PurchaseSyncService.instance.isSyncing ||
        PurchaseBatchSyncService.instance.isSyncing ||
        BillSyncService.instance.isSyncing ||
        EventOrderSyncService.instance.isSyncing ||
        ExpenseSyncService.instance.isSyncing;
  }

  static Future<void> _waitForSyncIdle({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (_anySyncing() && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  static Future<bool> _safe(
    Future<dynamic> Function() action,
    String label,
  ) async {
    try {
      final result = await action();
      if (_isSuccess(result)) {
        debugPrint('[SyncBootstrap] ✓ $label');
        return true;
      }
      final err = _errorMessage(result) ?? 'success=false';
      debugPrint('[SyncBootstrap] ✗ $label: $err');
      return false;
    } catch (e) {
      debugPrint('[SyncBootstrap] ✗ $label: $e');
      return false;
    }
  }

  static bool _isSuccess(dynamic result) {
    // void / null results (expense forceFullSync) — assume ok if no throw.
    if (result == null) return true;
    try {
      final success = (result as dynamic).success;
      if (success is bool) return success;
    } catch (_) {}
    return true;
  }

  static String? _errorMessage(dynamic result) {
    if (result == null) return null;
    try {
      final msg = (result as dynamic).errorMessage;
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return null;
  }
}
