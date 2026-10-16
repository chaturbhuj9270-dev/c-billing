import 'package:equatable/equatable.dart';
import '../../data/models/dashboard_data.dart';

/// Filter type for dashboard
enum DashboardFilter { today, thisWeek, thisMonth, thisYear, custom, all }

/// Base class for dashboard states
sealed class DashboardState extends Equatable {
  final DashboardFilter filter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const DashboardState({
    this.filter = DashboardFilter.thisMonth,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  List<Object?> get props => [filter, customStartDate, customEndDate];
}

/// Initial state when dashboard is first loaded
class DashboardInitial extends DashboardState {
  const DashboardInitial() : super();
}

/// Loading state while fetching data
class DashboardLoading extends DashboardState {
  final DashboardData? previousData;

  const DashboardLoading({
    super.filter,
    super.customStartDate,
    super.customEndDate,
    this.previousData,
  });

  @override
  List<Object?> get props => [...super.props, previousData];
}

/// Loaded state with dashboard data
class DashboardLoaded extends DashboardState {
  final DashboardData data;

  const DashboardLoaded({
    required this.data,
    super.filter,
    super.customStartDate,
    super.customEndDate,
  });

  @override
  List<Object?> get props => [...super.props, data];
}

/// Error state when data fetching fails
class DashboardError extends DashboardState {
  final String message;
  final DashboardData? previousData;

  const DashboardError({
    required this.message,
    super.filter,
    super.customStartDate,
    super.customEndDate,
    this.previousData,
  });

  @override
  List<Object?> get props => [...super.props, message, previousData];
}
