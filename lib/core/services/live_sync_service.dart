import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show TableInfo, TableUpdateQuery, UpdateKind, Variable;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../features/billing/data/services/bill_sync_service.dart';
import '../../features/company/data/services/company_sync_service.dart';
import '../../features/customer/data/services/customer_sync_service.dart';
import '../../features/customer/data/services/customer_transaction_sync_service.dart';
import '../../features/event_order/data/services/event_order_sync_service.dart';
import '../../features/expense/data/services/expense_sync_service.dart';
import '../../features/expense/offline/controllers/expense_offline_controller.dart';
import '../../features/inventory_management/data/services/purchase_batch_sync_service.dart';
import '../../features/inventory_management/data/services/purchase_sync_service.dart';
import '../../features/product/data/services/product_sync_service.dart';
import '../../features/supplier/data/services/supplier_sync_service.dart';
import '../database/app_database.dart';
import 'dashboard_refresh_service.dart';
import 'local_database.dart';
import 'sync_query_helper.dart';

/// Keeps every device (and the web app) in step with Firestore without any
/// paid service and without background polling or listeners.
///
///  * PUSH: any local write (Drift table update) triggers that entity's
///    `syncNow()` after a short debounce, so edits reach Firestore (and so the
///    web) within about a second. Failed pushes are retried with back-off and
///    then every [_slowRetry] while anything is still pending.
///  * PULL (screens): a screen that shows synced data registers the entities it
///    needs with [watchScreen] (see LiveRefreshMixin). While such a screen is
///    open and the app is in the foreground those entities are pulled every
///    [_screenRefreshEvery] (delta query) and checked for deletions.
///  * DELETES: a one-read `count()` check detects documents removed on another
///    device and removes the orphaned, already-synced local rows.
///  * RESUME: when the app returns to the foreground everything is re-synced.
///
/// Pulls/pushes still go through the existing, tested sync services; this class
/// only decides *when* to run them.
class LiveSyncService with WidgetsBindingObserver {
  LiveSyncService._();
  static final LiveSyncService instance = LiveSyncService._();

