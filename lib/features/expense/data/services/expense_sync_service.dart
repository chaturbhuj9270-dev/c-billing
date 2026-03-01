import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../offline/controllers/expense_offline_controller.dart';
import '../../offline/entities/expense_entity.dart';

/// Sync status for tracking sync state
enum ExpenseSyncServiceStatus { idle, syncing, success, failed }

/// Result of a sync operation
class ExpenseSyncResult {
  final bool success;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  ExpenseSyncResult({
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

/// Service for background synchronization of Expense data
/// Implements delta sync - only syncs NEW, UPDATED, or DELETED expenses
class ExpenseSyncService extends ChangeNotifier {
  static ExpenseSyncService? _instance;

  final ExpenseOfflineController _offlineController;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Connectivity _connectivity;

  ExpenseSyncServiceStatus _status = ExpenseSyncServiceStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  ExpenseSyncService._({
    ExpenseOfflineController? offlineController,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Connectivity? connectivity,
  }) : _offlineController =
           offlineController ?? ExpenseOfflineController.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static ExpenseSyncService get instance {
    _instance ??= ExpenseSyncService._();
    return _instance!;
  }

  /// Current sync status
  ExpenseSyncServiceStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == ExpenseSyncServiceStatus.syncing;

  /// Get the current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get expenses collection reference
  CollectionReference get _expensesCollection {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(_userId).collection('expenses');
  }

  /// Initialize the sync service
  void initialize() {
    debugPrint('[ExpenseSync] Initializing...');

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (_isConnected(results)) {
        debugPrint('[ExpenseSync] Network available - triggering sync');
        syncNow();
      }
    });

    // Start periodic sync (every 5 minutes)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
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

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }

  /// Trigger immediate sync
  Future<ExpenseSyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('[ExpenseSync] Sync already in progress, skipping');
      return ExpenseSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    if (!_isConnected(connectivityResult)) {
      debugPrint('[ExpenseSync] No network connection, skipping sync');
      return ExpenseSyncResult(
        success: false,
        errorMessage: 'No network connection',
        duration: Duration.zero,
      );
    }

    // Check authentication
    if (_userId == null) {
      debugPrint('[ExpenseSync] User not authenticated, skipping sync');
      return ExpenseSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    _status = ExpenseSyncServiceStatus.syncing;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    int created = 0, updated = 0, deleted = 0, downloaded = 0, failed = 0;

    try {
      debugPrint('[ExpenseSync] Starting sync...');

      // Step 1: Upload local changes
      final pendingExpenses = await _offlineController.getPendingSyncExpenses();
      debugPrint(
        '[ExpenseSync] Found ${pendingExpenses.length} expenses pending sync',
      );

      for (final expense in pendingExpenses) {
        try {
          switch (expense.syncStatus) {
            case ExpenseSyncStatus.newRecord:
              // Create on server
              final docRef = await _expensesCollection.add(expense.toJson());
              await _offlineController.markAsSynced(expense.id, docRef.id);
              created++;
              debugPrint(
                '[ExpenseSync] Created expense on server: ${docRef.id}',
              );
              break;

            case ExpenseSyncStatus.updated:
              // Update on server
              if (expense.serverId != null) {
                await _expensesCollection
                    .doc(expense.serverId)
                    .update(expense.toJson());
                await _offlineController.markAsSynced(
                  expense.id,
                  expense.serverId!,
                );
                updated++;
                debugPrint(
                  '[ExpenseSync] Updated expense on server: ${expense.serverId}',
                );
              }
              break;

            case ExpenseSyncStatus.deleted:
              // Delete from server
              if (expense.serverId != null) {
                await _expensesCollection.doc(expense.serverId).delete();
                await _offlineController.hardDelete(expense.id);
                deleted++;
                debugPrint(
                  '[ExpenseSync] Deleted expense from server: ${expense.serverId}',
                );
              } else {
                // Never synced, just hard delete
                await _offlineController.hardDelete(expense.id);
                deleted++;
              }
              break;

            case ExpenseSyncStatus.synced:
              // Already synced, skip
              break;
          }
        } catch (e) {
          failed++;
          debugPrint('[ExpenseSync] Failed to sync expense ${expense.id}: $e');
        }
      }

      // Step 2: Download new expenses from server
      try {
        final serverExpenses = await _expensesCollection
            .orderBy('createdAt', descending: true)
            .limit(500)
            .get();

        for (final doc in serverExpenses.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          // Check if we already have this expense
          final existing = await _offlineController.getExpenseByServerId(
            doc.id,
          );

          if (existing == null) {
            // New expense from server
            final expense = ExpenseEntity.fromJson(data);
            await _offlineController.importFromServer(expense);
            downloaded++;
            debugPrint(
              '[ExpenseSync] Downloaded expense from server: ${doc.id}',
            );
          }
        }
      } catch (e) {
        debugPrint('[ExpenseSync] Error downloading expenses: $e');
      }

      stopwatch.stop();
      _lastSyncTime = DateTime.now();
      _lastError = null;
      _status = ExpenseSyncServiceStatus.success;

      final result = ExpenseSyncResult(
        success: true,
        createdCount: created,
        updatedCount: updated,
        deletedCount: deleted,
        downloadedCount: downloaded,
        failedCount: failed,
        duration: stopwatch.elapsed,
      );

      debugPrint('[ExpenseSync] Sync completed: $result');
      notifyListeners();
      return result;
    } catch (e) {
      stopwatch.stop();
      _lastError = e.toString();
      _status = ExpenseSyncServiceStatus.failed;

      final result = ExpenseSyncResult(
        success: false,
        createdCount: created,
        updatedCount: updated,
        deletedCount: deleted,
        downloadedCount: downloaded,
        failedCount: failed,
        errorMessage: e.toString(),
        duration: stopwatch.elapsed,
      );

      debugPrint('[ExpenseSync] Sync failed: $e');
      notifyListeners();
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  /// Force full sync (download all from server)
  Future<void> forceFullSync() async {
    if (_userId == null) return;

    try {
      final serverExpenses = await _expensesCollection
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in serverExpenses.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final expense = ExpenseEntity.fromJson(data);
        await _offlineController.importFromServer(expense);
      }

      debugPrint(
        '[ExpenseSync] Full sync completed: ${serverExpenses.docs.length} expenses',
      );
    } catch (e) {
      debugPrint('[ExpenseSync] Full sync failed: $e');
    }
  }
}
