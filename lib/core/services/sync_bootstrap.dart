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
import 'local_user_data_guard.dart';

// Boots sync services after auth and forces a full server pull so mobile
// starts with complete local data. Also clears in-memory sync cursors on logout
// (local DB is wiped, but singletons otherwise keep lastSyncTime).
class SyncBootstrap {
  SyncBootstrap._();

  static bool _initialized = false;
  static bool _syncInFlight = false;

  // Wire listeners/timers once. Safe to call repeatedly.
  static void initializeServices() {
    if (_initialized) {
      debugPrint('[SyncBootstrap] Services already initialized');
      return;
    }

    debugPrint('[SyncBootstrap] Initializing sync services...');
    CustomerSyncService.instance.initialize();
    CustomerTransactionSyncService.instance.initialize();
    ProductSyncService.instance.initialize();
    SupplierSyncService.instance.initialize();
    CompanySyncService.instance.initialize();
    PurchaseSyncService.instance.initialize();
    PurchaseBatchSyncService.instance.initialize();
    BillSyncService.instance.initialize();
    EventOrderSyncService.instance.initialize();
    ExpenseSyncService.instance.initialize();
    _initialized = true;
    debugPrint('[SyncBootstrap] Sync services initialized');
  }

  // Call after AccessControlService.loadForCurrentUser() on login / session restore.
  // Initializes (if needed) then immediately pulls all entities from the server.
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
      await LocalUserDataGuard.ensureBoundToCurrentUser();

      // Clear cursors before wiring so the first initialize sync is a full pull.
      resetSyncCursors();
      initializeServices();

      // Let initialize-triggered syncs finish so forceFull is not skipped.
      await Future.delayed(const Duration(milliseconds: 1200));
      resetSyncCursors();

      await Future.wait([
        _safe(() => CustomerSyncService.instance.forceFullRefresh(), 'customers'),
        _safe(
          () => CustomerTransactionSyncService.instance.forceFullRefresh(),
          'customer_transactions',
        ),
        _safe(() => ProductSyncService.instance.forceFullRefresh(), 'products'),
        _safe(() => SupplierSyncService.instance.forceFullSync(), 'suppliers'),
        _safe(() => CompanySyncService.instance.forceFullSync(), 'companies'),
        _safe(() => PurchaseSyncService.instance.forceFullSync(), 'purchases'),
        _safe(
          () => PurchaseBatchSyncService.instance.forceFullSync(),
          'purchase_batches',
        ),
        _safe(() => BillSyncService.instance.forceFullRefresh(), 'bills'),
        _safe(
          () => EventOrderSyncService.instance.forceFullRefresh(),
          'event_orders',
        ),
        _safe(() => ExpenseSyncService.instance.forceFullSync(), 'expenses'),
      ]);

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

  static Future<void> _safe(
    Future<dynamic> Function() action,
    String label,
  ) async {
    try {
      await action();
      debugPrint('[SyncBootstrap] ✓ $label');
    } catch (e) {
      debugPrint('[SyncBootstrap] ✗ $label: $e');
    }
  }
}
