import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import 'optimized_dashboard_state.dart';

/// High-performance Dashboard Cubit with Isar-first reactive strategy
///
/// Key features:
/// 1. Synchronously loads cached data before any async operations (instant UI)
/// 2. Fetches fresh data from local Isar DB (< 5ms)
/// 3. Reactive: auto-refreshes when bills/purchases/batches change in Isar
/// 4. DashboardRefreshService events trigger recalculation too
/// 5. Debounced updates prevent excessive rebuilds
class OptimizedDashboardCubit extends Cubit<OptimizedDashboardState> {
  final DashboardRepositoryImpl _repository;
  StreamSubscription<DashboardSummary>? _realtimeSubscription;
  StreamSubscription<void>? _refreshServiceSubscription;

  /// Track if initial load has completed
  bool _isInitialized = false;

  /// Debounce timer for rapid successive updates
  Timer? _debounceTimer;

  OptimizedDashboardCubit({DashboardRepositoryImpl? repository})
    : _repository = repository ?? DashboardRepositoryImpl(),
      super(const DashboardInitialState()) {
    // Immediately try to load cached data synchronously
    _loadCachedDataSync();
  }

  /// Load cached data synchronously on cubit creation
  /// This ensures UI renders instantly with cached data
  void _loadCachedDataSync() {
    final cachedData = _repository.getCachedSummary(params: state.params);
    if (cachedData != null) {
      emit(
        DashboardReadyState(
          params: state.params,
          data: cachedData,
          isRefreshing: true, // Will fetch fresh data
          lastUpdated: cachedData.lastUpdated,
        ),
      );
    }
  }

  /// Initialize the dashboard - call this after widget is built
  /// Fetches fresh data from Isar and starts reactive subscription
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final stopwatch = Stopwatch()..start();

    try {
      // Initialize repository (loads cache from disk if not in memory)
      await _repository.init();

      // If we don't have data yet, try to get from cache
      if (!state.hasData) {
        final cached = _repository.getCachedSummary(params: state.params);
        if (cached != null) {
          emit(
            DashboardReadyState(
              params: state.params,
              data: cached,
              isRefreshing: true,
              lastUpdated: cached.lastUpdated,
            ),
          );
        }
      }

      // Fetch fresh data from Isar (instant)
      await _refreshData(showRefreshIndicator: state.hasData);

      // Start reactive Isar watchers — auto-refresh on any data change
      _subscribeToRealtimeUpdates();

      // Also subscribe to DashboardRefreshService for external refresh requests
      _subscribeToRefreshService();

      stopwatch.stop();
      debugPrint(
        '[DashboardCubit] Initialize completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      debugPrint('[DashboardCubit] Initialize error: $e');
      _handleError(e);
    }
  }

  /// Load dashboard with current parameters
  Future<void> loadDashboard() async {
    // If we have cached data, show it immediately with refreshing indicator
    if (state.hasData) {
      final currentState = state as DashboardReadyState;
      emit(currentState.withRefreshing(true));
    }

    try {
      final data = await _repository.getDashboardSummary(
        params: state.params,
        forceRefresh: true,
      );

      emit(
        DashboardReadyState(
          params: state.params,
          data: data,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      _handleError(e);
    }
  }

  /// Force refresh from Isar (called by pull-to-refresh or DashboardRefreshService)
  /// Debounced to coalesce rapid successive data changes
  Completer<void>? _refreshCompleter;

  Future<void> refresh() async {
    // Debounce rapid refresh calls (e.g., multiple data changes in quick succession)
    _debounceTimer?.cancel();

    // Reuse existing completer if a refresh is already pending
    _refreshCompleter ??= Completer<void>();
    final completer = _refreshCompleter!;

    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        // Mark as refreshing but keep existing data visible
        if (state.hasData) {
          final currentState = state as DashboardReadyState;
          emit(currentState.withRefreshing(true));
        }
        await _refreshData(showRefreshIndicator: true);
      } finally {
        if (!completer.isCompleted) completer.complete();
        _refreshCompleter = null;
      }
    });

