import 'dart:async';

import '../../features/dashboard/data/repositories/dashboard_repository.dart';

/// Enum representing the type of data that changed
enum DataChangeType {
  customer,
  supplier,
  company,
  product,
  bill,
  purchase,
  purchaseReturn,
  billSettings,
}

/// Singleton service to notify screens to refresh when data changes.
/// 
/// This service acts as a communication bridge between data modification pages
/// (Customer, Supplier, Company, Bill, Product pages) and other screens that
/// need to refresh their data.
/// 
/// Usage:
/// ```dart
/// // After adding/updating/deleting data:
/// DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
/// 
/// // Or for multiple types:
/// DashboardRefreshService.instance.notifyDataChanged();
/// ```
class DashboardRefreshService {
  static final DashboardRefreshService _instance = DashboardRefreshService._internal();
  
  static DashboardRefreshService get instance => _instance;
  
  DashboardRefreshService._internal();
  
  // Stream controller for notifying listeners about data changes (general)
  final StreamController<void> _refreshController = StreamController<void>.broadcast();
  
  // Stream controllers for specific data types
  final StreamController<void> _customerChangeController = StreamController<void>.broadcast();
  final StreamController<void> _supplierChangeController = StreamController<void>.broadcast();
  final StreamController<void> _companyChangeController = StreamController<void>.broadcast();
  final StreamController<void> _productChangeController = StreamController<void>.broadcast();
  final StreamController<void> _billChangeController = StreamController<void>.broadcast();
  final StreamController<void> _purchaseChangeController = StreamController<void>.broadcast();
  final StreamController<void> _purchaseReturnChangeController = StreamController<void>.broadcast();
  final StreamController<void> _billSettingsChangeController = StreamController<void>.broadcast();
  
  /// Stream that emits when any data changes (for dashboard)
  Stream<void> get onRefreshNeeded => _refreshController.stream;
  
  /// Stream that emits when customer data changes
  Stream<void> get onCustomerChanged => _customerChangeController.stream;
  
  /// Stream that emits when supplier data changes
  Stream<void> get onSupplierChanged => _supplierChangeController.stream;
  
  /// Stream that emits when company data changes
  Stream<void> get onCompanyChanged => _companyChangeController.stream;
  
  /// Stream that emits when product data changes
  Stream<void> get onProductChanged => _productChangeController.stream;
  
  /// Stream that emits when bill data changes
  Stream<void> get onBillChanged => _billChangeController.stream;
  
  /// Stream that emits when purchase data changes
  Stream<void> get onPurchaseChanged => _purchaseChangeController.stream;
  
  /// Stream that emits when purchase return data changes
  Stream<void> get onPurchaseReturnChanged => _purchaseReturnChangeController.stream;
  
  /// Stream that emits when bill settings change
  Stream<void> get onBillSettingsChanged => _billSettingsChangeController.stream;
  
  /// Call this method when any data that affects dashboard stats changes.
  /// Optionally specify the data type that changed for more granular notifications.
  void notifyDataChanged([DataChangeType? dataType]) {
    // Invalidate the cache in dashboard repository
    DashboardRepository.invalidateCache();
    
    // Notify all general listeners
    _refreshController.add(null);
    
    // Notify specific data type listeners
    if (dataType != null) {
      switch (dataType) {
        case DataChangeType.customer:
          _customerChangeController.add(null);
          break;
        case DataChangeType.supplier:
          _supplierChangeController.add(null);
          break;
        case DataChangeType.company:
          _companyChangeController.add(null);
          break;
        case DataChangeType.product:
          _productChangeController.add(null);
          break;
        case DataChangeType.bill:
          _billChangeController.add(null);
          break;
        case DataChangeType.purchase:
          _purchaseChangeController.add(null);
          break;
        case DataChangeType.purchaseReturn:
          _purchaseReturnChangeController.add(null);
          break;
        case DataChangeType.billSettings:
          _billSettingsChangeController.add(null);
          break;
      }
      print('[DashboardRefreshService] ${dataType.name} data changed - notifying listeners');
    } else {
      // Notify all specific listeners when no specific type is given
      _customerChangeController.add(null);
      _supplierChangeController.add(null);
      _companyChangeController.add(null);
      _productChangeController.add(null);
      _billChangeController.add(null);
      _purchaseChangeController.add(null);
      _purchaseReturnChangeController.add(null);
      _billSettingsChangeController.add(null);
      print('[DashboardRefreshService] All data changed - notifying all listeners');
    }
  }
  
  /// Dispose the service (typically called when app closes)
  void dispose() {
    _refreshController.close();
    _customerChangeController.close();
    _supplierChangeController.close();
    _companyChangeController.close();
    _productChangeController.close();
    _billChangeController.close();
    _purchaseChangeController.close();
    _purchaseReturnChangeController.close();
    _billSettingsChangeController.close();
  }
}
