import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/product_offline_controller.dart';
import '../../offline/entities/product_entity.dart';
import 'product_api_service.dart';

/// Sync status for tracking sync state
enum ProductSyncStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a sync operation
class ProductSyncResult {
  final bool success;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  ProductSyncResult({
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

/// Service for background synchronization of Product data
/// Implements delta sync - only syncs NEW, UPDATED, or DELETED products
/// 
/// Features:
/// - Connectivity monitoring with auto-sync on reconnect
/// - Periodic background sync
/// - Mutex to prevent concurrent sync operations
/// - Retry logic for failed syncs
class ProductSyncService extends ChangeNotifier {
  static ProductSyncService? _instance;

  final ProductOfflineController _offlineController;
  final ProductApiService _apiService;
  final Connectivity _connectivity;

  ProductSyncStatus _status = ProductSyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  Timer? _connectivityDebounceTimer;
  
  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  ProductSyncService._({
    ProductOfflineController? offlineController,
    ProductApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? ProductOfflineController.instance,
        _apiService = apiService ?? ProductApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static ProductSyncService get instance {
    _instance ??= ProductSyncService._();
    return _instance!;
  }

  /// Current sync status
  ProductSyncStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == ProductSyncStatus.syncing;

  /// Initialize the sync service
  /// Call this after Isar is initialized
  void initialize() {
    debugPrint('[ProductSync] Initializing...');
    
    // Listen for connectivity changes with debouncing
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_isConnected(results)) {
        // Cancel any pending debounce timer
        _connectivityDebounceTimer?.cancel();
        
        // Debounce to prevent multiple syncs when connectivity changes rapidly
        _connectivityDebounceTimer = Timer(const Duration(seconds: 3), () {
          if (!_isSyncing) {
            debugPrint('[ProductSync] Network available - triggering sync');
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
    _checkAndSync();
    
    debugPrint('[ProductSync] Initialized');
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _connectivityDebounceTimer?.cancel();
    super.dispose();
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
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

  /// Perform delta sync now
  /// Only syncs products with syncStatus != SYNCED
  /// Returns SyncResult with details of the sync operation
  Future<ProductSyncResult> syncNow() async {
    // Prevent concurrent sync operations
    if (_isSyncing) {
      debugPrint('[ProductSync] Sync already in progress, skipping');
      return ProductSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint('[ProductSync] User not authenticated, skipping sync');
      return ProductSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();
    _status = ProductSyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    int createdCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;
    int downloadedCount = 0;
    int failedCount = 0;

    try {
      // Check connectivity
      if (!await isOnline()) {
        throw Exception('No internet connection');
      }

      debugPrint('[ProductSync] Starting delta sync...');

      // Step 1: Push local changes to server (delta sync)
      final pushResult = await _pushLocalChanges();
      createdCount = pushResult['created'] ?? 0;
      updatedCount = pushResult['updated'] ?? 0;
      deletedCount = pushResult['deleted'] ?? 0;
      failedCount = pushResult['failed'] ?? 0;

      // Step 2: Pull changes from server
      downloadedCount = await _pullServerChanges();

      // Step 3: Clean up permanently deleted records
      await _offlineController.clearDeletedRecords();

      _status = ProductSyncStatus.success;
      _lastSyncTime = DateTime.now();
      _lastError = null;
      
      debugPrint('[ProductSync] Sync completed: created=$createdCount, updated=$updatedCount, deleted=$deletedCount, downloaded=$downloadedCount');
      
      notifyListeners();

      return ProductSyncResult(
        success: true,
        createdCount: createdCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        downloadedCount: downloadedCount,
        failedCount: failedCount,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      debugPrint('[ProductSync] Sync failed: $e');
      _status = ProductSyncStatus.failed;
      _lastError = e.toString();
      notifyListeners();

      return ProductSyncResult(
        success: false,
        createdCount: createdCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        downloadedCount: downloadedCount,
        failedCount: failedCount,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Push local changes to server (delta sync)
  /// Only pushes products where syncStatus != SYNCED
  Future<Map<String, int>> _pushLocalChanges() async {
    int created = 0;
    int updated = 0;
    int deleted = 0;
    int failed = 0;

    // Get NEW products → POST to server
    final newProducts = await _offlineController.getNewProducts();
    debugPrint('[ProductSync] NEW products to sync: ${newProducts.length}');
    
    for (final product in newProducts) {
      try {
        final response = await _apiService.createProduct(product.toSyncPayload());
        await _offlineController.updateWithServerResponse(product.id, response);
        created++;
      } catch (e) {
        debugPrint('[ProductSync] Failed to create product ${product.id}: $e');
        failed++;
      }
    }

    // Get UPDATED products → PUT to server
    final updatedProducts = await _offlineController.getUpdatedProducts();
    debugPrint('[ProductSync] UPDATED products to sync: ${updatedProducts.length}');
    
    for (final product in updatedProducts) {
      try {
        if (product.serverId != null) {
          await _apiService.updateProduct(product.serverId!, product.toSyncPayload());
          await _offlineController.markAsSynced(product.id);
          updated++;
        } else {
          // No server ID means it was never synced - treat as new
          final response = await _apiService.createProduct(product.toSyncPayload());
          await _offlineController.updateWithServerResponse(product.id, response);
          created++;
        }
      } catch (e) {
        debugPrint('[ProductSync] Failed to update product ${product.id}: $e');
        failed++;
      }
    }

    // Get DELETED products → DELETE from server
    final deletedProducts = await _offlineController.getDeletedProducts();
    debugPrint('[ProductSync] DELETED products to sync: ${deletedProducts.length}');
    
    for (final product in deletedProducts) {
      try {
        if (product.serverId != null) {
          await _apiService.deleteProduct(product.serverId!);
        }
        // Remove from local DB after successful server deletion
        await _offlineController.permanentlyDelete(product.id);
        deleted++;
      } catch (e) {
        debugPrint('[ProductSync] Failed to delete product ${product.id}: $e');
        failed++;
      }
    }

    return {
      'created': created,
      'updated': updated,
      'deleted': deleted,
      'failed': failed,
    };
  }

  /// Pull changes from server
  /// Merges into Isar using serverId, only updates changed records
  Future<int> _pullServerChanges() async {
    try {
      // Get last sync time for incremental sync
      final lastSync = _lastSyncTime;
      
      // Fetch products from server (with optional since parameter)
      final serverProducts = await _apiService.getProducts(
        updatedSince: lastSync,
      );

      debugPrint('[ProductSync] Received ${serverProducts.length} products from server');

      if (serverProducts.isNotEmpty) {
        return await _offlineController.importFromServer(serverProducts);
      }

      return 0;
    } catch (e) {
      debugPrint('[ProductSync] Failed to pull server changes: $e');
      rethrow;
    }
  }

  /// Force full refresh from server
  /// Use with caution - may overwrite local changes that are synced
  Future<ProductSyncResult> forceFullRefresh() async {
    if (_isSyncing) {
      return ProductSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();
    _status = ProductSyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // Get all products from server
      final serverProducts = await _apiService.getProducts();
      
      // Import all
      final count = await _offlineController.importFromServer(serverProducts);

      _status = ProductSyncStatus.success;
      _lastSyncTime = DateTime.now();
      notifyListeners();

      return ProductSyncResult(
        success: true,
        downloadedCount: count,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      _status = ProductSyncStatus.failed;
      _lastError = e.toString();
      notifyListeners();

      return ProductSyncResult(
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
