import 'package:flutter/foundation.dart';
import 'dart:async';

import '../../features/dashboard/data/repositories/dashboard_repository.dart';

// Enum representing the type of data that changed
enum DataChangeType {
  customer,
  supplier,
  company,
  product,
  bill,
  purchase,
  purchaseReturn,
  billSettings,
  eventOrder,
}

// Singleton service to notify screens to refresh when data changes. This service acts as a communication bridge between data modification pages (Customer, Supplier, Company, Bill,...
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
  final StreamController<void> _eventOrderChangeController = StreamController<void>.broadcast();
  
  // Stream that emits when any data changes (for dashboard)
  Stream<void> get onRefreshNeeded => _refreshController.stream;
  
  // Stream that emits when customer data changes
  Stream<void> get onCustomerChanged => _customerChangeController.stream;
  
  // Stream that emits when supplier data changes
  Stream<void> get onSupplierChanged => _supplierChangeController.stream;
  
  // Stream that emits when company data changes
  Stream<void> get onCompanyChanged => _companyChangeController.stream;
  
  // Stream that emits when product data changes
  Stream<void> get onProductChanged => _productChangeController.stream;
  
  // Stream that emits when bill data changes
  Stream<void> get onBillChanged => _billChangeController.stream;
  
  // Stream that emits when purchase data changes
  Stream<void> get onPurchaseChanged => _purchaseChangeController.stream;
  
  // Stream that emits when purchase return data changes
  Stream<void> get onPurchaseReturnChanged => _purchaseReturnChangeController.stream;
  
  // Stream that emits when bill settings change
  Stream<void> get onBillSettingsChanged => _billSettingsChangeController.stream;
  
  // Stream that emits when event/order data changes
  Stream<void> get onEventOrderChanged => _eventOrderChangeController.stream;
  
  // Call this method when any data that affects dashboard stats changes. Optionally specify the data type that changed for more granular notifications.
  void notifyDataChanged([DataChangeType? dataType]) {
    if (dataType == null) {
      notifyDataChangedTypes(DataChangeType.values);
      return;
    }
    notifyDataChangedTypes([dataType]);
  }

  // Notify multiple related streams with a single dashboard refresh. Use this for transactions that affect stock, bills, and ledgers together.
  void notifyDataChangedTypes(Iterable<DataChangeType> types) {
    final unique = <DataChangeType>{...types};
    if (unique.isEmpty) return;

    DashboardRepository.invalidateCache();
    _refreshController.add(null);

    for (final dataType in unique) {
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
        case DataChangeType.eventOrder:
          _eventOrderChangeController.add(null);
          break;
      }
    }

    debugPrint(
      '[DashboardRefreshService] ${unique.map((t) => t.name).join(', ')} changed - notifying listeners',
    );
  }

  // Stock / sale / purchase / return flows that should refresh inventory and ledger UIs immediately.
  void notifyInventoryTransactionChanged({
    bool includeCustomer = false,
    bool includeSupplier = false,
  }) {
    final types = <DataChangeType>[
      DataChangeType.product,
      DataChangeType.purchase,
      DataChangeType.purchaseReturn,
      DataChangeType.bill,
    ];
    if (includeCustomer) types.add(DataChangeType.customer);
    if (includeSupplier) types.add(DataChangeType.supplier);
    notifyDataChangedTypes(types);
  }
  
  // Dispose the service (typically called when app closes)
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
    _eventOrderChangeController.close();
  }
}
