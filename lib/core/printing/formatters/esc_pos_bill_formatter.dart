import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/print_bill_data.dart';
import '../models/printer_models.dart';
import '../../../features/shop/domain/entities/shop.dart';
import '../../services/bill_report_settings_service.dart';

/// ESC/POS Commands for thermal printer control
class EscPosCommands {
  // Initialize printer
  static final List<int> init = [0x1B, 0x40];

  // Text alignment
  static final List<int> alignLeft = [0x1B, 0x61, 0x00];
  static final List<int> alignCenter = [0x1B, 0x61, 0x01];
  static final List<int> alignRight = [0x1B, 0x61, 0x02];

  // Text formatting
  static final List<int> boldOn = [0x1B, 0x45, 0x01];
  static final List<int> boldOff = [0x1B, 0x45, 0x00];
  static final List<int> underlineOn = [0x1B, 0x2D, 0x01];
  static final List<int> underlineOff = [0x1B, 0x2D, 0x00];

  // Text size
  static final List<int> textNormal = [0x1D, 0x21, 0x00];
  static final List<int> textDoubleHeight = [0x1D, 0x21, 0x01];
  static final List<int> textDoubleWidth = [0x1D, 0x21, 0x10];
  static final List<int> textDoubleSize = [0x1D, 0x21, 0x11];

  // Line feed
  static final List<int> lineFeed = [0x0A];

  // Cut paper
  static final List<int> cutPaper = [0x1D, 0x56, 0x00];
  static final List<int> cutPaperPartial = [0x1D, 0x56, 0x01];

  // Open cash drawer
  static final List<int> openDrawer = [0x1B, 0x70, 0x00, 0x19, 0xFA];

  // Feed n lines
  static List<int> feedLines(int lines) => [0x1B, 0x64, lines];

  // Character / line spacing
  static List<int> setCharSpacing(int n) => [0x1B, 0x20, n];
  static List<int> setLineSpacing(int n) => [0x1B, 0x33, n];
  static final List<int> resetLineSpacing = [0x1B, 0x32];
}

// ═══════════════════════════════════════════════════════════════════════════
// Professional POS Receipt Formatter
// Designed for 58 mm (32 char) & 80 mm (48 char) thermal printers
// ═══════════════════════════════════════════════════════════════════════════

class EscPosBillFormatter {
  final PosPaperSize paperSize;
  late final int _cols;

  EscPosBillFormatter({this.paperSize = PosPaperSize.mm58}) {
    _cols = paperSize.charsPerLine;
  }

  // ─────────────── PUBLIC API ───────────────

  /// Generate complete bill bytes for printing
  Future<List<int>> generateBillBytes({
    required PrintBillData billData,
    required Shop shopDetails,
    PrinterConfig config = const PrinterConfig(),
  }) async {
    final b = <int>[];

    // 1 — Initialise & set tight line spacing for readability
    b.addAll(EscPosCommands.init);
    b.addAll(EscPosCommands.setLineSpacing(26));

    // 2 — Shop header
    b.addAll(_buildHeader(shopDetails));

    // 3 — Bill meta (number, date/time, customer)
    b.addAll(await _buildBillInfo(billData));

    // 4 — Items table
    b.addAll(_buildItemsTable(billData));

    // 5 — Totals & payment
    b.addAll(_buildTotals(billData));

    // 6 — Footer
    b.addAll(_buildFooter(billData));

    // 7 — Feed & cut
    b.addAll(EscPosCommands.feedLines(config.feedLines));
    if (config.cutPaper) b.addAll(EscPosCommands.cutPaperPartial);
    if (config.openCashDrawer) b.addAll(EscPosCommands.openDrawer);

    return b;
  }

  // ─────────────── SECTION BUILDERS ───────────────

  // ┌────────────────────────────────┐
  // │        SHOP NAME (big)         │
  // │     123 Main St, City-431001   │
  // │       Tel: 9876543210          │
  // │     GSTIN: 12ABCDE3456F       │
  // ├════════════════════════════════┤
  List<int> _buildHeader(Shop shop) {
    final b = <int>[];

    // Shop name — centered, bold, large
    // Double-size text uses 2x width per char, so effective cols = _cols / 2
    final nameLines = _wrap(shop.shopName.toUpperCase(), maxWidth: _cols ~/ 2);
    for (final line in nameLines) {
      b.addAll(_center(line, bold: true, large: true));
    }
    b.addAll(_lf());

    // Address (word-wrapped, centered)
    if (shop.address.isNotEmpty) {
      for (final line in _wrap(shop.fullAddress)) {
        b.addAll(_center(line));
      }
    }

    // Phone
    if (shop.phone.isNotEmpty) {
      b.addAll(_center('Tel: ${shop.phone}'));
    }

    // Email
    if (shop.email != null && shop.email!.isNotEmpty) {
      b.addAll(_center(shop.email!));
    }

    // GST
    if (shop.gstNumber != null && shop.gstNumber!.isNotEmpty) {
      b.addAll(_center('GSTIN: ${shop.gstNumber}'));
    }

    b.addAll(_thickDiv());
    return b;
  }

