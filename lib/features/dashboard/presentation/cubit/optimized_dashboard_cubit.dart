import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import 'optimized_dashboard_state.dart';

/// High-performance Dashboard Cubit with cache-first strategy
/// 
/// Key optimizations:
/// 1. Synchronously loads cached data before any async operations
/// 2. Emits UI-ready state immediately (no blocking on Firebase)
/// 3. Background refresh with smooth state transitions
/// 4. Minimal and incremental state updates to prevent unnecessary rebuilds
class OptimizedDashboardCubit extends Cubit<OptimizedDashboardState> {
  final DashboardRepositoryImpl _repository;
  StreamSubscription<DashboardSummary>? _subscription;
  
  /// Track if initial load has completed
  bool _isInitialized = false;

  OptimizedDashboardCubit({
    DashboardRepositoryImpl? repository,
  })  : _repository = repository ?? DashboardRepositoryImpl(),
        super(const DashboardInitialState()) {
    // Immediately try to load cached data synchronously
    _loadCachedDataSync();
  }

  /// Load cached data synchronously on cubit creation
  /// This ensures UI renders instantly with cached data
  void _loadCachedDataSync() {
    final cachedData = _repository.getCachedSummary(params: state.params);
    if (cachedData != null) {
      emit(DashboardReadyState(
        params: state.params,
        data: cachedData,
        isRefreshing: true, // Will fetch fresh data
        lastUpdated: cachedData.lastUpdated,
      ));
    }
  }

  /// Initialize the dashboard - call this after widget is built
  /// Fetches fresh data in background while UI is already rendered
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
          emit(DashboardReadyState(
            params: state.params,
            data: cached,
            isRefreshing: true,
            lastUpdated: cached.lastUpdated,
          ));
        }
      }

      // Fetch fresh data in background
      await _refreshData(showRefreshIndicator: state.hasData);

      stopwatch.stop();
      print('[OptimizedDashboardCubit] Initialize completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('[OptimizedDashboardCubit] Initialize error: $e');
      _handleError(e);
    }
  }

  /// Load dashboard with current parameters
  /// Uses cache-first strategy
  Future<void> loadDashboard() async {
    final stopwatch = Stopwatch()..start();

    // If we have cached data, show it immediately with refreshing indicator
    if (state.hasData) {
      final currentState = state as DashboardReadyState;
      emit(currentState.withRefreshing(true));
    }

    try {
      final data = await _repository.getDashboardSummary(
        params: state.params,
        forceRefresh: false, // Use cache-first
      );

      emit(DashboardReadyState(
        params: state.params,
        data: data,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      ));

      stopwatch.stop();
      print('[OptimizedDashboardCubit] Load completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      _handleError(e);
    }
  }

  /// Force refresh from network
  Future<void> refresh() async {
    // Mark as refreshing but keep existing data visible
    if (state.hasData) {
      final currentState = state as DashboardReadyState;
      emit(currentState.withRefreshing(true));
    }

    await _refreshData(showRefreshIndicator: true);
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
      // Have cached data - show it immediately
      emit(DashboardReadyState(
        params: newParams,
        data: cachedData,
        isRefreshing: true, // Will fetch fresh
        lastUpdated: cachedData.lastUpdated,
      ));
    } else if (state.hasData) {
      // No cache but have current data - keep showing it
      emit(DashboardReadyState(
        params: newParams,
        data: state.data!,
        isRefreshing: true,
        lastUpdated: state.lastUpdated,
      ));
    } else {
      // No data at all - show initial state
      emit(DashboardInitialState(params: newParams));
    }

    // Fetch fresh data
    await _refreshData(showRefreshIndicator: true);
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
      emit(DashboardReadyState(
        params: newParams,
        data: cachedData,
        isRefreshing: true,
        lastUpdated: cachedData.lastUpdated,
      ));
    } else if (state.hasData) {
      emit(DashboardReadyState(
        params: newParams,
        data: state.data!,
        isRefreshing: true,
        lastUpdated: state.lastUpdated,
      ));
    }

    await _refreshData(showRefreshIndicator: true);
  }

  /// Internal method to refresh data from Firebase
  Future<void> _refreshData({required bool showRefreshIndicator}) async {
    try {
      final data = await _repository.getDashboardSummary(
        params: state.params,
        forceRefresh: true,
      );

      emit(DashboardReadyState(
        params: state.params,
        data: data,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      _handleError(e);
    }
  }

  /// Handle errors gracefully
  void _handleError(Object error) {
    final message = error.toString();
    
    // If we have cached data, show error but keep data visible
    if (state.hasData) {
      emit(DashboardErrorState(
        params: state.params,
        errorMessage: message,
        data: state.data,
        canRetry: true,
      ));
    } else {
      emit(DashboardErrorState(
        params: state.params,
        errorMessage: message,
        canRetry: true,
      ));
    }
  }

  /// Subscribe to real-time updates (optional)
  void subscribeToUpdates() {
    _subscription?.cancel();
    _subscription = _repository
        .watchDashboardSummary(params: state.params)
        .listen(
          (data) {
            emit(DashboardReadyState(
              params: state.params,
              data: data,
              isRefreshing: false,
              lastUpdated: DateTime.now(),
            ));
          },
          onError: (e) => _handleError(e),
        );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}
