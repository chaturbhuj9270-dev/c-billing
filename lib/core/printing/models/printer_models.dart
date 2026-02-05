/// Enum representing different paper sizes for POS printers
enum PosPaperSize {
  mm58(32, 384),  // 58mm paper: 32 chars, 384 dots
  mm80(48, 576);  // 80mm paper: 48 chars, 576 dots

  final int charsPerLine;
  final int dotsPerLine;

  const PosPaperSize(this.charsPerLine, this.dotsPerLine);
}

/// Enum representing printer connection type
enum PrinterConnectionType {
  bluetooth,
  usb,
  network,
}

/// Enum representing printer status
enum PrinterStatus {
  connected,
  disconnected,
  connecting,
  printing,
  error,
}

/// Model representing a discovered POS printer
class PosPrinterDevice {
  final String id;
  final String name;
  final String? address;
  final PrinterConnectionType connectionType;
  final bool isConnected;

  const PosPrinterDevice({
    required this.id,
    required this.name,
    this.address,
    required this.connectionType,
    this.isConnected = false,
  });

  PosPrinterDevice copyWith({
    String? id,
    String? name,
    String? address,
    PrinterConnectionType? connectionType,
    bool? isConnected,
  }) {
    return PosPrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      connectionType: connectionType ?? this.connectionType,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  String toString() {
    return 'PosPrinterDevice(id: $id, name: $name, type: $connectionType, connected: $isConnected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PosPrinterDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Result class for printer operations
class PrinterResult {
  final bool success;
  final String? message;
  final dynamic data;

  const PrinterResult({
    required this.success,
    this.message,
    this.data,
  });

  factory PrinterResult.success([String? message, dynamic data]) {
    return PrinterResult(success: true, message: message, data: data);
  }

  factory PrinterResult.failure(String message) {
    return PrinterResult(success: false, message: message);
  }
}

/// Configuration options for printing
class PrinterConfig {
  final PosPaperSize paperSize;
  final bool cutPaper;
  final bool openCashDrawer;
  final int feedLines;
  final bool printLogo;

  const PrinterConfig({
    this.paperSize = PosPaperSize.mm58,
    this.cutPaper = true,
    this.openCashDrawer = false,
    this.feedLines = 3,
    this.printLogo = false,
  });

  PrinterConfig copyWith({
    PosPaperSize? paperSize,
    bool? cutPaper,
    bool? openCashDrawer,
    int? feedLines,
    bool? printLogo,
  }) {
    return PrinterConfig(
      paperSize: paperSize ?? this.paperSize,
      cutPaper: cutPaper ?? this.cutPaper,
      openCashDrawer: openCashDrawer ?? this.openCashDrawer,
      feedLines: feedLines ?? this.feedLines,
      printLogo: printLogo ?? this.printLogo,
    );
  }
}