  // ┌────────────────────────────────┐
  // │     *** RETURN BILL ***        │
  // │ Bill No     BILL-20260214-ABC  │
  // │ Date          14/02/2026       │
  // │ Time            02:30 PM       │
  // │ Customer    Rahul Sharma       │
  // │ Phone       9876543210         │
  // ├────────────────────────────────┤
  Future<List<int>> _buildBillInfo(PrintBillData d) async {
    final b = <int>[];
    final prefs = await SharedPreferences.getInstance();
    final showCustomer = prefs.getBool('bill_show_customer_details') ?? true;
    final generateViaContact =
        prefs.getBool('bill_generate_via_contact') ?? false;

    // Return-bill banner
    if (d.isReturnBill) {
      b.addAll(_center('*** RETURN BILL ***', bold: true));
      b.addAll(_lf());
    }

    // Bill number
    b.addAll(_kv('Bill No', d.billNumber, boldLabel: true));

    // Date & time — always printed
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('hh:mm a');
    b.addAll(_kv('Date', dateFmt.format(d.dateTime)));
    b.addAll(_kv('Time', timeFmt.format(d.dateTime)));

    // Customer info
    if (generateViaContact) {
      if (_notEmpty(d.customerPhone)) {
        b.addAll(_kv('Phone', d.customerPhone!));
      }
      if (showCustomer && _notEmpty(d.customerName)) {
        b.addAll(_kv('Customer', d.customerName!));
      }
    } else if (showCustomer) {
      if (_notEmpty(d.customerName)) {
        b.addAll(_kv('Customer', d.customerName!));
      }
      if (_notEmpty(d.customerPhone)) {
        b.addAll(_kv('Phone', d.customerPhone!));
      }
    }

    b.addAll(_thinDiv());
    return b;
  }

  // ┌────────────────────────────────┐
  // │ Item       Qty  Rate      Amt  │
  // ├────────────────────────────────┤
  // │ Rice 5kg     2   250   500.00  │
  // │ Sugar 1kg    5    45   225.00  │
  // ├────────────────────────────────┤
  List<int> _buildItemsTable(PrintBillData d) {
    final b = <int>[];
    final settings = BillReportSettingsService.instance;

    // Check which columns are visible
    final showQty = settings.isColumnVisible('quantity');
    final showRate = settings.isColumnVisible('rate');
    final showAmount = settings.isColumnVisible('amount');
    final showHsn = settings.isColumnVisible('hsn_code');
    final showCompany = settings.isColumnVisible('company');
    final showTax = settings.isColumnVisible('tax');

    // Build dynamic header based on visible columns
    b.addAll(EscPosCommands.boldOn);
    b.addAll(_dynamicItemRow(
      'Item',
      showQty ? 'Qty' : null,
      showRate ? 'Rate' : null,
      showAmount ? 'Amt' : null,
    ));
    b.addAll(EscPosCommands.boldOff);
    b.addAll(_thinDiv());

    // Each item
    for (final item in d.items) {
      // Build item name with optional company
      String itemName = item.name;
      if (showCompany && item.companyName != null && item.companyName!.isNotEmpty) {
        itemName = '$itemName (${item.companyName})';
      }

      b.addAll(_dynamicItemRow(
        itemName,
        showQty ? '${item.quantity}' : null,
        showRate ? _fmt(item.rate) : null,
        showAmount ? _fmt(item.amount) : null,
      ));

      // HSN code (only if enabled)
      if (showHsn) {
        final hsn = (item.hsnCode != null && item.hsnCode!.isNotEmpty) ? item.hsnCode! : '-';
        b.addAll(_left('  HSN: $hsn'));
      }

      // Per-item return note
      if (item.hasReturns) {
        b.addAll(_left(
          '  Ret: ${item.returnedQuantity} qty  -${_fmt(item.returnedAmount)}',
        ));
      }

      // Per-item GST breakdown (only if tax column is enabled)
      if (showTax && item.hasItemGst) {
        if (item.cgstPercent > 0) {
          b.addAll(_left(
            '  CGST(${_fmt(item.cgstPercent)}%): ${_fmt(item.cgstAmount)}',
          ));
        }
        if (item.sgstPercent > 0) {
          b.addAll(_left(
            '  SGST(${_fmt(item.sgstPercent)}%): ${_fmt(item.sgstAmount)}',
          ));
        }
      }
    }

    b.addAll(_thinDiv());

    // Aggregate return summary
    if (d.hasAnyReturns) {
      b.addAll(_kv('Returned Qty', '${d.totalReturnedQuantity}'));
      b.addAll(_kv('Return Amt', '-Rs.${_fmt(d.totalReturnedAmount)}'));
      b.addAll(_thinDiv());
    }

    return b;
  }

