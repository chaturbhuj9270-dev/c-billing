import 'dart:async';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';
import '../datasources/dashboard_cache_datasource.dart';
import '../datasources/dashboard_firebase_datasource.dart';

/// Repository implementation with cache-first strategy
/// 
/// Loading strategy:
/// 1. Return cached data immediately if available
/// 2. Fetch fresh data from Firebase in background
/// 3. Update cache and notify listeners when fresh data arrives
class DashboardRepositoryImpl implements DashboardRepositoryInterface {
  final DashboardCacheDataSource _cacheDataSource;
  final DashboardFirebaseDataSource _firebaseDataSource;

  /// Stream controllers for each filter type
  final Map<String, StreamController<DashboardSummary>> _controllers = {};

  DashboardRepositoryImpl({
    DashboardCacheDataSource? cacheDataSource,
    DashboardFirebaseDataSource? firebaseDataSource,
  })  : _cacheDataSource = cacheDataSource ?? DashboardCacheDataSource(),
        _firebaseDataSource = firebaseDataSource ?? DashboardFirebaseDataSource();

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

    // Try to get cached data first (unless force refresh)
    if (!forceRefresh) {
      final cached = await _cacheDataSource.getCached(params);
      if (cached != null) {
        print('[DashboardRepository] Returning cached data in ${stopwatch.elapsedMilliseconds}ms');
        
        // Trigger background refresh if cache is stale
        if (cached.isStale()) {
          _refreshInBackground(params);
        }
        
        return cached;
      }
    }

    // No cache available, fetch from Firebase
    try {
      final freshData = await _firebaseDataSource.fetchDashboardData(
        params: params,
        forceNetwork: forceRefresh,
      );

      // Save to cache
      await _cacheDataSource.saveToCache(params, freshData);

      stopwatch.stop();
      print('[DashboardRepository] Fresh data loaded in ${stopwatch.elapsedMilliseconds}ms');

      return freshData;
    } catch (e) {
      // If network fails, try to return stale cache
      final staleCache = await _cacheDataSource.getCached(params);
      if (staleCache != null) {
        print('[DashboardRepository] Network failed, returning stale cache');
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

    // Get or create stream controller
    if (!_controllers.containsKey(cacheKey)) {
      _controllers[cacheKey] = StreamController<DashboardSummary>.broadcast();
    }

    // First, emit cached data immediately if available
    final cached = await _cacheDataSource.getCached(params);
    if (cached != null) {
      yield cached;
    }

    // Then fetch fresh data
    try {
      final freshData = await _firebaseDataSource.fetchDashboardData(params: params);
      await _cacheDataSource.saveToCache(params, freshData);
      yield freshData;
    } catch (e) {
      // If we already emitted cached data, don't fail
      if (cached == null) {
        rethrow;
      }
    }

    // Continue listening for updates from the stream controller
    await for (final update in _controllers[cacheKey]!.stream) {
      yield update;
    }
  }

  /// Refresh data in background and update stream
  Future<void> _refreshInBackground(DashboardParams params) async {
    try {
      final freshData = await _firebaseDataSource.fetchDashboardData(
        params: params,
        forceNetwork: true,
      );
      await _cacheDataSource.saveToCache(params, freshData);

      // Notify listeners
      final controller = _controllers[params.cacheKey];
      if (controller != null && !controller.isClosed) {
        controller.add(freshData);
      }
    } catch (e) {
      print('[DashboardRepository] Background refresh failed: $e');
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

  /// Dispose all stream controllers
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
