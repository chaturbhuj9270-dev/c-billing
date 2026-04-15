import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/menu_offline_controller.dart';
import '../../offline/entities/menu_item_entity.dart';
import 'menu_api_service.dart';

enum MenuSyncServiceStatus { idle, syncing, success, failed }

class MenuSyncResult {
  final bool success;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  MenuSyncResult({
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
      return 'Menu sync: ↑$createdCount new, ↑$updatedCount updated, ↑$deletedCount deleted, ↓$downloadedCount downloaded';
    }
    return 'Menu sync failed: $errorMessage';
  }
}

class MenuSyncService extends ChangeNotifier {
  static MenuSyncService? _instance;

  final MenuOfflineController _offlineController;
  final MenuApiService _apiService;
  final Connectivity _connectivity;

  MenuSyncServiceStatus _status = MenuSyncServiceStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;

  MenuSyncService._({
    MenuOfflineController? offlineController,
    MenuApiService? apiService,
    Connectivity? connectivity,
  }) : _offlineController = offlineController ?? MenuOfflineController.instance,
       _apiService = apiService ?? MenuApiService.instance,
       _connectivity = connectivity ?? Connectivity();

  static MenuSyncService get instance {
    _instance ??= MenuSyncService._();
    return _instance!;
  }

  MenuSyncServiceStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  bool get isSyncing => _status == MenuSyncServiceStatus.syncing;

  void initialize() {
    debugPrint('[MenuSync] Initializing...');

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (_isConnected(results)) {
        Future.delayed(const Duration(seconds: 2), () => syncNow());
      }
    });

    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkAndSync();
    });

    _initialSync();
  }

  Future<void> _initialSync() async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final localCount = await _offlineController.getTotalCount();
      final results = await _connectivity.checkConnectivity();
      final isConnected = _isConnected(results);
      final isAuth = _apiService.isAuthenticated;

      if (!isConnected || !isAuth) {
        Future.delayed(const Duration(seconds: 3), () => _initialSync());
        return;
      }

      if (localCount == 0) {
        await forceFullSync();
      } else {
        await syncNow();
      }
    } catch (e) {
      debugPrint('[MenuSync] Initial sync failed: $e');
      Future.delayed(const Duration(seconds: 5), () => _initialSync());
    }
  }

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

  Future<void> _checkAndSync() async {
    final results = await _connectivity.checkConnectivity();
    if (_isConnected(results)) await syncNow();
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  Future<MenuSyncResult> syncNow() async {
    if (_isSyncing) {
      return MenuSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    if (!_apiService.isAuthenticated) {
      return MenuSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    _status = MenuSyncServiceStatus.syncing;
    _lastError = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    int createdCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;
    int failedCount = 0;

    try {
      final pendingItems = await _offlineController.getItemsNeedingSync();
      debugPrint('[MenuSync] ${pendingItems.length} items to sync');

      for (final item in pendingItems) {
        try {
          switch (item.syncStatus) {
            case MenuSyncStatus.newRecord:
              final serverId = await _apiService.createMenuItem(
                item.toSyncPayload(),
              );
              await _offlineController.markAsSynced(item.id, serverId);
              createdCount++;
              break;

            case MenuSyncStatus.updated:
              if (item.serverId != null) {
                await _apiService.updateMenuItem(
                  item.serverId!,
                  item.toSyncPayload(),
                );
                await _offlineController.markAsSynced(item.id, item.serverId!);
                updatedCount++;
              } else {
                final serverId = await _apiService.createMenuItem(
                  item.toSyncPayload(),
                );
                await _offlineController.markAsSynced(item.id, serverId);
                createdCount++;
              }
              break;

            case MenuSyncStatus.deleted:
              if (item.serverId != null) {
                await _apiService.deleteMenuItem(item.serverId!);
              }
              await _offlineController.permanentlyDelete(item.id);
              deletedCount++;
              break;

            case MenuSyncStatus.synced:
              break;
          }
        } catch (e) {
          debugPrint('[MenuSync] Failed: ${item.name}: $e');
          failedCount++;
        }
      }

      final downloadedCount = await _pullServerChanges();

      stopwatch.stop();
      _lastSyncTime = DateTime.now();
      _status = MenuSyncServiceStatus.success;
      notifyListeners();

      final result = MenuSyncResult(
        success: true,
        createdCount: createdCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        downloadedCount: downloadedCount,
        failedCount: failedCount,
        duration: stopwatch.elapsed,
      );

      debugPrint('[MenuSync] $result');

      if (failedCount > 0) {
        Future.delayed(const Duration(seconds: 10), () => syncNow());
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      _lastError = e.toString();
      _status = MenuSyncServiceStatus.failed;
      notifyListeners();

      return MenuSyncResult(
        success: false,
        errorMessage: e.toString(),
        failedCount: failedCount,
        duration: stopwatch.elapsed,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<int> _pullServerChanges() async {
    try {
      final serverItems = await _apiService.getMenuItems();
      if (serverItems.isNotEmpty) {
        await _offlineController.importFromServer(serverItems);
        return serverItems.length;
      }
      return 0;
    } catch (e) {
      debugPrint('[MenuSync] Pull failed: $e');
      rethrow;
    }
  }

  Future<MenuSyncResult> forceFullSync() async {
    try {
      await syncNow();
      final serverItems = await _apiService.getMenuItems();
      await _offlineController.importFromServer(serverItems);
      _lastSyncTime = DateTime.now();
      notifyListeners();

      return MenuSyncResult(
        success: true,
        downloadedCount: serverItems.length,
        duration: Duration.zero,
      );
    } catch (e) {
      return MenuSyncResult(
        success: false,
        errorMessage: e.toString(),
        duration: Duration.zero,
      );
    }
  }

  Future<int> getPendingSyncCount() async {
    return await _offlineController.getUnsyncedCount();
  }
}