  /// Dynamic item row that only shows visible columns
  List<int> _dynamicItemRow(String item, String? qty, String? rate, String? amt) {
    final b = <int>[];
    b.addAll(EscPosCommands.alignLeft);
    
    // Calculate available width for item name
    int usedWidth = 0;
    if (qty != null) usedWidth += 5; // Qty column
    if (rate != null) usedWidth += 7; // Rate column
    if (amt != null) usedWidth += 9; // Amount column
    
    final itemWidth = _cols - usedWidth;
    // Truncate item name if needed
    final truncatedItem = item.length > itemWidth ? item.substring(0, itemWidth - 1) : item;
    
    // Build the row
    final row = StringBuffer(truncatedItem.padRight(itemWidth));
    if (qty != null) row.write(qty.padLeft(5));
    if (rate != null) row.write(rate.padLeft(7));
    if (amt != null) row.write(amt.padLeft(9));
    
    b.addAll(utf8.encode('$row\n'));
    return b;
  }

  // ┌────────────────────────────────┐
  // │ Total Items           10 qty   │
  // │ Subtotal          Rs.1250.00   │
  // │ Discount(5%)       -Rs.62.50   │
  // ├════════════════════════════════┤
  // │ GRAND TOTAL       Rs.1187.50   │  ← big & bold
  // ├════════════════════════════════┤
  // │ Paid              Rs.1000.00   │
  // │ Pending            Rs.187.50   │
  // │ TOTAL DUE          Rs.500.00   │
  // ├════════════════════════════════┤
  // │       Payment: Cash            │
  // └────────────────────────────────┘
  List<int> _buildTotals(PrintBillData d) {
    final b = <int>[];

    // Item count
    b.addAll(_kv('Total Items', '${d.totalQuantity} qty'));

    // Subtotal
    b.addAll(_kv('Subtotal', 'Rs.${_fmt(d.subtotal)}'));

    // Discount
    if (d.hasDiscount) {
      final lbl = d.discountPercent != null && d.discountPercent! > 0
          ? 'Discount(${d.discountPercent!.toStringAsFixed(1)}%)'
          : 'Discount';
      b.addAll(_kv(lbl, '-Rs.${_fmt(d.discountAmount!)}'));
    }

    // Tax
    if (d.hasTax) {
      final lbl = d.taxPercent != null && d.taxPercent! > 0
          ? 'Tax(${d.taxPercent!.toStringAsFixed(1)}%)'
          : 'Tax';
      b.addAll(_kv(lbl, 'Rs.${_fmt(d.taxAmount!)}'));
    }

    // ══ Grand Total — bold + double height ══
    b.addAll(_thickDiv());
    b.addAll(EscPosCommands.boldOn);
    b.addAll(EscPosCommands.textDoubleHeight);
    b.addAll(_kv('TOTAL', 'Rs.${_fmt(d.grandTotal)}'));
    b.addAll(EscPosCommands.textNormal);
    b.addAll(EscPosCommands.boldOff);
    b.addAll(_thickDiv());

    // Return refund
    if (d.isReturnBill && d.refundAmount != null) {
      b.addAll(EscPosCommands.boldOn);
      b.addAll(_kv('REFUND', 'Rs.${_fmt(d.refundAmount!)}'));
      b.addAll(EscPosCommands.boldOff);
      b.addAll(_lf());
    }

    // Payment breakdown
    if (d.hasPaymentInfo) {
      if (d.paidAmount != null) {
        b.addAll(_kv('Paid', 'Rs.${_fmt(d.paidAmount!)}'));
      }
      if (d.hasPendingAmount) {
        b.addAll(EscPosCommands.boldOn);
        b.addAll(_kv('Pending', 'Rs.${_fmt(d.pendingAmount!)}'));
        b.addAll(EscPosCommands.boldOff);
      }
      if (d.totalDueAmount != null && d.totalDueAmount! > 0) {
        b.addAll(_thinDiv());
        b.addAll(EscPosCommands.boldOn);
        b.addAll(_kv('TOTAL DUE', 'Rs.${_fmt(d.totalDueAmount!)}'));
        b.addAll(EscPosCommands.boldOff);
      }
    }

    // Payment method
    if (d.paymentMethod != null && d.paymentMethod!.isNotEmpty) {
      b.addAll(_lf());
      b.addAll(_center('Payment: ${d.paymentMethod}'));
    }

    return b;
  }

