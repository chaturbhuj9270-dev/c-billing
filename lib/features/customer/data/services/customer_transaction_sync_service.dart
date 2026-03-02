import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../offline/controllers/customer_transaction_offline_controller.dart';
import '../../offline/entities/customer_transaction_entity.dart';
import 'customer_transaction_api_service.dart';

/// Sync status for tracking sync state
enum CustomerTransactionSyncStatus { idle, syncing, success, failed }

/// Result of a sync operation
class CustomerTransactionSyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  CustomerTransactionSyncResult({
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

/// Service for background synchronization of Customer Transaction data
/// Handles bidirectional sync between local Isar and Firebase Firestore
class CustomerTransactionSyncService extends ChangeNotifier {
  static CustomerTransactionSyncService? _instance;

  final CustomerTransactionOfflineController _offlineController;
  final CustomerTransactionApiService _apiService;
  final Connectivity _connectivity;

  CustomerTransactionSyncStatus _status = CustomerTransactionSyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  CustomerTransactionSyncService._({
    CustomerTransactionOfflineController? offlineController,
    CustomerTransactionApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController =
            offlineController ?? CustomerTransactionOfflineController.instance,
        _apiService = apiService ?? CustomerTransactionApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static CustomerTransactionSyncService get instance {
    _instance ??= CustomerTransactionSyncService._();
    return _instance!;
  }

  /// Reset instance (for testing)
  static void resetInstance() {
    _instance = null;
  }

  /// Current sync status
  CustomerTransactionSyncStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == CustomerTransactionSyncStatus.syncing;

  /// Initialize the sync service
  /// Call this after Isar is initialized
  void initialize() {
    debugPrint('[CustomerTransactionSync] Initializing...');

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (_isConnected(result)) {
        // Back online - trigger sync with delay
        Future.delayed(const Duration(seconds: 3), () {
          if (!_isSyncing) {
            debugPrint(
                '[CustomerTransactionSync] Network available - triggering sync');
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

    debugPrint('[CustomerTransactionSync] Initialized');
  }

  /// Dispose resources
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

  /// Perform sync now
  /// Returns SyncResult with details of the sync operation
  Future<CustomerTransactionSyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      return CustomerTransactionSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint(
          '[CustomerTransactionSync] User not authenticated, skipping sync');
      return CustomerTransactionSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();
    _status = CustomerTransactionSyncStatus.syncing;
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

      _status = CustomerTransactionSyncStatus.success;
      _lastSyncTime = DateTime.now();
      _lastError = null;
      notifyListeners();

      // Notify dashboard to refresh if any data was synced
      if (uploadedCount > 0 || downloadedCount > 0) {
        DashboardRefreshService.instance.notifyDataChanged(
          DataChangeType.customer,
        );
      }

      debugPrint(
          '[CustomerTransactionSync] Sync completed: ↑$uploadedCount ↓$downloadedCount');

      return CustomerTransactionSyncResult(
        success: true,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        failedCount: failedCount,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      _status = CustomerTransactionSyncStatus.failed;
      _lastError = e.toString();
      notifyListeners();

      debugPrint('[CustomerTransactionSync] Sync failed: $e');

      return CustomerTransactionSyncResult(
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

    final transactionsNeedingPush =
        await _offlineController.getTransactionsNeedingPush();

    for (final transaction in transactionsNeedingPush) {
      try {
        if (transaction.syncStatus == TransactionSyncStatus.deleted) {
          // Delete on server
          if (transaction.serverId != null) {
            await _apiService.deleteTransaction(transaction.serverId!);
          }
          await _offlineController.permanentlyDelete(transaction.id);
        } else if (transaction.serverId == null) {
          // Create on server
          final response = await _apiService.createTransaction(
            _convertToServerPayload(transaction),
          );
          await _offlineController.updateWithServerResponse(
            transaction.id,
            response,
          );
        }
        // Note: We don't update transactions on server after creation
        // Transactions are immutable financial records
        uploaded++;
      } catch (e) {
        debugPrint(
            '[CustomerTransactionSync] Failed to sync transaction ${transaction.id}: $e');
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

      // Fetch transactions from server (with optional since parameter)
      final serverTransactions = await _apiService.getTransactions(
        updatedSince: lastSync,
      );

      if (serverTransactions.isNotEmpty) {
        await _offlineController.importFromServer(serverTransactions);
      }

      return serverTransactions.length;
    } catch (e) {
      debugPrint('[CustomerTransactionSync] Failed to pull server changes: $e');
      rethrow;
    }
  }

  /// Force full refresh from server
  /// Use with caution - may overwrite local changes
  Future<CustomerTransactionSyncResult> forceFullRefresh() async {
    if (_status == CustomerTransactionSyncStatus.syncing) {
      return CustomerTransactionSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    final startTime = DateTime.now();
    _status = CustomerTransactionSyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // Get all transactions from server (no date filter)
      final serverTransactions = await _apiService.getTransactions();

      // Import all
      await _offlineController.importFromServer(serverTransactions);

      _status = CustomerTransactionSyncStatus.success;
      _lastSyncTime = DateTime.now();
      notifyListeners();

      // Notify dashboard to refresh after full sync
      if (serverTransactions.isNotEmpty) {
        DashboardRefreshService.instance.notifyDataChanged(
          DataChangeType.customer,
        );
      }

      debugPrint(
          '[CustomerTransactionSync] Full refresh completed: ${serverTransactions.length} records');

      return CustomerTransactionSyncResult(
        success: true,
        downloadedCount: serverTransactions.length,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      _status = CustomerTransactionSyncStatus.failed;
      _lastError = e.toString();
      notifyListeners();

      debugPrint('[CustomerTransactionSync] Full refresh failed: $e');

      return CustomerTransactionSyncResult(
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

  /// Convert offline entity to server payload
  Map<String, dynamic> _convertToServerPayload(
      CustomerTransactionEntity transaction) {
    // Map local transaction type to server format
    String serverTransactionType;
    switch (transaction.transactionType) {
      case TransactionType.payment:
        serverTransactionType = 'RECEIVED';
        break;
      case TransactionType.billCreated:
        serverTransactionType = 'BILL_GENERATED';
        break;
      case TransactionType.billReturn:
        serverTransactionType = 'REFUND';
        break;
      case TransactionType.adjustment:
        serverTransactionType = 'ADJUSTED';
        break;
    }

    // Map payment method to server format
    String? serverPaymentMode;
    if (transaction.paymentMethod != null) {
      switch (transaction.paymentMethod!.toUpperCase()) {
        case 'CASH':
          serverPaymentMode = 'CASH';
          break;
        case 'UPI':
          serverPaymentMode = 'UPI';
          break;
        case 'CARD':
          serverPaymentMode = 'CARD';
          break;
        case 'BANK TRANSFER':
        case 'ONLINE':
          serverPaymentMode = 'ONLINE';
          break;
        case 'CHEQUE':
          serverPaymentMode = 'CHEQUE';
          break;
        default:
          serverPaymentMode = 'OTHER';
      }
    }

    return {
      'customerId': transaction.customerId,
      'billId': transaction.referenceId,
      'amount': transaction.amount,
      'transactionType': serverTransactionType,
      'paymentMode': serverPaymentMode,
      'balanceAfterTransaction': transaction.balanceAfter,
      'notes': transaction.description,
      'createdAt': transaction.createdAt.toIso8601String(),
    };
  }
}
