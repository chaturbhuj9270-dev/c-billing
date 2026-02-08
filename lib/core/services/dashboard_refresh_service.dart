import 'dart:async';

import '../../features/dashboard/data/repositories/dashboard_repository.dart';

/// Singleton service to notify dashboard to refresh when data changes.
/// 
/// This service acts as a communication bridge between data modification pages
/// (Customer, Supplier, Company, Bill, Product pages) and the dashboard.
/// 
/// Usage:
/// ```dart
/// // After adding/updating/deleting data:
/// DashboardRefreshService.instance.notifyDataChanged();
/// ```
class DashboardRefreshService {
  static final DashboardRefreshService _instance = DashboardRefreshService._internal();
  
  static DashboardRefreshService get instance => _instance;
  
  DashboardRefreshService._internal();
  
  // Stream controller for notifying listeners about data changes
  final StreamController<void> _refreshController = StreamController<void>.broadcast();
  
  /// Stream that emits when data changes and dashboard should refresh
  Stream<void> get onRefreshNeeded => _refreshController.stream;
  
  /// Call this method when any data that affects dashboard stats changes.
  /// This includes:
  /// - Adding/updating/deleting customers
  /// - Adding/updating/deleting suppliers
  /// - Adding/updating/deleting companies
  /// - Adding/updating/deleting bills
  /// - Adding/updating/deleting products
  void notifyDataChanged() {
    // Invalidate the cache in dashboard repository
    DashboardRepository.invalidateCache();
    
    // Notify all listeners that refresh is needed
    _refreshController.add(null);
    
    print('[DashboardRefreshService] Data changed - notifying dashboard to refresh');
  }
  
  /// Dispose the service (typically called when app closes)
  void dispose() {
    _refreshController.close();
  }
}
