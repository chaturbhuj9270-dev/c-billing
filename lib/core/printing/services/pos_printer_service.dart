import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/printer_models.dart';
import '../models/print_bill_data.dart';
import '../formatters/esc_pos_bill_formatter.dart';
import '../../../features/shop/domain/entities/shop.dart';

/// Service class for managing POS thermal printer connections and printing
/// Supports Bluetooth ESC/POS printers with 58mm and 80mm paper sizes
class PosPrinterService {
  static final PosPrinterService _instance = PosPrinterService._internal();
  factory PosPrinterService() => _instance;
  PosPrinterService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  
  PosPrinterDevice? _connectedPrinter;
  PrinterStatus _status = PrinterStatus.disconnected;
  PrinterConfig _config = const PrinterConfig();
  
  final _statusController = StreamController<PrinterStatus>.broadcast();
  final _devicesController = StreamController<List<PosPrinterDevice>>.broadcast();
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Stream of printer status changes
  Stream<PrinterStatus> get statusStream => _statusController.stream;
  
  /// Stream of discovered devices
  Stream<List<PosPrinterDevice>> get devicesStream => _devicesController.stream;
  
  /// Current printer status
  PrinterStatus get status => _status;
  
  /// Currently connected printer
  PosPrinterDevice? get connectedPrinter => _connectedPrinter;
  
  /// Current printer configuration
  PrinterConfig get config => _config;

  /// Check if printer is connected
  bool get isConnected => _status == PrinterStatus.connected && _connectedDevice != null;

  /// Update printer configuration
  void updateConfig(PrinterConfig config) {
    _config = config;
  }

  /// Request necessary permissions for Bluetooth
  Future<PrinterResult> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final bluetoothScan = await Permission.bluetoothScan.request();
        final bluetoothConnect = await Permission.bluetoothConnect.request();
        final location = await Permission.locationWhenInUse.request();

