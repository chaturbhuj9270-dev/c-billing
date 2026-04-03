import 'package:flutter/material.dart';
import '../core/printing/models/print_bill_data.dart';
import '../core/printing/services/pos_printer_service.dart';
import '../features/shop/domain/entities/shop.dart';
import '../features/shop/data/repositories/shop_repository.dart';
import 'printer_selection_widget.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

/// Reusable widget for printing bills with printer selection and status display
class PrintBillButton extends StatefulWidget {
  final PrintBillData billData;
  final Shop? shopDetails;
  final String? buttonText;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onPrintSuccess;
  final Function(String)? onPrintError;
  final bool showTestPrint;
  final bool compact;

  const PrintBillButton({
    super.key,
    required this.billData,
    this.shopDetails,
    this.buttonText,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.onPrintSuccess,
    this.onPrintError,
    this.showTestPrint = false,
    this.compact = false,
  });

  @override
  State<PrintBillButton> createState() => _PrintBillButtonState();
}

class _PrintBillButtonState extends State<PrintBillButton> {
  final PosPrinterService _printerService = PosPrinterService();
  final ShopRepository _shopRepository = ShopRepository();

  bool _isPrinting = false;
  Shop? _shop;

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    if (widget.shopDetails != null) {
      _shop = widget.shopDetails;
    } else {
      _shop = await _shopRepository.getShopDetails();
    }
    if (mounted) setState(() {});
  }

  Future<void> _handlePrint() async {
    // Check if printer is connected
    if (!_printerService.isConnected) {
      // Show printer selection
      final selectedPrinter = await PrinterSelectionWidget.show(context);
      if (selectedPrinter == null) return;
    }

    // Ensure shop details are loaded
    _shop ??= await _shopRepository.getShopDetails();

    setState(() => _isPrinting = true);

    try {
      final result = await _printerService.printBill(
        billData: widget.billData,
        shopDetails: _shop!,
      );

      if (mounted) {
        setState(() => _isPrinting = false);

        if (result.success) {
          widget.onPrintSuccess?.call();
          _showSuccessSnackBar(result.message ?? 'Bill printed successfully');
        } else {
          widget.onPrintError?.call(result.message ?? 'Print failed');
          _showErrorSnackBar(result.message ?? 'Failed to print bill');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPrinting = false);
        widget.onPrintError?.call(e.toString());
        _showErrorSnackBar('Error printing: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    GlassyToast.show(context, message);
  }

  void _showErrorSnackBar(String message) {
    GlassyToast.show(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactButton();
    }
    return _buildFullButton();
  }

  Widget _buildFullButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPrinting ? null : _handlePrint,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.backgroundColor ?? const Color(0xFF1B4D3E),
              foregroundColor: widget.foregroundColor ?? Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor:
                  (widget.backgroundColor ?? const Color(0xFF1B4D3E))
                      .withValues(alpha: 0.5),
            ),
            child: _isPrinting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Printing...',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.foregroundColor ?? Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon ?? Icons.print, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        widget.buttonText ?? 'Print Bill',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_printerService.isConnected) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _printerService.connectedPrinter?.name ?? 'Printer connected',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompactButton() {
    return IconButton(
      onPressed: _isPrinting ? null : _handlePrint,
      icon: _isPrinting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
              ),
            )
          : Icon(
              widget.icon ?? Icons.print,
              color: widget.backgroundColor ?? const Color(0xFF1B4D3E),
            ),
      tooltip: widget.buttonText ?? 'Print Bill',
    );
  }
}

/// Standalone print action widget that can be used in any screen
class PrintActionWidget extends StatefulWidget {
  final PrintBillData billData;
  final Shop? shopDetails;
  final Widget Function(BuildContext, VoidCallback, bool)? builder;

  const PrintActionWidget({
    super.key,
    required this.billData,
    this.shopDetails,
    this.builder,
  });

  @override
  State<PrintActionWidget> createState() => _PrintActionWidgetState();
}

class _PrintActionWidgetState extends State<PrintActionWidget> {
  final PosPrinterService _printerService = PosPrinterService();
  final ShopRepository _shopRepository = ShopRepository();

  bool _isPrinting = false;

  Future<void> _handlePrint() async {
    // Check if printer is connected
    if (!_printerService.isConnected) {
      final selectedPrinter = await PrinterSelectionWidget.show(context);
      if (selectedPrinter == null) return;
    }

    // Get shop details
    final shop = widget.shopDetails ?? await _shopRepository.getShopDetails();

    setState(() => _isPrinting = true);

    try {
      final result = await _printerService.printBill(
        billData: widget.billData,
        shopDetails: shop,
      );

      if (mounted) {
        setState(() => _isPrinting = false);

        GlassyToast.show(context, result.message ?? 'Error', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPrinting = false);
        GlassyToast.show(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(context, _handlePrint, _isPrinting);
    }

    return IconButton(
      onPressed: _isPrinting ? null : _handlePrint,
      icon: _isPrinting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.print),
      tooltip: 'Print Bill',
    );
  }
}
