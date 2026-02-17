import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/purchase_batch_offline_controller.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import 'purchase_batch_api_service.dart';

/// Sync status for tracking sync state
enum PurchaseBatchSyncServiceStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a sync operation
class PurchaseBatchSyncResult {
  final bool success;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  PurchaseBatchSyncResult({
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

/// Service for background synchronization of Purchase Batch data
/// Implements delta sync - only syncs NEW, UPDATED, or DELETED batches
class PurchaseBatchSyncService extends ChangeNotifier {
  static PurchaseBatchSyncService? _instance;

  final PurchaseBatchOfflineController _offlineController;
  final PurchaseBatchApiService _apiService;
  final Connectivity _connectivity;

  PurchaseBatchSyncServiceStatus _status = PurchaseBatchSyncServiceStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  Timer? _connectivityDebounceTimer;
  
  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  PurchaseBatchSyncService._({
    PurchaseBatchOfflineController? offlineController,
    PurchaseBatchApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? PurchaseBatchOfflineController.instance,
        _apiService = apiService ?? PurchaseBatchApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static PurchaseBatchSyncService get instance {
    _instance ??= PurchaseBatchSyncService._();
    return _instance!;
  }

  /// Current sync status
  PurchaseBatchSyncServiceStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == PurchaseBatchSyncServiceStatus.syncing;

  /// Initialize the sync service
  void initialize() {
    debugPrint('[PurchaseBatchSync] Initializing...');
    
    // Listen for connectivity changes with debouncing
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_isConnected(results)) {
        // Cancel any pending debounce timer
        _connectivityDebounceTimer?.cancel();
        
        // Debounce to prevent multiple syncs when connectivity changes rapidly
        _connectivityDebounceTimer = Timer(const Duration(seconds: 3), () {
          if (!_isSyncing) {
            debugPrint('[PurchaseBatchSync] Network available - triggering sync');
            syncNow();
          }
        });
      }
    });

    // Set up periodic sync (every 3 minutes when online)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkAndSync();
    });
    
    // Initial sync
    _initialSync();
    
    debugPrint('[PurchaseBatchSync] Initialized');
  }

  /// Perform initial sync - download all batches if local database is empty
  Future<void> _initialSync() async {
    try {
      final localBatches = await _offlineController.getAllBatches(includeConsumed: true);
      debugPrint('[PurchaseBatchSync] Initial sync check: ${localBatches.length} local batches');
      
      // First sync any pending local changes
      await syncNow();
      
      // Then check if we need to download from server
      if (localBatches.isEmpty) {
        debugPrint('[PurchaseBatchSync] No local batches, downloading from server...');
        final results = await _connectivity.checkConnectivity();
        if (_isConnected(results) && _apiService.isAuthenticated) {
          await forceFullSync();
        }
      }
    } catch (e) {
      debugPrint('[PurchaseBatchSync] Initial sync failed: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _connectivityDebounceTimer?.cancel();
    super.dispose();
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => 
      r == ConnectivityResult.wifi || 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet
    );
  }

  Future<void> _checkAndSync() async {
    final results = await _connectivity.checkConnectivity();
    if (_isConnected(results)) {
      await syncNow();
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Perform delta sync - only sync changed records
  Future<PurchaseBatchSyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('[PurchaseBatchSync] Already syncing, skipping...');
      return PurchaseBatchSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint('[PurchaseBatchSync] User not authenticated, skipping sync');
      return PurchaseBatchSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    _status = PurchaseBatchSyncServiceStatus.syncing;
    _lastError = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    int createdCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;
    int failedCount = 0;

    try {
      debugPrint('[PurchaseBatchSync] Starting delta sync...');

      // Get all batches that need syncing
      final pendingBatches = await _offlineController.getBatchesNeedingSync();
      debugPrint('[PurchaseBatchSync] Found ${pendingBatches.length} batches to sync');

      for (final batch in pendingBatches) {
        try {
          switch (batch.syncStatus) {
            case BatchSyncStatus.newRecord:
              // Create on server
              final serverId = await _apiService.createBatch(batch.toSyncPayload());
              await _offlineController.markAsSynced(batch.id, serverId);
              createdCount++;
              debugPrint('[PurchaseBatchSync] Created: ${batch.productName} -> $serverId');
              break;

            case BatchSyncStatus.updated:
              // Update on server (needs serverId)
              if (batch.serverId != null) {
                await _apiService.updateBatch(batch.serverId!, batch.toSyncPayload());
                await _offlineController.markAsSynced(batch.id, batch.serverId!);
                updatedCount++;
                debugPrint('[PurchaseBatchSync] Updated: ${batch.productName}');
              } else {
                // No serverId, treat as new
                final serverId = await _apiService.createBatch(batch.toSyncPayload());
                await _offlineController.markAsSynced(batch.id, serverId);
                createdCount++;
              }
              break;

            case BatchSyncStatus.deleted:
              // Delete from server (if it exists there)
              if (batch.serverId != null) {
                await _apiService.deleteBatch(batch.serverId!);
              }
              // Permanently remove from local DB
              await _offlineController.permanentlyDelete(batch.id);
              deletedCount++;
              debugPrint('[PurchaseBatchSync] Deleted: ${batch.productName}');
              break;

            case BatchSyncStatus.synced:
              // Already synced, skip
              break;
          }
        } catch (e) {
          debugPrint('[PurchaseBatchSync] Failed to sync ${batch.productName}: $e');
          failedCount++;
        }
      }

      stopwatch.stop();
      _lastSyncTime = DateTime.now();
      _status = PurchaseBatchSyncServiceStatus.success;
      notifyListeners();

      final result = PurchaseBatchSyncResult(
        success: true,
        createdCount: createdCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        failedCount: failedCount,
        duration: stopwatch.elapsed,
      );

      debugPrint('[PurchaseBatchSync] $result');
      return result;

    } catch (e) {
      stopwatch.stop();
      _lastError = e.toString();
      _status = PurchaseBatchSyncServiceStatus.failed;
      notifyListeners();

      debugPrint('[PurchaseBatchSync] Sync failed: $e');
      return PurchaseBatchSyncResult(
        success: false,
        errorMessage: e.toString(),
        failedCount: failedCount,
        duration: stopwatch.elapsed,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Force a full sync (re-download all from server)
  Future<PurchaseBatchSyncResult> forceFullSync() async {
    // First upload any local changes
    await syncNow();
    
    // Then download all from server
    final serverBatches = await _apiService.getBatches();
    await _offlineController.importFromServer(serverBatches);
    
    return PurchaseBatchSyncResult(
      success: true,
      downloadedCount: serverBatches.length,
      duration: Duration.zero,
    );
  }

  /// Get count of pending syncs
  Future<int> getPendingSyncCount() async {
    final pending = await _offlineController.getBatchesNeedingSync();
    return pending.length;
  }

  /// Trigger immediate sync (for manual refresh)
  Future<void> triggerSync() async {
    if (!_isSyncing) {
      await syncNow();
    }
  }
}
