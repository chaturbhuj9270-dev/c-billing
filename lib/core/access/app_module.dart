import '../../features/dashboard/presentation/pages/web_shell.dart';

// Stable module keys used for employee permissions and navigation gating.
enum AppModule {
  dashboard('dashboard', WebShell.dashboard, 'Dashboard'),
  customers('customers', WebShell.customers, 'Customers'),
  billing('billing', WebShell.billing, 'Billing'),
  availability('availability', WebShell.availability, 'Availability'),
  purchase('purchase', WebShell.purchase, 'Purchase'),
  invoices('invoices', WebShell.invoices, 'Invoices'),
  products('products', WebShell.products, 'Products'),
  suppliers('suppliers', WebShell.suppliers, 'Suppliers'),
  companies('companies', WebShell.companies, 'Companies'),
  purchaseReturn('purchase_return', WebShell.purchaseReturn, 'Purchase return'),
  events('events', WebShell.events, 'Events'),
  quotations('quotations', WebShell.quotations, 'Quotations'),
  barcode('barcode', WebShell.barcode, 'Barcode'),
  expenses('expenses', WebShell.expenses, 'Expenses'),
  shop('shop', WebShell.shop, 'Shop details'),
  profile('profile', WebShell.profile, 'Profile'),
  password('password', WebShell.password, 'Change password'),
  employees('employees', WebShell.employees, 'Employees');

  const AppModule(this.key, this.shellIndex, this.label);

  final String key;
  final int shellIndex;
  final String label;

  // Modules an admin can grant to counter staff (excludes admin-only).
  static const List<AppModule> grantable = [
    AppModule.dashboard,
    AppModule.customers,
    AppModule.billing,
    AppModule.availability,
    AppModule.purchase,
    AppModule.invoices,
    AppModule.products,
    AppModule.suppliers,
    AppModule.companies,
    AppModule.purchaseReturn,
    AppModule.events,
    AppModule.quotations,
    AppModule.barcode,
    AppModule.expenses,
    AppModule.password,
  ];

  // Default for a new employee: all grantable modules except dashboard & expenses.
  static const List<AppModule> defaultEmployeeModules = [
    AppModule.customers,
    AppModule.billing,
    AppModule.availability,
    AppModule.purchase,
    AppModule.invoices,
    AppModule.products,
    AppModule.suppliers,
    AppModule.companies,
    AppModule.purchaseReturn,
    AppModule.events,
    AppModule.quotations,
    AppModule.barcode,
    AppModule.password,
  ];

  // Always owner-only — never grantable to employees.
  static const List<AppModule> ownerOnly = [
    AppModule.shop,
    AppModule.profile,
    AppModule.employees,
  ];

  static AppModule? fromKey(String key) {
    for (final m in AppModule.values) {
      if (m.key == key) return m;
    }
    return null;
  }

  static AppModule? fromShellIndex(int index) {
    for (final m in AppModule.values) {
      if (m.shellIndex == index) return m;
    }
    return null;
  }

  static Set<String> get allKeys =>
      AppModule.values.map((m) => m.key).toSet();
}
