import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/dashboard_offline_repository.dart';
import 'dashboard_state.dart';

/// Cubit for managing dashboard state and data loading
/// Uses offline-first repository for instant data loading
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardOfflineRepository _repository;

  DashboardCubit({DashboardOfflineRepository? repository})
    : _repository = repository ?? DashboardOfflineRepository.instance,
      super(const DashboardInitial());

  /// Load dashboard data with the current filter
  /// Uses local Isar database for microsecond-level loading
  Future<void> loadDashboard() async {
    final stopwatch = Stopwatch()..start();

    // Get previous data for loading state
    final previousData = state is DashboardLoaded
        ? (state as DashboardLoaded).data
        : state is DashboardLoading
        ? (state as DashboardLoading).previousData
        : null;

    emit(
      DashboardLoading(
        filter: state.filter,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        previousData: previousData,
      ),
    );

    try {
      final dateRange = _getDateRange(
        state.filter,
        state.customStartDate,
        state.customEndDate,
      );

      final data = await _repository.fetchDashboardData(
        startDate: dateRange['start'],
        endDate: dateRange['end'],
      );

      stopwatch.stop();
      print(
        '[DashboardCubit] Total load time: ${stopwatch.elapsedMicroseconds}μs (${stopwatch.elapsedMilliseconds}ms)',
      );

      emit(
        DashboardLoaded(
          data: data,
          filter: state.filter,
          customStartDate: state.customStartDate,
          customEndDate: state.customEndDate,
        ),
      );
    } catch (e) {
      print('[DashboardCubit] Error: $e');
      emit(
        DashboardError(
          message: e.toString(),
          filter: state.filter,
          customStartDate: state.customStartDate,
          customEndDate: state.customEndDate,
          previousData: previousData,
        ),
      );
    }
  }

  /// Change the filter and reload data
  Future<void> changeFilter(DashboardFilter filter) async {
    if (filter == state.filter && filter != DashboardFilter.custom) return;

    final previousData = state is DashboardLoaded
        ? (state as DashboardLoaded).data
        : null;

    emit(
      DashboardLoading(
        filter: filter,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        previousData: previousData,
      ),
    );

    await loadDashboard();
  }

  /// Set custom date range and reload
  Future<void> setCustomDateRange(DateTime start, DateTime end) async {
    final previousData = state is DashboardLoaded
        ? (state as DashboardLoaded).data
        : null;

    emit(
      DashboardLoading(
        filter: DashboardFilter.custom,
        customStartDate: start,
        customEndDate: end,
        previousData: previousData,
      ),
    );

    try {
      final data = await _repository.fetchDashboardData(
        startDate: start,
        endDate: DateTime(end.year, end.month, end.day, 23, 59, 59),
      );

      emit(
        DashboardLoaded(
          data: data,
          filter: DashboardFilter.custom,
          customStartDate: start,
          customEndDate: end,
        ),
      );
    } catch (e) {
      emit(
        DashboardError(
          message: e.toString(),
          filter: DashboardFilter.custom,
          customStartDate: start,
          customEndDate: end,
          previousData: previousData,
        ),
      );
    }
  }

  /// Refresh dashboard data with current filter
  Future<void> refresh() async {
    await loadDashboard();
  }

  /// Get date range based on filter
  Map<String, DateTime?> _getDateRange(
    DashboardFilter filter,
    DateTime? customStart,
    DateTime? customEnd,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case DashboardFilter.today:
        return {
          'start': today,
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case DashboardFilter.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return {'start': startOfWeek, 'end': endOfWeek};
      case DashboardFilter.thisMonth:
        return {
          'start': DateTime(now.year, now.month, 1),
          'end': DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        };
      case DashboardFilter.thisYear:
        return {
          'start': DateTime(now.year, 1, 1),
          'end': DateTime(now.year, 12, 31, 23, 59, 59),
        };
      case DashboardFilter.custom:
        return {
          'start': customStart,
          'end': customEnd != null
              ? DateTime(
                  customEnd.year,
                  customEnd.month,
                  customEnd.day,
                  23,
                  59,
                  59,
                )
              : null,
        };
      case DashboardFilter.all:
        return {'start': null, 'end': null};
    }
  }
}
