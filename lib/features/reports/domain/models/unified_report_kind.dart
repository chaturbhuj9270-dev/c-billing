import 'package:flutter/material.dart';
import 'package:c_billing/core/access/app_module.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// Report types available from the common Reports hub.
enum UnifiedReportKind {
  salesBills,
  salesReturns,
  purchases,
  purchaseReturns,
  events,
  quotations,
  expenses,
  products,
  customers,
  suppliers,
  stock,
  gstr1,
}

extension UnifiedReportKindX on UnifiedReportKind {
  String get title {
    switch (this) {
      case UnifiedReportKind.salesBills:
        return 'Sales / Bills';
      case UnifiedReportKind.salesReturns:
        return 'Sales returns';
      case UnifiedReportKind.purchases:
        return 'Purchases';
      case UnifiedReportKind.purchaseReturns:
        return 'Purchase returns';
      case UnifiedReportKind.events:
        return 'Orders / Events';
      case UnifiedReportKind.quotations:
        return 'Quotations';
      case UnifiedReportKind.expenses:
        return 'Expenses';
      case UnifiedReportKind.products:
        return 'Products';
      case UnifiedReportKind.customers:
        return 'Customers';
      case UnifiedReportKind.suppliers:
        return 'Suppliers';
      case UnifiedReportKind.stock:
        return 'Stock / Availability';
      case UnifiedReportKind.gstr1:
        return 'GST Summary (CA)';
    }
  }

  String get subtitle {
    switch (this) {
      case UnifiedReportKind.salesBills:
        return 'Sales with CGST / SGST / IGST for CA';
      case UnifiedReportKind.salesReturns:
        return 'Returned quantities from sales bills';
      case UnifiedReportKind.purchases:
        return 'Purchase entries for the selected period';
      case UnifiedReportKind.purchaseReturns:
        return 'Stock returned to suppliers';
      case UnifiedReportKind.events:
        return 'Event / order bookings';
      case UnifiedReportKind.quotations:
        return 'Quotations issued to customers';
      case UnifiedReportKind.expenses:
        return 'Shop expenses for the selected period';
      case UnifiedReportKind.products:
        return 'Full product catalogue with stock';
      case UnifiedReportKind.customers:
        return 'Customer directory';
      case UnifiedReportKind.suppliers:
        return 'Supplier directory';
      case UnifiedReportKind.stock:
        return 'Current stock levels';
      case UnifiedReportKind.gstr1:
        return 'B2B / B2C / HSN GST summary for CA reference';
    }
  }

  IconData get icon {
    switch (this) {
      case UnifiedReportKind.salesBills:
        return Icons.receipt_long_rounded;
      case UnifiedReportKind.salesReturns:
        return Icons.undo_rounded;
      case UnifiedReportKind.purchases:
        return Icons.shopping_cart_rounded;
      case UnifiedReportKind.purchaseReturns:
        return Icons.keyboard_return_rounded;
      case UnifiedReportKind.events:
        return Icons.auto_awesome_rounded;
      case UnifiedReportKind.quotations:
        return Icons.description_outlined;
      case UnifiedReportKind.expenses:
        return Icons.account_balance_wallet_outlined;
      case UnifiedReportKind.products:
        return Icons.inventory_2_rounded;
      case UnifiedReportKind.customers:
        return Icons.people_rounded;
      case UnifiedReportKind.suppliers:
        return Icons.local_shipping_rounded;
      case UnifiedReportKind.stock:
        return Icons.event_available_rounded;
      case UnifiedReportKind.gstr1:
        return Icons.account_balance_rounded;
    }
  }

  Color get color {
    switch (this) {
      case UnifiedReportKind.salesBills:
        return AppTheme.primary;
      case UnifiedReportKind.salesReturns:
        return AppTheme.toneRose;
      case UnifiedReportKind.purchases:
        return AppTheme.toneBlue;
      case UnifiedReportKind.purchaseReturns:
        return AppTheme.toneAmber;
      case UnifiedReportKind.events:
        return AppTheme.toneViolet;
      case UnifiedReportKind.quotations:
        return AppTheme.toneCyan;
      case UnifiedReportKind.expenses:
        return AppTheme.toneRose;
      case UnifiedReportKind.products:
        return AppTheme.green700;
      case UnifiedReportKind.customers:
        return AppTheme.toneBlue;
      case UnifiedReportKind.suppliers:
        return AppTheme.toneAmber;
      case UnifiedReportKind.stock:
        return AppTheme.primaryLight;
      case UnifiedReportKind.gstr1:
        return AppTheme.toneAmber;
    }
  }

  /// Whether date range applies (directories are snapshots).
  bool get usesDateRange {
    switch (this) {
      case UnifiedReportKind.products:
      case UnifiedReportKind.customers:
      case UnifiedReportKind.suppliers:
      case UnifiedReportKind.stock:
        return false;
      default:
        return true;
    }
  }

  /// Module used for access gating (owner always allowed).
  AppModule get requiredModule {
    switch (this) {
      case UnifiedReportKind.salesBills:
      case UnifiedReportKind.salesReturns:
      case UnifiedReportKind.gstr1:
        return AppModule.invoices;
      case UnifiedReportKind.purchases:
        return AppModule.purchase;
      case UnifiedReportKind.purchaseReturns:
        return AppModule.purchaseReturn;
      case UnifiedReportKind.events:
        return AppModule.events;
      case UnifiedReportKind.quotations:
        return AppModule.quotations;
      case UnifiedReportKind.expenses:
        return AppModule.expenses;
      case UnifiedReportKind.products:
      case UnifiedReportKind.stock:
        return AppModule.products;
      case UnifiedReportKind.customers:
        return AppModule.customers;
      case UnifiedReportKind.suppliers:
        return AppModule.suppliers;
    }
  }
}

enum UnifiedExportFormat { pdf, excel }

extension UnifiedExportFormatX on UnifiedExportFormat {
  String get label {
    switch (this) {
      case UnifiedExportFormat.pdf:
        return 'PDF';
      case UnifiedExportFormat.excel:
        return 'Excel';
    }
  }

  String get fileExtension {
    switch (this) {
      case UnifiedExportFormat.pdf:
        return 'pdf';
      case UnifiedExportFormat.excel:
        return 'csv'; // Excel-compatible CSV (UTF-8 BOM)
    }
  }

  IconData get icon {
    switch (this) {
      case UnifiedExportFormat.pdf:
        return Icons.picture_as_pdf_rounded;
      case UnifiedExportFormat.excel:
        return Icons.table_chart_rounded;
    }
  }
}

class UnifiedReportTable {
  final String title;
  final String filterDescription;
  final List<String> headers;
  final List<List<String>> rows;
  final String? summaryLine;

  const UnifiedReportTable({
    required this.title,
    required this.filterDescription,
    required this.headers,
    required this.rows,
    this.summaryLine,
  });

  bool get isEmpty => rows.isEmpty;
}
