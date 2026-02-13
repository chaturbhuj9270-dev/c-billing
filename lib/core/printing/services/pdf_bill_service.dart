import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/print_bill_data.dart';
import '../../../features/shop/domain/entities/shop.dart';

/// Service for generating PDF bills and sharing them
class PdfBillService {
  static final PdfBillService _instance = PdfBillService._internal();
  factory PdfBillService() => _instance;
  PdfBillService._internal();

  /// Generate a PDF document from bill data (POS receipt format)
  Future<pw.Document> generateBillPdf({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    final pdf = pw.Document();

    // Check if customer details should be shown
    final prefs = await SharedPreferences.getInstance();
    final showCustomer = prefs.getBool('bill_show_customer_details') ?? true;
    final generateViaContact =
        prefs.getBool('bill_generate_via_contact') ?? false;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(16),
        build: (context) => _buildBillContent(
          billData,
          shopDetails,
          showCustomer,
          generateViaContact,
        ),
      ),
    );

    return pdf;
  }

  /// Generate a Normal/Tabular A4 bill PDF (like Krushi Seva Kendra format)
  Future<pw.Document> generateNormalBillPdf({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    final pdf = pw.Document();

    // Check if customer details should be shown
    final prefs = await SharedPreferences.getInstance();
    final showCustomer = prefs.getBool('bill_show_customer_details') ?? true;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => _buildNormalBillContent(
          billData,
          shopDetails,
          showCustomer,
        ),
      ),
    );

    return pdf;
  }

  /// Build content for Normal/Tabular A4 bill
  pw.Widget _buildNormalBillContent(
    PrintBillData billData,
    Shop shopDetails,
    bool showCustomer,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Shop Header with border
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey800, width: 1.5),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                shopDetails.shopName.isNotEmpty
                    ? shopDetails.shopName.toUpperCase()
                    : 'STORE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (shopDetails.address.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  shopDetails.address,
                  style: const pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (shopDetails.phone.isNotEmpty)
                    pw.Text(
                      'Ph: ${shopDetails.phone}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  if (shopDetails.phone.isNotEmpty &&
                      shopDetails.gstNumber != null &&
                      shopDetails.gstNumber!.isNotEmpty)
                    pw.Text(' | ', style: const pw.TextStyle(fontSize: 11)),
                  if (shopDetails.gstNumber != null &&
                      shopDetails.gstNumber!.isNotEmpty)
                    pw.Text(
                      'GSTIN: ${shopDetails.gstNumber}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        // Bill Title
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey800),
            ),
            child: pw.Text(
              'TAX INVOICE / BILL',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),

        pw.SizedBox(height: 12),

        // Bill Info and Customer Info Row
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Row(
            children: [
              // Left side - Bill Details
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey400),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Bill No.', billData.billNumber),
                      pw.SizedBox(height: 4),
                      _buildInfoRow('Date', _formatDateNormal(billData.dateTime)),
                      pw.SizedBox(height: 4),
                      _buildInfoRow('Time', _formatTime(billData.dateTime)),
                    ],
                  ),
                ),
              ),
              // Right side - Customer Details
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (showCustomer &&
                          billData.customerName != null &&
                          billData.customerName!.isNotEmpty) ...[
                        _buildInfoRow('Customer', billData.customerName!),
                        pw.SizedBox(height: 4),
                      ],
                      if (billData.customerPhone != null &&
                          billData.customerPhone!.isNotEmpty) ...[
                        _buildInfoRow('Phone', billData.customerPhone!),
                        pw.SizedBox(height: 4),
                      ],
                      if ((!showCustomer || billData.customerName == null) &&
                          billData.customerPhone == null)
                        pw.Text(
                          'Walk-in Customer',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // Items Table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600),
          columnWidths: {
            0: const pw.FixedColumnWidth(40), // Sr.No
            1: const pw.FlexColumnWidth(4), // Item Name
            2: const pw.FixedColumnWidth(50), // Qty
            3: const pw.FixedColumnWidth(70), // Rate
            4: const pw.FixedColumnWidth(80), // Amount
          },
          children: [
            // Table Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeaderCell('Sr.'),
                _buildTableHeaderCell('Item Description'),
                _buildTableHeaderCell('Qty'),
                _buildTableHeaderCell('Rate (₹)'),
                _buildTableHeaderCell('Amount (₹)'),
              ],
            ),
            // Table Rows
            ...billData.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return pw.TableRow(
                children: [
                  _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                  _buildTableCell(item.name),
                  _buildTableCell('${item.quantity}', align: pw.TextAlign.center),
                  _buildTableCell(item.rate.toStringAsFixed(2), align: pw.TextAlign.right),
                  _buildTableCell(item.amount.toStringAsFixed(2), align: pw.TextAlign.right),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 12),

        // Totals Section
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left side - Notes or empty
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Terms & Conditions:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '1. Goods once sold will not be taken back.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      '2. Please check the items before leaving.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'Total Items: ${billData.items.length}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Total Quantity: ${billData.totalQuantity}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 16),
            // Right side - Amounts
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                ),
                child: pw.Column(
                  children: [
                    _buildAmountRow('Subtotal', billData.subtotal),
                    if (billData.discountAmount != null &&
                        billData.discountAmount! > 0)
                      _buildAmountRow(
                        'Discount${billData.discountPercent != null ? ' (${billData.discountPercent!.toStringAsFixed(0)}%)' : ''}',
                        -billData.discountAmount!,
                        isNegative: true,
                      ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.grey600),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'GRAND TOTAL',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '₹${billData.grandTotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (billData.hasPaymentInfo) ...[
                      _buildAmountRow('Paid', billData.paidAmount ?? 0, color: PdfColors.green700),
                      if (billData.hasPendingAmount)
                        _buildAmountRow('Pending', billData.pendingAmount!, color: PdfColors.orange700),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // Total Due Section
        if (billData.totalDueAmount != null && billData.totalDueAmount! > 0) ...[
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange400),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL DUE AMOUNT',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange800,
                  ),
                ),
                pw.Text(
                  '₹${billData.totalDueAmount!.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange800,
                  ),
                ),
              ],
            ),
          ),
        ],

        pw.SizedBox(height: 24),

        // Signature Section
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Customer Signature',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 120,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey600),
                    ),
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'For ${shopDetails.shopName.isNotEmpty ? shopDetails.shopName : 'Store'}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Authorized Signatory',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 16),

        // Footer
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 60,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildAmountRow(String label, double amount, {bool isNegative = false, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: color),
          ),
          pw.Text(
            '${isNegative ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateNormal(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  pw.Widget _buildBillContent(
    PrintBillData billData,
    Shop shopDetails,
    bool showCustomer,
    bool generateViaContact,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Shop Header
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                shopDetails.shopName.isNotEmpty
                    ? shopDetails.shopName
                    : 'STORE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (shopDetails.address.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  shopDetails.address,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (shopDetails.phone.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Ph: ${shopDetails.phone}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
              if (shopDetails.gstNumber != null &&
                  shopDetails.gstNumber!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'GSTIN: ${shopDetails.gstNumber}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        // Bill Info
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Bill: ${billData.billNumber}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              _formatDate(billData.dateTime),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.SizedBox(height: 4),

        // Customer Info - show based on settings
        if (generateViaContact &&
            billData.customerPhone != null &&
            billData.customerPhone!.isNotEmpty) ...[
          pw.Text(
            'Phone: ${billData.customerPhone}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (showCustomer &&
              billData.customerName != null &&
              billData.customerName!.isNotEmpty)
            pw.Text(
              'Customer: ${billData.customerName}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          pw.SizedBox(height: 4),
        ] else if (showCustomer &&
            billData.customerName != null &&
            billData.customerName!.isNotEmpty) ...[
          pw.Text(
            'Customer: ${billData.customerName}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (billData.customerPhone != null &&
              billData.customerPhone!.isNotEmpty)
            pw.Text(
              'Phone: ${billData.customerPhone}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          pw.SizedBox(height: 4),
        ],

        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        // Items Header
        pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                'Item',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(
              width: 40,
              child: pw.Text(
                'Qty',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(
              width: 50,
              child: pw.Text(
                'Rate',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(
              width: 60,
              child: pw.Text(
                'Amount',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.3),
        pw.SizedBox(height: 4),

        // Items
        ...billData.items.expand(
          (item) => [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      item.name,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.SizedBox(
                    width: 40,
                    child: pw.Text(
                      '${item.quantity}',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(
                    width: 50,
                    child: pw.Text(
                      '${item.rate.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.SizedBox(
                    width: 60,
                    child: pw.Text(
                      '${item.amount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            // Show returned quantity for this item
            if (item.hasReturns)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Returned: ${item.returnedQuantity} qty',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.orange800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '-Rs. ${item.returnedAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.orange800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        // Returns summary section
        if (billData.hasAnyReturns) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Returned Items:',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                '${billData.totalReturnedQuantity} qty',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Return Amount:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),
              pw.Text(
                '-Rs. ${billData.totalReturnedAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 8),
        ],

        // Totals
        _buildTotalRow('Subtotal', billData.subtotal),
        if (billData.discountAmount != null &&
            billData.discountAmount! > 0) ...[
          pw.SizedBox(height: 4),
          _buildTotalRow(
            'Discount (${billData.discountPercent?.toStringAsFixed(0) ?? '0'}%)',
            -(billData.discountAmount ?? 0),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        // Grand Total
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'GRAND TOTAL',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Rs. ${billData.grandTotal.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),

        // Payment Details Section
        if (billData.hasPaymentInfo) ...[
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 0.3),
          pw.SizedBox(height: 8),

          // Paid Amount
          if (billData.paidAmount != null)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Paid Amount', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  'Rs. ${billData.paidAmount!.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ],
            ),

          // Pending Amount
          if (billData.hasPendingAmount) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Pending Amount',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Rs. ${billData.pendingAmount!.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700,
                  ),
                ),
              ],
            ),
          ],

          // Total Due Amount
          if (billData.totalDueAmount != null &&
              billData.totalDueAmount! > 0) ...[
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.3),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange200),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL DUE',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Rs. ${billData.totalDueAmount!.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        pw.SizedBox(height: 16),
        pw.Divider(thickness: 0.3),
        pw.SizedBox(height: 8),

        // Footer
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Thank you for your purchase!',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Please visit again',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
          'Rs. ${amount.abs().toStringAsFixed(2)}${amount < 0 ? ' -' : ''}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year $hour:$minute $period';
  }

  /// Save PDF to file and return the file path
  Future<File> savePdfToFile({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    // Check bill type setting
    final prefs = await SharedPreferences.getInstance();
    final billType = prefs.getString('bill_type') ?? 'pos';
    
    final pw.Document pdf;
    if (billType == 'normal') {
      pdf = await generateNormalBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    } else {
      pdf = await generateBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    }

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'bill_${billData.billNumber.replaceAll('/', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Share the bill as PDF via the system share sheet
  Future<void> shareBillAsPdf({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    try {
      debugPrint('[PdfBillService] Starting shareBillAsPdf for bill: ${billData.billNumber}');
      
      // Check bill type setting
      final prefs = await SharedPreferences.getInstance();
      final billType = prefs.getString('bill_type') ?? 'pos';
      debugPrint('[PdfBillService] Bill type: $billType');
      
      final pw.Document pdf;
      if (billType == 'normal') {
        pdf = await generateNormalBillPdf(
          billData: billData,
          shopDetails: shopDetails,
        );
      } else {
        pdf = await generateBillPdf(
          billData: billData,
          shopDetails: shopDetails,
        );
      }
      debugPrint('[PdfBillService] PDF generated successfully');

      final bytes = await pdf.save();
      debugPrint('[PdfBillService] PDF bytes saved, size: ${bytes.length}');

      // Use XFile.fromData to let share_plus handle file creation internally
      final fileName =
          'bill_${billData.billNumber.replaceAll('/', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      debugPrint('[PdfBillService] Creating XFile from data with name: $fileName');
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType: 'application/pdf',
      );

      debugPrint('[PdfBillService] Calling Share.shareXFiles...');
      final result = await Share.shareXFiles(
        [xFile],
        text: 'Bill ${billData.billNumber} - ${shopDetails.shopName}',
        subject: 'Bill from ${shopDetails.shopName}',
      );
      debugPrint('[PdfBillService] Share result: ${result.status}');
    } catch (e, stackTrace) {
      debugPrint('[PdfBillService] ERROR in shareBillAsPdf: $e');
      debugPrint('[PdfBillService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Preview and print PDF using system print dialog
  Future<void> previewAndPrintPdf({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    // Check bill type setting
    final prefs = await SharedPreferences.getInstance();
    final billType = prefs.getString('bill_type') ?? 'pos';
    
    final pw.Document pdf;
    if (billType == 'normal') {
      pdf = await generateNormalBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    } else {
      pdf = await generateBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Bill_${billData.billNumber}',
    );
  }

  /// Show PDF preview in a dialog
  Future<void> showPdfPreview({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    // Check bill type setting
    final prefs = await SharedPreferences.getInstance();
    final billType = prefs.getString('bill_type') ?? 'pos';
    
    final pw.Document pdf;
    if (billType == 'normal') {
      pdf = await generateNormalBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    } else {
      pdf = await generateBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'bill_${billData.billNumber.replaceAll('/', '_')}.pdf',
    );
  }
}
