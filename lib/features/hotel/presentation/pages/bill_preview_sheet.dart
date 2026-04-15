import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../offline/entities/table_entity.dart';
import '../../offline/entities/table_order_entity.dart';
import '../../offline/controllers/table_order_controller.dart';

/// Bottom sheet that shows the final bill for a served table.
/// Provides "Print Bill" (PDF) and "Clear Table & Done" actions.
class BillPreviewSheet extends StatefulWidget {
  final TableEntity table;
  final TableOrderEntity order;

  const BillPreviewSheet({super.key, required this.table, required this.order});

  @override
  State<BillPreviewSheet> createState() => _BillPreviewSheetState();
}

class _BillPreviewSheetState extends State<BillPreviewSheet> {
  final _orderCtrl = TableOrderController.instance;
  bool _clearing = false;

  late List<OrderItem> _items;
  late double _subtotal;
  late double _cgst;
  late double _sgst;
  late double _grandTotal;

  static const double _gstRate = 0.025; // 2.5 % each

  @override
  void initState() {
    super.initState();
    _items = decodeOrderItems(widget.order.itemsJson);
    _subtotal = widget.order.totalAmount;
    _cgst = _subtotal * _gstRate;
    _sgst = _subtotal * _gstRate;
    _grandTotal = _subtotal + _cgst + _sgst;
  }

  // ── PDF generation ────────────────────────────────────────────

  Future<void> _printBill() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    await Printing.layoutPdf(
      onLayout: (_) => _buildPdfBytes(now),
      name: widget.order.billNumber ?? 'Bill',
    );
  }

  Future<Uint8List> _buildPdfBytes(DateTime now) async {
    final doc = pw.Document();

    pw.TextStyle title(double size) =>
        pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold);

    pw.TextStyle body(double size, {bool bold = false}) => pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Hotel header
            pw.Center(child: pw.Text('HOTEL RESTAURANT', style: title(14))),
            pw.Center(child: pw.Text('TAX INVOICE', style: body(9))),
            pw.SizedBox(height: 8),
            pw.Divider(),

            // Bill metadata
            _pdfRow('Bill No', widget.order.billNumber ?? '', body(9)),
            _pdfRow(
              'Date',
              '${now.day}/${now.month}/${now.year}  '
                  '${now.hour.toString().padLeft(2, '0')}:'
                  '${now.minute.toString().padLeft(2, '0')}',
              body(9),
            ),
            _pdfRow('Table', widget.table.tableNumber, body(9)),
            if ((widget.order.guestName ?? '').isNotEmpty)
              _pdfRow('Guest', widget.order.guestName!, body(9)),
            _pdfRow('Seats', widget.order.occupiedSeats.toString(), body(9)),
            pw.Divider(),

            // Items header
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text('ITEM', style: body(8, bold: true)),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'QTY',
                    style: body(8, bold: true),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'PRICE',
                    style: body(8, bold: true),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'AMT',
                    style: body(8, bold: true),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
            pw.Divider(),

            // Items rows
            ..._items.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(item.name, style: body(9)),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        '${item.quantity}',
                        style: body(9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        '${item.price.toStringAsFixed(2)}',
                        style: body(9),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        item.lineTotal.toStringAsFixed(2),
                        style: body(9),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            pw.Divider(),
            _pdfRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}', body(9)),
            _pdfRow('CGST (2.5%)', '₹${_cgst.toStringAsFixed(2)}', body(9)),
            _pdfRow('SGST (2.5%)', '₹${_sgst.toStringAsFixed(2)}', body(9)),
            pw.Divider(),
            _pdfRow(
              'GRAND TOTAL',
              '₹${_grandTotal.toStringAsFixed(2)}',
              title(12),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text('Thank you! Visit again.', style: body(10)),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfRow(String label, String value, pw.TextStyle style) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: style),
            pw.Text(value, style: style),
          ],
        ),
      );

  // ── Clear table ───────────────────────────────────────────────

  Future<void> _clearTable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF142318),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear Table',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Generate bill and mark table as empty?',
          style: TextStyle(color: Colors.white60, fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38, fontFamily: 'Literata'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Clear & Done',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.heavyImpact();
    setState(() => _clearing = true);
    try {
      await _orderCtrl.generateBill(widget.order.id, widget.table.id);
      if (mounted) {
        // Pop both this sheet and the detail sheet
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0E1C17),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFFF59E0B), width: 1.5),
            ),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(
              0,
              12,
              0,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Bill header
              _buildBillHeader(),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 24,
                ),
              ),

              // Items list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildItemsTable(),
              ),

              // Totals
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildTotals(),
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 1,
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActions(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillHeader() {
    final now = DateTime.now();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'HOTEL RESTAURANT',
            style: TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Literata',
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'TAX INVOICE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontFamily: 'Literata',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          _row('Bill No', widget.order.billNumber ?? 'PENDING', accent: true),
          const SizedBox(height: 6),
          _row(
            'Date',
            '${now.day}/${now.month}/${now.year}  '
                '${now.hour.toString().padLeft(2, '0')}:'
                '${now.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 6),
          _row('Table', widget.table.tableNumber),
          if ((widget.order.guestName ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            _row('Guest', widget.order.guestName!),
          ],
          const SizedBox(height: 6),
          _row('Seats', widget.order.occupiedSeats.toString()),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool accent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontFamily: 'Literata',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: accent ? const Color(0xFFF59E0B) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            _th('ITEM', flex: 4, align: TextAlign.left),
            _th('QTY', flex: 1),
            _th('PRICE', flex: 2, align: TextAlign.right),
            _th('TOTAL', flex: 2, align: TextAlign.right),
          ],
        ),
        Divider(color: Colors.white.withValues(alpha: 0.08), height: 12),
        ..._items.map(_buildItemRow),
      ],
    );
  }

  Widget _th(String text, {int flex = 1, TextAlign align = TextAlign.center}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontFamily: 'Literata',
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isVeg
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFF87171),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${item.price.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontFamily: 'Literata',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${item.lineTotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _totalRow('CGST (2.5%)', '₹${_cgst.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _totalRow('SGST (2.5%)', '₹${_sgst.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GRAND TOTAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '₹${_grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontFamily: 'Literata',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'Literata',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Print Bill
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _printBill,
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text(
              'Print Bill',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF60A5FA),
              side: const BorderSide(color: Color(0xFF60A5FA), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Clear Table & Done
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _clearing ? null : _clearTable,
            icon: _clearing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded, size: 20),
            label: Text(
              _clearing ? 'Processing...' : 'Clear Table & Done',
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFFF59E0B,
              ).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
