import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/product_batch_offline_controller.dart';
import '../../offline/entities/product_batch_entity.dart';
import 'product_batch_api_service.dart';

/// Sync status for tracking sync state
enum BatchSyncServiceStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a batch sync operation
class BatchSyncResult {
  final bool success;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  BatchSyncResult({
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
      return 'BatchSync completed: ↑$createdCount new, ↑$updatedCount updated, ↑$deletedCount deleted, ↓$downloadedCount downloaded';
    }
    return 'BatchSync failed: $errorMessage';
  }
}

/// Service for background synchronization of Product Batch data
/// Implements delta sync - only syncs NEW, UPDATED, or DELETED batches
class ProductBatchSyncService extends ChangeNotifier {
  static ProductBatchSyncService? _instance;

  final ProductBatchOfflineController _offlineController;
  final ProductBatchApiService _apiService;
  final Connectivity _connectivity;

  BatchSyncServiceStatus _status = BatchSyncServiceStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  Timer? _connectivityDebounceTimer;

  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  ProductBatchSyncService._({
    ProductBatchOfflineController? offlineController,
    ProductBatchApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? ProductBatchOfflineController.instance,
        _apiService = apiService ?? ProductBatchApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static ProductBatchSyncService get instance {
    _instance ??= ProductBatchSyncService._();
    return _instance!;
  }

  /// Current sync status
  BatchSyncServiceStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == BatchSyncServiceStatus.syncing;

  /// Initialize the sync service
  void initialize() {
    debugPrint('[BatchSync] Initializing...');

    // Listen for connectivity changes with debouncing
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_isConnected(results)) {
        _connectivityDebounceTimer?.cancel();
        _connectivityDebounceTimer = Timer(const Duration(seconds: 3), () {
          if (!_isSyncing) {
            debugPrint('[BatchSync] Network available - triggering sync');
            syncNow();
          }
        });
      }
    });

    // Set up periodic sync (every 3 minutes when online)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkAndSync();
    });

    debugPrint('[BatchSync] Initialized');
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
        r == ConnectivityResult.ethernet);
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
  Future<BatchSyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('[BatchSync] Already syncing, skipping...');
      return BatchSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint('[BatchSync] User not authenticated, skipping sync');
      return BatchSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    _status = BatchSyncServiceStatus.syncing;
    _lastError = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    int createdCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;
    int failedCount = 0;

    try {
      debugPrint('[BatchSync] Starting delta sync...');

      // Get all batches that need syncing
      final pendingBatches = await _offlineController.getBatchesNeedingSync();
      debugPrint('[BatchSync] Found ${pendingBatches.length} batches to sync');

      for (final batch in pendingBatches) {
        try {
          switch (batch.syncStatus) {
            case BatchSyncStatus.newRecord:
              // Create on server
              final serverId = await _apiService.createBatch(batch.toSyncPayload());
              await _offlineController.markAsSynced(batch.id, serverId);
              createdCount++;
              debugPrint('[BatchSync] Created: ${batch.batchNumber} -> $serverId');
              break;

            case BatchSyncStatus.updated:
              // Update on server (needs serverId)
              if (batch.serverId != null) {
                await _apiService.updateBatch(batch.serverId!, batch.toSyncPayload());
                await _offlineController.markAsSynced(batch.id, batch.serverId!);
                updatedCount++;
                debugPrint('[BatchSync] Updated: ${batch.batchNumber}');
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
              debugPrint('[BatchSync] Deleted: ${batch.batchNumber}');
              break;

            case BatchSyncStatus.synced:
              // Already synced, skip
              break;
          }
        } catch (e) {
          debugPrint('[BatchSync] Failed to sync ${batch.batchNumber}: $e');
          failedCount++;
        }
      }

      stopwatch.stop();
      _lastSyncTime = DateTime.now();
      _status = BatchSyncServiceStatus.success;
      notifyListeners();

      final result = BatchSyncResult(
        success: true,
        createdCount: createdCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        failedCount: failedCount,
        duration: stopwatch.elapsed,
      );

      debugPrint('[BatchSync] $result');
      return result;
    } catch (e) {
      stopwatch.stop();
      _lastError = e.toString();
      _status = BatchSyncServiceStatus.failed;
      notifyListeners();

      debugPrint('[BatchSync] Sync failed: $e');
      return BatchSyncResult(
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
  Future<BatchSyncResult> forceFullSync() async {
    // First upload any local changes
    await syncNow();

    // Then download all from server
    final serverBatches = await _apiService.getBatches();
    await _offlineController.importFromServer(serverBatches);

    return BatchSyncResult(
      success: true,
      downloadedCount: serverBatches.length,
      duration: Duration.zero,
    );
  }

  /// Get count of pending syncs
  Future<int> getPendingSyncCount() async {
    return await _offlineController.getUnsyncedCount();
  }
}
