import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/customer_offline_controller.dart';
import 'customer_api_service.dart';

/// Sync status for tracking sync state
enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  SyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    required this.duration,
  });

  @override
  String toString() {
    if (success) {
      return 'Sync completed: ↑$uploadedCount ↓$downloadedCount';
    }
    return 'Sync failed: $errorMessage';
  }
}

/// Service for background synchronization of Customer data
/// Handles bidirectional sync between local Isar and remote server
class CustomerSyncService extends ChangeNotifier {
  static CustomerSyncService? _instance;

  final CustomerOfflineController _offlineController;
  final CustomerApiService _apiService;
  final Connectivity _connectivity;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  
  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  CustomerSyncService._({
    CustomerOfflineController? offlineController,
    CustomerApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? CustomerOfflineController.instance,
        _apiService = apiService ?? CustomerApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static CustomerSyncService get instance {
    _instance ??= CustomerSyncService._();
    return _instance!;
  }

  /// Current sync status
  SyncStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Initialize the sync service
  /// Call this after Isar is initialized
  void initialize() {
    debugPrint('[CustomerSync] Initializing...');
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (_isConnected(result)) {
        // Back online - trigger sync with delay
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isSyncing) {
            debugPrint('[CustomerSync] Network available - triggering sync');
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
    
    debugPrint('[CustomerSync] Initialized');
  }

  /// Dispose resources
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

  /// Perform sync now
  /// Returns SyncResult with details of the sync operation
  Future<SyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      return SyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint('[CustomerSync] User not authenticated, skipping sync');
      return SyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();
    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    int uploadedCount = 0;
    int downloadedCount = 0;
    int failedCount = 0;

    try {
      // Check connectivity
      if (!await isOnline()) {
        throw Exception('No internet connection');
      }

      // Step 1: Push local changes to server
      final pushResult = await _pushLocalChanges();
      uploadedCount = pushResult['uploaded'] ?? 0;
      failedCount = pushResult['failed'] ?? 0;

      // Step 2: Pull changes from server
      downloadedCount = await _pullServerChanges();

      // Step 3: Clean up deleted records
      await _offlineController.clearSyncedDeletedRecords();

      _status = SyncStatus.success;
      _lastSyncTime = DateTime.now();
      _lastError = null;
      notifyListeners();

      return SyncResult(
        success: true,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        failedCount: failedCount,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      _status = SyncStatus.failed;
      _lastError = e.toString();
      notifyListeners();

      return SyncResult(
        success: false,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        failedCount: failedCount,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Push local changes to server
  Future<Map<String, int>> _pushLocalChanges() async {
    int uploaded = 0;
    int failed = 0;

    final customersNeedingPush = await _offlineController.getCustomersNeedingPush();

    for (final customer in customersNeedingPush) {
      try {
        if (customer.isDeleted) {
          // Delete on server
          if (customer.serverId != null) {
            await _apiService.deleteCustomer(customer.serverId!);
          }
          await _offlineController.permanentlyDelete(customer.id);
        } else if (customer.serverId == null) {
          // Create on server
          final response = await _apiService.createCustomer(customer.toSyncPayload());
          await _offlineController.updateWithServerResponse(customer.id, response);
        } else {
          // Update on server
          await _apiService.updateCustomer(customer.serverId!, customer.toSyncPayload());
          await _offlineController.markAsSynced(customer.id);
        }
        uploaded++;
      } catch (e) {
        debugPrint('Failed to sync customer ${customer.id}: $e');
        failed++;
      }
    }

    return {'uploaded': uploaded, 'failed': failed};
  }

  /// Pull changes from server
  Future<int> _pullServerChanges() async {
    try {
      // Get last sync time for incremental sync
      final lastSync = _lastSyncTime;
      
      // Fetch customers from server (with optional since parameter)
      final serverCustomers = await _apiService.getCustomers(
        updatedSince: lastSync,
      );

      if (serverCustomers.isNotEmpty) {
        await _offlineController.importFromServer(serverCustomers);
      }

      return serverCustomers.length;
    } catch (e) {
      debugPrint('Failed to pull server changes: $e');
      rethrow;
    }
  }

  /// Force full refresh from server
  /// Use with caution - may overwrite local changes
  Future<SyncResult> forceFullRefresh() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    final startTime = DateTime.now();
    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // Get all customers from server
      final serverCustomers = await _apiService.getCustomers();
      
      // Import all
      await _offlineController.importFromServer(serverCustomers);

      _status = SyncStatus.success;
      _lastSyncTime = DateTime.now();
      notifyListeners();

      return SyncResult(
        success: true,
        downloadedCount: serverCustomers.length,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      _status = SyncStatus.failed;
      _lastError = e.toString();
      notifyListeners();

      return SyncResult(
        success: false,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  /// Get number of pending sync items
  Future<int> getPendingSyncCount() async {
    return await _offlineController.getUnsyncedCount();
  }
}
