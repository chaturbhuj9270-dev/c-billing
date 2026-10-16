import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';

/// Optimized dashboard state for cache-first loading
/// Uses sealed classes for type-safe state handling
sealed class OptimizedDashboardState extends Equatable {
  final DashboardParams params;
  final DashboardSummary? data;
  final bool isRefreshing;
  final DateTime? lastUpdated;

  const OptimizedDashboardState({
    required this.params,
    this.data,
    this.isRefreshing = false,
    this.lastUpdated,
  });

  /// Check if we have data to display
  bool get hasData => data != null;

  /// Check if data is from cache
  bool get isFromCache => data?.isFromCache ?? false;

  @override
  List<Object?> get props => [params, data, isRefreshing, lastUpdated];
}

/// Initial state - no data loaded yet
/// UI should show placeholder/shimmer
class DashboardInitialState extends OptimizedDashboardState {
  const DashboardInitialState({
    super.params = const DashboardParams(),
  }) : super(data: null, isRefreshing: false);
}

/// Ready state - has data (cached or fresh)
/// UI renders normally with data
class DashboardReadyState extends OptimizedDashboardState {
  const DashboardReadyState({
    required super.params,
    required DashboardSummary super.data,
    super.isRefreshing,
    super.lastUpdated,
  });

  /// Create a copy with refreshing status
  DashboardReadyState withRefreshing(bool refreshing) {
    return DashboardReadyState(
      params: params,
      data: data!,
      isRefreshing: refreshing,
      lastUpdated: lastUpdated,
    );
  }

  /// Create a copy with new data
  DashboardReadyState withNewData(DashboardSummary newData) {
    return DashboardReadyState(
      params: params,
      data: newData,
      isRefreshing: false,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Error state - fetch failed but may have cached data
/// UI shows error indicator but can still display cached data
class DashboardErrorState extends OptimizedDashboardState {
  final String errorMessage;
  final bool canRetry;

  const DashboardErrorState({
    required super.params,
    required this.errorMessage,
    super.data,
    this.canRetry = true,
  }) : super(isRefreshing: false);

  @override
  List<Object?> get props => [...super.props, errorMessage, canRetry];
}
