import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/print_bill_data.dart';
import '../models/printer_models.dart';
import '../../../features/shop/domain/entities/shop.dart';

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

  // Text size - double height and width
  static final List<int> textNormal = [0x1D, 0x21, 0x00];
  static final List<int> textDoubleHeight = [0x1D, 0x21, 0x01];
  static final List<int> textDoubleWidth = [0x1D, 0x21, 0x10];
  static final List<int> textDoubleSize = [0x1D, 0x21, 0x11];

  // Line feed
  static final List<int> lineFeed = [0x0A];

  // Cut paper (full cut)
  static final List<int> cutPaper = [0x1D, 0x56, 0x00];

  // Cut paper (partial cut)
  static final List<int> cutPaperPartial = [0x1D, 0x56, 0x01];

  // Open cash drawer
  static final List<int> openDrawer = [0x1B, 0x70, 0x00, 0x19, 0xFA];

  // Feed lines
  static List<int> feedLines(int lines) => [0x1B, 0x64, lines];

  // Set character spacing
  static List<int> setCharSpacing(int n) => [0x1B, 0x20, n];

  // Set line spacing
  static List<int> setLineSpacing(int n) => [0x1B, 0x33, n];

  // Reset line spacing to default
  static final List<int> resetLineSpacing = [0x1B, 0x32];
}

/// Formatter class for generating ESC/POS commands for POS thermal printers
/// Supports both 58mm and 80mm paper sizes with proper column alignment
class EscPosBillFormatter {
  final PosPaperSize paperSize;
  late final int _charsPerLine;

  EscPosBillFormatter({this.paperSize = PosPaperSize.mm58}) {
    _charsPerLine = paperSize.charsPerLine;
  }

  /// Generate complete bill bytes for printing
  Future<List<int>> generateBillBytes({
    required PrintBillData billData,
    required Shop shopDetails,
    PrinterConfig config = const PrinterConfig(),
  }) async {
    List<int> bytes = [];

    // Initialize printer
    bytes.addAll(EscPosCommands.init);
    bytes.addAll(EscPosCommands.resetLineSpacing);

    // Header Section - Shop Details
    bytes.addAll(_generateHeader(shopDetails));

    // Bill Info Section
    bytes.addAll(await _generateBillInfo(billData));

    // Items Section
    bytes.addAll(_generateItemsSection(billData));

    // Summary Section
    bytes.addAll(_generateSummary(billData));

    // Footer Section
    bytes.addAll(_generateFooter(billData));

    // Feed and Cut
    bytes.addAll(EscPosCommands.feedLines(config.feedLines));
    if (config.cutPaper) {
      bytes.addAll(EscPosCommands.cutPaperPartial);
    }

    // Open cash drawer if configured
    if (config.openCashDrawer) {
      bytes.addAll(EscPosCommands.openDrawer);
    }

    return bytes;
  }

  /// Convert string to bytes with proper encoding
  List<int> _textToBytes(String text) {
    // Use Latin1 encoding for basic ASCII, which works with most thermal printers
    try {
      return latin1.encode(text);
    } catch (e) {
      // Fallback to UTF-8 if Latin1 fails
      return utf8.encode(text);
    }
  }

  /// Print a line of text with alignment
  List<int> _printLine(
    String text, {
    bool center = false,
    bool right = false,
    bool bold = false,
    bool large = false,
  }) {
    List<int> bytes = [];

    if (center) {
      bytes.addAll(EscPosCommands.alignCenter);
    } else if (right) {
      bytes.addAll(EscPosCommands.alignRight);
    } else {
      bytes.addAll(EscPosCommands.alignLeft);
    }

    if (bold) {
      bytes.addAll(EscPosCommands.boldOn);
    }

    if (large) {
      bytes.addAll(EscPosCommands.textDoubleSize);
    }

    bytes.addAll(_textToBytes(text));
    bytes.addAll(EscPosCommands.lineFeed);

    if (large) {
      bytes.addAll(EscPosCommands.textNormal);
    }

    if (bold) {
      bytes.addAll(EscPosCommands.boldOff);
    }

    bytes.addAll(EscPosCommands.alignLeft);

    return bytes;
  }

  /// Print a divider line
  List<int> _printDivider({String char = '-'}) {
    return _printLine(char * _charsPerLine, center: true);
  }

  /// Print two columns (left and right aligned)
  List<int> _printTwoColumns(String left, String right, {bool bold = false}) {
    List<int> bytes = [];

    if (bold) {
      bytes.addAll(EscPosCommands.boldOn);
    }

    // Calculate spacing
    final totalLength = left.length + right.length;
    final spaces = _charsPerLine - totalLength;

    String line;
    if (spaces > 0) {
      line = left + (' ' * spaces) + right;
    } else {
      // Truncate left side if too long
      final maxLeft = _charsPerLine - right.length - 1;
      line = left.substring(0, maxLeft.clamp(0, left.length)) + ' ' + right;
    }

    bytes.addAll(_textToBytes(line));
    bytes.addAll(EscPosCommands.lineFeed);

    if (bold) {
      bytes.addAll(EscPosCommands.boldOff);
    }

    return bytes;
  }

