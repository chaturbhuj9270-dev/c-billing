import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/company_offline_controller.dart';
import '../../offline/entities/company_entity.dart';
import 'company_api_service.dart';

/// Sync status for tracking sync state
enum CompanySyncServiceStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a sync operation
class CompanySyncResult {
  final bool success;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  CompanySyncResult({
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

/// Service for background synchronization of Company data
/// Implements delta sync - only syncs NEW, UPDATED, or DELETED companies
class CompanySyncService extends ChangeNotifier {
  static CompanySyncService? _instance;

  final CompanyOfflineController _offlineController;
  final CompanyApiService _apiService;
  final Connectivity _connectivity;

  CompanySyncServiceStatus _status = CompanySyncServiceStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  
  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  CompanySyncService._({
    CompanyOfflineController? offlineController,
    CompanyApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? CompanyOfflineController.instance,
        _apiService = apiService ?? CompanyApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static CompanySyncService get instance {
    _instance ??= CompanySyncService._();
    return _instance!;
  }

  /// Current sync status
  CompanySyncServiceStatus get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == CompanySyncServiceStatus.syncing;

  /// Initialize the sync service
  void initialize() {
    debugPrint('[CompanySync] Initializing...');
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_isConnected(results)) {
        debugPrint('[CompanySync] Network available - triggering sync');
        Future.delayed(const Duration(seconds: 2), () => syncNow());
      }
    });

    // Set up periodic sync (every 3 minutes when online)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkAndSync();
    });
    
    // Initial sync - download from server if local is empty
    _initialSync();
    
    debugPrint('[CompanySync] Initialized');
  }

  /// Perform initial sync - download all companies if local database is empty
  Future<void> _initialSync() async {
    try {
      final localCount = await _offlineController.getTotalCount();
      debugPrint('[CompanySync] Initial sync check: $localCount local companies');
      
      if (localCount == 0) {
        debugPrint('[CompanySync] No local companies, downloading from server...');
        final results = await _connectivity.checkConnectivity();
        if (_isConnected(results) && _apiService.isAuthenticated) {
          await forceFullSync();
        }
      }
    } catch (e) {
      debugPrint('[CompanySync] Initial sync failed: $e');
    }
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
  Future<CompanySyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('[CompanySync] Already syncing, skipping...');
      return CompanySyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint('[CompanySync] User not authenticated, skipping sync');
      return CompanySyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    _status = CompanySyncServiceStatus.syncing;
    _lastError = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    int createdCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;
    int failedCount = 0;

    try {
      debugPrint('[CompanySync] Starting delta sync...');

      // Get all companies that need syncing
      final pendingCompanies = await _offlineController.getCompaniesNeedingSync();
      debugPrint('[CompanySync] Found ${pendingCompanies.length} companies to sync');

      for (final company in pendingCompanies) {
        try {
          switch (company.syncStatus) {
            case CompanySyncStatus.newRecord:
              // Create on server
              final serverId = await _apiService.createCompany(company.toSyncPayload());
              await _offlineController.markAsSynced(company.id, serverId);
              createdCount++;
              debugPrint('[CompanySync] Created: ${company.companyName} -> $serverId');
              break;

            case CompanySyncStatus.updated:
              // Update on server (needs serverId)
              if (company.serverId != null) {
                await _apiService.updateCompany(company.serverId!, company.toSyncPayload());
                await _offlineController.markAsSynced(company.id, company.serverId!);
                updatedCount++;
                debugPrint('[CompanySync] Updated: ${company.companyName}');
              } else {
                // No serverId, treat as new
                final serverId = await _apiService.createCompany(company.toSyncPayload());
                await _offlineController.markAsSynced(company.id, serverId);
                createdCount++;
              }
              break;

            case CompanySyncStatus.deleted:
              // Delete from server (if it exists there)
              if (company.serverId != null) {
                await _apiService.deleteCompany(company.serverId!);
              }
              // Permanently remove from local DB
              await _offlineController.permanentlyDelete(company.id);
              deletedCount++;
              debugPrint('[CompanySync] Deleted: ${company.companyName}');
              break;

            case CompanySyncStatus.synced:
              // Already synced, skip
              break;
          }
        } catch (e) {
          debugPrint('[CompanySync] Failed to sync ${company.companyName}: $e');
          failedCount++;
        }
      }

      stopwatch.stop();
      _lastSyncTime = DateTime.now();
      _status = CompanySyncServiceStatus.success;
      notifyListeners();

      final result = CompanySyncResult(
        success: true,
        createdCount: createdCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        failedCount: failedCount,
        duration: stopwatch.elapsed,
      );

      debugPrint('[CompanySync] $result');
      return result;

    } catch (e) {
      stopwatch.stop();
      _lastError = e.toString();
      _status = CompanySyncServiceStatus.failed;
      notifyListeners();

      debugPrint('[CompanySync] Sync failed: $e');
      return CompanySyncResult(
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
  Future<CompanySyncResult> forceFullSync() async {
    // First upload any local changes
    await syncNow();
    
    // Then download all from server
    final serverCompanies = await _apiService.getCompanies();
    await _offlineController.importFromServer(serverCompanies);
    
    return CompanySyncResult(
      success: true,
      downloadedCount: serverCompanies.length,
      duration: Duration.zero,
    );
  }

  /// Get count of pending syncs
  Future<int> getPendingSyncCount() async {
    return await _offlineController.getUnsyncedCount();
  }
}
