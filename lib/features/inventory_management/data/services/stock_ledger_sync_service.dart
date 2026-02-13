import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/stock_ledger_offline_controller.dart';
import '../../offline/entities/stock_ledger_entity.dart';
import 'stock_ledger_api_service.dart';

/// Sync status for tracking sync state
enum LedgerSyncServiceStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a ledger sync operation
class LedgerSyncResult {
  final bool success;
  final int createdCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  LedgerSyncResult({
    required this.success,
    this.createdCount = 0,
    this.deletedCount = 0,
    this.downloadedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    required this.duration,
  });

  int get totalSynced => createdCount + deletedCount;

  @override
  String toString() {
    if (success) {
      return 'LedgerSync completed: ↑$createdCount new, ↑$deletedCount deleted, ↓$downloadedCount downloaded';
    }
    return 'LedgerSync failed: $errorMessage';
  }
}

/// Service for background synchronization of Stock Ledger data
/// Implements delta sync - only syncs NEW or DELETED ledger entries
/// Ledger entries are immutable once created (no update needed)
class StockLedgerSyncService extends ChangeNotifier {
  static StockLedgerSyncService? _instance;

  final StockLedgerOfflineController _offlineController;
  final StockLedgerApiService _apiService;
  final Connectivity _connectivity;

  LedgerSyncServiceStatus _status = LedgerSyncServiceStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  Timer? _connectivityDebounceTimer;

  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  StockLedgerSyncService._({
    StockLedgerOfflineController? offlineController,
    StockLedgerApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? StockLedgerOfflineController.instance,
        _apiService = apiService ?? StockLedgerApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static StockLedgerSyncService get instance {
    _instance ??= StockLedgerSyncService._();
    return _instance!;
  }

  /// Current sync status
  LedgerSyncServiceStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == LedgerSyncServiceStatus.syncing;

  /// Initialize the sync service
  void initialize() {
    debugPrint('[LedgerSync] Initializing...');

    // Listen for connectivity changes with debouncing
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_isConnected(results)) {
        _connectivityDebounceTimer?.cancel();
        _connectivityDebounceTimer = Timer(const Duration(seconds: 4), () {
          if (!_isSyncing) {
            debugPrint('[LedgerSync] Network available - triggering sync');
            syncNow();
          }
        });
      }
    });

    // Set up periodic sync (every 3 minutes when online)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkAndSync();
    });

    debugPrint('[LedgerSync] Initialized');
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
  Future<LedgerSyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('[LedgerSync] Already syncing, skipping...');
      return LedgerSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint('[LedgerSync] User not authenticated, skipping sync');
      return LedgerSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    _status = LedgerSyncServiceStatus.syncing;
    _lastError = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    int createdCount = 0;
    int deletedCount = 0;
    int failedCount = 0;

    try {
      debugPrint('[LedgerSync] Starting delta sync...');

      // Get all ledger entries that need syncing
      final pendingEntries = await _offlineController.getLedgerNeedingSync();
      debugPrint('[LedgerSync] Found ${pendingEntries.length} entries to sync');

      for (final entry in pendingEntries) {
        try {
          switch (entry.syncStatus) {
            case LedgerSyncStatus.newRecord:
              // Create on server
              final serverId = await _apiService.createEntry(entry.toSyncPayload());
              await _offlineController.markAsSynced(entry.id, serverId);
              createdCount++;
              debugPrint('[LedgerSync] Created: ${entry.transactionType.name} -> $serverId');
              break;

            case LedgerSyncStatus.deleted:
              // Delete from server (if it exists there)
              if (entry.serverId != null) {
                await _apiService.deleteEntry(entry.serverId!);
              }
              // Permanently remove from local DB
              await _offlineController.permanentlyDelete(entry.id);
              deletedCount++;
              debugPrint('[LedgerSync] Deleted entry: ${entry.id}');
              break;

            case LedgerSyncStatus.synced:
              // Already synced, skip
              break;
          }
        } catch (e) {
          debugPrint('[LedgerSync] Failed to sync entry ${entry.id}: $e');
          failedCount++;
        }
      }

      stopwatch.stop();
      _lastSyncTime = DateTime.now();
      _status = LedgerSyncServiceStatus.success;
      notifyListeners();

      final result = LedgerSyncResult(
        success: true,
        createdCount: createdCount,
        deletedCount: deletedCount,
        failedCount: failedCount,
        duration: stopwatch.elapsed,
      );

      debugPrint('[LedgerSync] $result');
      return result;
    } catch (e) {
      stopwatch.stop();
      _lastError = e.toString();
      _status = LedgerSyncServiceStatus.failed;
      notifyListeners();

      debugPrint('[LedgerSync] Sync failed: $e');
      return LedgerSyncResult(
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
  Future<LedgerSyncResult> forceFullSync() async {
    // First upload any local changes
    await syncNow();

    // Then download all from server
    final serverEntries = await _apiService.getEntries();
    await _offlineController.importFromServer(serverEntries);

    return LedgerSyncResult(
      success: true,
      downloadedCount: serverEntries.length,
      duration: Duration.zero,
    );
  }

  /// Get count of pending syncs
  Future<int> getPendingSyncCount() async {
    return await _offlineController.getUnsyncedCount();
  }
}
