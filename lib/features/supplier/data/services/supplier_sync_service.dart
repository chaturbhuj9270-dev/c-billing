import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/supplier_offline_controller.dart';
import 'supplier_api_service.dart';

/// Sync status for tracking sync state
enum SupplierSyncServiceStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a sync operation
class SupplierSyncResult {
  final bool success;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  SupplierSyncResult({
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

/// Service for background synchronization of Supplier data
/// Implements delta sync - only syncs NEW, UPDATED, or DELETED suppliers
class SupplierSyncService extends ChangeNotifier {
  static SupplierSyncService? _instance;

  final SupplierOfflineController _offlineController;
  final SupplierApiService _apiService;
  final Connectivity _connectivity;

  SupplierSyncServiceStatus _status = SupplierSyncServiceStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  
  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  SupplierSyncService._({
    SupplierOfflineController? offlineController,
    SupplierApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? SupplierOfflineController.instance,
        _apiService = apiService ?? SupplierApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static SupplierSyncService get instance {
    _instance ??= SupplierSyncService._();
    return _instance!;
  }

  /// Current sync status
  SupplierSyncServiceStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == SupplierSyncServiceStatus.syncing;

  /// Initialize the sync service
  void initialize() {
    debugPrint('[SupplierSync] Initializing...');
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_isConnected(results)) {
        debugPrint('[SupplierSync] Network available - triggering sync');
        Future.delayed(const Duration(seconds: 2), () => syncNow());
      }
    });

    // Set up periodic sync (every 3 minutes when online)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkAndSync();
    });
    
    debugPrint('[SupplierSync] Initialized');
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
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
  Future<SupplierSyncResult> syncNow() async {
    // Prevent concurrent sync operations
    if (_isSyncing) {
      debugPrint('[SupplierSync] Sync already in progress, skipping');
      return SupplierSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check connectivity
    if (!await isOnline()) {
      debugPrint('[SupplierSync] No network, skipping sync');
      return SupplierSyncResult(
        success: false,
        errorMessage: 'No network connection',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    _status = SupplierSyncServiceStatus.syncing;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    int created = 0;
    int updated = 0;
    int deleted = 0;
    int downloaded = 0;
    int failed = 0;

    try {
      debugPrint('[SupplierSync] Starting delta sync...');

      // 1. Push local NEW records to server
      final newSuppliers = await _offlineController.getNewSuppliers();
      for (final supplier in newSuppliers) {
        try {
          final serverResponse = await _apiService.createSupplier(supplier.toSyncPayload());
          await _offlineController.updateWithServerResponse(supplier.id, serverResponse);
          created++;
          debugPrint('[SupplierSync] Created: ${supplier.fullName}');
        } catch (e) {
          debugPrint('[SupplierSync] Failed to create ${supplier.fullName}: $e');
          failed++;
        }
      }

      // 2. Push local UPDATED records to server
      final updatedSuppliers = await _offlineController.getUpdatedSuppliers();
      for (final supplier in updatedSuppliers) {
        if (supplier.serverId == null) {
          debugPrint('[SupplierSync] Skipping update - no server ID: ${supplier.fullName}');
          continue;
        }
        try {
          await _apiService.updateSupplier(supplier.serverId!, supplier.toSyncPayload());
          await _offlineController.markAsSynced(supplier.id);
          updated++;
          debugPrint('[SupplierSync] Updated: ${supplier.fullName}');
        } catch (e) {
          debugPrint('[SupplierSync] Failed to update ${supplier.fullName}: $e');
          failed++;
        }
      }

      // 3. Delete server records for locally DELETED items
      final deletedSuppliers = await _offlineController.getDeletedSuppliers();
      for (final supplier in deletedSuppliers) {
        if (supplier.serverId == null) {
          // Never synced, just remove locally
          await _offlineController.permanentlyDelete(supplier.id);
          deleted++;
          continue;
        }
        try {
          await _apiService.deleteSupplier(supplier.serverId!);
          await _offlineController.permanentlyDelete(supplier.id);
          deleted++;
          debugPrint('[SupplierSync] Deleted: ${supplier.fullName}');
        } catch (e) {
          debugPrint('[SupplierSync] Failed to delete ${supplier.fullName}: $e');
          failed++;
        }
      }

      // 4. Pull server changes (download new/updated from server)
      try {
        final serverSuppliers = await _apiService.getSuppliers(
          updatedSince: _lastSyncTime,
        );
        downloaded = await _offlineController.importFromServer(serverSuppliers);
        debugPrint('[SupplierSync] Downloaded $downloaded suppliers from server');
      } catch (e) {
        debugPrint('[SupplierSync] Failed to pull server changes: $e');
      }

      stopwatch.stop();
      _lastSyncTime = DateTime.now();
      _status = SupplierSyncServiceStatus.success;
      _lastError = null;

      final result = SupplierSyncResult(
        success: true,
        createdCount: created,
        updatedCount: updated,
        deletedCount: deleted,
        downloadedCount: downloaded,
        failedCount: failed,
        duration: stopwatch.elapsed,
      );

      debugPrint('[SupplierSync] $result');
      notifyListeners();
      return result;

    } catch (e) {
      stopwatch.stop();
      _status = SupplierSyncServiceStatus.failed;
      _lastError = e.toString();

      final result = SupplierSyncResult(
        success: false,
        createdCount: created,
        updatedCount: updated,
        deletedCount: deleted,
        downloadedCount: downloaded,
        failedCount: failed,
        errorMessage: e.toString(),
        duration: stopwatch.elapsed,
      );

      debugPrint('[SupplierSync] Sync failed: $e');
      notifyListeners();
      return result;

    } finally {
      _isSyncing = false;
    }
  }

  /// Force full sync (ignore last sync time)
  Future<SupplierSyncResult> forceFullSync() async {
    _lastSyncTime = null;
    return await syncNow();
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    return await _offlineController.getUnsyncedCount();
  }
}
