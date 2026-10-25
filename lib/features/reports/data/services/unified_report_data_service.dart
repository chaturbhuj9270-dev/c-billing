import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../billing/domain/entities/bill.dart';
import '../../../billing/offline/controllers/bill_offline_controller.dart';
import '../../../customer/offline/controllers/customer_offline_controller.dart';
import '../../../event_order/offline/controllers/event_order_offline_controller.dart';
import '../../../expense/offline/controllers/expense_offline_controller.dart';
import '../../../inventory_management/offline/controllers/purchase_offline_controller.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../purchase_return/data/services/purchase_return_service.dart';
import '../../../quotation/offline/controllers/quotation_offline_controller.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../domain/models/unified_report_kind.dart';

/// Loads tabular report data from existing offline stores (and purchase-return service).
/// Does not change any module’s own report generators.
class UnifiedReportDataService {
  UnifiedReportDataService._();
  static final UnifiedReportDataService instance = UnifiedReportDataService._();

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _money = NumberFormat('#,##0.00');

  Future<UnifiedReportTable> build({
    required UnifiedReportKind kind,
    required DateTime start,
    required DateTime end,
  }) async {
    final rangeLabel =
        '${_dateFmt.format(start)} - ${_dateFmt.format(end)}';
    switch (kind) {
      case UnifiedReportKind.salesBills:
        return _salesBills(start, end, rangeLabel);
      case UnifiedReportKind.salesReturns:
        return _salesReturns(start, end, rangeLabel);
      case UnifiedReportKind.purchases:
        return _purchases(start, end, rangeLabel);
      case UnifiedReportKind.purchaseReturns:
        return _purchaseReturns(start, end, rangeLabel);
      case UnifiedReportKind.events:
        return _events(start, end, rangeLabel);
      case UnifiedReportKind.quotations:
        return _quotations(start, end, rangeLabel);
      case UnifiedReportKind.expenses:
        return _expenses(start, end, rangeLabel);
      case UnifiedReportKind.products:
        return _products();
      case UnifiedReportKind.customers:
        return _customers();
      case UnifiedReportKind.suppliers:
        return _suppliers();
      case UnifiedReportKind.stock:
        return _stock();
      case UnifiedReportKind.gstr1:
        return _gstr1(start, end, rangeLabel);
    }
  }