  /// Print item row with name, qty, rate, amount
  List<int> _printItemRow(String name, String qty, String rate, String amount) {
    List<int> bytes = [];

    // Column widths based on paper size
    int nameWidth, qtyWidth, rateWidth, amtWidth;

    if (paperSize == PosPaperSize.mm58) {
      // 32 chars total: name=14, qty=4, rate=6, amt=8
      nameWidth = 14;
      qtyWidth = 4;
      rateWidth = 6;
      amtWidth = 8;
    } else {
      // 48 chars total: name=22, qty=6, rate=9, amt=11
      nameWidth = 22;
      qtyWidth = 6;
      rateWidth = 9;
      amtWidth = 11;
    }

    // Truncate or pad name
    String namePart = name.length > nameWidth
        ? name.substring(0, nameWidth)
        : name.padRight(nameWidth);

    // Right-align numeric columns
    String qtyPart = qty.padLeft(qtyWidth);
    String ratePart = rate.padLeft(rateWidth);
    String amtPart = amount.padLeft(amtWidth);

    String line = namePart + qtyPart + ratePart + amtPart;

    bytes.addAll(_textToBytes(line));
    bytes.addAll(EscPosCommands.lineFeed);

    // If name was truncated, print the rest on next line
    if (name.length > nameWidth) {
      String remaining = name.substring(nameWidth);
      bytes.addAll(_textToBytes('  $remaining'));
      bytes.addAll(EscPosCommands.lineFeed);
    }

    return bytes;
  }

  /// Generate header section with shop details
  List<int> _generateHeader(Shop shop) {
    List<int> bytes = [];

    // Shop Name - Center, Bold, Large
    bytes.addAll(
      _printLine(
        shop.shopName.toUpperCase(),
        center: true,
        bold: true,
        large: true,
      ),
    );

    bytes.addAll(EscPosCommands.lineFeed);

    // Address - Center
    if (shop.address.isNotEmpty) {
      // Wrap long address
      final address = shop.fullAddress;
      final lines = _wrapText(address, _charsPerLine);
      for (final line in lines) {
        bytes.addAll(_printLine(line, center: true));
      }
    }

    // Email - Center
    if (shop.email != null && shop.email!.isNotEmpty) {
      bytes.addAll(_printLine(shop.email!, center: true));
    }

    // Phone - Center
    if (shop.phone.isNotEmpty) {
      bytes.addAll(_printLine('Tel: ${shop.phone}', center: true));
    }

    // GST Number if available
    if (shop.gstNumber != null && shop.gstNumber!.isNotEmpty) {
      bytes.addAll(_printLine('GSTIN: ${shop.gstNumber}', center: true));
    }

    bytes.addAll(EscPosCommands.lineFeed);
    bytes.addAll(_printDivider());

    return bytes;
  }

  /// Generate bill information section
  Future<List<int>> _generateBillInfo(PrintBillData billData) async {
    List<int> bytes = [];

    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    
    // Check if customer details should be shown
    final prefs = await SharedPreferences.getInstance();
    final showCustomer = prefs.getBool('bill_show_customer_details') ?? true;
    final generateViaContact = prefs.getBool('bill_generate_via_contact') ?? false;

    // Return Bill indicator
    if (billData.isReturnBill) {
      bytes.addAll(_printLine('*** RETURN BILL ***', center: true, bold: true));
      bytes.addAll(EscPosCommands.lineFeed);
    }

    // Bill Number
    bytes.addAll(_printLine('Bill No: ${billData.billNumber}', bold: true));

    // Date and Time on separate lines to avoid cropping
    bytes.addAll(_printLine('Date: ${dateFormatter.format(billData.dateTime)}'));
    bytes.addAll(_printLine('Time: ${timeFormatter.format(billData.dateTime)}'));

    // Always show phone number when generate via contact is enabled
    if (generateViaContact) {
      if (billData.customerPhone != null && billData.customerPhone!.isNotEmpty) {
        bytes.addAll(_printLine('Phone: ${billData.customerPhone}'));
      }
      // Also show customer name if found via phone search
      if (showCustomer && billData.customerName != null && billData.customerName!.isNotEmpty) {
        bytes.addAll(_printLine('Customer: ${billData.customerName}'));
      }
    } else if (showCustomer) {
      // Normal mode - show customer details if enabled
      if (billData.customerName != null && billData.customerName!.isNotEmpty) {
        bytes.addAll(_printLine('Customer: ${billData.customerName}'));
      }
      if (billData.customerPhone != null && billData.customerPhone!.isNotEmpty) {
        bytes.addAll(_printLine('Phone: ${billData.customerPhone}'));
      }
    }

    bytes.addAll(_printDivider());

    return bytes;
  }