    return completer.future;
  }

  /// Change filter and reload data
  Future<void> changeFilter(DashboardFilter filter) async {
    if (filter == state.params.filter && filter != DashboardFilter.custom) {
      return; // No change needed
    }

    final newParams = state.params.copyWith(filter: filter);

    // Try to get cached data for new filter first
    final cachedData = _repository.getCachedSummary(params: newParams);

    if (cachedData != null) {
      emit(
        DashboardReadyState(
          params: newParams,
          data: cachedData,
          isRefreshing: true,
          lastUpdated: cachedData.lastUpdated,
        ),
      );
    } else if (state.hasData) {
      emit(
        DashboardReadyState(
          params: newParams,
          data: state.data!,
          isRefreshing: true,
          lastUpdated: state.lastUpdated,
        ),
      );
    } else {
      emit(DashboardInitialState(params: newParams));
    }

    // Fetch fresh data from Isar
    await _refreshData(showRefreshIndicator: true);

    // Re-subscribe with new params
    _subscribeToRealtimeUpdates();
  }

  /// Set custom date range
  Future<void> setCustomDateRange(DateTime start, DateTime end) async {
    final newParams = DashboardParams(
      filter: DashboardFilter.custom,
      startDate: start,
      endDate: end,
    );

    // Try cached data first
    final cachedData = _repository.getCachedSummary(params: newParams);

    if (cachedData != null) {
      emit(
        DashboardReadyState(
          params: newParams,
          data: cachedData,
          isRefreshing: true,
          lastUpdated: cachedData.lastUpdated,
        ),
      );
    } else if (state.hasData) {
      emit(
        DashboardReadyState(
          params: newParams,
          data: state.data!,
          isRefreshing: true,
          lastUpdated: state.lastUpdated,
        ),
      );
    }

    await _refreshData(showRefreshIndicator: true);

    // Re-subscribe with new params
    _subscribeToRealtimeUpdates();
  }

  /// Internal method to refresh data from Isar
  Future<void> _refreshData({required bool showRefreshIndicator}) async {
    try {
      final data = await _repository.getDashboardSummary(
        params: state.params,
        forceRefresh: true,
      );

      emit(
        DashboardReadyState(
          params: state.params,
          data: data,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      _handleError(e);
    }
  }

  /// Subscribe to real-time Isar updates
  /// Isar's watchLazy() fires whenever bills/purchases/batches change locally
  void _subscribeToRealtimeUpdates() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _repository
        .watchDashboardSummary(params: state.params)
        .listen(
          (data) {
            // Only emit if data actually changed (Equatable comparison)
            if (data != state.data) {
              emit(
                DashboardReadyState(
                  params: state.params,
                  data: data,
                  isRefreshing: false,
                  lastUpdated: DateTime.now(),
                ),
              );
            }
          },
          onError: (e) {
            debugPrint('[DashboardCubit] Realtime stream error: $e');
          },
        );
  }

  /// Subscribe to DashboardRefreshService for external refresh requests
  /// This catches refreshes triggered from other parts of the app
  void _subscribeToRefreshService() {
    _refreshServiceSubscription?.cancel();
    _refreshServiceSubscription = DashboardRefreshService
        .instance
        .onRefreshNeeded
        .listen((_) {
          debugPrint(
            '[DashboardCubit] External refresh requested via DashboardRefreshService',
          );
          refresh();
        });
  }

  /// Handle errors gracefully
  void _handleError(Object error) {
    final message = error.toString();

    // If we have cached data, show error but keep data visible
    if (state.hasData) {
      emit(
        DashboardErrorState(
          params: state.params,
          errorMessage: message,
          data: state.data,
          canRetry: true,
        ),
      );
    } else {
      emit(
        DashboardErrorState(
          params: state.params,
          errorMessage: message,
          canRetry: true,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _realtimeSubscription?.cancel();
    _refreshServiceSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}
