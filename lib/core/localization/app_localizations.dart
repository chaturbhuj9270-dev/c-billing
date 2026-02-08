import 'english.dart';
import 'hindi.dart';
import 'marathi.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(String language) {
    return AppLocalizations(language);
  }

  // App General
  String get appName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.appName;
      case 'Marathi':
        return MarathiLocalization.appName;
      default:
        return EnglishLocalization.appName;
    }
  }

  String get tagline {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.tagline;
      case 'Marathi':
        return MarathiLocalization.tagline;
      default:
        return EnglishLocalization.tagline;
    }
  }

  // Dashboard
  String get dashboard {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.dashboard;
      case 'Marathi':
        return MarathiLocalization.dashboard;
      default:
        return EnglishLocalization.dashboard;
    }
  }

  String get welcomeBack {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.welcomeBack;
      case 'Marathi':
        return MarathiLocalization.welcomeBack;
      default:
        return EnglishLocalization.welcomeBack;
    }
  }

  String get goodMorning {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.goodMorning;
      case 'Marathi':
        return MarathiLocalization.goodMorning;
      default:
        return EnglishLocalization.goodMorning;
    }
  }

  String get goodAfternoon {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.goodAfternoon;
      case 'Marathi':
        return MarathiLocalization.goodAfternoon;
      default:
        return EnglishLocalization.goodAfternoon;
    }
  }

  String get goodEvening {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.goodEvening;
      case 'Marathi':
        return MarathiLocalization.goodEvening;
      default:
        return EnglishLocalization.goodEvening;
    }
  }

  String get businessOverview {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.businessOverview;
      case 'Marathi':
        return MarathiLocalization.businessOverview;
      default:
        return EnglishLocalization.businessOverview;
    }
  }

  String get quickInsights {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.quickInsights;
      case 'Marathi':
        return MarathiLocalization.quickInsights;
      default:
        return EnglishLocalization.quickInsights;
    }
  }

  String get atAGlance {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.atAGlance;
      case 'Marathi':
        return MarathiLocalization.atAGlance;
      default:
        return EnglishLocalization.atAGlance;
    }
  }

  // Quick Stats
  String get invoices {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.invoices;
      case 'Marathi':
        return MarathiLocalization.invoices;
      default:
        return EnglishLocalization.invoices;
    }
  }

  String get products {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.products;
      case 'Marathi':
        return MarathiLocalization.products;
      default:
        return EnglishLocalization.products;
    }
  }

  String get suppliers {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.suppliers;
      case 'Marathi':
        return MarathiLocalization.suppliers;
      default:
        return EnglishLocalization.suppliers;
    }
  }

  String get companies {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companies;
      case 'Marathi':
        return MarathiLocalization.companies;
      default:
        return EnglishLocalization.companies;
    }
  }

  // Filter Section
  String get filterByPeriod {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.filterByPeriod;
      case 'Marathi':
        return MarathiLocalization.filterByPeriod;
      default:
        return EnglishLocalization.filterByPeriod;
    }
  }

  String get today {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.today;
      case 'Marathi':
        return MarathiLocalization.today;
      default:
        return EnglishLocalization.today;
    }
  }

  String get thisWeek {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.thisWeek;
      case 'Marathi':
        return MarathiLocalization.thisWeek;
      default:
        return EnglishLocalization.thisWeek;
    }
  }

  String get thisMonth {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.thisMonth;
      case 'Marathi':
        return MarathiLocalization.thisMonth;
      default:
        return EnglishLocalization.thisMonth;
    }
  }

  String get thisYear {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.thisYear;
      case 'Marathi':
        return MarathiLocalization.thisYear;
      default:
        return EnglishLocalization.thisYear;
    }
  }

  String get allTime {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.allTime;
      case 'Marathi':
        return MarathiLocalization.allTime;
      default:
        return EnglishLocalization.allTime;
    }
  }

  String get customRange {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.customRange;
      case 'Marathi':
        return MarathiLocalization.customRange;
      default:
        return EnglishLocalization.customRange;
    }
  }

  // Sales & Profit
  String get salesProfitAnalysis {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.salesProfitAnalysis;
      case 'Marathi':
        return MarathiLocalization.salesProfitAnalysis;
      default:
        return EnglishLocalization.salesProfitAnalysis;
    }
  }

  String get totalSales {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.totalSales;
      case 'Marathi':
        return MarathiLocalization.totalSales;
      default:
        return EnglishLocalization.totalSales;
    }
  }

  String get totalPurchase {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.totalPurchase;
      case 'Marathi':
        return MarathiLocalization.totalPurchase;
      default:
        return EnglishLocalization.totalPurchase;
    }
  }

  String get netProfit {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.netProfit;
      case 'Marathi':
        return MarathiLocalization.netProfit;
      default:
        return EnglishLocalization.netProfit;
    }
  }

  String get profitMargin {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.profitMargin;
      case 'Marathi':
        return MarathiLocalization.profitMargin;
      default:
        return EnglishLocalization.profitMargin;
    }
  }

  String get bills {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.bills;
      case 'Marathi':
        return MarathiLocalization.bills;
      default:
        return EnglishLocalization.bills;
    }
  }

  String get items {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.items;
      case 'Marathi':
        return MarathiLocalization.items;
      default:
        return EnglishLocalization.items;
    }
  }

  String get orders {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.orders;
      case 'Marathi':
        return MarathiLocalization.orders;
      default:
        return EnglishLocalization.orders;
    }
  }

  String get qty {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.qty;
      case 'Marathi':
        return MarathiLocalization.qty;
      default:
        return EnglishLocalization.qty;
    }
  }

  // Inventory & Payments
  String get inventoryPayments {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.inventoryPayments;
      case 'Marathi':
        return MarathiLocalization.inventoryPayments;
      default:
        return EnglishLocalization.inventoryPayments;
    }
  }

  String get liveStatus {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.liveStatus;
      case 'Marathi':
        return MarathiLocalization.liveStatus;
      default:
        return EnglishLocalization.liveStatus;
    }
  }

  String get upcomingPayments {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.upcomingPayments;
      case 'Marathi':
        return MarathiLocalization.upcomingPayments;
      default:
        return EnglishLocalization.upcomingPayments;
    }
  }

  String get topProducts {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.topProducts;
      case 'Marathi':
        return MarathiLocalization.topProducts;
      default:
        return EnglishLocalization.topProducts;
    }
  }

  String get pendingPayments {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pendingPayments;
      case 'Marathi':
        return MarathiLocalization.pendingPayments;
      default:
        return EnglishLocalization.pendingPayments;
    }
  }

  String get lastDues {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.lastDues;
      case 'Marathi':
        return MarathiLocalization.lastDues;
      default:
        return EnglishLocalization.lastDues;
    }
  }

  String get lowStockItems {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.lowStockItems;
      case 'Marathi':
        return MarathiLocalization.lowStockItems;
      default:
        return EnglishLocalization.lowStockItems;
    }
  }

  // Navigation
  String get home {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.home;
      case 'Marathi':
        return MarathiLocalization.home;
      default:
        return EnglishLocalization.home;
    }
  }

  String get billing {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billing;
      case 'Marathi':
        return MarathiLocalization.billing;
      default:
        return EnglishLocalization.billing;
    }
  }

  String get customers {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.customers;
      case 'Marathi':
        return MarathiLocalization.customers;
      default:
        return EnglishLocalization.customers;
    }
  }

  String get availability {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.availability;
      case 'Marathi':
        return MarathiLocalization.availability;
      default:
        return EnglishLocalization.availability;
    }
  }

  String get purchase {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.purchase;
      case 'Marathi':
        return MarathiLocalization.purchase;
      default:
        return EnglishLocalization.purchase;
    }
  }

  // Actions
  String get refresh {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.refresh;
      case 'Marathi':
        return MarathiLocalization.refresh;
      default:
        return EnglishLocalization.refresh;
    }
  }

  String get viewAll {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.viewAll;
      case 'Marathi':
        return MarathiLocalization.viewAll;
      default:
        return EnglishLocalization.viewAll;
    }
  }

  String get unlockNow {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.unlockNow;
      case 'Marathi':
        return MarathiLocalization.unlockNow;
      default:
        return EnglishLocalization.unlockNow;
    }
  }

  // Messages
  String get noDataAvailable {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noDataAvailable;
      case 'Marathi':
        return MarathiLocalization.noDataAvailable;
      default:
        return EnglishLocalization.noDataAvailable;
    }
  }

  String get loadingData {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.loadingData;
      case 'Marathi':
        return MarathiLocalization.loadingData;
      default:
        return EnglishLocalization.loadingData;
    }
  }

  String get errorLoadingData {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorLoadingData;
      case 'Marathi':
        return MarathiLocalization.errorLoadingData;
      default:
        return EnglishLocalization.errorLoadingData;
    }
  }

  // Details
  String get customerName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.customerName;
      case 'Marathi':
        return MarathiLocalization.customerName;
      default:
        return EnglishLocalization.customerName;
    }
  }

  String get amount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.amount;
      case 'Marathi':
        return MarathiLocalization.amount;
      default:
        return EnglishLocalization.amount;
    }
  }

  String get dueDate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.dueDate;
      case 'Marathi':
        return MarathiLocalization.dueDate;
      default:
        return EnglishLocalization.dueDate;
    }
  }

  String get productName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productName;
      case 'Marathi':
        return MarathiLocalization.productName;
      default:
        return EnglishLocalization.productName;
    }
  }

  String get quantitySold {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.quantitySold;
      case 'Marathi':
        return MarathiLocalization.quantitySold;
      default:
        return EnglishLocalization.quantitySold;
    }
  }

  String get revenue {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.revenue;
      case 'Marathi':
        return MarathiLocalization.revenue;
      default:
        return EnglishLocalization.revenue;
    }
  }

  String get pendingAmount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pendingAmount;
      case 'Marathi':
        return MarathiLocalization.pendingAmount;
      default:
        return EnglishLocalization.pendingAmount;
    }
  }

  String get billNumber {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billNumber;
      case 'Marathi':
        return MarathiLocalization.billNumber;
      default:
        return EnglishLocalization.billNumber;
    }
  }

  String get date {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.date;
      case 'Marathi':
        return MarathiLocalization.date;
      default:
        return EnglishLocalization.date;
    }
  }

  String get currentStock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.currentStock;
      case 'Marathi':
        return MarathiLocalization.currentStock;
      default:
        return EnglishLocalization.currentStock;
    }
  }

  String get minStock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.minStock;
      case 'Marathi':
        return MarathiLocalization.minStock;
      default:
        return EnglishLocalization.minStock;
    }
  }

  // Navigation Subtitles
  String get manageCustomers {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.manageCustomers;
      case 'Marathi':
        return MarathiLocalization.manageCustomers;
      default:
        return EnglishLocalization.manageCustomers;
    }
  }

  String get stockAvailability {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.stockAvailability;
      case 'Marathi':
        return MarathiLocalization.stockAvailability;
      default:
        return EnglishLocalization.stockAvailability;
    }
  }

  String get generateInvoice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.generateInvoice;
      case 'Marathi':
        return MarathiLocalization.generateInvoice;
      default:
        return EnglishLocalization.generateInvoice;
    }
  }

  String get trackPurchases {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.trackPurchases;
      case 'Marathi':
        return MarathiLocalization.trackPurchases;
      default:
        return EnglishLocalization.trackPurchases;
    }
  }

  // Availability Page
  String get stockOverview {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.stockOverview;
      case 'Marathi':
        return MarathiLocalization.stockOverview;
      default:
        return EnglishLocalization.stockOverview;
    }
  }

  String get totalProducts {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.totalProducts;
      case 'Marathi':
        return MarathiLocalization.totalProducts;
      default:
        return EnglishLocalization.totalProducts;
    }
  }

  String get inStock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.inStock;
      case 'Marathi':
        return MarathiLocalization.inStock;
      default:
        return EnglishLocalization.inStock;
    }
  }

  String get lowStock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.lowStock;
      case 'Marathi':
        return MarathiLocalization.lowStock;
      default:
        return EnglishLocalization.lowStock;
    }
  }

  String get outOfStock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.outOfStock;
      case 'Marathi':
        return MarathiLocalization.outOfStock;
      default:
        return EnglishLocalization.outOfStock;
    }
  }

  String get searchProducts {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchProducts;
      case 'Marathi':
        return MarathiLocalization.searchProducts;
      default:
        return EnglishLocalization.searchProducts;
    }
  }

  String get all {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.all;
      case 'Marathi':
        return MarathiLocalization.all;
      default:
        return EnglishLocalization.all;
    }
  }

  String get noProductsFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noProductsFound;
      case 'Marathi':
        return MarathiLocalization.noProductsFound;
      default:
        return EnglishLocalization.noProductsFound;
    }
  }

  String get noProductsMatch {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noProductsMatch;
      case 'Marathi':
        return MarathiLocalization.noProductsMatch;
      default:
        return EnglishLocalization.noProductsMatch;
    }
  }

  String get units {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.units;
      case 'Marathi':
        return MarathiLocalization.units;
      default:
        return EnglishLocalization.units;
    }
  }

  String get stockValue {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.stockValue;
      case 'Marathi':
        return MarathiLocalization.stockValue;
      default:
        return EnglishLocalization.stockValue;
    }
  }

  String get outOfStockMessage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.outOfStockMessage;
      case 'Marathi':
        return MarathiLocalization.outOfStockMessage;
      default:
        return EnglishLocalization.outOfStockMessage;
    }
  }

  String get lowStockMessage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.lowStockMessage;
      case 'Marathi':
        return MarathiLocalization.lowStockMessage;
      default:
        return EnglishLocalization.lowStockMessage;
    }
  }

  String get generateReport {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.generateReport;
      case 'Marathi':
        return MarathiLocalization.generateReport;
      default:
        return EnglishLocalization.generateReport;
    }
  }

  String get exportInventory {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.exportInventory;
      case 'Marathi':
        return MarathiLocalization.exportInventory;
      default:
        return EnglishLocalization.exportInventory;
    }
  }

  String get reportType {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.reportType;
      case 'Marathi':
        return MarathiLocalization.reportType;
      default:
        return EnglishLocalization.reportType;
    }
  }

  String get selectReportTypes {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectReportTypes;
      case 'Marathi':
        return MarathiLocalization.selectReportTypes;
      default:
        return EnglishLocalization.selectReportTypes;
    }
  }

  String get outOfStockProducts {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.outOfStockProducts;
      case 'Marathi':
        return MarathiLocalization.outOfStockProducts;
      default:
        return EnglishLocalization.outOfStockProducts;
    }
  }

  String get productsWithZero {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productsWithZero;
      case 'Marathi':
        return MarathiLocalization.productsWithZero;
      default:
        return EnglishLocalization.productsWithZero;
    }
  }

  String get lowStockProducts {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.lowStockProducts;
      case 'Marathi':
        return MarathiLocalization.lowStockProducts;
      default:
        return EnglishLocalization.lowStockProducts;
    }
  }

  String get productsWithLow {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productsWithLow;
      case 'Marathi':
        return MarathiLocalization.productsWithLow;
      default:
        return EnglishLocalization.productsWithLow;
    }
  }

  String get allProducts {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.allProducts;
      case 'Marathi':
        return MarathiLocalization.allProducts;
      default:
        return EnglishLocalization.allProducts;
    }
  }

  String get completeInventory {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.completeInventory;
      case 'Marathi':
        return MarathiLocalization.completeInventory;
      default:
        return EnglishLocalization.completeInventory;
    }
  }

  String get exportFormat {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.exportFormat;
      case 'Marathi':
        return MarathiLocalization.exportFormat;
      default:
        return EnglishLocalization.exportFormat;
    }
  }

  String get generateAndShare {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.generateAndShare;
      case 'Marathi':
        return MarathiLocalization.generateAndShare;
      default:
        return EnglishLocalization.generateAndShare;
    }
  }

  // Customer Page
  String get addNewCustomer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addNewCustomer;
      case 'Marathi':
        return MarathiLocalization.addNewCustomer;
      default:
        return EnglishLocalization.addNewCustomer;
    }
  }

  String get editCustomer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.editCustomer;
      case 'Marathi':
        return MarathiLocalization.editCustomer;
      default:
        return EnglishLocalization.editCustomer;
    }
  }

  String get firstName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.firstName;
      case 'Marathi':
        return MarathiLocalization.firstName;
      default:
        return EnglishLocalization.firstName;
    }
  }

  String get middleName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.middleName;
      case 'Marathi':
        return MarathiLocalization.middleName;
      default:
        return EnglishLocalization.middleName;
    }
  }

  String get lastName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.lastName;
      case 'Marathi':
        return MarathiLocalization.lastName;
      default:
        return EnglishLocalization.lastName;
    }
  }

  String get contactNumber {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.contactNumber;
      case 'Marathi':
        return MarathiLocalization.contactNumber;
      default:
        return EnglishLocalization.contactNumber;
    }
  }

  String get address {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.address;
      case 'Marathi':
        return MarathiLocalization.address;
      default:
        return EnglishLocalization.address;
    }
  }

  String get addCustomer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addCustomer;
      case 'Marathi':
        return MarathiLocalization.addCustomer;
      default:
        return EnglishLocalization.addCustomer;
    }
  }

  String get update {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.update;
      case 'Marathi':
        return MarathiLocalization.update;
      default:
        return EnglishLocalization.update;
    }
  }

  String get cancel {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.cancel;
      case 'Marathi':
        return MarathiLocalization.cancel;
      default:
        return EnglishLocalization.cancel;
    }
  }

  String get deleteCustomer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.deleteCustomer;
      case 'Marathi':
        return MarathiLocalization.deleteCustomer;
      default:
        return EnglishLocalization.deleteCustomer;
    }
  }

  String get delete {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.delete;
      case 'Marathi':
        return MarathiLocalization.delete;
      default:
        return EnglishLocalization.delete;
    }
  }

  String get noCustomersYet {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noCustomersYet;
      case 'Marathi':
        return MarathiLocalization.noCustomersYet;
      default:
        return EnglishLocalization.noCustomersYet;
    }
  }

  String get noResultsFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noResultsFound;
      case 'Marathi':
        return MarathiLocalization.noResultsFound;
      default:
        return EnglishLocalization.noResultsFound;
    }
  }

  String get createFirstCustomer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.createFirstCustomer;
      case 'Marathi':
        return MarathiLocalization.createFirstCustomer;
      default:
        return EnglishLocalization.createFirstCustomer;
    }
  }

  String get tryDifferentSearch {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.tryDifferentSearch;
      case 'Marathi':
        return MarathiLocalization.tryDifferentSearch;
      default:
        return EnglishLocalization.tryDifferentSearch;
    }
  }

  String get searchCustomers {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchCustomers;
      case 'Marathi':
        return MarathiLocalization.searchCustomers;
      default:
        return EnglishLocalization.searchCustomers;
    }
  }

  String get viewBalance {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.viewBalance;
      case 'Marathi':
        return MarathiLocalization.viewBalance;
      default:
        return EnglishLocalization.viewBalance;
    }
  }

  String get edit {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.edit;
      case 'Marathi':
        return MarathiLocalization.edit;
      default:
        return EnglishLocalization.edit;
    }
  }

  String get isRequired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.isRequired;
      case 'Marathi':
        return MarathiLocalization.isRequired;
      default:
        return EnglishLocalization.isRequired;
    }
  }

  String get enterValidPhone {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterValidPhone;
      case 'Marathi':
        return MarathiLocalization.enterValidPhone;
      default:
        return EnglishLocalization.enterValidPhone;
    }
  }

  // Purchase Page
  String get addNewProduct {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addNewProduct;
      case 'Marathi':
        return MarathiLocalization.addNewProduct;
      default:
        return EnglishLocalization.addNewProduct;
    }
  }

  String get enterProductName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterProductName;
      case 'Marathi':
        return MarathiLocalization.enterProductName;
      default:
        return EnglishLocalization.enterProductName;
    }
  }

  String get purchasePrice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.purchasePrice;
      case 'Marathi':
        return MarathiLocalization.purchasePrice;
      default:
        return EnglishLocalization.purchasePrice;
    }
  }

  String get salesPrice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.salesPrice;
      case 'Marathi':
        return MarathiLocalization.salesPrice;
      default:
        return EnglishLocalization.salesPrice;
    }
  }

  String get addProduct {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addProduct;
      case 'Marathi':
        return MarathiLocalization.addProduct;
      default:
        return EnglishLocalization.addProduct;
    }
  }

  String get productAddedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productAddedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.productAddedSuccessfully;
      default:
        return EnglishLocalization.productAddedSuccessfully;
    }
  }

  String get selectProduct {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectProduct;
      case 'Marathi':
        return MarathiLocalization.selectProduct;
      default:
        return EnglishLocalization.selectProduct;
    }
  }

  String get searchByProduct {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchByProduct;
      case 'Marathi':
        return MarathiLocalization.searchByProduct;
      default:
        return EnglishLocalization.searchByProduct;
    }
  }

  String get noProductsAvailable {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noProductsAvailable;
      case 'Marathi':
        return MarathiLocalization.noProductsAvailable;
      default:
        return EnglishLocalization.noProductsAvailable;
    }
  }

  String get selectSupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectSupplier;
      case 'Marathi':
        return MarathiLocalization.selectSupplier;
      default:
        return EnglishLocalization.selectSupplier;
    }
  }

  String get searchBySupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchBySupplier;
      case 'Marathi':
        return MarathiLocalization.searchBySupplier;
      default:
        return EnglishLocalization.searchBySupplier;
    }
  }

  String get noSuppliersAvailable {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noSuppliersAvailable;
      case 'Marathi':
        return MarathiLocalization.noSuppliersAvailable;
      default:
        return EnglishLocalization.noSuppliersAvailable;
    }
  }

  String get noSuppliersFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noSuppliersFound;
      case 'Marathi':
        return MarathiLocalization.noSuppliersFound;
      default:
        return EnglishLocalization.noSuppliersFound;
    }
  }

  String get selectCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectCompany;
      case 'Marathi':
        return MarathiLocalization.selectCompany;
      default:
        return EnglishLocalization.selectCompany;
    }
  }

  String get searchByCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchByCompany;
      case 'Marathi':
        return MarathiLocalization.searchByCompany;
      default:
        return EnglishLocalization.searchByCompany;
    }
  }

  String get noCompaniesAvailable {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noCompaniesAvailable;
      case 'Marathi':
        return MarathiLocalization.noCompaniesAvailable;
      default:
        return EnglishLocalization.noCompaniesAvailable;
    }
  }

  String get noCompaniesFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noCompaniesFound;
      case 'Marathi':
        return MarathiLocalization.noCompaniesFound;
      default:
        return EnglishLocalization.noCompaniesFound;
    }
  }

  String get quantity {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.quantity;
      case 'Marathi':
        return MarathiLocalization.quantity;
      default:
        return EnglishLocalization.quantity;
    }
  }

  String get price {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.price;
      case 'Marathi':
        return MarathiLocalization.price;
      default:
        return EnglishLocalization.price;
    }
  }

  String get supplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.supplier;
      case 'Marathi':
        return MarathiLocalization.supplier;
      default:
        return EnglishLocalization.supplier;
    }
  }

  String get company {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.company;
      case 'Marathi':
        return MarathiLocalization.company;
      default:
        return EnglishLocalization.company;
    }
  }

  String get productionDate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productionDate;
      case 'Marathi':
        return MarathiLocalization.productionDate;
      default:
        return EnglishLocalization.productionDate;
    }
  }

  String get expiryDate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.expiryDate;
      case 'Marathi':
        return MarathiLocalization.expiryDate;
      default:
        return EnglishLocalization.expiryDate;
    }
  }

  String get notes {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.notes;
      case 'Marathi':
        return MarathiLocalization.notes;
      default:
        return EnglishLocalization.notes;
    }
  }

  String get optional {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.optional;
      case 'Marathi':
        return MarathiLocalization.optional;
      default:
        return EnglishLocalization.optional;
    }
  }

  String get stock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.stock;
      case 'Marathi':
        return MarathiLocalization.stock;
      default:
        return EnglishLocalization.stock;
    }
  }

  String get recordPurchase {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.recordPurchase;
      case 'Marathi':
        return MarathiLocalization.recordPurchase;
      default:
        return EnglishLocalization.recordPurchase;
    }
  }

  String get purchaseRecorded {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.purchaseRecorded;
      case 'Marathi':
        return MarathiLocalization.purchaseRecorded;
      default:
        return EnglishLocalization.purchaseRecorded;
    }
  }

  String get errorRecordingPurchase {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorRecordingPurchase;
      case 'Marathi':
        return MarathiLocalization.errorRecordingPurchase;
      default:
        return EnglishLocalization.errorRecordingPurchase;
    }
  }

  String get errorLoadingProducts {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorLoadingProducts;
      case 'Marathi':
        return MarathiLocalization.errorLoadingProducts;
      default:
        return EnglishLocalization.errorLoadingProducts;
    }
  }

  String get errorLoadingSuppliers {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorLoadingSuppliers;
      case 'Marathi':
        return MarathiLocalization.errorLoadingSuppliers;
      default:
        return EnglishLocalization.errorLoadingSuppliers;
    }
  }

  String get errorLoadingCompanies {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorLoadingCompanies;
      case 'Marathi':
        return MarathiLocalization.errorLoadingCompanies;
      default:
        return EnglishLocalization.errorLoadingCompanies;
    }
  }
}
