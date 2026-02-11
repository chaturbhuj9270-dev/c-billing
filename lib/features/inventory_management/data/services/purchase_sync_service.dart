import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/purchase_offline_controller.dart';
import '../../offline/entities/purchase_entity.dart';
import 'purchase_api_service.dart';

/// Sync status for tracking sync state
enum PurchaseSyncServiceStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a sync operation
class PurchaseSyncResult {
  final bool success;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  PurchaseSyncResult({
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

/// Service for background synchronization of Purchase data
/// Implements delta sync - only syncs NEW, UPDATED, or DELETED purchases
class PurchaseSyncService extends ChangeNotifier {
  static PurchaseSyncService? _instance;

  final PurchaseOfflineController _offlineController;
  final PurchaseApiService _apiService;
  final Connectivity _connectivity;

  PurchaseSyncServiceStatus _status = PurchaseSyncServiceStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  
  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  PurchaseSyncService._({
    PurchaseOfflineController? offlineController,
    PurchaseApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? PurchaseOfflineController.instance,
        _apiService = apiService ?? PurchaseApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static PurchaseSyncService get instance {
    _instance ??= PurchaseSyncService._();
    return _instance!;
  }

  /// Current sync status
  PurchaseSyncServiceStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == PurchaseSyncServiceStatus.syncing;

  /// Initialize the sync service
  void initialize() {
    debugPrint('[PurchaseSync] Initializing...');
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_isConnected(results)) {
        debugPrint('[PurchaseSync] Network available - triggering sync');
        Future.delayed(const Duration(seconds: 2), () => syncNow());
      }
    });

    // Set up periodic sync (every 3 minutes when online)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkAndSync();
    });
    
    debugPrint('[PurchaseSync] Initialized');
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
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
  Future<PurchaseSyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('[PurchaseSync] Already syncing, skipping...');
      return PurchaseSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint('[PurchaseSync] User not authenticated, skipping sync');
      return PurchaseSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    _status = PurchaseSyncServiceStatus.syncing;
    _lastError = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    int createdCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;
    int failedCount = 0;

    try {
      debugPrint('[PurchaseSync] Starting delta sync...');

      // Get all purchases that need syncing
      final pendingPurchases = await _offlineController.getPurchasesNeedingSync();
      debugPrint('[PurchaseSync] Found ${pendingPurchases.length} purchases to sync');

      for (final purchase in pendingPurchases) {
        try {
          switch (purchase.syncStatus) {
            case PurchaseSyncStatus.newRecord:
              // Create on server
              final serverId = await _apiService.createPurchase(purchase.toSyncPayload());
              await _offlineController.markAsSynced(purchase.id, serverId);
              createdCount++;
              debugPrint('[PurchaseSync] Created: ${purchase.productName} -> $serverId');
              break;

            case PurchaseSyncStatus.updated:
              // Update on server (needs serverId)
              if (purchase.serverId != null) {
                await _apiService.updatePurchase(purchase.serverId!, purchase.toSyncPayload());
                await _offlineController.markAsSynced(purchase.id, purchase.serverId!);
                updatedCount++;
                debugPrint('[PurchaseSync] Updated: ${purchase.productName}');
              } else {
                // No serverId, treat as new
                final serverId = await _apiService.createPurchase(purchase.toSyncPayload());
                await _offlineController.markAsSynced(purchase.id, serverId);
                createdCount++;
              }
              break;

            case PurchaseSyncStatus.deleted:
              // Delete from server (if it exists there)
              if (purchase.serverId != null) {
                await _apiService.deletePurchase(purchase.serverId!);
              }
              // Permanently remove from local DB
              await _offlineController.permanentlyDelete(purchase.id);
              deletedCount++;
              debugPrint('[PurchaseSync] Deleted: ${purchase.productName}');
              break;

            case PurchaseSyncStatus.synced:
              // Already synced, skip
              break;
          }
        } catch (e) {
          debugPrint('[PurchaseSync] Failed to sync ${purchase.productName}: $e');
          failedCount++;
        }
      }

      stopwatch.stop();
      _lastSyncTime = DateTime.now();
      _status = PurchaseSyncServiceStatus.success;
      notifyListeners();

      final result = PurchaseSyncResult(
        success: true,
        createdCount: createdCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        failedCount: failedCount,
        duration: stopwatch.elapsed,
      );

      debugPrint('[PurchaseSync] $result');
      return result;

    } catch (e) {
      stopwatch.stop();
      _lastError = e.toString();
      _status = PurchaseSyncServiceStatus.failed;
      notifyListeners();

      debugPrint('[PurchaseSync] Sync failed: $e');
      return PurchaseSyncResult(
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
  Future<PurchaseSyncResult> forceFullSync() async {
    // First upload any local changes
    await syncNow();
    
    // Then download all from server
    final serverPurchases = await _apiService.getPurchases();
    await _offlineController.importFromServer(serverPurchases);
    
    return PurchaseSyncResult(
      success: true,
      downloadedCount: serverPurchases.length,
      duration: Duration.zero,
    );
  }

  /// Get count of pending syncs
  Future<int> getPendingSyncCount() async {
    return await _offlineController.getUnsyncedCount();
  }
}
