/// Core printing module for POS thermal printers
///
/// This module provides ESC/POS thermal printer support for:
/// - Bluetooth printers
/// - 58mm and 80mm paper sizes
/// - Bill formatting with shop details
///
/// Usage:
/// ```dart
/// import 'package:c_billing/core/printing/printing.dart';
///
/// final printerService = PosPrinterService();
/// await printerService.startScan();
/// await printerService.connectPrinter(device);
/// await printerService.printBill(billData: billData, shopDetails: shop);
/// ```
library;

// Models
export 'models/print_bill_data.dart';
export 'models/printer_models.dart';

// Formatters
export 'formatters/esc_pos_bill_formatter.dart';

// Services
export 'services/pos_printer_service.dart';
export 'services/pdf_bill_service.dart';