  bool _inRange(DateTime d, DateTime start, DateTime end) {
    final day = DateTime(d.year, d.month, d.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !day.isBefore(s) && !day.isAfter(e);
  }

  String _rs(double v) => _money.format(v);

  Future<UnifiedReportTable> _salesBills(
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final entities = await BillOfflineController.instance.getBillsByDateRange(
      start,
      end,
    );
    final bills = entities.map(Bill.fromBillEntity).toList();
    final headers = [
      'Sr',
      'Bill No',
      'Date',
      'Customer',
      'GSTIN',
      'Supply',
      'Items',
      'Qty',
      'Taxable',
      'CGST',
      'SGST',
      'IGST',
      'Total Tax',
      'Discount',
      'Invoice Value',
      'Payment',
    ];
    final rows = <List<String>>[];
    var i = 0;
    double sumFinal = 0;
    double sumTax = 0;
    double sumCgst = 0;
    double sumSgst = 0;
    double sumIgst = 0;
    double sumTaxable = 0;
    for (final b in bills) {
      i++;
      final taxable = b.isGstApplied
          ? (b.isTaxInclusive
                ? (b.totalAmount - b.totalTaxAmount - b.discountAmount)
                    .clamp(0, double.infinity)
                : (b.totalAmount - b.discountAmount).clamp(0, double.infinity))
          : (b.totalAmount - b.discountAmount).clamp(0, double.infinity);
      sumFinal += b.finalAmount;
      sumTax += b.totalTaxAmount;
      sumCgst += b.cgstAmount;
      sumSgst += b.sgstAmount;
      sumIgst += b.igstAmount;
      sumTaxable += taxable;
      rows.add([
        '$i',
        b.billNumber,
        _dateFmt.format(b.billDate),
        (b.customerName?.trim().isNotEmpty ?? false)
            ? b.customerName!.trim()
            : 'Walk-in',
        (b.customerGstin?.trim().isNotEmpty ?? false) ? b.customerGstin! : '-',
        !b.isGstApplied
            ? 'No GST'
            : (b.isInterstate ? 'Inter (IGST)' : 'Intra (CGST+SGST)'),
        '${b.items.length}',
        '${b.totalQuantity}',
        _rs(taxable.toDouble()),
        _rs(b.cgstAmount),
        _rs(b.sgstAmount),
        _rs(b.igstAmount),
        _rs(b.totalTaxAmount),
        _rs(b.discountAmount),
        _rs(b.finalAmount),
        b.paymentStatus.name,
      ]);
    }
    return UnifiedReportTable(
      title: 'Sales / Bills Report (with GST)',
      filterDescription: rangeLabel,
      headers: headers,
      rows: rows,
      summaryLine:
          'Bills: ${rows.length} | Taxable: Rs ${_rs(sumTaxable)} | '
          'CGST: Rs ${_rs(sumCgst)} | SGST: Rs ${_rs(sumSgst)} | '
          'IGST: Rs ${_rs(sumIgst)} | Tax: Rs ${_rs(sumTax)} | '
          'Total: Rs ${_rs(sumFinal)}',
    );
  }

  Future<UnifiedReportTable> _salesReturns(
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final entities = await BillOfflineController.instance.getBillsByDateRange(
      start,
      end,
    );
    final bills = entities.map(Bill.fromBillEntity).toList();
    final headers = [
      'Sr',
      'Bill No',
      'Date',
      'Customer',
      'Product',
      'Sold Qty',
      'Returned Qty',
      'Rate',
      'Return Value',
    ];
    final rows = <List<String>>[];
    var i = 0;
    double sum = 0;
    for (final b in bills) {
      for (final item in b.items) {
        if (item.returnedQuantity <= 0) continue;
        i++;
        final value = item.sellingPrice * item.returnedQuantity;
        sum += value;
        rows.add([
          '$i',
          b.billNumber,
          _dateFmt.format(b.billDate),
          (b.customerName?.trim().isNotEmpty ?? false)
              ? b.customerName!.trim()
              : 'Walk-in',
          item.productName,
          '${item.quantity}',
          '${item.returnedQuantity}',
          _rs(item.sellingPrice),
          _rs(value),
        ]);
      }
    }
    return UnifiedReportTable(
      title: 'Sales Returns Report',
      filterDescription: rangeLabel,
      headers: headers,
      rows: rows,
      summaryLine: 'Return lines: ${rows.length} | Value: Rs ${_rs(sum)}',
    );
  }

  Future<UnifiedReportTable> _purchases(
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final all = await PurchaseOfflineController.instance.getAllPurchases();
    final list = all.where((p) => _inRange(p.createdAt, start, end)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final headers = [
      'Sr',
      'Date',
      'Product',
      'Supplier',
      'Company',
      'Qty',
      'Purchase Rs',
      'Sale Rs',
      'Total',
    ];
    final rows = <List<String>>[];
    var i = 0;
    double sum = 0;
    for (final p in list) {
      i++;
      sum += p.totalAmount;
      rows.add([
        '$i',
        _dateFmt.format(p.createdAt),
        p.productName,
        p.supplierName ?? '-',
        p.companyName ?? '-',
        '${p.quantity}',
        _rs(p.purchasePrice),
        _rs(p.salesPrice),
        _rs(p.totalAmount),
      ]);
    }
    return UnifiedReportTable(
      title: 'Purchases Report',
      filterDescription: rangeLabel,
      headers: headers,
      rows: rows,
      summaryLine: 'Entries: ${rows.length} | Total: Rs ${_rs(sum)}',
    );
  }

  Future<UnifiedReportTable> _purchaseReturns(
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final headers = [
      'Sr',
      'Date',
      'Supplier',
      'Items',
      'Qty',
      'Amount',
      'Reason',
      'Status',
    ];
    final rows = <List<String>>[];
    var i = 0;
    double sum = 0;
    try {
      final returns = await PurchaseReturnService.instance
          .getReturnHistory()
          .timeout(const Duration(seconds: 12));
      final list = returns
          .where((r) => _inRange(r.returnDate, start, end))
          .toList()
        ..sort((a, b) => b.returnDate.compareTo(a.returnDate));
      for (final r in list) {
        i++;
        sum += r.totalAmount;
        rows.add([
          '$i',
          _dateFmt.format(r.returnDate),
          r.supplierName,
          '${r.totalItems}',
          '${r.totalQuantity}',
          _rs(r.totalAmount),
          r.reason.isEmpty ? '-' : r.reason,
          r.status,
        ]);
      }
    } catch (e) {
      debugPrint('[UnifiedReport] purchase returns load failed: $e');
    }
    return UnifiedReportTable(
      title: 'Purchase Returns Report',
      filterDescription: rangeLabel,
      headers: headers,
      rows: rows,
      summaryLine: 'Returns: ${rows.length} | Total: Rs ${_rs(sum)}',
    );
  }

  Future<UnifiedReportTable> _events(
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final all = await EventOrderOfflineController.instance.getAllEventOrders();
    final list = all.where((o) => _inRange(o.eventDate, start, end)).toList()
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
    final statusNames = const [
      'Pending',
      'Confirmed',
      'In progress',
      'Delivered',
      'Cancelled',
      'Converted',
    ];
    final headers = [
      'Sr',
      'Order',
      'Date',
      'Customer',
      'Title',
      'Items',
      'Amount',
      'Status',
    ];
    final rows = <List<String>>[];
    var i = 0;
    double sum = 0;
    for (final o in list) {
      i++;
      sum += o.totalAmount;
      final st = o.status >= 0 && o.status < statusNames.length
          ? statusNames[o.status]
          : '${o.status}';
      rows.add([
        '$i',
        o.serverId ?? 'local_${o.id}',
        _dateFmt.format(o.eventDate),
        o.customerName,
        o.orderName,
        '${o.items.length}',
        _rs(o.totalAmount),
        st,
      ]);
    }
    return UnifiedReportTable(
      title: 'Orders / Events Report',
      filterDescription: rangeLabel,
      headers: headers,
      rows: rows,
      summaryLine: 'Orders: ${rows.length} | Total: Rs ${_rs(sum)}',
    );
  }

  Future<UnifiedReportTable> _quotations(
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final all = await QuotationOfflineController.instance.getAllQuotations();
    final list = all
        .where((q) => _inRange(q.referenceDate, start, end))
        .toList()
      ..sort((a, b) => b.referenceDate.compareTo(a.referenceDate));
    final headers = [
      'Sr',
      'Quotation No',
      'Date',
      'Customer',
      'Title',
      'Amount',
      'Valid Until',
      'Status',
    ];
    final statusNames = const [
      'Draft',
      'Sent',
      'Accepted',
      'Rejected',
      'Expired',
      'Converted',
    ];
    final rows = <List<String>>[];
    var i = 0;
    double sum = 0;
    for (final q in list) {
      i++;
      sum += q.totalAmount;
      final st = q.status >= 0 && q.status < statusNames.length
          ? statusNames[q.status]
          : '${q.status}';
      rows.add([
        '$i',
        q.quotationNumber,
        _dateFmt.format(q.referenceDate),
        q.customerName,
        q.title,
        _rs(q.totalAmount),
        _dateFmt.format(q.validUntil),
        st,
      ]);
    }
    return UnifiedReportTable(
      title: 'Quotations Report',
      filterDescription: rangeLabel,
      headers: headers,
      rows: rows,
      summaryLine: 'Quotations: ${rows.length} | Total: Rs ${_rs(sum)}',
    );
  }

  Future<UnifiedReportTable> _expenses(
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final all = await ExpenseOfflineController.instance.getAllExpenses();
    final list = all.where((e) => _inRange(e.expenseDate, start, end)).toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    final headers = [
      'Sr',
      'Date',
      'Title',
      'Category',
      'Vendor',
      'Payment',
      'Amount',
    ];
    final rows = <List<String>>[];
    var i = 0;
    double sum = 0;
    for (final e in list) {
      i++;
      sum += e.amount;
      rows.add([
        '$i',
        _dateFmt.format(e.expenseDate),
        e.title,
        e.category.name,
        e.vendorName ?? '-',
        e.paymentMethod ?? '-',
        _rs(e.amount),
      ]);
    }
    return UnifiedReportTable(
      title: 'Expenses Report',
      filterDescription: rangeLabel,
      headers: headers,
      rows: rows,
      summaryLine: 'Expenses: ${rows.length} | Total: Rs ${_rs(sum)}',
    );
  }

  Future<UnifiedReportTable> _products() async {
    final list = await ProductOfflineController.instance.getAllProducts();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final headers = [
      'Sr',
      'Index',
      'Name',
      'Company',
      'Category',
      'HSN',
      'CGST %',
      'SGST %',
      'Stock',
      'Unit',
      'Purchase Rs',
      'Sale Rs',
    ];
    final rows = <List<String>>[];
    var i = 0;
    for (final p in list) {
      i++;
      rows.add([
        '$i',
        '${p.indexNo}',
        p.name,
        p.companyName,
        p.category,
        (p.hsnCode?.trim().isNotEmpty ?? false) ? p.hsnCode! : '-',
        p.cgstPercent > 0 ? p.cgstPercent.toStringAsFixed(1) : '-',
        p.sgstPercent > 0 ? p.sgstPercent.toStringAsFixed(1) : '-',
        '${p.currentStock}',
        p.unit ?? '-',
        _rs(p.purchasePrice),
        _rs(p.salesPrice),
      ]);
    }
    return UnifiedReportTable(
      title: 'Products Report',
      filterDescription: 'All products (with HSN / GST rates)',
      headers: headers,
      rows: rows,
      summaryLine: 'Products: ${rows.length}',
    );
  }

  Future<UnifiedReportTable> _customers() async {
    final list = await CustomerOfflineController.instance.getAllCustomers();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final headers = ['Sr', 'Name', 'Phone', 'GSTIN', 'Address', 'Pending'];
    final rows = <List<String>>[];
    var i = 0;
    for (final c in list) {
      i++;
      rows.add([
        '$i',
        c.name,
        c.mobile,
        (c.gstin?.trim().isNotEmpty ?? false) ? c.gstin!.trim() : '-',
        (c.address?.trim().isNotEmpty ?? false) ? c.address!.trim() : '-',
        _rs(c.currentPendingAmount),
      ]);
    }
    return UnifiedReportTable(
      title: 'Customers Report',
      filterDescription: 'All customers',
      headers: headers,
      rows: rows,
      summaryLine: 'Customers: ${rows.length}',
    );
  }

  Future<UnifiedReportTable> _suppliers() async {
    final list = await SupplierOfflineController.instance.getAllSuppliers();
    list.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    final headers = ['Sr', 'Name', 'Code', 'Phone', 'Address'];
    final rows = <List<String>>[];
    var i = 0;
    for (final s in list) {
      i++;
      rows.add([
        '$i',
        s.fullName,
        s.supplierCode.isEmpty ? '-' : s.supplierCode,
        s.contact,
        s.address.trim().isEmpty ? '-' : s.address.trim(),
      ]);
    }
    return UnifiedReportTable(
      title: 'Suppliers Report',
      filterDescription: 'All suppliers',
      headers: headers,
      rows: rows,
      summaryLine: 'Suppliers: ${rows.length}',
    );
  }

  Future<UnifiedReportTable> _stock() async {
    final list = await ProductOfflineController.instance.getAllProducts();
    list.sort((a, b) => a.currentStock.compareTo(b.currentStock));
    final headers = [
      'Sr',
      'Product',
      'Company',
      'Stock',
      'Unit',
      'Status',
      'Sale Rs',
    ];
    final rows = <List<String>>[];
    var i = 0;
    var low = 0;
    var out = 0;
    for (final p in list) {
      i++;
      final status = p.currentStock <= 0
          ? 'Out of stock'
          : (p.currentStock <= 5 ? 'Low' : 'OK');
      if (p.currentStock <= 0) {
        out++;
      } else if (p.currentStock <= 5) {
        low++;
      }
      rows.add([
        '$i',
        p.name,
        p.companyName,
        '${p.currentStock}',
        p.unit ?? '-',
        status,
        _rs(p.salesPrice),
      ]);
    }
    return UnifiedReportTable(
      title: 'Stock / Availability Report',
      filterDescription: 'Current stock snapshot',
      headers: headers,
      rows: rows,
      summaryLine:
          'Products: ${rows.length} | Low: $low | Out: $out',
    );
  }

  /// GSTR-1 oriented export: B2B invoices, B2C summary, HSN-wise tax.
  Future<UnifiedReportTable> _gstr1(
    DateTime start,
    DateTime end,
    String rangeLabel,
  ) async {
    final entities = await BillOfflineController.instance.getBillsByDateRange(
      start,
      end,
    );
    final bills = entities
        .map(Bill.fromBillEntity)
        .where((b) => !b.returnStatus && b.isGstApplied)
        .toList();

    final headers = [
      'Section',
      'Date',
      'Invoice',
      'Customer',
      'GSTIN',
      'Place of Supply',
      'Supply',
      'HSN',
      'Taxable',
      'CGST',
      'SGST',
      'IGST',
      'Total Tax',
      'Invoice Value',
    ];
    final rows = <List<String>>[];

    // —— B2B ——
    final b2b = bills
        .where(
          (b) =>
              (b.customerGstin != null && b.customerGstin!.trim().isNotEmpty),
        )
        .toList();
    double b2bTaxable = 0;
    double b2bTax = 0;
    for (final b in b2b) {
      final taxable = b.isTaxInclusive
          ? (b.totalAmount - b.totalTaxAmount - b.discountAmount)
              .clamp(0, double.infinity)
          : (b.totalAmount - b.discountAmount).clamp(0, double.infinity);
      b2bTaxable += taxable;
      b2bTax += b.totalTaxAmount;
      rows.add([
        'B2B',
        _dateFmt.format(b.billDate),
        b.billNumber,
        (b.customerName?.trim().isNotEmpty ?? false)
            ? b.customerName!.trim()
            : 'Customer',
        b.customerGstin ?? '',
        b.placeOfSupply ?? '-',
        b.isInterstate ? 'Inter' : 'Intra',
        '-',
        _rs(taxable.toDouble()),
        _rs(b.cgstAmount),
        _rs(b.sgstAmount),
        _rs(b.igstAmount),
        _rs(b.totalTaxAmount),
        _rs(b.finalAmount),
      ]);
    }

    // —— B2C (aggregate) ——
    final b2c = bills
        .where(
          (b) =>
              b.customerGstin == null || b.customerGstin!.trim().isEmpty,
        )
        .toList();
    double b2cTaxable = 0;
    double b2cCgst = 0;
    double b2cSgst = 0;
    double b2cIgst = 0;
    double b2cTax = 0;
    double b2cValue = 0;
    for (final b in b2c) {
      final taxable = b.isTaxInclusive
          ? (b.totalAmount - b.totalTaxAmount - b.discountAmount)
              .clamp(0, double.infinity)
          : (b.totalAmount - b.discountAmount).clamp(0, double.infinity);
      b2cTaxable += taxable;
      b2cCgst += b.cgstAmount;
      b2cSgst += b.sgstAmount;
      b2cIgst += b.igstAmount;
      b2cTax += b.totalTaxAmount;
      b2cValue += b.finalAmount;
    }
    if (b2c.isNotEmpty) {
      rows.add([
        'B2C',
        rangeLabel,
        '${b2c.length} invoices',
        'Unregistered / Walk-in',
        '',
        '-',
        b2cIgst > 0 ? 'Mixed' : 'Intra',
        '-',
        _rs(b2cTaxable),
        _rs(b2cCgst),
        _rs(b2cSgst),
        _rs(b2cIgst),
        _rs(b2cTax),
        _rs(b2cValue),
      ]);
    }

    // —— HSN summary ——
    final hsnMap = <String, _HsnAgg>{};
    for (final b in bills) {
      final discountRatio = (b.discountAmount > 0 && b.totalAmount > 0)
          ? b.discountAmount / b.totalAmount
          : 0.0;
      for (final item in b.items) {
        final hsn =
            (item.hsnCode != null && item.hsnCode!.trim().isNotEmpty)
            ? item.hsnCode!.trim()
            : 'UNMAPPED';
        final net = item.subtotal * (1 - discountRatio);
        double taxable;
        double cgst;
        double sgst;
        double igst;
        if (b.isInterstate || b.igstAmount > 0) {
          final rate = item.cgstPercent + item.sgstPercent;
          // Prefer persisted line IGST if present
          final igstRate = (item.cgstPercent + item.sgstPercent);
          if (b.isTaxInclusive && igstRate > 0) {
            taxable = net / (1 + igstRate / 100);
            igst = taxable * (igstRate / 100);
          } else {
            taxable = net;
            igst = net * (igstRate / 100);
          }
          cgst = 0;
          sgst = 0;
          // If bill had CGST/SGST only, fall back
          if (igst == 0 && rate == 0) {
            // allocate bill tax proportionally
            final share = b.totalAmount > 0 ? item.subtotal / b.totalAmount : 0;
            igst = b.igstAmount * share;
            cgst = b.cgstAmount * share;
            sgst = b.sgstAmount * share;
            taxable = b.isTaxInclusive ? net - (cgst + sgst + igst) : net;
          }
        } else {
          final rate = item.cgstPercent + item.sgstPercent;
          if (b.isTaxInclusive && rate > 0) {
            taxable = net / (1 + rate / 100);
            cgst = taxable * (item.cgstPercent / 100);
            sgst = taxable * (item.sgstPercent / 100);
          } else {
            taxable = net;
            cgst = net * (item.cgstPercent / 100);
            sgst = net * (item.sgstPercent / 100);
          }
          igst = 0;
          if (rate == 0 && b.totalTaxAmount > 0) {
            final share = b.totalAmount > 0 ? item.subtotal / b.totalAmount : 0;
            cgst = b.cgstAmount * share;
            sgst = b.sgstAmount * share;
            igst = b.igstAmount * share;
            taxable = b.isTaxInclusive ? net - (cgst + sgst + igst) : net;
          }
        }
        final agg = hsnMap.putIfAbsent(hsn, () => _HsnAgg());
        agg.taxable += taxable;
        agg.cgst += cgst;
        agg.sgst += sgst;
        agg.igst += igst;
        agg.qty += item.quantity;
      }
    }
    final hsnKeys = hsnMap.keys.toList()..sort();
    for (final hsn in hsnKeys) {
      final a = hsnMap[hsn]!;
      rows.add([
        'HSN',
        rangeLabel,
        '-',
        '-',
        '-',
        '-',
        '-',
        hsn,
        _rs(a.taxable),
        _rs(a.cgst),
        _rs(a.sgst),
        _rs(a.igst),
        _rs(a.cgst + a.sgst + a.igst),
        _rs(a.taxable + a.cgst + a.sgst + a.igst),
      ]);
    }

    return UnifiedReportTable(
      title: 'GST Summary for CA',
      filterDescription: rangeLabel,
      headers: headers,
      rows: rows,
      summaryLine:
          'B2B: ${b2b.length} (Taxable Rs ${_rs(b2bTaxable)}, Tax Rs ${_rs(b2bTax)}) | '
          'B2C: ${b2c.length} (Taxable Rs ${_rs(b2cTaxable)}, Tax Rs ${_rs(b2cTax)}) | '
          'HSN codes: ${hsnKeys.length}',
    );
  }
}

class _HsnAgg {
  double taxable = 0;
  double cgst = 0;
  double sgst = 0;
  double igst = 0;
  double qty = 0;
}
