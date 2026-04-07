import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';
import '../datasources/dashboard_cache_datasource.dart';
import '../datasources/dashboard_isar_datasource.dart';

/// Repository implementation with Isar-first reactive strategy
///
/// Loading strategy:
/// 1. Return cached data immediately if available (instant)
/// 2. Fetch fresh data from LOCAL Isar DB (< 5ms)
/// 3. Update cache and notify listeners
/// 4. Reactive: Isar watchLazy() auto-triggers recalculation on any data change
///
/// Key changes from old Firebase-based approach:
/// - Primary datasource is now Isar (local, instant, offline-capable)
/// - Reactive streams via Isar collection watchers (bills, purchases, batches)
/// - DashboardRefreshService events also trigger recalculation
/// - Firebase datasource is no longer used for dashboard (sync is separate concern)
class DashboardRepositoryImpl implements DashboardRepositoryInterface {
  final DashboardCacheDataSource _cacheDataSource;
  final DashboardIsarDataSource _isarDataSource;

  /// Stream controllers for each filter type (for manual refresh triggers)
  final Map<String, StreamController<DashboardSummary>> _controllers = {};

  /// Active Isar watch subscriptions per filter
  final Map<String, StreamSubscription<DashboardSummary>> _isarWatchSubs = {};

  DashboardRepositoryImpl({
    DashboardCacheDataSource? cacheDataSource,
    DashboardIsarDataSource? isarDataSource,
  }) : _cacheDataSource = cacheDataSource ?? DashboardCacheDataSource(),
       _isarDataSource = isarDataSource ?? DashboardIsarDataSource.instance;

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

    // Fetch fresh data from local Isar DB (instant, < 5ms)
    // Always go to Isar for live calculations — cache is only for pre-render
    try {
      final freshData = await _isarDataSource.fetchDashboardSummary(
        params: params,
      );

      // Save to cache
      await _cacheDataSource.saveToCache(params, freshData);

      stopwatch.stop();
      debugPrint(
        '[DashboardRepo] Isar data loaded in ${stopwatch.elapsedMilliseconds}ms',
      );

      return freshData;
    } catch (e) {
      // If Isar fails somehow, try stale cache
      final staleCache = await _cacheDataSource.getCached(params);
      if (staleCache != null) {
        debugPrint('[DashboardRepo] Isar failed, returning stale cache');
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

    // 2. Fetch fresh data from Isar
    try {
      final freshData = await _isarDataSource.fetchDashboardSummary(
        params: params,
      );
      await _cacheDataSource.saveToCache(params, freshData);
      yield freshData;
    } catch (e) {
      if (cached == null) rethrow;
    }

    // 3. Start reactive Isar watcher
    final isarStream = _isarDataSource.watchDashboardSummary(params: params);
    _isarWatchSubs[cacheKey] = isarStream.listen(
      (summary) async {
        await _cacheDataSource.saveToCache(params, summary);
        final controller = _controllers[cacheKey];
        if (controller != null && !controller.isClosed) {
          controller.add(summary);
        }
      },
      onError: (e) {
        debugPrint('[DashboardRepo] Isar watch error: $e');
      },
    );

    // 4. Continue listening for updates from the controller
    await for (final update in _controllers[cacheKey]!.stream) {
      yield update;
    }
  }

  /// Clean up watcher and controller for a given cache key
  Future<void> _cleanupWatcher(String cacheKey) async {
    final oldSub = _isarWatchSubs.remove(cacheKey);
    await oldSub?.cancel();

    final oldController = _controllers.remove(cacheKey);
    if (oldController != null && !oldController.isClosed) {
      oldController.close();
    }
  }

  /// Force refresh from Isar and push to stream listeners
  Future<void> refreshAndNotify(DashboardParams params) async {
    try {
      final freshData = await _isarDataSource.fetchDashboardSummary(
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

  /// Dispose all stream controllers and Isar watchers
  void dispose() {
    for (final sub in _isarWatchSubs.values) {
      sub.cancel();
    }
    _isarWatchSubs.clear();

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();

    _isarDataSource.dispose();
  }
}
