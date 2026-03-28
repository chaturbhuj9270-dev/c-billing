import 'package:flutter/material.dart';
import '../core/printing/models/printer_models.dart';
import '../core/printing/services/pos_printer_service.dart';

/// Widget for discovering and selecting POS printers
/// Shows a bottom sheet with available printers
class PrinterSelectionWidget extends StatefulWidget {
  final Function(PosPrinterDevice)? onPrinterSelected;
  final VoidCallback? onDismiss;

  const PrinterSelectionWidget({
    super.key,
    this.onPrinterSelected,
    this.onDismiss,
  });

  /// Show printer selection as a bottom sheet
  static Future<PosPrinterDevice?> show(BuildContext context) async {
    return showModalBottomSheet<PosPrinterDevice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrinterSelectionWidget(
        onPrinterSelected: (printer) => Navigator.pop(context, printer),
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  State<PrinterSelectionWidget> createState() => _PrinterSelectionWidgetState();
}

class _PrinterSelectionWidgetState extends State<PrinterSelectionWidget> {
  final PosPrinterService _printerService = PosPrinterService();

  List<PosPrinterDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _errorMessage;
  PosPrinterDevice? _selectedDevice;
  PosPaperSize _selectedPaperSize = PosPaperSize.mm58;

  @override
  void initState() {
    super.initState();
    _listenToDevices();
    _startScan();
  }

  void _listenToDevices() {
    _printerService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices;
        });
      }
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _devices = [];
    });

    final result = await _printerService.startScan();

    if (mounted) {
      setState(() {
        _isScanning = false;
        if (!result.success) {
          _errorMessage = result.message;
        }
      });
    }
  }

  Future<void> _connectAndSelect(PosPrinterDevice device) async {
    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
      _errorMessage = null;
    });

    // Update config with selected paper size
    _printerService.updateConfig(
      _printerService.config.copyWith(paperSize: _selectedPaperSize),
    );

    final result = await _printerService.connectPrinter(device);

    if (mounted) {
      setState(() {
        _isConnecting = false;
      });

      if (result.success) {
        widget.onPrinterSelected?.call(device);
      } else {
        setState(() {
          _errorMessage = result.message;
          _selectedDevice = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              _buildHeader(),
              _buildPaperSizeSelector(),
              Expanded(child: _buildDeviceList(scrollController)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.print,
                  color: Color(0xFF1B4D3E),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Printer',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    Text(
                      _isScanning
                          ? 'Scanning...'
                          : '${_devices.length} printer(s) found',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: _isScanning ? null : _startScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1B4D3E),
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Color(0xFF1B4D3E)),
              ),
              // Close button
              IconButton(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaperSizeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Text(
            'Paper Size:',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _buildPaperSizeOption(PosPaperSize.mm58, '58mm'),
                const SizedBox(width: 12),
                _buildPaperSizeOption(PosPaperSize.mm80, '80mm'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperSizeOption(PosPaperSize size, String label) {
    final isSelected = _selectedPaperSize == size;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaperSize = size),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(ScrollController scrollController) {
    if (_isScanning && _devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
            ),
            SizedBox(height: 16),
            Text(
              'Scanning for printers...',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print_disabled, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No printers found',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure your printer is on and\nBluetooth is enabled',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Scan Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isSelected = _selectedDevice?.id == device.id;
        final isConnecting = _isConnecting && isSelected;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: device.isConnected
                    ? Colors.green[50]
                    : const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.print,
                color: device.isConnected
                    ? Colors.green[700]
                    : const Color(0xFF1B4D3E),
                size: 22,
              ),
            ),
            title: Text(
              device.name,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              device.address ?? 'Unknown address',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            trailing: isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1B4D3E),
                      ),
                    ),
                  )
                : device.isConnected
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Connected',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: isConnecting ? null : () => _connectAndSelect(device),
          ),
        );
      },
    );
  }
}