  /// Generate items section with proper column alignment
  List<int> _generateItemsSection(PrintBillData billData) {
    List<int> bytes = [];

    // Column headers
    bytes.addAll(EscPosCommands.boldOn);
    bytes.addAll(_printItemRow('Item', 'Qty', 'Rate', 'Amount'));
    bytes.addAll(EscPosCommands.boldOff);

    bytes.addAll(_printDivider(char: '-'));

    // Print each item
    for (final item in billData.items) {
      bytes.addAll(
        _printItemRow(
          item.name,
          item.quantity.toString(),
          _formatAmount(item.rate),
          _formatAmount(item.amount),
        ),
      );
    }

    bytes.addAll(_printDivider());

    return bytes;
  }

  /// Generate summary section
  List<int> _generateSummary(PrintBillData billData) {
    List<int> bytes = [];

    // Total Items
    bytes.addAll(
      _printTwoColumns('Total Items:', '${billData.totalQuantity} qty'),
    );

    // Subtotal
    bytes.addAll(
      _printTwoColumns('Subtotal:', 'Rs.${_formatAmount(billData.subtotal)}'),
    );

    // Discount if applicable
    if (billData.hasDiscount) {
      final discountLabel =
          billData.discountPercent != null && billData.discountPercent! > 0
          ? 'Discount (${billData.discountPercent!.toStringAsFixed(1)}%):'
          : 'Discount:';
      bytes.addAll(
        _printTwoColumns(
          discountLabel,
          '-Rs.${_formatAmount(billData.discountAmount!)}',
        ),
      );
    }

    // Tax if applicable
    if (billData.hasTax) {
      final taxLabel = billData.taxPercent != null && billData.taxPercent! > 0
          ? 'Tax (${billData.taxPercent!.toStringAsFixed(1)}%):'
          : 'Tax:';
      bytes.addAll(
        _printTwoColumns(taxLabel, 'Rs.${_formatAmount(billData.taxAmount!)}'),
      );
    }

    bytes.addAll(_printDivider(char: '='));

    // Grand Total - Bold and larger
    bytes.addAll(EscPosCommands.boldOn);
    bytes.addAll(EscPosCommands.textDoubleHeight);
    bytes.addAll(
      _printTwoColumns(
        'GRAND TOTAL:',
        'Rs.${_formatAmount(billData.grandTotal)}',
        bold: true,
      ),
    );
    bytes.addAll(EscPosCommands.textNormal);
    bytes.addAll(EscPosCommands.boldOff);

    // Refund amount for return bills
    if (billData.isReturnBill && billData.refundAmount != null) {
      bytes.addAll(EscPosCommands.lineFeed);
      bytes.addAll(
        _printTwoColumns(
          'REFUND:',
          'Rs.${_formatAmount(billData.refundAmount!)}',
          bold: true,
        ),
      );
    }

    // Payment details section
    if (billData.hasPaymentInfo) {
      bytes.addAll(EscPosCommands.lineFeed);

      // Paid Amount
      if (billData.paidAmount != null) {
        bytes.addAll(
          _printTwoColumns(
            'Paid Amount:',
            'Rs.${_formatAmount(billData.paidAmount!)}',
          ),
        );
      }

      // Pending Amount for this bill
      if (billData.hasPendingAmount) {
        bytes.addAll(EscPosCommands.boldOn);
        bytes.addAll(
          _printTwoColumns(
            'Pending Amount:',
            'Rs.${_formatAmount(billData.pendingAmount!)}',
            bold: true,
          ),
        );
        bytes.addAll(EscPosCommands.boldOff);
      }

      // Total Due Amount (customer's running balance)
      if (billData.totalDueAmount != null && billData.totalDueAmount! > 0) {
        bytes.addAll(_printDivider(char: '-'));
        bytes.addAll(EscPosCommands.boldOn);
        bytes.addAll(
          _printTwoColumns(
            'TOTAL DUE:',
            'Rs.${_formatAmount(billData.totalDueAmount!)}',
            bold: true,
          ),
        );
        bytes.addAll(EscPosCommands.boldOff);
      }
    }

    bytes.addAll(_printDivider(char: '='));

    // Payment method if specified
    if (billData.paymentMethod != null && billData.paymentMethod!.isNotEmpty) {
      bytes.addAll(
        _printLine('Payment: ${billData.paymentMethod}', center: true),
      );
    }

    return bytes;
  }

  /// Generate footer section
  List<int> _generateFooter(PrintBillData billData) {
    List<int> bytes = [];

    bytes.addAll(EscPosCommands.lineFeed);

    // Notes if any
    if (billData.notes != null && billData.notes!.isNotEmpty) {
      bytes.addAll(_printLine('Note: ${billData.notes}', center: true));
      bytes.addAll(EscPosCommands.lineFeed);
    }

    // Thank you message
    bytes.addAll(
      _printLine('Thank You for Your Business!', center: true, bold: true),
    );
    bytes.addAll(_printLine('Visit Again', center: true));

    return bytes;
  }

  /// Format amount with proper decimal places
  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  /// Wrap text into multiple lines
  List<String> _wrapText(String text, int maxWidth) {
    final List<String> lines = [];
    final words = text.split(' ');
    String currentLine = '';

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + word.length + 1) <= maxWidth) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }
}
