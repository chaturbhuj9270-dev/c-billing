import '../entities/dashboard_summary.dart';

/// Date range filter for dashboard queries
enum DashboardFilter { today, thisWeek, thisMonth, thisYear, custom, all }

/// Parameters for fetching dashboard data
class DashboardParams {
  final DashboardFilter filter;
  final DateTime? startDate;
  final DateTime? endDate;

  const DashboardParams({
    this.filter = DashboardFilter.thisMonth,
    this.startDate,
    this.endDate,
  });

  /// Generate cache key for these params
  String get cacheKey {
    if (filter == DashboardFilter.custom && startDate != null && endDate != null) {
      return 'dashboard_${filter.name}_${startDate!.millisecondsSinceEpoch}_${endDate!.millisecondsSinceEpoch}';
    }
    return 'dashboard_${filter.name}';
  }

  /// Get date range based on filter
  (DateTime?, DateTime?) getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case DashboardFilter.today:
        return (today, DateTime(now.year, now.month, now.day, 23, 59, 59));
      case DashboardFilter.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return (startOfWeek, endOfWeek);
      case DashboardFilter.thisMonth:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case DashboardFilter.thisYear:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case DashboardFilter.custom:
        if (startDate != null && endDate != null) {
          return (
            startDate,
            DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59),
          );
        }
        return (null, null);
      case DashboardFilter.all:
        return (null, null);
    }
  }

  DashboardParams copyWith({
    DashboardFilter? filter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DashboardParams(
      filter: filter ?? this.filter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// Abstract repository interface for dashboard data
/// This defines the contract for data access, enabling clean architecture
abstract class DashboardRepositoryInterface {
  /// Get dashboard summary data
  /// Returns cached data first if available, then fresh data
  /// 
  /// [params] - Filter parameters for the dashboard query
  /// [forceRefresh] - If true, bypasses cache and fetches from network
  Future<DashboardSummary> getDashboardSummary({
    required DashboardParams params,
    bool forceRefresh = false,
  });

  /// Stream of dashboard data for real-time updates
  /// Emits cached data first, then fresh data when available
  Stream<DashboardSummary> watchDashboardSummary({
    required DashboardParams params,
  });

  /// Get cached dashboard data synchronously
  /// Returns null if no cache exists
  DashboardSummary? getCachedSummary({required DashboardParams params});

  /// Clear all cached dashboard data
  Future<void> clearCache();

  /// Preload dashboard cache (call during app initialization)
  Future<void> preloadCache();
}
