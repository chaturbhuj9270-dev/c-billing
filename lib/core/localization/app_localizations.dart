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
}
