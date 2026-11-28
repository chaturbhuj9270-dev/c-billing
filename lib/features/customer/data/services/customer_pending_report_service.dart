import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../billing/offline/controllers/bill_offline_controller.dart';
import '../../../billing/offline/entities/bill_entity.dart';
import '../../../event_order/domain/entities/event_order.dart';
import '../../../event_order/offline/controllers/event_order_offline_controller.dart';
import '../../../event_order/offline/entities/event_order_entity.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../../core/printing/upi_payment_uri.dart';

/// One unpaid bill in the report.
class PendingBillRow {
  final String billNo;
  final DateTime date;
  final double total;
  final double paid;
  final double pending;

  const PendingBillRow({
    required this.billNo,
    required this.date,
    required this.total,
    required this.paid,
    required this.pending,
  });
}

/// One event / sales order with a balance due.
class PendingEventRow {
  final String name;
  final DateTime date;
  final double total;
  final double paid;
  final double pending;

  const PendingEventRow({
    required this.name,
    required this.date,
    required this.total,
    required this.paid,
    required this.pending,
  });
}

/// Pending-amount statement for one customer.
///
/// READ-ONLY: it only reads bills / event orders and takes the customer's
/// pending total from the ledger value the customer list already shows. It
/// never writes ledger entries or changes any balance.
class CustomerPendingReport {
  final String customerName;
  final String phone;
  final DateTime generatedAt;
  final List<PendingBillRow> bills;
  final List<PendingEventRow> events;

  /// Total pending exactly as shown on the customer card (ledger value).
  final double totalPending;

  const CustomerPendingReport({
    required this.customerName,
    required this.phone,
    required this.generatedAt,
    required this.bills,
    required this.events,
    required this.totalPending,
  });

  double get billsListedTotal => bills.fold(0.0, (t, b) => t + b.pending);
  double get eventsListedTotal => events.fold(0.0, (t, e) => t + e.pending);

  /// Part of the pending total that is not an open bill / event (for example
  /// an opening balance or a manual adjustment) so the statement always adds
  /// up to the ledger.
  double get otherAmount => totalPending - billsListedTotal - eventsListedTotal;

  bool get hasOther => otherAmount.abs() >= 0.01;
}

class CustomerPendingReportService {
  CustomerPendingReportService._();
  static final CustomerPendingReportService instance =
      CustomerPendingReportService._();

  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');

  /// A slow / blocked local query must never keep the report loader spinning;
  /// the statement then still adds up to the ledger through the "Other" row.
  static const Duration _queryTimeout = Duration(seconds: 8);

  /// Rupee amount for messages: no decimals when whole.
  static String formatAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  static String formatDate(DateTime date) => _dateFmt.format(date);

