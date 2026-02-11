import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/bill_offline_controller.dart';
import '../../offline/entities/bill_entity.dart';
import 'bill_api_service.dart';

/// Sync status for tracking sync state
enum BillSyncServiceStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a sync operation
class BillSyncResult {
  final bool success;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  BillSyncResult({
    required this.success,
    this.createdCount = 0,
    this.updatedCount = 0,
    this.deletedCount = 0,
    this.downloadedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    required this.duration,
  });

  int get totalSynced => createdCount + updatedCount + deletedCount;

  @override
  String toString() {
    if (success) {
      return 'Sync completed: ↑$createdCount new, ↑$updatedCount updated, ↑$deletedCount deleted, ↓$downloadedCount downloaded';
    }
    return 'Sync failed: $errorMessage';
  }
}

/// Service for background synchronization of Bill data
/// Implements delta sync - only syncs NEW, UPDATED, or DELETED bills
class BillSyncService extends ChangeNotifier {
  static BillSyncService? _instance;

  final BillOfflineController _offlineController;
  final BillApiService _apiService;
  final Connectivity _connectivity;

  BillSyncServiceStatus _status = BillSyncServiceStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  
  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  BillSyncService._({
    BillOfflineController? offlineController,
    BillApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? BillOfflineController.instance,
        _apiService = apiService ?? BillApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static BillSyncService get instance {
    _instance ??= BillSyncService._();
    return _instance!;
  }

  /// Current sync status
  BillSyncServiceStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == BillSyncServiceStatus.syncing;

  /// Initialize the sync service
  void initialize() {
    debugPrint('[BillSync] Initializing...');
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_isConnected(results)) {
        debugPrint('[BillSync] Network available - triggering sync');
        syncNow();
      }
    });

    // Start periodic sync (every 3 minutes)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      syncNow();
    });

    // Initial sync
    syncNow();
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }

  /// Check if connected to network
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => 
      r == ConnectivityResult.wifi || 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet
    );
  }

  /// Trigger immediate sync
  Future<BillSyncResult> syncNow() async {
    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint('[BillSync] User not authenticated, skipping sync');
      return BillSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    // Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('[BillSync] Sync already in progress, skipping');
      return BillSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();
    _status = BillSyncServiceStatus.syncing;
    _lastError = null;
    notifyListeners();

    int created = 0;
    int updated = 0;
    int deleted = 0;
    int downloaded = 0;
    int failed = 0;

    try {
      // Check connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      if (!_isConnected(connectivityResults)) {
        throw Exception('No network connection');
      }

      // Step 1: Push local changes to server
      final unsyncedBills = await _offlineController.getUnsyncedBills();
      debugPrint('[BillSync] Found ${unsyncedBills.length} unsynced bills');

      for (final bill in unsyncedBills) {
        try {
          switch (bill.syncStatus) {
            case BillSyncStatus.newRecord:
              // Create on server
              final serverId = await _apiService.createBill(bill.toSyncPayload());
              await _offlineController.markAsSynced(bill.id, serverId);
              created++;
              break;

            case BillSyncStatus.updated:
              // Update on server
              if (bill.serverId != null) {
                await _apiService.updateBill(bill.serverId!, bill.toSyncPayload());
                await _offlineController.markAsSynced(bill.id, bill.serverId!);
                updated++;
              }
              break;

            case BillSyncStatus.deleted:
              // Delete from server, then remove locally
              if (bill.serverId != null) {
                await _apiService.deleteBill(bill.serverId!);
              }
              await _offlineController.removeAfterServerDelete(bill.id);
              deleted++;
              break;

            case BillSyncStatus.synced:
              // Already synced, nothing to do
              break;
          }
        } catch (e) {
          debugPrint('[BillSync] Failed to sync bill ${bill.id}: $e');
          failed++;
        }
      }

      // Step 2: Pull changes from server
      downloaded = await _pullServerChanges();

      _status = BillSyncServiceStatus.success;
      _lastSyncTime = DateTime.now();
      notifyListeners();

      final result = BillSyncResult(
        success: true,
        createdCount: created,
        updatedCount: updated,
        deletedCount: deleted,
        downloadedCount: downloaded,
        failedCount: failed,
        duration: DateTime.now().difference(startTime),
      );

      debugPrint('[BillSync] $result');
      return result;

    } catch (e) {
      _status = BillSyncServiceStatus.failed;
      _lastError = e.toString();
      notifyListeners();

      debugPrint('[BillSync] Sync failed: $e');
      return BillSyncResult(
        success: false,
        createdCount: created,
        updatedCount: updated,
        deletedCount: deleted,
        downloadedCount: downloaded,
        failedCount: failed,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Pull changes from server
  Future<int> _pullServerChanges() async {
    try {
      // Get last sync time for incremental sync
      final lastSync = _lastSyncTime;
      
      // Fetch bills from server (with optional since parameter)
      final serverBills = await _apiService.getBills(
        updatedSince: lastSync,
      );

      debugPrint('[BillSync] Received ${serverBills.length} bills from server');

      if (serverBills.isNotEmpty) {
        await _offlineController.importFromServer(serverBills);
        return serverBills.length;
      }

      return 0;
    } catch (e) {
      debugPrint('[BillSync] Failed to pull server changes: $e');
      rethrow;
    }
  }

  /// Force full refresh from server
  Future<BillSyncResult> forceFullRefresh() async {
    if (_isSyncing) {
      return BillSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();
    _status = BillSyncServiceStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // Get all bills from server
      final serverBills = await _apiService.getBills();
      
      // Import all
      await _offlineController.importFromServer(serverBills);

      _status = BillSyncServiceStatus.success;
      _lastSyncTime = DateTime.now();
      notifyListeners();

      return BillSyncResult(
        success: true,
        downloadedCount: serverBills.length,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      _status = BillSyncServiceStatus.failed;
      _lastError = e.toString();
      notifyListeners();

      return BillSyncResult(
        success: false,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Get number of pending sync items
  Future<int> getPendingSyncCount() async {
    return await _offlineController.getUnsyncedCount();
  }
}