  static const Duration _localDebounce = Duration(milliseconds: 500);
  static const Duration _screenRefreshEvery = Duration(seconds: 45);
  static const Duration _slowRetry = Duration(seconds: 30);
  static const List<Duration> _retryBackoff = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
  ];

  final List<_LiveEntity> _entities = [];
  StreamSubscription<User?>? _authSub;
  Timer? _screenTimer;
  Timer? _startRetryTimer;
  bool _foreground = true;
  DateTime? _lastScreenRefresh;
  final Map<String, int> _watched = {};
  String? _uid;
  bool _observing = false;
  DateTime? _lastResume;
  int _startAttempts = 0;

  bool get isRunning => _uid != null && _entities.isNotEmpty;

  /// Safe to call repeatedly (login, splash, hot restart). Restarts only when
  /// the signed-in user changes.
  void start() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_uid == user.uid && _entities.isNotEmpty) return;

    if (!LocalDatabase.instance.isInitialized) {
      // Local DB is created during splash; try again shortly.
      if (_startAttempts++ < 20) {
        _startRetryTimer?.cancel();
        _startRetryTimer = Timer(const Duration(seconds: 1), start);
      }
      return;
    }
    _startAttempts = 0;

    stop();
    _uid = user.uid;
    SyncQueryHelper.beginSession(user.uid);

    _entities.addAll(_buildEntities());
    for (final entity in _entities) {
      _attachLocalWatcher(entity);
      _attachServiceListener(entity);
    }

    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((u) {
      if (u == null) stop();
    });
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    if (_watched.isNotEmpty) _ensureScreenTimer();

    // Let the initial full syncs finish first, then verify deletions.
    Timer(const Duration(seconds: 20), () => unawaited(_reconcileAll()));
    debugPrint('[LiveSync] Started for ${user.uid} (${_entities.length} entities)');
  }

  void stop() {
    _startRetryTimer?.cancel();
    _screenTimer?.cancel();
    _screenTimer = null;
    for (final entity in _entities) {
      entity.dispose();
    }
    _entities.clear();
    _uid = null;
  }

  // ───────────────────────── lifecycle ─────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed || _uid == null) return;
    final now = DateTime.now();
    if (_lastResume != null &&
        now.difference(_lastResume!) < const Duration(seconds: 10)) {
      return;
    }
    _lastResume = now;
    unawaited(_onResume());
  }

  Future<void> _onResume() async {
    final uid = _uid;
    if (uid == null) return;
    debugPrint('[LiveSync] App resumed - refreshing all entities');
    for (final entity in _entities) {
      unawaited(_runSync(entity));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    await _reconcileAll(force: true);
  }

  // ───────────────────────── remote → local (screens) ─────────────────────────

  /// Registers the entities (e.g. `customers`, `bills`) that the calling screen
  /// shows. While at least one screen is registered and the app is in the
  /// foreground they are refreshed every [_screenRefreshEvery]. Returns the
  /// function that unregisters the screen (call it from `dispose`).
  VoidCallback watchScreen(Set<String> entityNames) {
    for (final name in entityNames) {
      _watched[name] = (_watched[name] ?? 0) + 1;
    }
    _ensureScreenTimer();
    // Opening a screen shows fresh data right away (rate limited).
    unawaited(_refreshWatched(minGap: const Duration(seconds: 10)));

    var released = false;
    return () {
      if (released) return;
      released = true;
      for (final name in entityNames) {
        final left = (_watched[name] ?? 1) - 1;
        if (left <= 0) {
          _watched.remove(name);
        } else {
          _watched[name] = left;
        }
      }
      if (_watched.isEmpty) {
        _screenTimer?.cancel();
        _screenTimer = null;
      }
    };
  }

  void _ensureScreenTimer() {
    if (_screenTimer != null || _watched.isEmpty) return;
    _screenTimer = Timer.periodic(
      _screenRefreshEvery,
      (_) => unawaited(_refreshWatched()),
    );
  }

  Future<void> _refreshWatched({Duration? minGap}) async {
    if (_uid == null || !_foreground || _watched.isEmpty) return;
    final now = DateTime.now();
    if (minGap != null &&
        _lastScreenRefresh != null &&
        now.difference(_lastScreenRefresh!) < minGap) {
      return;
    }
    _lastScreenRefresh = now;

    final targets = [
      for (final entity in _entities)
        if (_watched.containsKey(entity.name)) entity,
    ];
    for (final entity in targets) {
      unawaited(_runSync(entity));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    // Deletions made on another device (cheap count() check, rate limited).
    Timer(const Duration(seconds: 3), () {
      for (final entity in targets) {
        if (_uid == null) return;
        unawaited(_reconcile(entity));
      }
    });
  }

  // ───────────────────────── local → remote ─────────────────────────

  void _attachLocalWatcher(_LiveEntity entity) {
    final db = LocalDatabase.instance.db;
    entity.tableSub = db
        .tableUpdates(TableUpdateQuery.onTable(entity.tableOf(db)))
        .listen((_) => _onLocalWrite(entity));
  }

  void _onLocalWrite(_LiveEntity entity) {
    // Writes made by the sync itself (marking synced / importing) must not
    // re-trigger a sync. User writes during a sync are caught in _afterSync.
    if (entity.isSyncing()) return;
    entity.retries = 0;
    entity.localTimer?.cancel();
    entity.localTimer = Timer(_localDebounce, () => unawaited(_pushIfPending(entity)));
  }

  Future<void> _pushIfPending(_LiveEntity entity) async {
    if (_uid == null || entity.isSyncing()) return;
    try {
      if (await entity.pending() <= 0) return;
    } catch (_) {
      return;
    }
    await _runSync(entity);
  }

  // ───────────────────────── sync plumbing ─────────────────────────

  Future<void> _runSync(_LiveEntity entity) async {
    if (_uid == null) return;
    if (entity.isSyncing()) {
      // Something changed while a sync was running: run once more afterwards.
      entity.rerun = true;
      return;
    }
    try {
      await entity.sync();
    } catch (e) {
      debugPrint('[LiveSync] ${entity.name} sync error: $e');
    }
  }

  void _attachServiceListener(_LiveEntity entity) {
    void onNotify() {
      final syncing = entity.isSyncing();
      if (syncing) {
        entity.wasSyncing = true;
      } else if (entity.wasSyncing) {
        entity.wasSyncing = false;
        unawaited(_afterSync(entity));
      }
    }

    entity.serviceListenable.addListener(onNotify);
    entity.detachService = () => entity.serviceListenable.removeListener(onNotify);
  }

  Future<void> _afterSync(_LiveEntity entity) async {
    if (_uid == null) return;
    if (entity.rerun) {
      entity.rerun = false;
      entity.retryTimer?.cancel();
      entity.retryTimer = Timer(
        const Duration(milliseconds: 300),
        () => unawaited(_runSync(entity)),
      );
      return;
    }
    int pending;
    try {
      pending = await entity.pending();
    } catch (_) {
      return;
    }
    if (pending <= 0) {
      entity.retries = 0;
      return;
    }
    // Local changes are still unsynced (offline, error, or edited mid-sync).
    final delay = entity.retries < _retryBackoff.length
        ? _retryBackoff[entity.retries++]
        : _slowRetry;
    entity.retryTimer?.cancel();
    entity.retryTimer = Timer(delay, () => unawaited(_pushIfPending(entity)));
  }

  // ───────────────────────── deletes made elsewhere ─────────────────────────

  Future<void> _reconcileAll({bool force = false}) async {
    for (final entity in List<_LiveEntity>.of(_entities)) {
      if (_uid == null) return;
      await _reconcile(entity, force: force);
    }
  }

  /// Cheap check: compares the server document count with the local number of
  /// server-linked rows. Only when the server has FEWER documents (something
  /// was deleted on another device) do we list ids and remove local orphans.
  Future<void> _reconcile(_LiveEntity entity, {bool force = false}) async {
    final uid = _uid;
    if (uid == null || entity.reconciling) return;
    final now = DateTime.now();
    if (!force &&
        entity.lastCountCheck != null &&
        now.difference(entity.lastCountCheck!) < const Duration(seconds: 20)) {
      return;
    }
    entity.reconciling = true;
    entity.lastCountCheck = now;
    try {
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(entity.collection);
      final aggregate = await col.count().get();
      final serverCount = aggregate.count;
      if (serverCount == null) return;

      final db = LocalDatabase.instance.db;
      final countRow = await db
          .customSelect(
            'SELECT COUNT(*) AS c FROM ${entity.table} WHERE ${entity.liveWhere}',
          )
          .getSingle();
      final localCount = countRow.read<int>('c');

      if (serverCount == localCount) {
        entity.idFetchBackoff = 1;
        return;
      }
      if (serverCount > localCount) {
        // Missing locally: a delta pull will fetch it.
        unawaited(_runSync(entity));
        return;
      }

      // Server has fewer documents than we hold => deleted on another device.
      final minGap = Duration(minutes: 5 * entity.idFetchBackoff);
      if (!force &&
          entity.lastIdFetch != null &&
          now.difference(entity.lastIdFetch!) < minGap) {
        return;
      }
      entity.lastIdFetch = now;

      final snapshot = await col.get(const GetOptions(source: Source.server));
      if (snapshot.docs.length != serverCount) return; // changed meanwhile
      final serverIds = snapshot.docs.map((d) => d.id).toSet();

      final localRows = await db
          .customSelect(
            'SELECT id, server_id FROM ${entity.table} '
            'WHERE ${entity.syncedWhere}',
          )
          .get();
      final orphanIds = <int>[
        for (final row in localRows)
          if (!serverIds.contains(row.read<String>('server_id')))
            row.read<int>('id'),
      ];

      if (orphanIds.isEmpty) {
        // Mismatch is benign (e.g. duplicates); back off so we do not re-list
        // the whole collection on every check.
        entity.idFetchBackoff = (entity.idFetchBackoff * 2).clamp(1, 72).toInt();
        return;
      }
      final limit = localRows.length ~/ 2 > 20 ? localRows.length ~/ 2 : 20;
      if (orphanIds.length > limit) {
        debugPrint(
          '[LiveSync] ${entity.name}: refusing to remove ${orphanIds.length} '
          'of ${localRows.length} rows (safety limit)',
        );
        entity.idFetchBackoff = (entity.idFetchBackoff * 2).clamp(1, 72).toInt();
        return;
      }

      const chunkSize = 400;
      for (var i = 0; i < orphanIds.length; i += chunkSize) {
        final chunk = orphanIds.sublist(
          i,
          i + chunkSize > orphanIds.length ? orphanIds.length : i + chunkSize,
        );
        final placeholders = List.filled(chunk.length, '?').join(',');
        await db.customUpdate(
          'DELETE FROM ${entity.table} WHERE id IN ($placeholders)',
          variables: [for (final id in chunk) Variable.withInt(id)],
          updates: {entity.tableOf(db)},
          updateKind: UpdateKind.delete,
        );
      }
      entity.idFetchBackoff = 1;
      debugPrint(
        '[LiveSync] ${entity.name}: removed ${orphanIds.length} record(s) '
        'deleted on another device',
      );
      DashboardRefreshService.instance.notifyDataChanged(entity.changeType);
    } catch (e) {
      debugPrint('[LiveSync] ${entity.name} reconcile skipped: $e');
    } finally {
      entity.reconciling = false;
    }
  }

  // ───────────────────────── registry ─────────────────────────

  static const String _liveByStatus = 'server_id IS NOT NULL AND sync_status != 2';
  static const String _syncedByStatus = 'server_id IS NOT NULL AND sync_status = 3';

  List<_LiveEntity> _buildEntities() {
    return [
      _LiveEntity(
        name: 'customers',
        collection: 'customers',
        table: 'customers',
        liveWhere: 'server_id IS NOT NULL AND is_deleted = 0',
        syncedWhere:
            'server_id IS NOT NULL AND is_synced = 1 AND is_deleted = 0',
        tableOf: (db) => db.customerRecords,
        serviceListenable: CustomerSyncService.instance,
        isSyncing: () => CustomerSyncService.instance.isSyncing,
        sync: () => CustomerSyncService.instance.syncNow(),
        pending: () => CustomerSyncService.instance.getPendingSyncCount(),
        changeType: DataChangeType.customer,
      ),
      _LiveEntity(
        name: 'customer_transactions',
        collection: 'customer_transactions',
        table: 'customer_transactions',
        cursorField: 'createdAt',
        liveWhere: _liveByStatus,
        syncedWhere: _syncedByStatus,
        tableOf: (db) => db.customerTransactionRecords,
        serviceListenable: CustomerTransactionSyncService.instance,
        isSyncing: () => CustomerTransactionSyncService.instance.isSyncing,
        sync: () => CustomerTransactionSyncService.instance.syncNow(),
        pending: () =>
            CustomerTransactionSyncService.instance.getPendingSyncCount(),
        changeType: DataChangeType.customer,
      ),
      _LiveEntity(
        name: 'suppliers',
        collection: 'suppliers',
        table: 'suppliers',
        liveWhere: _liveByStatus,
        syncedWhere: _syncedByStatus,
        tableOf: (db) => db.supplierRecords,
        serviceListenable: SupplierSyncService.instance,
        isSyncing: () => SupplierSyncService.instance.isSyncing,
        sync: () => SupplierSyncService.instance.syncNow(),
        pending: () => SupplierSyncService.instance.getPendingSyncCount(),
        changeType: DataChangeType.supplier,
      ),
      _LiveEntity(
        name: 'companies',
        collection: 'companies',
        table: 'companies',
        liveWhere: _liveByStatus,
        syncedWhere: _syncedByStatus,
        tableOf: (db) => db.companyRecords,
        serviceListenable: CompanySyncService.instance,
        isSyncing: () => CompanySyncService.instance.isSyncing,
        sync: () => CompanySyncService.instance.syncNow(),
        pending: () => CompanySyncService.instance.getPendingSyncCount(),
        changeType: DataChangeType.company,
      ),
      _LiveEntity(
        name: 'products',
        collection: 'products',
        table: 'products',
        liveWhere: _liveByStatus,
        syncedWhere: _syncedByStatus,
        tableOf: (db) => db.productRecords,
        serviceListenable: ProductSyncService.instance,
        isSyncing: () => ProductSyncService.instance.isSyncing,
        sync: () => ProductSyncService.instance.syncNow(),
        pending: () => ProductSyncService.instance.getPendingSyncCount(),
        changeType: DataChangeType.product,
      ),
      _LiveEntity(
        name: 'purchases',
        collection: 'purchases',
        table: 'purchases',
        liveWhere: _liveByStatus,
        syncedWhere: _syncedByStatus,
        tableOf: (db) => db.purchaseRecords,
        serviceListenable: PurchaseSyncService.instance,
        isSyncing: () => PurchaseSyncService.instance.isSyncing,
        sync: () => PurchaseSyncService.instance.syncNow(),
        pending: () => PurchaseSyncService.instance.getPendingSyncCount(),
        changeType: DataChangeType.purchase,
      ),
      _LiveEntity(
        name: 'purchaseBatches',
        collection: 'purchaseBatches',
        table: 'purchase_batches',
        liveWhere: _liveByStatus,
        syncedWhere: _syncedByStatus,
        tableOf: (db) => db.purchaseBatchRecords,
        serviceListenable: PurchaseBatchSyncService.instance,
        isSyncing: () => PurchaseBatchSyncService.instance.isSyncing,
        sync: () => PurchaseBatchSyncService.instance.syncNow(),
        pending: () => PurchaseBatchSyncService.instance.getPendingSyncCount(),
        changeType: DataChangeType.purchase,
      ),
      _LiveEntity(
        name: 'bills',
        collection: 'bills',
        table: 'bills',
        liveWhere: _liveByStatus,
        syncedWhere: _syncedByStatus,
        tableOf: (db) => db.billRecords,
        serviceListenable: BillSyncService.instance,
        isSyncing: () => BillSyncService.instance.isSyncing,
        sync: () => BillSyncService.instance.syncNow(),
        pending: () => BillSyncService.instance.getPendingSyncCount(),
        changeType: DataChangeType.bill,
      ),
      _LiveEntity(
        name: 'eventOrders',
        collection: 'eventOrders',
        table: 'event_orders',
        liveWhere: _liveByStatus,
        syncedWhere: _syncedByStatus,
        tableOf: (db) => db.eventOrderRecords,
        serviceListenable: EventOrderSyncService.instance,
        isSyncing: () => EventOrderSyncService.instance.isSyncing,
        sync: () => EventOrderSyncService.instance.syncNow(),
        pending: () => EventOrderSyncService.instance.getPendingSyncCount(),
        changeType: DataChangeType.eventOrder,
      ),
      _LiveEntity(
        name: 'expenses',
        collection: 'expenses',
        table: 'expenses',
        liveWhere: _liveByStatus,
        syncedWhere: _syncedByStatus,
        tableOf: (db) => db.expenseRecords,
        serviceListenable: ExpenseSyncService.instance,
        isSyncing: () => ExpenseSyncService.instance.isSyncing,
        sync: () => ExpenseSyncService.instance.syncNow(),
        pending: () async =>
            (await ExpenseOfflineController.instance.getPendingSyncExpenses())
                .length,
        changeType: null,
      ),
    ];
  }
}

class _LiveEntity {
  _LiveEntity({
    required this.name,
    required this.collection,
    required this.table,
    required this.liveWhere,
    required this.syncedWhere,
    required this.tableOf,
    required this.serviceListenable,
    required this.isSyncing,
    required Future<Object?> Function() sync,
    required this.pending,
    required this.changeType,
    this.cursorField = 'updatedAt',
  }) : _sync = sync;

  final String name;
  final String collection;
  final String table;

  /// Firestore field used as the change cursor.
  final String cursorField;

  /// SQL predicate: rows linked to a server document and not pending delete.
  final String liveWhere;

  /// SQL predicate: rows linked to a server document with nothing to push.
  final String syncedWhere;

  final TableInfo Function(AppDatabase db) tableOf;
  final Listenable serviceListenable;
  final bool Function() isSyncing;
  final Future<Object?> Function() _sync;
  final Future<int> Function() pending;
  final DataChangeType? changeType;

  Future<void> sync() async {
    await _sync();
  }

  // Mutable runtime state.
  StreamSubscription<dynamic>? tableSub;
  VoidCallback? detachService;
  Timer? localTimer;
  Timer? retryTimer;
  int retries = 0;
  bool wasSyncing = false;
  bool rerun = false;
  bool reconciling = false;
  DateTime? lastCountCheck;
  DateTime? lastIdFetch;
  int idFetchBackoff = 1;

  void dispose() {
    tableSub?.cancel();
    tableSub = null;
    detachService?.call();
    detachService = null;
    localTimer?.cancel();
    retryTimer?.cancel();
  }
}
