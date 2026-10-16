import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';
import '../datasources/dashboard_cache_datasource.dart';
import '../datasources/dashboard_local_datasource.dart';

/// Repository implementation with offline-first reactive strategy
///
/// Loading strategy:
/// 1. Return cached data immediately if available (instant)
/// 2. Fetch fresh data from LOCAL local database (< 5ms)
/// 3. Update cache and notify listeners
/// 4. Reactive: table update watches auto-triggers recalculation on any data change
///
/// Key changes from old Firebase-based approach:
/// - Primary datasource is now local database (local, instant, offline-capable)
/// - Reactive streams via the local database collection watchers (bills, purchases, batches)
/// - DashboardRefreshService events also trigger recalculation
/// - Firebase datasource is no longer used for dashboard (sync is separate concern)
class DashboardRepositoryImpl implements DashboardRepositoryInterface {
  final DashboardCacheDataSource _cacheDataSource;
  final DashboardLocalDataSource _localDataSource;

  /// Stream controllers for each filter type (for manual refresh triggers)
  final Map<String, StreamController<DashboardSummary>> _controllers = {};

  /// Active Local watch subscriptions per filter
  final Map<String, StreamSubscription<DashboardSummary>> _localWatchSubs = {};

  DashboardRepositoryImpl({
    DashboardCacheDataSource? cacheDataSource,
    DashboardLocalDataSource? localDataSource,
  }) : _cacheDataSource = cacheDataSource ?? DashboardCacheDataSource(),
       _localDataSource = localDataSource ?? DashboardLocalDataSource.instance;

  /// Initialize repository and cache
  Future<void> init() async {
    await _cacheDataSource.init();
  }

  @override
  DashboardSummary? getCachedSummary({required DashboardParams params}) {
    return _cacheDataSource.getCachedSync(params);
  }

  @override
  Future<DashboardSummary> getDashboardSummary({
    required DashboardParams params,
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Fetch fresh data from local DB (instant, < 5ms)
    // Always go to the local database for live calculations — cache is only for pre-render
    try {
      final freshData = await _localDataSource.fetchDashboardSummary(
        params: params,
      );

      // Save to cache
      await _cacheDataSource.saveToCache(params, freshData);

      stopwatch.stop();
      debugPrint(
        '[DashboardRepo] Local data loaded in ${stopwatch.elapsedMilliseconds}ms',
      );

      return freshData;
    } catch (e) {
      // If local database fails somehow, try stale cache
      final staleCache = await _cacheDataSource.getCached(params);
      if (staleCache != null) {
        debugPrint('[DashboardRepo] Local load failed, returning stale cache');
        return staleCache;
      }
      rethrow;
    }
  }

  @override
  Stream<DashboardSummary> watchDashboardSummary({
    required DashboardParams params,
  }) async* {
    final cacheKey = params.cacheKey;

    // Clean up any existing watcher for this cacheKey to prevent stale streams
    await _cleanupWatcher(cacheKey);

    // Create fresh broadcast controller
    _controllers[cacheKey] = StreamController<DashboardSummary>.broadcast();

    // 1. Emit cached data immediately if available
    final cached = await _cacheDataSource.getCached(params);
    if (cached != null) {
      yield cached;
    }

    // 2. Fetch fresh data from the local database
    try {
      final freshData = await _localDataSource.fetchDashboardSummary(
        params: params,
      );
      await _cacheDataSource.saveToCache(params, freshData);
      yield freshData;
    } catch (e) {
      if (cached == null) rethrow;
    }

    // 3. Start reactive Local watcher
    final localStream = _localDataSource.watchDashboardSummary(params: params);
    _localWatchSubs[cacheKey] = localStream.listen(
      (summary) async {
        await _cacheDataSource.saveToCache(params, summary);
        final controller = _controllers[cacheKey];
        if (controller != null && !controller.isClosed) {
          controller.add(summary);
        }
      },
      onError: (e) {
        debugPrint('[DashboardRepo] Local watch error: $e');
      },
    );

    // 4. Continue listening for updates from the controller
    await for (final update in _controllers[cacheKey]!.stream) {
      yield update;
    }
  }

  /// Clean up watcher and controller for a given cache key
  Future<void> _cleanupWatcher(String cacheKey) async {
    final oldSub = _localWatchSubs.remove(cacheKey);
    await oldSub?.cancel();

    final oldController = _controllers.remove(cacheKey);
    if (oldController != null && !oldController.isClosed) {
      oldController.close();
    }
  }

  /// Force refresh from the local database and push to stream listeners
  Future<void> refreshAndNotify(DashboardParams params) async {
    try {
      final freshData = await _localDataSource.fetchDashboardSummary(
        params: params,
      );
      await _cacheDataSource.saveToCache(params, freshData);

      final controller = _controllers[params.cacheKey];
      if (controller != null && !controller.isClosed) {
        controller.add(freshData);
      }
    } catch (e) {
      debugPrint('[DashboardRepo] Manual refresh failed: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    await _cacheDataSource.clearAll();
  }

  @override
  Future<void> preloadCache() async {
    await _cacheDataSource.preloadDefaultCache();
  }

  /// Dispose all stream controllers and Local watchers
  void dispose() {
    for (final sub in _localWatchSubs.values) {
      sub.cancel();
    }
    _localWatchSubs.clear();

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();

    _localDataSource.dispose();
  }
}
