import 'package:c_billing/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:c_billing/features/dashboard/domain/repositories/dashboard_repository_interface.dart';
import 'package:c_billing/features/dashboard/presentation/cubit/optimized_dashboard_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('error state with cached data is not a DashboardReadyState', () {
    final summary = DashboardSummary(
      lastUpdated: DateTime(2026, 1, 1),
      totalSales: 100,
      isFromCache: true,
    );
    final state = DashboardErrorState(
      params: const DashboardParams(),
      errorMessage: 'boom',
      data: summary,
      canRetry: true,
    );

    expect(state.hasData, isTrue);
    expect(state, isA<OptimizedDashboardState>());
    expect(state, isNot(isA<DashboardReadyState>()));

    // The safe refresh path rebuilds Ready from base fields instead of casting.
    final refreshing = DashboardReadyState(
      params: state.params,
      data: state.data!,
      isRefreshing: true,
      lastUpdated: state.lastUpdated,
    );
    expect(refreshing.isRefreshing, isTrue);
    expect(refreshing.data?.totalSales, 100);
  });
}
