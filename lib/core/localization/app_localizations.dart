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

  // Purchase Page - Additional
  String get addNewItems {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addNewItems;
      case 'Marathi':
        return MarathiLocalization.addNewItems;
      default:
        return EnglishLocalization.addNewItems;
    }
  }

  String get createNewProduct {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.createNewProduct;
      case 'Marathi':
        return MarathiLocalization.createNewProduct;
      default:
        return EnglishLocalization.createNewProduct;
    }
  }

  String get addNewSupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addNewSupplier;
      case 'Marathi':
        return MarathiLocalization.addNewSupplier;
      default:
        return EnglishLocalization.addNewSupplier;
    }
  }

  String get addNewCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addNewCompany;
      case 'Marathi':
        return MarathiLocalization.addNewCompany;
      default:
        return EnglishLocalization.addNewCompany;
    }
  }

  String get addSupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addSupplier;
      case 'Marathi':
        return MarathiLocalization.addSupplier;
      default:
        return EnglishLocalization.addSupplier;
    }
  }

  String get addCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addCompany;
      case 'Marathi':
        return MarathiLocalization.addCompany;
      default:
        return EnglishLocalization.addCompany;
    }
  }

  String get companyName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companyName;
      case 'Marathi':
        return MarathiLocalization.companyName;
      default:
        return EnglishLocalization.companyName;
    }
  }

  String get enterCompanyName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterCompanyName;
      case 'Marathi':
        return MarathiLocalization.enterCompanyName;
      default:
        return EnglishLocalization.enterCompanyName;
    }
  }

  String get enterFirstName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterFirstName;
      case 'Marathi':
        return MarathiLocalization.enterFirstName;
      default:
        return EnglishLocalization.enterFirstName;
    }
  }

  String get enterLastName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterLastName;
      case 'Marathi':
        return MarathiLocalization.enterLastName;
      default:
        return EnglishLocalization.enterLastName;
    }
  }

  // Validation Messages
  String get firstNameRequired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.firstNameRequired;
      case 'Marathi':
        return MarathiLocalization.firstNameRequired;
      default:
        return EnglishLocalization.firstNameRequired;
    }
  }

  String get lastNameRequired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.lastNameRequired;
      case 'Marathi':
        return MarathiLocalization.lastNameRequired;
      default:
        return EnglishLocalization.lastNameRequired;
    }
  }

  String get companyNameRequired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companyNameRequired;
      case 'Marathi':
        return MarathiLocalization.companyNameRequired;
      default:
        return EnglishLocalization.companyNameRequired;
    }
  }

  String get firstLastNameRequired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.firstLastNameRequired;
      case 'Marathi':
        return MarathiLocalization.firstLastNameRequired;
      default:
        return EnglishLocalization.firstLastNameRequired;
    }
  }

  String get companyNameIsRequired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companyNameIsRequired;
      case 'Marathi':
        return MarathiLocalization.companyNameIsRequired;
      default:
        return EnglishLocalization.companyNameIsRequired;
    }
  }

  String get supplierAddedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.supplierAddedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.supplierAddedSuccessfully;
      default:
        return EnglishLocalization.supplierAddedSuccessfully;
    }
  }

  String get companyAddedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companyAddedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.companyAddedSuccessfully;
      default:
        return EnglishLocalization.companyAddedSuccessfully;
    }
  }

  String get errorAddingSupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorAddingSupplier;
      case 'Marathi':
        return MarathiLocalization.errorAddingSupplier;
      default:
        return EnglishLocalization.errorAddingSupplier;
    }
  }

  String get errorAddingCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorAddingCompany;
      case 'Marathi':
        return MarathiLocalization.errorAddingCompany;
      default:
        return EnglishLocalization.errorAddingCompany;
    }
  }

  String get pleaseSelectProduct {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseSelectProduct;
      case 'Marathi':
        return MarathiLocalization.pleaseSelectProduct;
      default:
        return EnglishLocalization.pleaseSelectProduct;
    }
  }

  String get pleaseSelectSupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseSelectSupplier;
      case 'Marathi':
        return MarathiLocalization.pleaseSelectSupplier;
      default:
        return EnglishLocalization.pleaseSelectSupplier;
    }
  }

  String get pleaseSelectCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseSelectCompany;
      case 'Marathi':
        return MarathiLocalization.pleaseSelectCompany;
      default:
        return EnglishLocalization.pleaseSelectCompany;
    }
  }

  String get pleaseSelectProductionDate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseSelectProductionDate;
      case 'Marathi':
        return MarathiLocalization.pleaseSelectProductionDate;
      default:
        return EnglishLocalization.pleaseSelectProductionDate;
    }
  }

  String get pleaseSelectExpiryDate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseSelectExpiryDate;
      case 'Marathi':
        return MarathiLocalization.pleaseSelectExpiryDate;
      default:
        return EnglishLocalization.pleaseSelectExpiryDate;
    }
  }

  String get expiryBeforeProduction {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.expiryBeforeProduction;
      case 'Marathi':
        return MarathiLocalization.expiryBeforeProduction;
      default:
        return EnglishLocalization.expiryBeforeProduction;
    }
  }

  String get pleaseEnterValidQuantity {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterValidQuantity;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterValidQuantity;
      default:
        return EnglishLocalization.pleaseEnterValidQuantity;
    }
  }

  String get pleaseEnterValidPurchasePrice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterValidPurchasePrice;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterValidPurchasePrice;
      default:
        return EnglishLocalization.pleaseEnterValidPurchasePrice;
    }
  }

  String get pleaseEnterValidSalesPrice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterValidSalesPrice;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterValidSalesPrice;
      default:
        return EnglishLocalization.pleaseEnterValidSalesPrice;
    }
  }

  String get error {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.error;
      case 'Marathi':
        return MarathiLocalization.error;
      default:
        return EnglishLocalization.error;
    }
  }

  // Billing Page
  String get createBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.createBill;
      case 'Marathi':
        return MarathiLocalization.createBill;
      default:
        return EnglishLocalization.createBill;
    }
  }

  String get customerOptional {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.customerOptional;
      case 'Marathi':
        return MarathiLocalization.customerOptional;
      default:
        return EnglishLocalization.customerOptional;
    }
  }

  String get searchExistingCustomer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchExistingCustomer;
      case 'Marathi':
        return MarathiLocalization.searchExistingCustomer;
      default:
        return EnglishLocalization.searchExistingCustomer;
    }
  }

  String get name {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.name;
      case 'Marathi':
        return MarathiLocalization.name;
      default:
        return EnglishLocalization.name;
    }
  }

  String get phone {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.phone;
      case 'Marathi':
        return MarathiLocalization.phone;
      default:
        return EnglishLocalization.phone;
    }
  }

  String get enterProductCode {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterProductCode;
      case 'Marathi':
        return MarathiLocalization.enterProductCode;
      default:
        return EnglishLocalization.enterProductCode;
    }
  }

  String get add {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.add;
      case 'Marathi':
        return MarathiLocalization.add;
      default:
        return EnglishLocalization.add;
    }
  }

  String get searchProduct {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchProduct;
      case 'Marathi':
        return MarathiLocalization.searchProduct;
      default:
        return EnglishLocalization.searchProduct;
    }
  }

  String get billItems {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billItems;
      case 'Marathi':
        return MarathiLocalization.billItems;
      default:
        return EnglishLocalization.billItems;
    }
  }

  String get discount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.discount;
      case 'Marathi':
        return MarathiLocalization.discount;
      default:
        return EnglishLocalization.discount;
    }
  }

  String get payment {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.payment;
      case 'Marathi':
        return MarathiLocalization.payment;
      default:
        return EnglishLocalization.payment;
    }
  }

  String get fullPayment {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.fullPayment;
      case 'Marathi':
        return MarathiLocalization.fullPayment;
      default:
        return EnglishLocalization.fullPayment;
    }
  }

  String get partialPayment {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.partialPayment;
      case 'Marathi':
        return MarathiLocalization.partialPayment;
      default:
        return EnglishLocalization.partialPayment;
    }
  }

  String get receivedAmount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.receivedAmount;
      case 'Marathi':
        return MarathiLocalization.receivedAmount;
      default:
        return EnglishLocalization.receivedAmount;
    }
  }

  String get selectCustomerToTrack {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectCustomerToTrack;
      case 'Marathi':
        return MarathiLocalization.selectCustomerToTrack;
      default:
        return EnglishLocalization.selectCustomerToTrack;
    }
  }

  String get billTotal {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billTotal;
      case 'Marathi':
        return MarathiLocalization.billTotal;
      default:
        return EnglishLocalization.billTotal;
    }
  }

  String get received {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.received;
      case 'Marathi':
        return MarathiLocalization.received;
      default:
        return EnglishLocalization.received;
    }
  }

  String get pending {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pending;
      case 'Marathi':
        return MarathiLocalization.pending;
      default:
        return EnglishLocalization.pending;
    }
  }

  String get subtotal {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.subtotal;
      case 'Marathi':
        return MarathiLocalization.subtotal;
      default:
        return EnglishLocalization.subtotal;
    }
  }

  String get finalTotal {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.finalTotal;
      case 'Marathi':
        return MarathiLocalization.finalTotal;
      default:
        return EnglishLocalization.finalTotal;
    }
  }

  String get saveBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.saveBill;
      case 'Marathi':
        return MarathiLocalization.saveBill;
      default:
        return EnglishLocalization.saveBill;
    }
  }

  String get billSavedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billSavedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.billSavedSuccessfully;
      default:
        return EnglishLocalization.billSavedSuccessfully;
    }
  }

  String get customer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.customer;
      case 'Marathi':
        return MarathiLocalization.customer;
      default:
        return EnglishLocalization.customer;
    }
  }

  String get total {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.total;
      case 'Marathi':
        return MarathiLocalization.total;
      default:
        return EnglishLocalization.total;
    }
  }

  String get share {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.share;
      case 'Marathi':
        return MarathiLocalization.share;
      default:
        return EnglishLocalization.share;
    }
  }

  String get savePdf {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.savePdf;
      case 'Marathi':
        return MarathiLocalization.savePdf;
      default:
        return EnglishLocalization.savePdf;
    }
  }

  String get printToPOS {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.printToPOS;
      case 'Marathi':
        return MarathiLocalization.printToPOS;
      default:
        return EnglishLocalization.printToPOS;
    }
  }

  String get done {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.done;
      case 'Marathi':
        return MarathiLocalization.done;
      default:
        return EnglishLocalization.done;
    }
  }

  String get addItems {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addItems;
      case 'Marathi':
        return MarathiLocalization.addItems;
      default:
        return EnglishLocalization.addItems;
    }
  }

  String get tapToAddItems {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.tapToAddItems;
      case 'Marathi':
        return MarathiLocalization.tapToAddItems;
      default:
        return EnglishLocalization.tapToAddItems;
    }
  }

  String get selectCustomer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectCustomer;
      case 'Marathi':
        return MarathiLocalization.selectCustomer;
      default:
        return EnglishLocalization.selectCustomer;
    }
  }

  String get chooseFromExisting {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.chooseFromExisting;
      case 'Marathi':
        return MarathiLocalization.chooseFromExisting;
      default:
        return EnglishLocalization.chooseFromExisting;
    }
  }

  String get searchByNameOrPhone {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchByNameOrPhone;
      case 'Marathi':
        return MarathiLocalization.searchByNameOrPhone;
      default:
        return EnglishLocalization.searchByNameOrPhone;
    }
  }

  String get noCustomersFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noCustomersFound;
      case 'Marathi':
        return MarathiLocalization.noCustomersFound;
      default:
        return EnglishLocalization.noCustomersFound;
    }
  }

  String get maxStock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.maxStock;
      case 'Marathi':
        return MarathiLocalization.maxStock;
      default:
        return EnglishLocalization.maxStock;
    }
  }

  String get added {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.added;
      case 'Marathi':
        return MarathiLocalization.added;
      default:
        return EnglishLocalization.added;
    }
  }

  String get productNotFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productNotFound;
      case 'Marathi':
        return MarathiLocalization.productNotFound;
      default:
        return EnglishLocalization.productNotFound;
    }
  }

  String get pleaseAddAtLeastOneItem {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseAddAtLeastOneItem;
      case 'Marathi':
        return MarathiLocalization.pleaseAddAtLeastOneItem;
      default:
        return EnglishLocalization.pleaseAddAtLeastOneItem;
    }
  }

  String get pleaseEnterValidNumber {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterValidNumber;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterValidNumber;
      default:
        return EnglishLocalization.pleaseEnterValidNumber;
    }
  }

  String get errorSavingBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorSavingBill;
      case 'Marathi':
        return MarathiLocalization.errorSavingBill;
      default:
        return EnglishLocalization.errorSavingBill;
    }
  }

  String get pdfSaved {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pdfSaved;
      case 'Marathi':
        return MarathiLocalization.pdfSaved;
      default:
        return EnglishLocalization.pdfSaved;
    }
  }

  String get preparingPdf {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.preparingPdf;
      case 'Marathi':
        return MarathiLocalization.preparingPdf;
      default:
        return EnglishLocalization.preparingPdf;
    }
  }

  String get errorSavingPdf {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorSavingPdf;
      case 'Marathi':
        return MarathiLocalization.errorSavingPdf;
      default:
        return EnglishLocalization.errorSavingPdf;
    }
  }

  String get errorSharingBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorSharingBill;
      case 'Marathi':
        return MarathiLocalization.errorSharingBill;
      default:
        return EnglishLocalization.errorSharingBill;
    }
  }

  String get failedToConnect {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.failedToConnect;
      case 'Marathi':
        return MarathiLocalization.failedToConnect;
      default:
        return EnglishLocalization.failedToConnect;
    }
  }

  String get billPrintedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billPrintedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.billPrintedSuccessfully;
      default:
        return EnglishLocalization.billPrintedSuccessfully;
    }
  }

  String get printFailed {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.printFailed;
      case 'Marathi':
        return MarathiLocalization.printFailed;
      default:
        return EnglishLocalization.printFailed;
    }
  }

  String get errorPrinting {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorPrinting;
      case 'Marathi':
        return MarathiLocalization.errorPrinting;
      default:
        return EnglishLocalization.errorPrinting;
    }
  }

  String get na {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.na;
      case 'Marathi':
        return MarathiLocalization.na;
      default:
        return EnglishLocalization.na;
    }
  }

  String get chooseFromExistingCustomers {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.chooseFromExistingCustomers;
      case 'Marathi':
        return MarathiLocalization.chooseFromExistingCustomers;
      default:
        return EnglishLocalization.chooseFromExistingCustomers;
    }
  }

  String get selectCustomerForPending {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectCustomerForPending;
      case 'Marathi':
        return MarathiLocalization.selectCustomerForPending;
      default:
        return EnglishLocalization.selectCustomerForPending;
    }
  }

  String get enterPercent {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterPercent;
      case 'Marathi':
        return MarathiLocalization.enterPercent;
      default:
        return EnglishLocalization.enterPercent;
    }
  }

  String get enterAmount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterAmount;
      case 'Marathi':
        return MarathiLocalization.enterAmount;
      default:
        return EnglishLocalization.enterAmount;
    }
  }

  // Bill History Page getters
  String get billsHistory {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billsHistory;
      case 'Marathi':
        return MarathiLocalization.billsHistory;
      default:
        return EnglishLocalization.billsHistory;
    }
  }

  String get viewAllTransactions {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.viewAllTransactions;
      case 'Marathi':
        return MarathiLocalization.viewAllTransactions;
      default:
        return EnglishLocalization.viewAllTransactions;
    }
  }

  String get totalBills {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.totalBills;
      case 'Marathi':
        return MarathiLocalization.totalBills;
      default:
        return EnglishLocalization.totalBills;
    }
  }

  String get avgBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.avgBill;
      case 'Marathi':
        return MarathiLocalization.avgBill;
      default:
        return EnglishLocalization.avgBill;
    }
  }

  String get searchBills {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchBills;
      case 'Marathi':
        return MarathiLocalization.searchBills;
      default:
        return EnglishLocalization.searchBills;
    }
  }

  String get newest {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.newest;
      case 'Marathi':
        return MarathiLocalization.newest;
      default:
        return EnglishLocalization.newest;
    }
  }

  String get oldest {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.oldest;
      case 'Marathi':
        return MarathiLocalization.oldest;
      default:
        return EnglishLocalization.oldest;
    }
  }

  String get highest {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.highest;
      case 'Marathi':
        return MarathiLocalization.highest;
      default:
        return EnglishLocalization.highest;
    }
  }

  String get lowest {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.lowest;
      case 'Marathi':
        return MarathiLocalization.lowest;
      default:
        return EnglishLocalization.lowest;
    }
  }

  String get noBillsFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noBillsFound;
      case 'Marathi':
        return MarathiLocalization.noBillsFound;
      default:
        return EnglishLocalization.noBillsFound;
    }
  }

  String get clearFilters {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.clearFilters;
      case 'Marathi':
        return MarathiLocalization.clearFilters;
      default:
        return EnglishLocalization.clearFilters;
    }
  }

  String get printPreview {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.printPreview;
      case 'Marathi':
        return MarathiLocalization.printPreview;
      default:
        return EnglishLocalization.printPreview;
    }
  }

  String get unknown {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.unknown;
      case 'Marathi':
        return MarathiLocalization.unknown;
      default:
        return EnglishLocalization.unknown;
    }
  }

  String get open {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.open;
      case 'Marathi':
        return MarathiLocalization.open;
      default:
        return EnglishLocalization.open;
    }
  }

  String get print {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.print;
      case 'Marathi':
        return MarathiLocalization.print;
      default:
        return EnglishLocalization.print;
    }
  }

  // Product Management Page
  String get productManagement {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productManagement;
      case 'Marathi':
        return MarathiLocalization.productManagement;
      default:
        return EnglishLocalization.productManagement;
    }
  }

  String get noProductsMatchFilter {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noProductsMatchFilter;
      case 'Marathi':
        return MarathiLocalization.noProductsMatchFilter;
      default:
        return EnglishLocalization.noProductsMatchFilter;
    }
  }

  String get editProduct {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.editProduct;
      case 'Marathi':
        return MarathiLocalization.editProduct;
      default:
        return EnglishLocalization.editProduct;
    }
  }

  String get deleteProduct {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.deleteProduct;
      case 'Marathi':
        return MarathiLocalization.deleteProduct;
      default:
        return EnglishLocalization.deleteProduct;
    }
  }

  String get initialStock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.initialStock;
      case 'Marathi':
        return MarathiLocalization.initialStock;
      default:
        return EnglishLocalization.initialStock;
    }
  }

  String get purchasePriceReadOnly {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.purchasePriceReadOnly;
      case 'Marathi':
        return MarathiLocalization.purchasePriceReadOnly;
      default:
        return EnglishLocalization.purchasePriceReadOnly;
    }
  }

  String get salesPriceReadOnly {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.salesPriceReadOnly;
      case 'Marathi':
        return MarathiLocalization.salesPriceReadOnly;
      default:
        return EnglishLocalization.salesPriceReadOnly;
    }
  }

  String get currentStockReadOnly {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.currentStockReadOnly;
      case 'Marathi':
        return MarathiLocalization.currentStockReadOnly;
      default:
        return EnglishLocalization.currentStockReadOnly;
    }
  }

  String get updatedFromPurchasePage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.updatedFromPurchasePage;
      case 'Marathi':
        return MarathiLocalization.updatedFromPurchasePage;
      default:
        return EnglishLocalization.updatedFromPurchasePage;
    }
  }

  String get minStockLevel {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.minStockLevel;
      case 'Marathi':
        return MarathiLocalization.minStockLevel;
      default:
        return EnglishLocalization.minStockLevel;
    }
  }

  String get description {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.description;
      case 'Marathi':
        return MarathiLocalization.description;
      default:
        return EnglishLocalization.description;
    }
  }

  String get requiredWhenGstApplied {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.requiredWhenGstApplied;
      case 'Marathi':
        return MarathiLocalization.requiredWhenGstApplied;
      default:
        return EnglishLocalization.requiredWhenGstApplied;
    }
  }

  String get filterProducts {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.filterProducts;
      case 'Marathi':
        return MarathiLocalization.filterProducts;
      default:
        return EnglishLocalization.filterProducts;
    }
  }

  String get selectCategory {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectCategory;
      case 'Marathi':
        return MarathiLocalization.selectCategory;
      default:
        return EnglishLocalization.selectCategory;
    }
  }

  String get category {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.category;
      case 'Marathi':
        return MarathiLocalization.category;
      default:
        return EnglishLocalization.category;
    }
  }

  String get priceRange {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.priceRange;
      case 'Marathi':
        return MarathiLocalization.priceRange;
      default:
        return EnglishLocalization.priceRange;
    }
  }

  String get minPrice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.minPrice;
      case 'Marathi':
        return MarathiLocalization.minPrice;
      default:
        return EnglishLocalization.minPrice;
    }
  }

  String get maxPrice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.maxPrice;
      case 'Marathi':
        return MarathiLocalization.maxPrice;
      default:
        return EnglishLocalization.maxPrice;
    }
  }

  String get stockRange {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.stockRange;
      case 'Marathi':
        return MarathiLocalization.stockRange;
      default:
        return EnglishLocalization.stockRange;
    }
  }

  String get apply {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.apply;
      case 'Marathi':
        return MarathiLocalization.apply;
      default:
        return EnglishLocalization.apply;
    }
  }

  String get deleteConfirmation {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.deleteConfirmation;
      case 'Marathi':
        return MarathiLocalization.deleteConfirmation;
      default:
        return EnglishLocalization.deleteConfirmation;
    }
  }

  String get actionCannotBeUndone {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.actionCannotBeUndone;
      case 'Marathi':
        return MarathiLocalization.actionCannotBeUndone;
      default:
        return EnglishLocalization.actionCannotBeUndone;
    }
  }

  String get productUpdatedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productUpdatedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.productUpdatedSuccessfully;
      default:
        return EnglishLocalization.productUpdatedSuccessfully;
    }
  }

  String get productDeletedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productDeletedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.productDeletedSuccessfully;
      default:
        return EnglishLocalization.productDeletedSuccessfully;
    }
  }

  String get filters {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.filters;
      case 'Marathi':
        return MarathiLocalization.filters;
      default:
        return EnglishLocalization.filters;
    }
  }

  String get allCategories {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.allCategories;
      case 'Marathi':
        return MarathiLocalization.allCategories;
      default:
        return EnglishLocalization.allCategories;
    }
  }

  // Company Page
  String get myCompanies {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.myCompanies;
      case 'Marathi':
        return MarathiLocalization.myCompanies;
      default:
        return EnglishLocalization.myCompanies;
    }
  }

  String get manageYourBusinesses {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.manageYourBusinesses;
      case 'Marathi':
        return MarathiLocalization.manageYourBusinesses;
      default:
        return EnglishLocalization.manageYourBusinesses;
    }
  }

  String get searchCompanies {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchCompanies;
      case 'Marathi':
        return MarathiLocalization.searchCompanies;
      default:
        return EnglishLocalization.searchCompanies;
    }
  }

  String get noCompaniesYet {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noCompaniesYet;
      case 'Marathi':
        return MarathiLocalization.noCompaniesYet;
      default:
        return EnglishLocalization.noCompaniesYet;
    }
  }

  String get createFirstCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.createFirstCompany;
      case 'Marathi':
        return MarathiLocalization.createFirstCompany;
      default:
        return EnglishLocalization.createFirstCompany;
    }
  }

  String get editCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.editCompany;
      case 'Marathi':
        return MarathiLocalization.editCompany;
      default:
        return EnglishLocalization.editCompany;
    }
  }

  String get selectContactPerson {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectContactPerson;
      case 'Marathi':
        return MarathiLocalization.selectContactPerson;
      default:
        return EnglishLocalization.selectContactPerson;
    }
  }

  String get contactPersonSupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.contactPersonSupplier;
      case 'Marathi':
        return MarathiLocalization.contactPersonSupplier;
      default:
        return EnglishLocalization.contactPersonSupplier;
    }
  }

  String get selectASupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectASupplier;
      case 'Marathi':
        return MarathiLocalization.selectASupplier;
      default:
        return EnglishLocalization.selectASupplier;
    }
  }

  String get searchByNameOrContact {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchByNameOrContact;
      case 'Marathi':
        return MarathiLocalization.searchByNameOrContact;
      default:
        return EnglishLocalization.searchByNameOrContact;
    }
  }

  String get noSuppliersYet {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noSuppliersYet;
      case 'Marathi':
        return MarathiLocalization.noSuppliersYet;
      default:
        return EnglishLocalization.noSuppliersYet;
    }
  }

  String get addSuppliersFirst {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addSuppliersFirst;
      case 'Marathi':
        return MarathiLocalization.addSuppliersFirst;
      default:
        return EnglishLocalization.addSuppliersFirst;
    }
  }

  String get pleaseSelectContactPerson {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseSelectContactPerson;
      case 'Marathi':
        return MarathiLocalization.pleaseSelectContactPerson;
      default:
        return EnglishLocalization.pleaseSelectContactPerson;
    }
  }

  String get companyUpdatedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companyUpdatedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.companyUpdatedSuccessfully;
      default:
        return EnglishLocalization.companyUpdatedSuccessfully;
    }
  }

  String get deleteCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.deleteCompany;
      case 'Marathi':
        return MarathiLocalization.deleteCompany;
      default:
        return EnglishLocalization.deleteCompany;
    }
  }

  String get deleteCompanyConfirm {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.deleteCompanyConfirm;
      case 'Marathi':
        return MarathiLocalization.deleteCompanyConfirm;
      default:
        return EnglishLocalization.deleteCompanyConfirm;
    }
  }

  String get companyDeletedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companyDeletedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.companyDeletedSuccessfully;
      default:
        return EnglishLocalization.companyDeletedSuccessfully;
    }
  }

  String get errorSavingCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorSavingCompany;
      case 'Marathi':
        return MarathiLocalization.errorSavingCompany;
      default:
        return EnglishLocalization.errorSavingCompany;
    }
  }

  String get errorDeletingCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorDeletingCompany;
      case 'Marathi':
        return MarathiLocalization.errorDeletingCompany;
      default:
        return EnglishLocalization.errorDeletingCompany;
    }
  }

  String get unknownCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.unknownCompany;
      case 'Marathi':
        return MarathiLocalization.unknownCompany;
      default:
        return EnglishLocalization.unknownCompany;
    }
  }

  String get userNotAuthenticated {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.userNotAuthenticated;
      case 'Marathi':
        return MarathiLocalization.userNotAuthenticated;
      default:
        return EnglishLocalization.userNotAuthenticated;
    }
  }

  // Supplier Page
  String get mySuppliers {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.mySuppliers;
      case 'Marathi':
        return MarathiLocalization.mySuppliers;
      default:
        return EnglishLocalization.mySuppliers;
    }
  }

  String get manageYourVendors {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.manageYourVendors;
      case 'Marathi':
        return MarathiLocalization.manageYourVendors;
      default:
        return EnglishLocalization.manageYourVendors;
    }
  }

  String get editSupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.editSupplier;
      case 'Marathi':
        return MarathiLocalization.editSupplier;
      default:
        return EnglishLocalization.editSupplier;
    }
  }

  String get searchSuppliers {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchSuppliers;
      case 'Marathi':
        return MarathiLocalization.searchSuppliers;
      default:
        return EnglishLocalization.searchSuppliers;
    }
  }

  String get noSuppliersYetPage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noSuppliersYetPage;
      case 'Marathi':
        return MarathiLocalization.noSuppliersYetPage;
      default:
        return EnglishLocalization.noSuppliersYetPage;
    }
  }

  String get createFirstSupplier {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.createFirstSupplier;
      case 'Marathi':
        return MarathiLocalization.createFirstSupplier;
      default:
        return EnglishLocalization.createFirstSupplier;
    }
  }

  String get supplierUpdatedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.supplierUpdatedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.supplierUpdatedSuccessfully;
      default:
        return EnglishLocalization.supplierUpdatedSuccessfully;
    }
  }

  String get supplierDeletedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.supplierDeletedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.supplierDeletedSuccessfully;
      default:
        return EnglishLocalization.supplierDeletedSuccessfully;
    }
  }

  // Subscription Screen
  String get premiumFinancialSolutions {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.premiumFinancialSolutions;
      case 'Marathi':
        return MarathiLocalization.premiumFinancialSolutions;
      default:
        return EnglishLocalization.premiumFinancialSolutions;
    }
  }

  String get subscriptionExpired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.subscriptionExpired;
      case 'Marathi':
        return MarathiLocalization.subscriptionExpired;
      default:
        return EnglishLocalization.subscriptionExpired;
    }
  }

  String get premiumPlan {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.premiumPlan;
      case 'Marathi':
        return MarathiLocalization.premiumPlan;
      default:
        return EnglishLocalization.premiumPlan;
    }
  }

  String get perYear {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.perYear;
      case 'Marathi':
        return MarathiLocalization.perYear;
      default:
        return EnglishLocalization.perYear;
    }
  }

  String get hurryUpFirstUsers {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.hurryUpFirstUsers;
      case 'Marathi':
        return MarathiLocalization.hurryUpFirstUsers;
      default:
        return EnglishLocalization.hurryUpFirstUsers;
    }
  }

  String get justPerMonth {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.justPerMonth;
      case 'Marathi':
        return MarathiLocalization.justPerMonth;
      default:
        return EnglishLocalization.justPerMonth;
    }
  }

  String get whatsIncluded {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.whatsIncluded;
      case 'Marathi':
        return MarathiLocalization.whatsIncluded;
      default:
        return EnglishLocalization.whatsIncluded;
    }
  }

  String get unlimitedBillGeneration {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.unlimitedBillGeneration;
      case 'Marathi':
        return MarathiLocalization.unlimitedBillGeneration;
      default:
        return EnglishLocalization.unlimitedBillGeneration;
    }
  }

  String get completeInventoryManagement {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.completeInventoryManagement;
      case 'Marathi':
        return MarathiLocalization.completeInventoryManagement;
      default:
        return EnglishLocalization.completeInventoryManagement;
    }
  }

  String get customerSupplierTracking {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.customerSupplierTracking;
      case 'Marathi':
        return MarathiLocalization.customerSupplierTracking;
      default:
        return EnglishLocalization.customerSupplierTracking;
    }
  }

  String get advancedReportsAnalytics {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.advancedReportsAnalytics;
      case 'Marathi':
        return MarathiLocalization.advancedReportsAnalytics;
      default:
        return EnglishLocalization.advancedReportsAnalytics;
    }
  }

  String get posPrinterSupport {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.posPrinterSupport;
      case 'Marathi':
        return MarathiLocalization.posPrinterSupport;
      default:
        return EnglishLocalization.posPrinterSupport;
    }
  }

  String get cloudBackupPrioritySupport {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.cloudBackupPrioritySupport;
      case 'Marathi':
        return MarathiLocalization.cloudBackupPrioritySupport;
      default:
        return EnglishLocalization.cloudBackupPrioritySupport;
    }
  }

  String get subscribeNow {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.subscribeNow;
      case 'Marathi':
        return MarathiLocalization.subscribeNow;
      default:
        return EnglishLocalization.subscribeNow;
    }
  }

  String get needHelpContactUs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.needHelpContactUs;
      case 'Marathi':
        return MarathiLocalization.needHelpContactUs;
      default:
        return EnglishLocalization.needHelpContactUs;
    }
  }

  String get poweredBy {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.poweredBy;
      case 'Marathi':
        return MarathiLocalization.poweredBy;
      default:
        return EnglishLocalization.poweredBy;
    }
  }

  String get chaturbhujSolutions {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.chaturbhujSolutions;
      case 'Marathi':
        return MarathiLocalization.chaturbhujSolutions;
      default:
        return EnglishLocalization.chaturbhujSolutions;
    }
  }

  String get amountToPay {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.amountToPay;
      case 'Marathi':
        return MarathiLocalization.amountToPay;
      default:
        return EnglishLocalization.amountToPay;
    }
  }

  String get oneYearSubscription {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.oneYearSubscription;
      case 'Marathi':
        return MarathiLocalization.oneYearSubscription;
      default:
        return EnglishLocalization.oneYearSubscription;
    }
  }

  String get scanQRCodeToPay {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.scanQRCodeToPay;
      case 'Marathi':
        return MarathiLocalization.scanQRCodeToPay;
      default:
        return EnglishLocalization.scanQRCodeToPay;
    }
  }

  String get payViaAnyUPIApp {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.payViaAnyUPIApp;
      case 'Marathi':
        return MarathiLocalization.payViaAnyUPIApp;
      default:
        return EnglishLocalization.payViaAnyUPIApp;
    }
  }

  String get important {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.important;
      case 'Marathi':
        return MarathiLocalization.important;
      default:
        return EnglishLocalization.important;
    }
  }

  String get pleaseShareScreenshotOn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseShareScreenshotOn;
      case 'Marathi':
        return MarathiLocalization.pleaseShareScreenshotOn;
      default:
        return EnglishLocalization.pleaseShareScreenshotOn;
    }
  }

  String get subscriptionActivatedWithin24Hours {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.subscriptionActivatedWithin24Hours;
      case 'Marathi':
        return MarathiLocalization.subscriptionActivatedWithin24Hours;
      default:
        return EnglishLocalization.subscriptionActivatedWithin24Hours;
    }
  }

  String get phoneNumberCopied {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.phoneNumberCopied;
      case 'Marathi':
        return MarathiLocalization.phoneNumberCopied;
      default:
        return EnglishLocalization.phoneNumberCopied;
    }
  }

  String get shareOnWhatsApp {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.shareOnWhatsApp;
      case 'Marathi':
        return MarathiLocalization.shareOnWhatsApp;
      default:
        return EnglishLocalization.shareOnWhatsApp;
    }
  }

  String get callSupport {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.callSupport;
      case 'Marathi':
        return MarathiLocalization.callSupport;
      default:
        return EnglishLocalization.callSupport;
    }
  }

  String get securePayment {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.securePayment;
      case 'Marathi':
        return MarathiLocalization.securePayment;
      default:
        return EnglishLocalization.securePayment;
    }
  }

  String get couldNotOpenWhatsApp {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.couldNotOpenWhatsApp;
      case 'Marathi':
        return MarathiLocalization.couldNotOpenWhatsApp;
      default:
        return EnglishLocalization.couldNotOpenWhatsApp;
    }
  }

  // Supplier/Company Code fields
  String get supplierCode {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.supplierCode;
      case 'Marathi':
        return MarathiLocalization.supplierCode;
      default:
        return EnglishLocalization.supplierCode;
    }
  }

  String get companyCode {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companyCode;
      case 'Marathi':
        return MarathiLocalization.companyCode;
      default:
        return EnglishLocalization.companyCode;
    }
  }

  String get supplierCodeRequired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.supplierCodeRequired;
      case 'Marathi':
        return MarathiLocalization.supplierCodeRequired;
      default:
        return EnglishLocalization.supplierCodeRequired;
    }
  }

  String get companyCodeRequired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companyCodeRequired;
      case 'Marathi':
        return MarathiLocalization.companyCodeRequired;
      default:
        return EnglishLocalization.companyCodeRequired;
    }
  }

  String get supplierCodeAlreadyExists {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.supplierCodeAlreadyExists;
      case 'Marathi':
        return MarathiLocalization.supplierCodeAlreadyExists;
      default:
        return EnglishLocalization.supplierCodeAlreadyExists;
    }
  }

  String get companyCodeAlreadyExists {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.companyCodeAlreadyExists;
      case 'Marathi':
        return MarathiLocalization.companyCodeAlreadyExists;
      default:
        return EnglishLocalization.companyCodeAlreadyExists;
    }
  }

  String get addYourFirstCompany {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addYourFirstCompany;
      case 'Marathi':
        return MarathiLocalization.addYourFirstCompany;
      default:
        return EnglishLocalization.addYourFirstCompany;
    }
  }

  String get addCompanyNow {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addCompanyNow;
      case 'Marathi':
        return MarathiLocalization.addCompanyNow;
      default:
        return EnglishLocalization.addCompanyNow;
    }
  }

  // Billing - Batch Selection
  String get selectStockEntry {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectStockEntry;
      case 'Marathi':
        return MarathiLocalization.selectStockEntry;
      default:
        return EnglishLocalization.selectStockEntry;
    }
  }

  String get chooseSpecificBatch {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.chooseSpecificBatch;
      case 'Marathi':
        return MarathiLocalization.chooseSpecificBatch;
      default:
        return EnglishLocalization.chooseSpecificBatch;
    }
  }

  String get availableEntries {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.availableEntries;
      case 'Marathi':
        return MarathiLocalization.availableEntries;
      default:
        return EnglishLocalization.availableEntries;
    }
  }

  String get batch {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.batch;
      case 'Marathi':
        return MarathiLocalization.batch;
      default:
        return EnglishLocalization.batch;
    }
  }

  String get purchasedOn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.purchasedOn;
      case 'Marathi':
        return MarathiLocalization.purchasedOn;
      default:
        return EnglishLocalization.purchasedOn;
    }
  }

  String get pcsAvailable {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pcsAvailable;
      case 'Marathi':
        return MarathiLocalization.pcsAvailable;
      default:
        return EnglishLocalization.pcsAvailable;
    }
  }

  String get sellPrice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.sellPrice;
      case 'Marathi':
        return MarathiLocalization.sellPrice;
      default:
        return EnglishLocalization.sellPrice;
    }
  }

  String get costPrice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.costPrice;
      case 'Marathi':
        return MarathiLocalization.costPrice;
      default:
        return EnglishLocalization.costPrice;
    }
  }

  String get fifoRecommended {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.fifoRecommended;
      case 'Marathi':
        return MarathiLocalization.fifoRecommended;
      default:
        return EnglishLocalization.fifoRecommended;
    }
  }

  String get oldestBatch {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.oldestBatch;
      case 'Marathi':
        return MarathiLocalization.oldestBatch;
      default:
        return EnglishLocalization.oldestBatch;
    }
  }

  String get selectThisEntry {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectThisEntry;
      case 'Marathi':
        return MarathiLocalization.selectThisEntry;
      default:
        return EnglishLocalization.selectThisEntry;
    }
  }

  String get enterQuantity {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterQuantity;
      case 'Marathi':
        return MarathiLocalization.enterQuantity;
      default:
        return EnglishLocalization.enterQuantity;
    }
  }

  String get quantityExceedsStock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.quantityExceedsStock;
      case 'Marathi':
        return MarathiLocalization.quantityExceedsStock;
      default:
        return EnglishLocalization.quantityExceedsStock;
    }
  }

  String get addToBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addToBill;
      case 'Marathi':
        return MarathiLocalization.addToBill;
      default:
        return EnglishLocalization.addToBill;
    }
  }

  String get variants {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.variants;
      case 'Marathi':
        return MarathiLocalization.variants;
      default:
        return EnglishLocalization.variants;
    }
  }

  String get totalAvailable {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.totalAvailable;
      case 'Marathi':
        return MarathiLocalization.totalAvailable;
      default:
        return EnglishLocalization.totalAvailable;
    }
  }

  String get searchBatches {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchBatches;
      case 'Marathi':
        return MarathiLocalization.searchBatches;
      default:
        return EnglishLocalization.searchBatches;
    }
  }

  String get productCode {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.productCode;
      case 'Marathi':
        return MarathiLocalization.productCode;
      default:
        return EnglishLocalization.productCode;
    }
  }

  String get noBatchesFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noBatchesFound;
      case 'Marathi':
        return MarathiLocalization.noBatchesFound;
      default:
        return EnglishLocalization.noBatchesFound;
    }
  }

  // ═══════════════════════════════════════════════════
  // Bill Details Dialog (Bills History)
  // ═══════════════════════════════════════════════════

  String get billDetails {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billDetails;
      case 'Marathi':
        return MarathiLocalization.billDetails;
      default:
        return EnglishLocalization.billDetails;
    }
  }

  String get soldItems {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.soldItems;
      case 'Marathi':
        return MarathiLocalization.soldItems;
      default:
        return EnglishLocalization.soldItems;
    }
  }

  String get billNo {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billNo;
      case 'Marathi':
        return MarathiLocalization.billNo;
      default:
        return EnglishLocalization.billNo;
    }
  }

  String get mobile {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.mobile;
      case 'Marathi':
        return MarathiLocalization.mobile;
      default:
        return EnglishLocalization.mobile;
    }
  }

  String get totalQuantity {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.totalQuantity;
      case 'Marathi':
        return MarathiLocalization.totalQuantity;
      default:
        return EnglishLocalization.totalQuantity;
    }
  }

  String get billTotalLabel {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billTotalLabel;
      case 'Marathi':
        return MarathiLocalization.billTotalLabel;
      default:
        return EnglishLocalization.billTotalLabel;
    }
  }

  String get returnDeduction {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returnDeduction;
      case 'Marathi':
        return MarathiLocalization.returnDeduction;
      default:
        return EnglishLocalization.returnDeduction;
    }
  }

  String get finalPayable {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.finalPayable;
      case 'Marathi':
        return MarathiLocalization.finalPayable;
      default:
        return EnglishLocalization.finalPayable;
    }
  }

  String get finalAmount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.finalAmount;
      case 'Marathi':
        return MarathiLocalization.finalAmount;
      default:
        return EnglishLocalization.finalAmount;
    }
  }

  String get fullyReturned {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.fullyReturned;
      case 'Marathi':
        return MarathiLocalization.fullyReturned;
      default:
        return EnglishLocalization.fullyReturned;
    }
  }

  String get partialReturn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.partialReturn;
      case 'Marathi':
        return MarathiLocalization.partialReturn;
      default:
        return EnglishLocalization.partialReturn;
    }
  }

  String get statusFullyReturned {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.statusFullyReturned;
      case 'Marathi':
        return MarathiLocalization.statusFullyReturned;
      default:
        return EnglishLocalization.statusFullyReturned;
    }
  }

  String get includeReturnedItemsInPrint {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.includeReturnedItemsInPrint;
      case 'Marathi':
        return MarathiLocalization.includeReturnedItemsInPrint;
      default:
        return EnglishLocalization.includeReturnedItemsInPrint;
    }
  }

  String get returnThisBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returnThisBill;
      case 'Marathi':
        return MarathiLocalization.returnThisBill;
      default:
        return EnglishLocalization.returnThisBill;
    }
  }

  String get billReturned {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billReturned;
      case 'Marathi':
        return MarathiLocalization.billReturned;
      default:
        return EnglishLocalization.billReturned;
    }
  }

  String get paidAmount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.paidAmount;
      case 'Marathi':
        return MarathiLocalization.paidAmount;
      default:
        return EnglishLocalization.paidAmount;
    }
  }

  String get selectDateRange {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectDateRange;
      case 'Marathi':
        return MarathiLocalization.selectDateRange;
      default:
        return EnglishLocalization.selectDateRange;
    }
  }

  String get startDate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.startDate;
      case 'Marathi':
        return MarathiLocalization.startDate;
      default:
        return EnglishLocalization.startDate;
    }
  }

  String get endDate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.endDate;
      case 'Marathi':
        return MarathiLocalization.endDate;
      default:
        return EnglishLocalization.endDate;
    }
  }

  String get reset {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.reset;
      case 'Marathi':
        return MarathiLocalization.reset;
      default:
        return EnglishLocalization.reset;
    }
  }

  String get product {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.product;
      case 'Marathi':
        return MarathiLocalization.product;
      default:
        return EnglishLocalization.product;
    }
  }

  String get rate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.rate;
      case 'Marathi':
        return MarathiLocalization.rate;
      default:
        return EnglishLocalization.rate;
    }
  }

  String get returnLabel {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returnLabel;
      case 'Marathi':
        return MarathiLocalization.returnLabel;
      default:
        return EnglishLocalization.returnLabel;
    }
  }

  String get errorLoadingBills {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorLoadingBills;
      case 'Marathi':
        return MarathiLocalization.errorLoadingBills;
      default:
        return EnglishLocalization.errorLoadingBills;
    }
  }

  String get errorSharingBillGeneric {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorSharingBillGeneric;
      case 'Marathi':
        return MarathiLocalization.errorSharingBillGeneric;
      default:
        return EnglishLocalization.errorSharingBillGeneric;
    }
  }

  String get errorSavingPdfGeneric {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorSavingPdfGeneric;
      case 'Marathi':
        return MarathiLocalization.errorSavingPdfGeneric;
      default:
        return EnglishLocalization.errorSavingPdfGeneric;
    }
  }

  String get errorPrintingBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorPrintingBill;
      case 'Marathi':
        return MarathiLocalization.errorPrintingBill;
      default:
        return EnglishLocalization.errorPrintingBill;
    }
  }

  String get totalReturns {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.totalReturns;
      case 'Marathi':
        return MarathiLocalization.totalReturns;
      default:
        return EnglishLocalization.totalReturns;
    }
  }

  // ═══════════════════════════════════════════════════
  // Dashboard Page
  // ═══════════════════════════════════════════════════

  String get exitApp {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.exitApp;
      case 'Marathi':
        return MarathiLocalization.exitApp;
      default:
        return EnglishLocalization.exitApp;
    }
  }

  String get exitAppConfirm {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.exitAppConfirm;
      case 'Marathi':
        return MarathiLocalization.exitAppConfirm;
      default:
        return EnglishLocalization.exitAppConfirm;
    }
  }

  String get exit {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.exit;
      case 'Marathi':
        return MarathiLocalization.exit;
      default:
        return EnglishLocalization.exit;
    }
  }

  String get selectLanguage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectLanguage;
      case 'Marathi':
        return MarathiLocalization.selectLanguage;
      default:
        return EnglishLocalization.selectLanguage;
    }
  }

  String get languageChangedTo {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.languageChangedTo;
      case 'Marathi':
        return MarathiLocalization.languageChangedTo;
      default:
        return EnglishLocalization.languageChangedTo;
    }
  }

  String get unableToRefresh {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.unableToRefresh;
      case 'Marathi':
        return MarathiLocalization.unableToRefresh;
      default:
        return EnglishLocalization.unableToRefresh;
    }
  }

  String get retry {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.retry;
      case 'Marathi':
        return MarathiLocalization.retry;
      default:
        return EnglishLocalization.retry;
    }
  }

  String get custom {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.custom;
      case 'Marathi':
        return MarathiLocalization.custom;
      default:
        return EnglishLocalization.custom;
    }
  }

  String get returns {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returns;
      case 'Marathi':
        return MarathiLocalization.returns;
      default:
        return EnglishLocalization.returns;
    }
  }

  String get netSales {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.netSales;
      case 'Marathi':
        return MarathiLocalization.netSales;
      default:
        return EnglishLocalization.netSales;
    }
  }

  String get afterReturnsDeducted {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.afterReturnsDeducted;
      case 'Marathi':
        return MarathiLocalization.afterReturnsDeducted;
      default:
        return EnglishLocalization.afterReturnsDeducted;
    }
  }

  String get stockAndPayments {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.stockAndPayments;
      case 'Marathi':
        return MarathiLocalization.stockAndPayments;
      default:
        return EnglishLocalization.stockAndPayments;
    }
  }

  String get paymentStatus {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.paymentStatus;
      case 'Marathi':
        return MarathiLocalization.paymentStatus;
      default:
        return EnglishLocalization.paymentStatus;
    }
  }

  String get comingSoon {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.comingSoon;
      case 'Marathi':
        return MarathiLocalization.comingSoon;
      default:
        return EnglishLocalization.comingSoon;
    }
  }

  String get paymentTrackingMessage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.paymentTrackingMessage;
      case 'Marathi':
        return MarathiLocalization.paymentTrackingMessage;
      default:
        return EnglishLocalization.paymentTrackingMessage;
    }
  }

  String get loss {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.loss;
      case 'Marathi':
        return MarathiLocalization.loss;
      default:
        return EnglishLocalization.loss;
    }
  }

  String get billSettings {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billSettings;
      case 'Marathi':
        return MarathiLocalization.billSettings;
      default:
        return EnglishLocalization.billSettings;
    }
  }

  String get purchaseSettings {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.purchaseSettings;
      case 'Marathi':
        return MarathiLocalization.purchaseSettings;
      default:
        return EnglishLocalization.purchaseSettings;
    }
  }

  String get language {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.language;
      case 'Marathi':
        return MarathiLocalization.language;
      default:
        return EnglishLocalization.language;
    }
  }

  String get viewLogs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.viewLogs;
      case 'Marathi':
        return MarathiLocalization.viewLogs;
      default:
        return EnglishLocalization.viewLogs;
    }
  }

  String get onlyLeftInStock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.onlyLeftInStock;
      case 'Marathi':
        return MarathiLocalization.onlyLeftInStock;
      default:
        return EnglishLocalization.onlyLeftInStock;
    }
  }

  String get outOfStockAlert {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.outOfStockAlert;
      case 'Marathi':
        return MarathiLocalization.outOfStockAlert;
      default:
        return EnglishLocalization.outOfStockAlert;
    }
  }

  String get order {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.order;
      case 'Marathi':
        return MarathiLocalization.order;
      default:
        return EnglishLocalization.order;
    }
  }

  String get noDataAvailableDashboard {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noDataAvailableDashboard;
      case 'Marathi':
        return MarathiLocalization.noDataAvailableDashboard;
      default:
        return EnglishLocalization.noDataAvailableDashboard;
    }
  }

  String get year {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.year;
      case 'Marathi':
        return MarathiLocalization.year;
      default:
        return EnglishLocalization.year;
    }
  }

  // ═══════════════════════════════════════════════════
  // Return Bill Page
  // ═══════════════════════════════════════════════════

  String get returnBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returnBill;
      case 'Marathi':
        return MarathiLocalization.returnBill;
      default:
        return EnglishLocalization.returnBill;
    }
  }

  String get processBillReturns {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.processBillReturns;
      case 'Marathi':
        return MarathiLocalization.processBillReturns;
      default:
        return EnglishLocalization.processBillReturns;
    }
  }

  String get searchBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchBill;
      case 'Marathi':
        return MarathiLocalization.searchBill;
      default:
        return EnglishLocalization.searchBill;
    }
  }

  String get enterBillOrMobile {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterBillOrMobile;
      case 'Marathi':
        return MarathiLocalization.enterBillOrMobile;
      default:
        return EnglishLocalization.enterBillOrMobile;
    }
  }

  String get billOrMobileHint {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billOrMobileHint;
      case 'Marathi':
        return MarathiLocalization.billOrMobileHint;
      default:
        return EnglishLocalization.billOrMobileHint;
    }
  }

  String get searchAndValidate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchAndValidate;
      case 'Marathi':
        return MarathiLocalization.searchAndValidate;
      default:
        return EnglishLocalization.searchAndValidate;
    }
  }

  String get pleaseEnterBillOrMobile {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterBillOrMobile;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterBillOrMobile;
      default:
        return EnglishLocalization.pleaseEnterBillOrMobile;
    }
  }

  String get billNotFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billNotFound;
      case 'Marathi':
        return MarathiLocalization.billNotFound;
      default:
        return EnglishLocalization.billNotFound;
    }
  }

  String get errorSearchingBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorSearchingBill;
      case 'Marathi':
        return MarathiLocalization.errorSearchingBill;
      default:
        return EnglishLocalization.errorSearchingBill;
    }
  }

  String get allItemsReturned {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.allItemsReturned;
      case 'Marathi':
        return MarathiLocalization.allItemsReturned;
      default:
        return EnglishLocalization.allItemsReturned;
    }
  }

  String get billDate {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billDate;
      case 'Marathi':
        return MarathiLocalization.billDate;
      default:
        return EnglishLocalization.billDate;
    }
  }

  String get contact {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.contact;
      case 'Marathi':
        return MarathiLocalization.contact;
      default:
        return EnglishLocalization.contact;
    }
  }

  String get active {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.active;
      case 'Marathi':
        return MarathiLocalization.active;
      default:
        return EnglishLocalization.active;
    }
  }

  String get returnedLabel {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returnedLabel;
      case 'Marathi':
        return MarathiLocalization.returnedLabel;
      default:
        return EnglishLocalization.returnedLabel;
    }
  }

  String get originalQuantity {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.originalQuantity;
      case 'Marathi':
        return MarathiLocalization.originalQuantity;
      default:
        return EnglishLocalization.originalQuantity;
    }
  }

  String get returnQty {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returnQty;
      case 'Marathi':
        return MarathiLocalization.returnQty;
      default:
        return EnglishLocalization.returnQty;
    }
  }

  String get refundAmount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.refundAmount;
      case 'Marathi':
        return MarathiLocalization.refundAmount;
      default:
        return EnglishLocalization.refundAmount;
    }
  }

  String get selectItemsToReturn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectItemsToReturn;
      case 'Marathi':
        return MarathiLocalization.selectItemsToReturn;
      default:
        return EnglishLocalization.selectItemsToReturn;
    }
  }

  String get itemsToReturn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.itemsToReturn;
      case 'Marathi':
        return MarathiLocalization.itemsToReturn;
      default:
        return EnglishLocalization.itemsToReturn;
    }
  }

  String get selectAll {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectAll;
      case 'Marathi':
        return MarathiLocalization.selectAll;
      default:
        return EnglishLocalization.selectAll;
    }
  }

  String get clear {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.clear;
      case 'Marathi':
        return MarathiLocalization.clear;
      default:
        return EnglishLocalization.clear;
    }
  }

  String get confirmReturn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.confirmReturn;
      case 'Marathi':
        return MarathiLocalization.confirmReturn;
      default:
        return EnglishLocalization.confirmReturn;
    }
  }

  String get confirmReturnMessage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.confirmReturnMessage;
      case 'Marathi':
        return MarathiLocalization.confirmReturnMessage;
      default:
        return EnglishLocalization.confirmReturnMessage;
    }
  }

  String get restoreToInventory {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.restoreToInventory;
      case 'Marathi':
        return MarathiLocalization.restoreToInventory;
      default:
        return EnglishLocalization.restoreToInventory;
    }
  }

  String get processReturn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.processReturn;
      case 'Marathi':
        return MarathiLocalization.processReturn;
      default:
        return EnglishLocalization.processReturn;
    }
  }

  String get processingReturn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.processingReturn;
      case 'Marathi':
        return MarathiLocalization.processingReturn;
      default:
        return EnglishLocalization.processingReturn;
    }
  }

  String get returnProcessedSuccess {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returnProcessedSuccess;
      case 'Marathi':
        return MarathiLocalization.returnProcessedSuccess;
      default:
        return EnglishLocalization.returnProcessedSuccess;
    }
  }

  String get returnProcessedPrint {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returnProcessedPrint;
      case 'Marathi':
        return MarathiLocalization.returnProcessedPrint;
      default:
        return EnglishLocalization.returnProcessedPrint;
    }
  }

  String get failedToProcessReturn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.failedToProcessReturn;
      case 'Marathi':
        return MarathiLocalization.failedToProcessReturn;
      default:
        return EnglishLocalization.failedToProcessReturn;
    }
  }

  String get errorProcessingReturn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorProcessingReturn;
      case 'Marathi':
        return MarathiLocalization.errorProcessingReturn;
      default:
        return EnglishLocalization.errorProcessingReturn;
    }
  }

  String get returnedOn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.returnedOn;
      case 'Marathi':
        return MarathiLocalization.returnedOn;
      default:
        return EnglishLocalization.returnedOn;
    }
  }

  String get refund {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.refund;
      case 'Marathi':
        return MarathiLocalization.refund;
      default:
        return EnglishLocalization.refund;
    }
  }

  // ═══════════════════════════════════════════════════
  // Billing Page (additional)
  // ═══════════════════════════════════════════════════

  String get enterPhoneNumber {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterPhoneNumber;
      case 'Marathi':
        return MarathiLocalization.enterPhoneNumber;
      default:
        return EnglishLocalization.enterPhoneNumber;
    }
  }

  String get enterCustomerPhone {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterCustomerPhone;
      case 'Marathi':
        return MarathiLocalization.enterCustomerPhone;
      default:
        return EnglishLocalization.enterCustomerPhone;
    }
  }

  String get firstNameRequired2 {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.firstNameRequired2;
      case 'Marathi':
        return MarathiLocalization.firstNameRequired2;
      default:
        return EnglishLocalization.firstNameRequired2;
    }
  }

  String get lastNameRequired2 {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.lastNameRequired2;
      case 'Marathi':
        return MarathiLocalization.lastNameRequired2;
      default:
        return EnglishLocalization.lastNameRequired2;
    }
  }

  String get saveAndAttach {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.saveAndAttach;
      case 'Marathi':
        return MarathiLocalization.saveAndAttach;
      default:
        return EnglishLocalization.saveAndAttach;
    }
  }

  String get skip {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.skip;
      case 'Marathi':
        return MarathiLocalization.skip;
      default:
        return EnglishLocalization.skip;
    }
  }

  String get full {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.full;
      case 'Marathi':
        return MarathiLocalization.full;
      default:
        return EnglishLocalization.full;
    }
  }

  String get continuingWithoutCustomer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.continuingWithoutCustomer;
      case 'Marathi':
        return MarathiLocalization.continuingWithoutCustomer;
      default:
        return EnglishLocalization.continuingWithoutCustomer;
    }
  }

  String get billProcessingFailed {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billProcessingFailed;
      case 'Marathi':
        return MarathiLocalization.billProcessingFailed;
      default:
        return EnglishLocalization.billProcessingFailed;
    }
  }

  String get pleaseEnterValidContact {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterValidContact;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterValidContact;
      default:
        return EnglishLocalization.pleaseEnterValidContact;
    }
  }

  String get clearPhoneNumber {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.clearPhoneNumber;
      case 'Marathi':
        return MarathiLocalization.clearPhoneNumber;
      default:
        return EnglishLocalization.clearPhoneNumber;
    }
  }

  String get phoneNumberOptional {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.phoneNumberOptional;
      case 'Marathi':
        return MarathiLocalization.phoneNumberOptional;
      default:
        return EnglishLocalization.phoneNumberOptional;
    }
  }

  String get printBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.printBill;
      case 'Marathi':
        return MarathiLocalization.printBill;
      default:
        return EnglishLocalization.printBill;
    }
  }

  String get customerNotFoundFor {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.customerNotFoundFor;
      case 'Marathi':
        return MarathiLocalization.customerNotFoundFor;
      default:
        return EnglishLocalization.customerNotFoundFor;
    }
  }

  String get customerColon {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.customerColon;
      case 'Marathi':
        return MarathiLocalization.customerColon;
      default:
        return EnglishLocalization.customerColon;
    }
  }

  String get discountWithPercent {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.discountWithPercent;
      case 'Marathi':
        return MarathiLocalization.discountWithPercent;
      default:
        return EnglishLocalization.discountWithPercent;
    }
  }

  // ═══════════════════════════════════════════════════
  // Bill Settings Page
  // ═══════════════════════════════════════════════════

  String get billingSettings {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billingSettings;
      case 'Marathi':
        return MarathiLocalization.billingSettings;
      default:
        return EnglishLocalization.billingSettings;
    }
  }

  String get billType {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billType;
      case 'Marathi':
        return MarathiLocalization.billType;
      default:
        return EnglishLocalization.billType;
    }
  }

  String get selectDefaultBillType {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectDefaultBillType;
      case 'Marathi':
        return MarathiLocalization.selectDefaultBillType;
      default:
        return EnglishLocalization.selectDefaultBillType;
    }
  }

  String get normalBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.normalBill;
      case 'Marathi':
        return MarathiLocalization.normalBill;
      default:
        return EnglishLocalization.normalBill;
    }
  }

  String get thermalReceipt {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.thermalReceipt;
      case 'Marathi':
        return MarathiLocalization.thermalReceipt;
      default:
        return EnglishLocalization.thermalReceipt;
    }
  }

  String get selected {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selected;
      case 'Marathi':
        return MarathiLocalization.selected;
      default:
        return EnglishLocalization.selected;
    }
  }

  String get printSettings {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.printSettings;
      case 'Marathi':
        return MarathiLocalization.printSettings;
      default:
        return EnglishLocalization.printSettings;
    }
  }

  String get posPrinter {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.posPrinter;
      case 'Marathi':
        return MarathiLocalization.posPrinter;
      default:
        return EnglishLocalization.posPrinter;
    }
  }

  String get pdfFormat {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pdfFormat;
      case 'Marathi':
        return MarathiLocalization.pdfFormat;
      default:
        return EnglishLocalization.pdfFormat;
    }
  }

  String get showCustomerDetailsOnBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.showCustomerDetailsOnBill;
      case 'Marathi':
        return MarathiLocalization.showCustomerDetailsOnBill;
      default:
        return EnglishLocalization.showCustomerDetailsOnBill;
    }
  }

  String get displayCustomerOnBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.displayCustomerOnBill;
      case 'Marathi':
        return MarathiLocalization.displayCustomerOnBill;
      default:
        return EnglishLocalization.displayCustomerOnBill;
    }
  }

  String get generateBillViaContact {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.generateBillViaContact;
      case 'Marathi':
        return MarathiLocalization.generateBillViaContact;
      default:
        return EnglishLocalization.generateBillViaContact;
    }
  }

  String get requireContactNumber {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.requireContactNumber;
      case 'Marathi':
        return MarathiLocalization.requireContactNumber;
      default:
        return EnglishLocalization.requireContactNumber;
    }
  }

  String get contactNumberNote {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.contactNumberNote;
      case 'Marathi':
        return MarathiLocalization.contactNumberNote;
      default:
        return EnglishLocalization.contactNumberNote;
    }
  }

  String get settingsSaved {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.settingsSaved;
      case 'Marathi':
        return MarathiLocalization.settingsSaved;
      default:
        return EnglishLocalization.settingsSaved;
    }
  }

  // ═══════════════════════════════════════════════════
  // Shop Details Page
  // ═══════════════════════════════════════════════════

  String get shopDetails {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.shopDetails;
      case 'Marathi':
        return MarathiLocalization.shopDetails;
      default:
        return EnglishLocalization.shopDetails;
    }
  }

  String get shopInformation {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.shopInformation;
      case 'Marathi':
        return MarathiLocalization.shopInformation;
      default:
        return EnglishLocalization.shopInformation;
    }
  }

  String get shopName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.shopName;
      case 'Marathi':
        return MarathiLocalization.shopName;
      default:
        return EnglishLocalization.shopName;
    }
  }

  String get businessInformation {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.businessInformation;
      case 'Marathi':
        return MarathiLocalization.businessInformation;
      default:
        return EnglishLocalization.businessInformation;
    }
  }

  String get gstNumber {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.gstNumber;
      case 'Marathi':
        return MarathiLocalization.gstNumber;
      default:
        return EnglishLocalization.gstNumber;
    }
  }

  String get contactInformation {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.contactInformation;
      case 'Marathi':
        return MarathiLocalization.contactInformation;
      default:
        return EnglishLocalization.contactInformation;
    }
  }

  String get email {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.email;
      case 'Marathi':
        return MarathiLocalization.email;
      default:
        return EnglishLocalization.email;
    }
  }

  String get pincode {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pincode;
      case 'Marathi':
        return MarathiLocalization.pincode;
      default:
        return EnglishLocalization.pincode;
    }
  }

  String get ownerName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.ownerName;
      case 'Marathi':
        return MarathiLocalization.ownerName;
      default:
        return EnglishLocalization.ownerName;
    }
  }

  String get saveShopDetails {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.saveShopDetails;
      case 'Marathi':
        return MarathiLocalization.saveShopDetails;
      default:
        return EnglishLocalization.saveShopDetails;
    }
  }

  String get shopDetailsSaved {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.shopDetailsSaved;
      case 'Marathi':
        return MarathiLocalization.shopDetailsSaved;
      default:
        return EnglishLocalization.shopDetailsSaved;
    }
  }

  // ═══════════════════════════════════════════════════
  // Flyout Menu
  // ═══════════════════════════════════════════════════

  String get profile {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.profile;
      case 'Marathi':
        return MarathiLocalization.profile;
      default:
        return EnglishLocalization.profile;
    }
  }

  String get settings {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.settings;
      case 'Marathi':
        return MarathiLocalization.settings;
      default:
        return EnglishLocalization.settings;
    }
  }

  String get inventory {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.inventory;
      case 'Marathi':
        return MarathiLocalization.inventory;
      default:
        return EnglishLocalization.inventory;
    }
  }

  String get clients {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.clients;
      case 'Marathi':
        return MarathiLocalization.clients;
      default:
        return EnglishLocalization.clients;
    }
  }

  String get purchases {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.purchases;
      case 'Marathi':
        return MarathiLocalization.purchases;
      default:
        return EnglishLocalization.purchases;
    }
  }

  String get reports {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.reports;
      case 'Marathi':
        return MarathiLocalization.reports;
      default:
        return EnglishLocalization.reports;
    }
  }

  String get reportsComingSoon {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.reportsComingSoon;
      case 'Marathi':
        return MarathiLocalization.reportsComingSoon;
      default:
        return EnglishLocalization.reportsComingSoon;
    }
  }

  String get invoicesComingSoon {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.invoicesComingSoon;
      case 'Marathi':
        return MarathiLocalization.invoicesComingSoon;
      default:
        return EnglishLocalization.invoicesComingSoon;
    }
  }

  String get logout {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.logout;
      case 'Marathi':
        return MarathiLocalization.logout;
      default:
        return EnglishLocalization.logout;
    }
  }

  String get close {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.close;
      case 'Marathi':
        return MarathiLocalization.close;
      default:
        return EnglishLocalization.close;
    }
  }

  String get online {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.online;
      case 'Marathi':
        return MarathiLocalization.online;
      default:
        return EnglishLocalization.online;
    }
  }

  String get forgotPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.forgotPassword;
      case 'Marathi':
        return MarathiLocalization.forgotPassword;
      default:
        return EnglishLocalization.forgotPassword;
    }
  }

  String get changePassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.changePassword;
      case 'Marathi':
        return MarathiLocalization.changePassword;
      default:
        return EnglishLocalization.changePassword;
    }
  }

  String get biometricLock {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.biometricLock;
      case 'Marathi':
        return MarathiLocalization.biometricLock;
      default:
        return EnglishLocalization.biometricLock;
    }
  }

  String get unlockWithBiometric {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.unlockWithBiometric;
      case 'Marathi':
        return MarathiLocalization.unlockWithBiometric;
      default:
        return EnglishLocalization.unlockWithBiometric;
    }
  }

  String get biometricEnabled {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.biometricEnabled;
      case 'Marathi':
        return MarathiLocalization.biometricEnabled;
      default:
        return EnglishLocalization.biometricEnabled;
    }
  }

  String get biometricDisabled {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.biometricDisabled;
      case 'Marathi':
        return MarathiLocalization.biometricDisabled;
      default:
        return EnglishLocalization.biometricDisabled;
    }
  }

  String get biometricsNotAvailable {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.biometricsNotAvailable;
      case 'Marathi':
        return MarathiLocalization.biometricsNotAvailable;
      default:
        return EnglishLocalization.biometricsNotAvailable;
    }
  }

  String get version {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.version;
      case 'Marathi':
        return MarathiLocalization.version;
      default:
        return EnglishLocalization.version;
    }
  }

  String get user {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.user;
      case 'Marathi':
        return MarathiLocalization.user;
      default:
        return EnglishLocalization.user;
    }
  }

  String get logs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.logs;
      case 'Marathi':
        return MarathiLocalization.logs;
      default:
        return EnglishLocalization.logs;
    }
  }

  // ═══════════════════════════════════════════════════
  // Profile Page
  // ═══════════════════════════════════════════════════

  String get myProfile {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.myProfile;
      case 'Marathi':
        return MarathiLocalization.myProfile;
      default:
        return EnglishLocalization.myProfile;
    }
  }

  String get fullName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.fullName;
      case 'Marathi':
        return MarathiLocalization.fullName;
      default:
        return EnglishLocalization.fullName;
    }
  }

  String get enterFullName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterFullName;
      case 'Marathi':
        return MarathiLocalization.enterFullName;
      default:
        return EnglishLocalization.enterFullName;
    }
  }

  String get emailAddress {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.emailAddress;
      case 'Marathi':
        return MarathiLocalization.emailAddress;
      default:
        return EnglishLocalization.emailAddress;
    }
  }

  String get yourEmail {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.yourEmail;
      case 'Marathi':
        return MarathiLocalization.yourEmail;
      default:
        return EnglishLocalization.yourEmail;
    }
  }

  String get phoneNumber {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.phoneNumber;
      case 'Marathi':
        return MarathiLocalization.phoneNumber;
      default:
        return EnglishLocalization.phoneNumber;
    }
  }

  String get enterPhoneNumberProfile {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterPhoneNumberProfile;
      case 'Marathi':
        return MarathiLocalization.enterPhoneNumberProfile;
      default:
        return EnglishLocalization.enterPhoneNumberProfile;
    }
  }

  String get enterAddress {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterAddress;
      case 'Marathi':
        return MarathiLocalization.enterAddress;
      default:
        return EnglishLocalization.enterAddress;
    }
  }

  String get saveChanges {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.saveChanges;
      case 'Marathi':
        return MarathiLocalization.saveChanges;
      default:
        return EnglishLocalization.saveChanges;
    }
  }

  String get pleaseEnterName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterName;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterName;
      default:
        return EnglishLocalization.pleaseEnterName;
    }
  }

  String get profileUpdated {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.profileUpdated;
      case 'Marathi':
        return MarathiLocalization.profileUpdated;
      default:
        return EnglishLocalization.profileUpdated;
    }
  }

  String get profileUpdatedSuccessfully {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.profileUpdatedSuccessfully;
      case 'Marathi':
        return MarathiLocalization.profileUpdatedSuccessfully;
      default:
        return EnglishLocalization.profileUpdatedSuccessfully;
    }
  }

  String get errorSavingProfile {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorSavingProfile;
      case 'Marathi':
        return MarathiLocalization.errorSavingProfile;
      default:
        return EnglishLocalization.errorSavingProfile;
    }
  }

  String get failedToPickImage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.failedToPickImage;
      case 'Marathi':
        return MarathiLocalization.failedToPickImage;
      default:
        return EnglishLocalization.failedToPickImage;
    }
  }

  // ═══════════════════════════════════════════════════
  // Auth Pages (Login/Signup/Change Password)
  // ═══════════════════════════════════════════════════

  String get welcomeBackLogin {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.welcomeBackLogin;
      case 'Marathi':
        return MarathiLocalization.welcomeBackLogin;
      default:
        return EnglishLocalization.welcomeBackLogin;
    }
  }

  String get signInToAccount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.signInToAccount;
      case 'Marathi':
        return MarathiLocalization.signInToAccount;
      default:
        return EnglishLocalization.signInToAccount;
    }
  }

  String get backboneOfBusiness {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.backboneOfBusiness;
      case 'Marathi':
        return MarathiLocalization.backboneOfBusiness;
      default:
        return EnglishLocalization.backboneOfBusiness;
    }
  }

  String get enterEmailPhone {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterEmailPhone;
      case 'Marathi':
        return MarathiLocalization.enterEmailPhone;
      default:
        return EnglishLocalization.enterEmailPhone;
    }
  }

  String get password {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.password;
      case 'Marathi':
        return MarathiLocalization.password;
      default:
        return EnglishLocalization.password;
    }
  }

  String get forgotPasswordQuestion {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.forgotPasswordQuestion;
      case 'Marathi':
        return MarathiLocalization.forgotPasswordQuestion;
      default:
        return EnglishLocalization.forgotPasswordQuestion;
    }
  }

  String get signIn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.signIn;
      case 'Marathi':
        return MarathiLocalization.signIn;
      default:
        return EnglishLocalization.signIn;
    }
  }

  String get continueWithGoogle {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.continueWithGoogle;
      case 'Marathi':
        return MarathiLocalization.continueWithGoogle;
      default:
        return EnglishLocalization.continueWithGoogle;
    }
  }

  String get signUp {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.signUp;
      case 'Marathi':
        return MarathiLocalization.signUp;
      default:
        return EnglishLocalization.signUp;
    }
  }

  String get orDivider {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.orDivider;
      case 'Marathi':
        return MarathiLocalization.orDivider;
      default:
        return EnglishLocalization.orDivider;
    }
  }

  String get dontHaveAccount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.dontHaveAccount;
      case 'Marathi':
        return MarathiLocalization.dontHaveAccount;
      default:
        return EnglishLocalization.dontHaveAccount;
    }
  }

  String get cBillingAppLogs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.cBillingAppLogs;
      case 'Marathi':
        return MarathiLocalization.cBillingAppLogs;
      default:
        return EnglishLocalization.cBillingAppLogs;
    }
  }

  String get loginSuccessful {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.loginSuccessful;
      case 'Marathi':
        return MarathiLocalization.loginSuccessful;
      default:
        return EnglishLocalization.loginSuccessful;
    }
  }

  String get authError {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.authError;
      case 'Marathi':
        return MarathiLocalization.authError;
      default:
        return EnglishLocalization.authError;
    }
  }

  String get sessionExpired {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.sessionExpired;
      case 'Marathi':
        return MarathiLocalization.sessionExpired;
      default:
        return EnglishLocalization.sessionExpired;
    }
  }

  String get createAccount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.createAccount;
      case 'Marathi':
        return MarathiLocalization.createAccount;
      default:
        return EnglishLocalization.createAccount;
    }
  }

  String get createYourAccount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.createYourAccount;
      case 'Marathi':
        return MarathiLocalization.createYourAccount;
      default:
        return EnglishLocalization.createYourAccount;
    }
  }

  String get confirmPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.confirmPassword;
      case 'Marathi':
        return MarathiLocalization.confirmPassword;
      default:
        return EnglishLocalization.confirmPassword;
    }
  }

  String get alreadyHaveAccount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.alreadyHaveAccount;
      case 'Marathi':
        return MarathiLocalization.alreadyHaveAccount;
      default:
        return EnglishLocalization.alreadyHaveAccount;
    }
  }

  String get accountCreated {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.accountCreated;
      case 'Marathi':
        return MarathiLocalization.accountCreated;
      default:
        return EnglishLocalization.accountCreated;
    }
  }

  String get accountCreationFailed {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.accountCreationFailed;
      case 'Marathi':
        return MarathiLocalization.accountCreationFailed;
      default:
        return EnglishLocalization.accountCreationFailed;
    }
  }

  String get passwordsDoNotMatch {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.passwordsDoNotMatch;
      case 'Marathi':
        return MarathiLocalization.passwordsDoNotMatch;
      default:
        return EnglishLocalization.passwordsDoNotMatch;
    }
  }

  String get pleaseFillAllFields {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseFillAllFields;
      case 'Marathi':
        return MarathiLocalization.pleaseFillAllFields;
      default:
        return EnglishLocalization.pleaseFillAllFields;
    }
  }

  String get enterValid10DigitPhone {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterValid10DigitPhone;
      case 'Marathi':
        return MarathiLocalization.enterValid10DigitPhone;
      default:
        return EnglishLocalization.enterValid10DigitPhone;
    }
  }

  String get changePasswordTitle {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.changePasswordTitle;
      case 'Marathi':
        return MarathiLocalization.changePasswordTitle;
      default:
        return EnglishLocalization.changePasswordTitle;
    }
  }

  String get updateYourPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.updateYourPassword;
      case 'Marathi':
        return MarathiLocalization.updateYourPassword;
      default:
        return EnglishLocalization.updateYourPassword;
    }
  }

  String get enterOldAndNew {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterOldAndNew;
      case 'Marathi':
        return MarathiLocalization.enterOldAndNew;
      default:
        return EnglishLocalization.enterOldAndNew;
    }
  }

  String get oldPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.oldPassword;
      case 'Marathi':
        return MarathiLocalization.oldPassword;
      default:
        return EnglishLocalization.oldPassword;
    }
  }

  String get enterOldPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterOldPassword;
      case 'Marathi':
        return MarathiLocalization.enterOldPassword;
      default:
        return EnglishLocalization.enterOldPassword;
    }
  }

  String get newPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.newPassword;
      case 'Marathi':
        return MarathiLocalization.newPassword;
      default:
        return EnglishLocalization.newPassword;
    }
  }

  String get enterNewPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterNewPassword;
      case 'Marathi':
        return MarathiLocalization.enterNewPassword;
      default:
        return EnglishLocalization.enterNewPassword;
    }
  }

  String get reenterNewPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.reenterNewPassword;
      case 'Marathi':
        return MarathiLocalization.reenterNewPassword;
      default:
        return EnglishLocalization.reenterNewPassword;
    }
  }

  String get updatePassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.updatePassword;
      case 'Marathi':
        return MarathiLocalization.updatePassword;
      default:
        return EnglishLocalization.updatePassword;
    }
  }

  String get pleaseEnterOldPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterOldPassword;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterOldPassword;
      default:
        return EnglishLocalization.pleaseEnterOldPassword;
    }
  }

  String get pleaseEnterNewPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterNewPassword;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterNewPassword;
      default:
        return EnglishLocalization.pleaseEnterNewPassword;
    }
  }

  String get pleaseConfirmNewPassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseConfirmNewPassword;
      case 'Marathi':
        return MarathiLocalization.pleaseConfirmNewPassword;
      default:
        return EnglishLocalization.pleaseConfirmNewPassword;
    }
  }

  String get newPasswordDoNotMatch {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.newPasswordDoNotMatch;
      case 'Marathi':
        return MarathiLocalization.newPasswordDoNotMatch;
      default:
        return EnglishLocalization.newPasswordDoNotMatch;
    }
  }

  String get newPasswordTooWeak {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.newPasswordTooWeak;
      case 'Marathi':
        return MarathiLocalization.newPasswordTooWeak;
      default:
        return EnglishLocalization.newPasswordTooWeak;
    }
  }

  String get newPasswordMustDiffer {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.newPasswordMustDiffer;
      case 'Marathi':
        return MarathiLocalization.newPasswordMustDiffer;
      default:
        return EnglishLocalization.newPasswordMustDiffer;
    }
  }

  String get oldPasswordIncorrect {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.oldPasswordIncorrect;
      case 'Marathi':
        return MarathiLocalization.oldPasswordIncorrect;
      default:
        return EnglishLocalization.oldPasswordIncorrect;
    }
  }

  String get passwordUpdated {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.passwordUpdated;
      case 'Marathi':
        return MarathiLocalization.passwordUpdated;
      default:
        return EnglishLocalization.passwordUpdated;
    }
  }

  String get failedToUpdatePassword {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.failedToUpdatePassword;
      case 'Marathi':
        return MarathiLocalization.failedToUpdatePassword;
      default:
        return EnglishLocalization.failedToUpdatePassword;
    }
  }

  String get noUserLoggedIn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noUserLoggedIn;
      case 'Marathi':
        return MarathiLocalization.noUserLoggedIn;
      default:
        return EnglishLocalization.noUserLoggedIn;
    }
  }

  String get pleaseRelogin {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseRelogin;
      case 'Marathi':
        return MarathiLocalization.pleaseRelogin;
      default:
        return EnglishLocalization.pleaseRelogin;
    }
  }

  String get passwordMinLength {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.passwordMinLength;
      case 'Marathi':
        return MarathiLocalization.passwordMinLength;
      default:
        return EnglishLocalization.passwordMinLength;
    }
  }

  String get passwordTips {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.passwordTips;
      case 'Marathi':
        return MarathiLocalization.passwordTips;
      default:
        return EnglishLocalization.passwordTips;
    }
  }

  String get useAtLeast6Chars {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.useAtLeast6Chars;
      case 'Marathi':
        return MarathiLocalization.useAtLeast6Chars;
      default:
        return EnglishLocalization.useAtLeast6Chars;
    }
  }

  String get includeUpperLower {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.includeUpperLower;
      case 'Marathi':
        return MarathiLocalization.includeUpperLower;
      default:
        return EnglishLocalization.includeUpperLower;
    }
  }

  String get addNumbersSpecial {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addNumbersSpecial;
      case 'Marathi':
        return MarathiLocalization.addNumbersSpecial;
      default:
        return EnglishLocalization.addNumbersSpecial;
    }
  }

  String get avoidPersonalInfo {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.avoidPersonalInfo;
      case 'Marathi':
        return MarathiLocalization.avoidPersonalInfo;
      default:
        return EnglishLocalization.avoidPersonalInfo;
    }
  }

  // ═══════════════════════════════════════════════════
  // Logs Viewer Page
  // ═══════════════════════════════════════════════════

  String get appLogs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.appLogs;
      case 'Marathi':
        return MarathiLocalization.appLogs;
      default:
        return EnglishLocalization.appLogs;
    }
  }

  String get searchLogs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.searchLogs;
      case 'Marathi':
        return MarathiLocalization.searchLogs;
      default:
        return EnglishLocalization.searchLogs;
    }
  }

  String get clearLogs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.clearLogs;
      case 'Marathi':
        return MarathiLocalization.clearLogs;
      default:
        return EnglishLocalization.clearLogs;
    }
  }

  String get clearLogsConfirm {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.clearLogsConfirm;
      case 'Marathi':
        return MarathiLocalization.clearLogsConfirm;
      default:
        return EnglishLocalization.clearLogsConfirm;
    }
  }

  String get clearLogsMessage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.clearLogsMessage;
      case 'Marathi':
        return MarathiLocalization.clearLogsMessage;
      default:
        return EnglishLocalization.clearLogsMessage;
    }
  }

  String get shareLogs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.shareLogs;
      case 'Marathi':
        return MarathiLocalization.shareLogs;
      default:
        return EnglishLocalization.shareLogs;
    }
  }

  String get copyLogs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.copyLogs;
      case 'Marathi':
        return MarathiLocalization.copyLogs;
      default:
        return EnglishLocalization.copyLogs;
    }
  }

  String get logsCopied {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.logsCopied;
      case 'Marathi':
        return MarathiLocalization.logsCopied;
      default:
        return EnglishLocalization.logsCopied;
    }
  }

  String get enableAutoScroll {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enableAutoScroll;
      case 'Marathi':
        return MarathiLocalization.enableAutoScroll;
      default:
        return EnglishLocalization.enableAutoScroll;
    }
  }

  String get disableAutoScroll {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.disableAutoScroll;
      case 'Marathi':
        return MarathiLocalization.disableAutoScroll;
      default:
        return EnglishLocalization.disableAutoScroll;
    }
  }

  String get noLogsToDisplay {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noLogsToDisplay;
      case 'Marathi':
        return MarathiLocalization.noLogsToDisplay;
      default:
        return EnglishLocalization.noLogsToDisplay;
    }
  }

  String get errorSharingLogs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.errorSharingLogs;
      case 'Marathi':
        return MarathiLocalization.errorSharingLogs;
      default:
        return EnglishLocalization.errorSharingLogs;
    }
  }

  String get appLogsExported {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.appLogsExported;
      case 'Marathi':
        return MarathiLocalization.appLogsExported;
      default:
        return EnglishLocalization.appLogsExported;
    }
  }

  String get debug {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.debug;
      case 'Marathi':
        return MarathiLocalization.debug;
      default:
        return EnglishLocalization.debug;
    }
  }

  String get info {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.info;
      case 'Marathi':
        return MarathiLocalization.info;
      default:
        return EnglishLocalization.info;
    }
  }

  String get warn {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.warn;
      case 'Marathi':
        return MarathiLocalization.warn;
      default:
        return EnglishLocalization.warn;
    }
  }

  String get level {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.level;
      case 'Marathi':
        return MarathiLocalization.level;
      default:
        return EnglishLocalization.level;
    }
  }

  String get stackTrace {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.stackTrace;
      case 'Marathi':
        return MarathiLocalization.stackTrace;
      default:
        return EnglishLocalization.stackTrace;
    }
  }

  // Action Menu
  String get options {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.options;
      case 'Marathi':
        return MarathiLocalization.options;
      default:
        return EnglishLocalization.options;
    }
  }

  String get reportIssue {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.reportIssue;
      case 'Marathi':
        return MarathiLocalization.reportIssue;
      default:
        return EnglishLocalization.reportIssue;
    }
  }

  // ═══════════════════════════════════════════════════
  // Purchase History Screen
  // ═══════════════════════════════════════════════════
  String get purchaseHistory {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.purchaseHistory;
      case 'Marathi':
        return MarathiLocalization.purchaseHistory;
      default:
        return EnglishLocalization.purchaseHistory;
    }
  }

  String get noPurchasesFound {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noPurchasesFound;
      case 'Marathi':
        return MarathiLocalization.noPurchasesFound;
      default:
        return EnglishLocalization.noPurchasesFound;
    }
  }

  String get addNewPurchase {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.addNewPurchase;
      case 'Marathi':
        return MarathiLocalization.addNewPurchase;
      default:
        return EnglishLocalization.addNewPurchase;
    }
  }

  // ═══════════════════════════════════════════════════
  // GST / Tax Settings
  // ═══════════════════════════════════════════════════
  String get taxSettings {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.taxSettings;
      case 'Marathi':
        return MarathiLocalization.taxSettings;
      default:
        return EnglishLocalization.taxSettings;
    }
  }

  String get taxConfiguration {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.taxConfiguration;
      case 'Marathi':
        return MarathiLocalization.taxConfiguration;
      default:
        return EnglishLocalization.taxConfiguration;
    }
  }

  String get enableCgst {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enableCgst;
      case 'Marathi':
        return MarathiLocalization.enableCgst;
      default:
        return EnglishLocalization.enableCgst;
    }
  }

  String get enableSgst {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enableSgst;
      case 'Marathi':
        return MarathiLocalization.enableSgst;
      default:
        return EnglishLocalization.enableSgst;
    }
  }

  String get enableOtherTax {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enableOtherTax;
      case 'Marathi':
        return MarathiLocalization.enableOtherTax;
      default:
        return EnglishLocalization.enableOtherTax;
    }
  }

  String get cgstPercent {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.cgstPercent;
      case 'Marathi':
        return MarathiLocalization.cgstPercent;
      default:
        return EnglishLocalization.cgstPercent;
    }
  }

  String get sgstPercent {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.sgstPercent;
      case 'Marathi':
        return MarathiLocalization.sgstPercent;
      default:
        return EnglishLocalization.sgstPercent;
    }
  }

  String get otherTaxName {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.otherTaxName;
      case 'Marathi':
        return MarathiLocalization.otherTaxName;
      default:
        return EnglishLocalization.otherTaxName;
    }
  }

  String get otherTaxPercent {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.otherTaxPercent;
      case 'Marathi':
        return MarathiLocalization.otherTaxPercent;
      default:
        return EnglishLocalization.otherTaxPercent;
    }
  }

  String get defaultGstMode {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.defaultGstMode;
      case 'Marathi':
        return MarathiLocalization.defaultGstMode;
      default:
        return EnglishLocalization.defaultGstMode;
    }
  }

  String get includeGstInTotal {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.includeGstInTotal;
      case 'Marathi':
        return MarathiLocalization.includeGstInTotal;
      default:
        return EnglishLocalization.includeGstInTotal;
    }
  }

  String get excludeGstFromTotal {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.excludeGstFromTotal;
      case 'Marathi':
        return MarathiLocalization.excludeGstFromTotal;
      default:
        return EnglishLocalization.excludeGstFromTotal;
    }
  }

  String get includeGstSubtitle {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.includeGstSubtitle;
      case 'Marathi':
        return MarathiLocalization.includeGstSubtitle;
      default:
        return EnglishLocalization.includeGstSubtitle;
    }
  }

  String get excludeGstSubtitle {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.excludeGstSubtitle;
      case 'Marathi':
        return MarathiLocalization.excludeGstSubtitle;
      default:
        return EnglishLocalization.excludeGstSubtitle;
    }
  }

  String get billWithoutGst {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billWithoutGst;
      case 'Marathi':
        return MarathiLocalization.billWithoutGst;
      default:
        return EnglishLocalization.billWithoutGst;
    }
  }

  String get billWithGst {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.billWithGst;
      case 'Marathi':
        return MarathiLocalization.billWithGst;
      default:
        return EnglishLocalization.billWithGst;
    }
  }

  String get gstCalculationMode {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.gstCalculationMode;
      case 'Marathi':
        return MarathiLocalization.gstCalculationMode;
      default:
        return EnglishLocalization.gstCalculationMode;
    }
  }

  String get taxMode {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.taxMode;
      case 'Marathi':
        return MarathiLocalization.taxMode;
      default:
        return EnglishLocalization.taxMode;
    }
  }

  String get cgst {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.cgst;
      case 'Marathi':
        return MarathiLocalization.cgst;
      default:
        return EnglishLocalization.cgst;
    }
  }

  String get sgst {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.sgst;
      case 'Marathi':
        return MarathiLocalization.sgst;
      default:
        return EnglishLocalization.sgst;
    }
  }

  String get totalTax {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.totalTax;
      case 'Marathi':
        return MarathiLocalization.totalTax;
      default:
        return EnglishLocalization.totalTax;
    }
  }

  String get taxableValue {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.taxableValue;
      case 'Marathi':
        return MarathiLocalization.taxableValue;
      default:
        return EnglishLocalization.taxableValue;
    }
  }

  String get pricesInclusiveOfGst {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pricesInclusiveOfGst;
      case 'Marathi':
        return MarathiLocalization.pricesInclusiveOfGst;
      default:
        return EnglishLocalization.pricesInclusiveOfGst;
    }
  }

  String get gstExtra {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.gstExtra;
      case 'Marathi':
        return MarathiLocalization.gstExtra;
      default:
        return EnglishLocalization.gstExtra;
    }
  }

  String get enterValidPercentage {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterValidPercentage;
      case 'Marathi':
        return MarathiLocalization.enterValidPercentage;
      default:
        return EnglishLocalization.enterValidPercentage;
    }
  }

  String get taxPercentageInputs {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.taxPercentageInputs;
      case 'Marathi':
        return MarathiLocalization.taxPercentageInputs;
      default:
        return EnglishLocalization.taxPercentageInputs;
    }
  }

  String get taxToggles {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.taxToggles;
      case 'Marathi':
        return MarathiLocalization.taxToggles;
      default:
        return EnglishLocalization.taxToggles;
    }
  }

  // ═══════════════════════════════════════════════════
  // Billing Module Extended
  // ═══════════════════════════════════════════════════
  String get linkCustomerToBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.linkCustomerToBill;
      case 'Marathi':
        return MarathiLocalization.linkCustomerToBill;
      default:
        return EnglishLocalization.linkCustomerToBill;
    }
  }

  String get autoLinkByPhone {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.autoLinkByPhone;
      case 'Marathi':
        return MarathiLocalization.autoLinkByPhone;
      default:
        return EnglishLocalization.autoLinkByPhone;
    }
  }

  String get quickAddByCodeOrSearch {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.quickAddByCodeOrSearch;
      case 'Marathi':
        return MarathiLocalization.quickAddByCodeOrSearch;
      default:
        return EnglishLocalization.quickAddByCodeOrSearch;
    }
  }

  String get enterValidAmount {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.enterValidAmount;
      case 'Marathi':
        return MarathiLocalization.enterValidAmount;
      default:
        return EnglishLocalization.enterValidAmount;
    }
  }

  String get pleaseEnterValidPrice {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pleaseEnterValidPrice;
      case 'Marathi':
        return MarathiLocalization.pleaseEnterValidPrice;
      default:
        return EnglishLocalization.pleaseEnterValidPrice;
    }
  }

  String get reset {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.reset;
      case 'Marathi':
        return MarathiLocalization.reset;
      default:
        return EnglishLocalization.reset;
    }
  }

  String get applyDiscountToBill {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.applyDiscountToBill;
      case 'Marathi':
        return MarathiLocalization.applyDiscountToBill;
      default:
        return EnglishLocalization.applyDiscountToBill;
    }
  }

  String get selectTaxMethod {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectTaxMethod;
      case 'Marathi':
        return MarathiLocalization.selectTaxMethod;
      default:
        return EnglishLocalization.selectTaxMethod;
    }
  }

  String get noGst {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.noGst;
      case 'Marathi':
        return MarathiLocalization.noGst;
      default:
        return EnglishLocalization.noGst;
    }
  }

  String get incl {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.incl;
      case 'Marathi':
        return MarathiLocalization.incl;
      default:
        return EnglishLocalization.incl;
    }
  }

  String get excl {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.excl;
      case 'Marathi':
        return MarathiLocalization.excl;
      default:
        return EnglishLocalization.excl;
    }
  }

  String get selectPaymentMethod {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.selectPaymentMethod;
      case 'Marathi':
        return MarathiLocalization.selectPaymentMethod;
      default:
        return EnglishLocalization.selectPaymentMethod;
    }
  }

  String get quickActions {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.quickActions;
      case 'Marathi':
        return MarathiLocalization.quickActions;
      default:
        return EnglishLocalization.quickActions;
    }
  }

  String get events {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.events;
      case 'Marathi':
        return MarathiLocalization.events;
      default:
        return EnglishLocalization.events;
    }
  }

  String get barcode {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.barcode;
      case 'Marathi':
        return MarathiLocalization.barcode;
      default:
        return EnglishLocalization.barcode;
    }
  }

  String get createAndPrintInvoices {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.createAndPrintInvoices;
      case 'Marathi':
        return MarathiLocalization.createAndPrintInvoices;
      default:
        return EnglishLocalization.createAndPrintInvoices;
    }
  }

  String get printColumnSettings {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.printColumnSettings;
      case 'Marathi':
        return MarathiLocalization.printColumnSettings;
      default:
        return EnglishLocalization.printColumnSettings;
    }
  }

  String get pdfCreationFailed {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pdfCreationFailed;
      case 'Marathi':
        return MarathiLocalization.pdfCreationFailed;
      default:
        return EnglishLocalization.pdfCreationFailed;
    }
  }

  String get pdfFileEmpty {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.pdfFileEmpty;
      case 'Marathi':
        return MarathiLocalization.pdfFileEmpty;
      default:
        return EnglishLocalization.pdfFileEmpty;
    }
  }

  String get failedToGeneratePdf {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.failedToGeneratePdf;
      case 'Marathi':
        return MarathiLocalization.failedToGeneratePdf;
      default:
        return EnglishLocalization.failedToGeneratePdf;
    }
  }

  String get full {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.full;
      case 'Marathi':
        return MarathiLocalization.full;
      default:
        return EnglishLocalization.full;
    }
  }

  String get partial {
    switch (languageCode) {
      case 'Hindi':
        return HindiLocalization.partial;
      case 'Marathi':
        return MarathiLocalization.partial;
      default:
        return EnglishLocalization.partial;
    }
  }
}
