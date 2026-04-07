/// Predefined hotel staff roles.
enum HotelUserRole {
  admin,
  waiter,
  cook,
  captain,
  receptionist,
  manager,
  housekeeping,
  custom,
}

extension HotelUserRoleX on HotelUserRole {
  String get label {
    switch (this) {
      case HotelUserRole.admin:
        return 'Admin';
      case HotelUserRole.waiter:
        return 'Waiter';
      case HotelUserRole.cook:
        return 'Cook';
      case HotelUserRole.captain:
        return 'Captain';
      case HotelUserRole.receptionist:
        return 'Receptionist';
      case HotelUserRole.manager:
        return 'Manager';
      case HotelUserRole.housekeeping:
        return 'Housekeeping';
      case HotelUserRole.custom:
        return 'Custom';
    }
  }

  static HotelUserRole fromString(String value) {
    return HotelUserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => HotelUserRole.custom,
    );
  }
}

/// Modules available in the Hotel app for permission control.
enum HotelModule {
  dashboard,
  tableManagement,
  orderManagement,
  menuManagement,
  kitchenDisplay,
  billing,
  inventory,
  roomManagement,
  guestManagement,
  staffManagement,
  reports,
  settings,
  expenses,
}

extension HotelModuleX on HotelModule {
  String get label {
    switch (this) {
      case HotelModule.dashboard:
        return 'Dashboard';
      case HotelModule.tableManagement:
        return 'Table Management';
      case HotelModule.orderManagement:
        return 'Order Management';
      case HotelModule.menuManagement:
        return 'Menu Management';
      case HotelModule.kitchenDisplay:
        return 'Kitchen Display';
      case HotelModule.billing:
        return 'Billing';
      case HotelModule.inventory:
        return 'Inventory';
      case HotelModule.roomManagement:
        return 'Room Management';
      case HotelModule.guestManagement:
        return 'Guest Management';
      case HotelModule.staffManagement:
        return 'Staff Management';
      case HotelModule.reports:
        return 'Reports';
      case HotelModule.settings:
        return 'Settings';
      case HotelModule.expenses:
        return 'Expenses';
    }
  }

  String get icon {
    switch (this) {
      case HotelModule.dashboard:
        return 'dashboard';
      case HotelModule.tableManagement:
        return 'table_restaurant';
      case HotelModule.orderManagement:
        return 'receipt_long';
      case HotelModule.menuManagement:
        return 'restaurant_menu';
      case HotelModule.kitchenDisplay:
        return 'kitchen';
      case HotelModule.billing:
        return 'point_of_sale';
      case HotelModule.inventory:
        return 'inventory_2';
      case HotelModule.roomManagement:
        return 'hotel';
      case HotelModule.guestManagement:
        return 'people';
      case HotelModule.staffManagement:
        return 'badge';
      case HotelModule.reports:
        return 'analytics';
      case HotelModule.settings:
        return 'settings';
      case HotelModule.expenses:
        return 'account_balance_wallet';
    }
  }
}