  /// Footer — notes + thank-you
  List<int> _buildFooter(PrintBillData d) {
    final b = <int>[];
    b.addAll(_lf());

    if (d.notes != null && d.notes!.isNotEmpty) {
      for (final line in _wrap('Note: ${d.notes}')) {
        b.addAll(_center(line));
      }
      b.addAll(_lf());
    }

    b.addAll(_thinDiv());
    b.addAll(_center('Thank You!', bold: true));
    b.addAll(_center('Visit Again'));
    b.addAll(_lf());
    return b;
  }

  // ─────────────── LOW-LEVEL PRIMITIVES ───────────────

  /// Encode text to bytes (Latin-1 with UTF-8 fallback)
  List<int> _enc(String s) {
    try {
      return latin1.encode(s);
    } catch (_) {
      return utf8.encode(s);
    }
  }

  /// Single line feed
  List<int> _lf() => [...EscPosCommands.lineFeed];

  /// Thin divider  --------------------------------
  List<int> _thinDiv() => _center('-' * _cols);

  /// Thick divider  ================================
  List<int> _thickDiv() => _center('=' * _cols);

  /// Center-aligned line
  List<int> _center(String text, {bool bold = false, bool large = false}) {
    final b = <int>[];
    b.addAll(EscPosCommands.alignCenter);
    if (bold) b.addAll(EscPosCommands.boldOn);
    if (large) b.addAll(EscPosCommands.textDoubleSize);

    b.addAll(_enc(text));
    b.addAll(EscPosCommands.lineFeed);

    if (large) b.addAll(EscPosCommands.textNormal);
    if (bold) b.addAll(EscPosCommands.boldOff);
    b.addAll(EscPosCommands.alignLeft);
    return b;
  }

  /// Left-aligned line
  List<int> _left(String text, {bool bold = false}) {
    final b = <int>[];
    b.addAll(EscPosCommands.alignLeft);
    if (bold) b.addAll(EscPosCommands.boldOn);
    b.addAll(_enc(text));
    b.addAll(EscPosCommands.lineFeed);
    if (bold) b.addAll(EscPosCommands.boldOff);
    return b;
  }

  /// Key–value row:  "Label          Value"
  /// Left label, right-aligned value, space-padded to fill line width.
  List<int> _kv(String label, String value, {bool boldLabel = false}) {
    final b = <int>[];
    if (boldLabel) b.addAll(EscPosCommands.boldOn);

    final gap = _cols - label.length - value.length;
    String line;
    if (gap >= 1) {
      line = label + (' ' * gap) + value;
    } else {
      // Truncate label to make room
      final maxL = _cols - value.length - 1;
      if (maxL > 0) {
        line = '${label.substring(0, maxL.clamp(0, label.length))} $value';
      } else {
        line = value;
      }
    }

    b.addAll(_enc(line));
    b.addAll(EscPosCommands.lineFeed);
    if (boldLabel) b.addAll(EscPosCommands.boldOff);
    return b;
  }

  /// 4-column item row  (name | qty | rate | amount)
  /// Column widths carefully tuned per paper size.
  List<int> _itemRow(String name, String qty, String rate, String amt) {
    final b = <int>[];

    int nameW, qtyW, rateW, amtW;
    if (paperSize == PosPaperSize.mm58) {
      // 32 = 13 + 4 + 7 + 8
      nameW = 13; qtyW = 4; rateW = 7; amtW = 8;
    } else {
      // 48 = 21 + 5 + 10 + 12
      nameW = 21; qtyW = 5; rateW = 10; amtW = 12;
    }

    final n = name.length > nameW
        ? name.substring(0, nameW)
        : name.padRight(nameW);
    final q = qty.padLeft(qtyW);
    final r = rate.padLeft(rateW);
    final a = amt.padLeft(amtW);

    b.addAll(_enc('$n$q$r$a'));
    b.addAll(EscPosCommands.lineFeed);

    // Overflow name on next line (indented)
    if (name.length > nameW) {
      b.addAll(_enc('  ${name.substring(nameW)}'));
      b.addAll(EscPosCommands.lineFeed);
    }

    return b;
  }

  /// Format money — show decimals only when fractional
  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  /// Null-safe non-empty check
  bool _notEmpty(String? s) => s != null && s.isNotEmpty;

  /// Word-wrap text to fit within column width.
  /// [maxWidth] overrides the default line width (useful for double-size text).
  List<String> _wrap(String text, {int? maxWidth}) {
    final width = maxWidth ?? _cols;
    final lines = <String>[];
    final words = text.split(' ');
    var cur = '';
    for (final w in words) {
      if (cur.isEmpty) {
        cur = w;
      } else if (cur.length + w.length + 1 <= width) {
        cur += ' $w';
      } else {
        lines.add(cur);
        cur = w;
      }
    }
    if (cur.isNotEmpty) lines.add(cur);
    return lines;
  }
}