        if (bluetoothScan.isDenied || 
            bluetoothConnect.isDenied || 
            location.isDenied) {
          return PrinterResult.failure(
            'Bluetooth and location permissions are required for printer discovery',
          );
        }
      } else if (Platform.isIOS) {
        final bluetooth = await Permission.bluetooth.request();
        if (bluetooth.isDenied) {
          return PrinterResult.failure('Bluetooth permission is required');
        }
      }
      return PrinterResult.success('Permissions granted');
    } catch (e) {
      return PrinterResult.failure('Failed to request permissions: $e');
    }
  }

  /// Check if Bluetooth is available and on
  Future<bool> _checkBluetoothState() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        return false;
      }
      
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  /// Start scanning for Bluetooth printers
  Future<PrinterResult> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      _updateStatus(PrinterStatus.connecting);
      
      final permissionResult = await requestPermissions();
      if (!permissionResult.success) {
        _updateStatus(PrinterStatus.error);
        return permissionResult;
      }

      final bluetoothOn = await _checkBluetoothState();
      if (!bluetoothOn) {
        _updateStatus(PrinterStatus.error);
        return PrinterResult.failure('Please turn on Bluetooth');
      }

      final List<PosPrinterDevice> discoveredDevices = [];

      // Cancel any existing scan
      await _scanSubscription?.cancel();
      await FlutterBluePlus.stopScan();

      // Start new scan
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        discoveredDevices.clear();
        for (final result in results) {
          // Filter for devices that might be printers
          // Many Bluetooth printers have names containing 'print', 'pos', 'thermal', etc.
          final name = result.device.platformName;
          if (name.isNotEmpty) {
            discoveredDevices.add(PosPrinterDevice(
              id: result.device.remoteId.str,
              name: name,
              address: result.device.remoteId.str,
              connectionType: PrinterConnectionType.bluetooth,
              isConnected: _connectedPrinter?.id == result.device.remoteId.str,
            ));
          }
        }
        _devicesController.add(discoveredDevices);
      });

      await FlutterBluePlus.startScan(timeout: timeout);

      // Wait for scan to complete
      await Future.delayed(timeout);
      
      _updateStatus(_connectedPrinter != null 
          ? PrinterStatus.connected 
          : PrinterStatus.disconnected);

      return PrinterResult.success(
        'Found ${discoveredDevices.length} device(s)',
        discoveredDevices,
      );
    } catch (e) {
      _updateStatus(PrinterStatus.error);
      return PrinterResult.failure('Failed to scan for printers: $e');
    }
  }

  /// Stop scanning for printers
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
  }

  /// Connect to a Bluetooth printer
  Future<PrinterResult> connectPrinter(PosPrinterDevice device) async {
    try {
      _updateStatus(PrinterStatus.connecting);

      // Disconnect from any existing device
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      // Find the BluetoothDevice
      final targetDevice = BluetoothDevice.fromId(device.id);

      // Connect to the device
      await targetDevice.connect(timeout: const Duration(seconds: 10));
      
      _connectedDevice = targetDevice;

      // Discover services and find the write characteristic
      final services = await targetDevice.discoverServices();
      
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          // Look for a writable characteristic
          if (characteristic.properties.write || 
              characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            break;
          }
        }
        if (_writeCharacteristic != null) break;
      }

      if (_writeCharacteristic == null) {
        await targetDevice.disconnect();
        _connectedDevice = null;
        _updateStatus(PrinterStatus.error);
        return PrinterResult.failure(
          'Could not find a writable characteristic on this device',
        );
      }

      _connectedPrinter = device.copyWith(isConnected: true);
      _updateStatus(PrinterStatus.connected);

      return PrinterResult.success('Connected to ${device.name}');
    } catch (e) {
      _connectedDevice = null;
      _writeCharacteristic = null;
      _updateStatus(PrinterStatus.error);
      return PrinterResult.failure('Failed to connect: $e');
    }
  }

  /// Disconnect from current printer
  Future<PrinterResult> disconnectPrinter() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      _connectedDevice = null;
      _writeCharacteristic = null;
      _connectedPrinter = null;
      _updateStatus(PrinterStatus.disconnected);
      return PrinterResult.success('Disconnected');
    } catch (e) {
      return PrinterResult.failure('Failed to disconnect: $e');
    }
  }

  /// Print bill using the connected printer
  Future<PrinterResult> printBill({
    required PrintBillData billData,
    required Shop shopDetails,
    PrinterConfig? config,
  }) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      return PrinterResult.failure('No printer connected');
    }

    try {
      _updateStatus(PrinterStatus.printing);
      
      final printerConfig = config ?? _config;
      
      // Generate bill bytes using formatter
      final formatter = EscPosBillFormatter(paperSize: printerConfig.paperSize);
      final bytes = await formatter.generateBillBytes(
        billData: billData,
        shopDetails: shopDetails,
        config: printerConfig,
      );

      // Send bytes to printer in chunks (BLE has MTU limits)
      await _sendBytes(bytes);
      
      _updateStatus(PrinterStatus.connected);
      return PrinterResult.success('Bill printed successfully');
    } catch (e) {
      _updateStatus(PrinterStatus.error);
      return PrinterResult.failure('Failed to print: $e');
    }
  }

  /// Print raw bytes (for custom printing)
  Future<PrinterResult> printRaw(List<int> bytes) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      return PrinterResult.failure('No printer connected');
    }

    try {
      _updateStatus(PrinterStatus.printing);
      
      await _sendBytes(bytes);
      
      _updateStatus(PrinterStatus.connected);
      return PrinterResult.success('Printed successfully');
    } catch (e) {
      _updateStatus(PrinterStatus.error);
      return PrinterResult.failure('Failed to print: $e');
    }
  }

  /// Send bytes to printer in chunks
  Future<void> _sendBytes(List<int> bytes) async {
    if (_writeCharacteristic == null) {
      throw Exception('No write characteristic available');
    }

    // BLE typically has MTU of around 512 bytes, but safe to use smaller chunks
    const chunkSize = 200;
    
    for (var i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      final chunk = bytes.sublist(i, end);
      
      if (_writeCharacteristic!.properties.writeWithoutResponse) {
        await _writeCharacteristic!.write(chunk, withoutResponse: true);
      } else {
        await _writeCharacteristic!.write(chunk, withoutResponse: false);
      }
      
      // Small delay between chunks to prevent buffer overflow
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Test print - prints a simple test page
  Future<PrinterResult> printTest() async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      return PrinterResult.failure('No printer connected');
    }

    try {
      _updateStatus(PrinterStatus.printing);

      final formatter = EscPosBillFormatter(paperSize: _config.paperSize);
      
      // Create test bill data
      final testBill = PrintBillData(
        billNumber: 'TEST-001',
        dateTime: DateTime.now(),
        items: const [
          PrintBillItem(name: 'Test Item 1', quantity: 2, rate: 100.00, amount: 200.00),
          PrintBillItem(name: 'Test Item 2', quantity: 1, rate: 50.00, amount: 50.00),
        ],
        subtotal: 250.00,
        grandTotal: 250.00,
      );

      const testShop = Shop(
        id: 'test',
        shopName: 'Test Shop',
        address: '123 Test Street',
        phone: '9876543210',
        email: 'test@shop.com',
      );

      final bytes = await formatter.generateBillBytes(
        billData: testBill,
        shopDetails: testShop,
        config: _config,
      );

      await _sendBytes(bytes);
      
      _updateStatus(PrinterStatus.connected);
      return PrinterResult.success('Test page printed successfully');
    } catch (e) {
      _updateStatus(PrinterStatus.error);
      return PrinterResult.failure('Failed to print test: $e');
    }
  }

  /// Update internal status and notify listeners
  void _updateStatus(PrinterStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// Dispose resources
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    _connectedDevice?.disconnect();
    _statusController.close();
    _devicesController.close();
  }
}

/// Extension to get user-friendly status messages
extension PrinterStatusExtension on PrinterStatus {
  String get message {
    switch (this) {
      case PrinterStatus.connected:
        return 'Connected';
      case PrinterStatus.disconnected:
        return 'Disconnected';
      case PrinterStatus.connecting:
        return 'Connecting...';
      case PrinterStatus.printing:
        return 'Printing...';
      case PrinterStatus.error:
        return 'Error';
    }
  }

  bool get isLoading {
    return this == PrinterStatus.connecting || this == PrinterStatus.printing;
  }
}