  /// Builds the report for a customer map from the customer list.
  Future<CustomerPendingReport> load(Map<String, dynamic> customer) async {
    final name = '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'
        .trim();
    final serverId = (customer['serverId'] ?? '').toString();
    final localId = (customer['localId'] ?? '').toString();
    final listId = (customer['id'] ?? '').toString();
    final total = (customer['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;

    final billIds = <String>{
      listId,
      serverId,
      localId,
      if (int.tryParse(localId) != null) 'local_$localId',
    }..removeWhere((id) => id.isEmpty);

    final eventIds = <String>{
      serverId,
      if (int.tryParse(localId) != null) 'local_$localId',
    }..removeWhere((id) => id.isEmpty);

    // One SQL query each, filtered to this customer's open rows. Loading every
    // bill / event (with items) per id made the report slow and time out.
    final results = await Future.wait([
      BillOfflineController.instance
          .getOpenBillsByCustomerIds(billIds)
          .timeout(_queryTimeout)
          .catchError((Object e) {
            debugPrint('[PendingReport] bills failed: $e');
            return <BillEntity>[];
          }),
      EventOrderOfflineController.instance
          .getOpenEventOrdersByCustomerIds(eventIds)
          .timeout(_queryTimeout)
          .catchError((Object e) {
            debugPrint('[PendingReport] events failed: $e');
            return <EventOrderEntity>[];
          }),
    ]);

    final bills = <int, PendingBillRow>{};
    for (final bill in results[0] as List<BillEntity>) {
      if (bill.pendingAmount <= 0.009) continue;
      bills[bill.id] = PendingBillRow(
        billNo: '#${bill.id}',
        date: bill.billDate,
        total: bill.finalAmount,
        paid: bill.paidAmount,
        pending: bill.pendingAmount,
      );
    }

    final events = <int, PendingEventRow>{};
    for (final order in results[1] as List<EventOrderEntity>) {
      if (order.status == OrderStatus.cancelled.index ||
          order.status == OrderStatus.convertedToBill.index) {
        continue;
      }
      if (order.remainingAmount <= 0.009) continue;
      events[order.id] = PendingEventRow(
        name: order.orderName,
        date: order.eventDate,
        total: order.totalAmount,
        paid: order.advanceAmount,
        pending: order.remainingAmount,
      );
    }

    final billRows = bills.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final eventRows = events.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return CustomerPendingReport(
      customerName: name,
      phone: (customer['contact'] ?? '').toString(),
      generatedAt: DateTime.now(),
      bills: billRows,
      events: eventRows,
      totalPending: total,
    );
  }

  /// A4 statement PDF.
  Future<Uint8List> buildPdf(CustomerPendingReport report, Shop shop) async {
    final doc = pw.Document();
    const accent = PdfColors.blueGrey800;
    const light = PdfColors.grey200;

    String money(double v) => 'Rs. ${v.toStringAsFixed(2)}';

    pw.Widget sectionTitle(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: accent,
        ),
      ),
    );

    pw.Widget table(List<String> headers, List<List<String>> rows) {
      return pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: accent),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignments: {
          for (var i = 0; i < headers.length; i++)
            i: i <= 1 ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
        },
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
        oddRowDecoration: const pw.BoxDecoration(color: light),
      );
    }

    final upi = (shop.upiId ?? '').trim();
    final showQr = upi.isNotEmpty && report.totalPending > 0;
    final qrData = showQr
        ? buildUpiPaymentUri(
            upiId: upi,
            payeeName: upiPayeeName(
              accountHolderName: shop.accountHolderName,
              shopName: shop.shopName,
            ),
            amount: report.totalPending,
            note: 'Pending dues',
          )
        : null;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      shop.shopName.isEmpty ? 'Statement' : shop.shopName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    if (shop.address.isNotEmpty)
                      pw.Text(
                        shop.address,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    if (shop.phone.isNotEmpty)
                      pw.Text(
                        'Phone: ${shop.phone}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    if ((shop.gstNumber ?? '').isNotEmpty)
                      pw.Text(
                        'GSTIN: ${shop.gstNumber}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'PENDING AMOUNT STATEMENT',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'As on ${formatDate(report.generatedAt)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(color: PdfColors.grey500),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: light,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Customer',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      report.customerName.isEmpty ? '-' : report.customerName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (report.phone.isNotEmpty)
                      pw.Text(
                        report.phone,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total pending',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      money(report.totalPending),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (report.bills.isNotEmpty) ...[
            sectionTitle('Pending bills'),
            table(
              ['Bill', 'Date', 'Bill total', 'Received', 'Pending'],
              [
                for (final b in report.bills)
                  [
                    b.billNo,
                    formatDate(b.date),
                    money(b.total),
                    money(b.paid),
                    money(b.pending),
                  ],
              ],
            ),
          ],
          if (report.events.isNotEmpty) ...[
            sectionTitle('Pending events / orders'),
            table(
              ['Event / order', 'Date', 'Total', 'Advance', 'Pending'],
              [
                for (final e in report.events)
                  [
                    e.name,
                    formatDate(e.date),
                    money(e.total),
                    money(e.paid),
                    money(e.pending),
                  ],
              ],
            ),
          ],
          if (report.hasOther) ...[
            sectionTitle('Other'),
            table(
              ['Description', '', '', '', 'Amount'],
              [
                [
                  'Opening balance / adjustments',
                  '',
                  '',
                  '',
                  money(report.otherAmount),
                ],
              ],
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'TOTAL PENDING: ${money(report.totalPending)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          if (qrData != null) ...[
            pw.SizedBox(height: 16),
            pw.Row(
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrData,
                  width: 80,
                  height: 80,
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    'Scan to pay ${money(report.totalPending)} via UPI\n$upi',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            'Kindly clear the pending amount at the earliest. Thank you!',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
