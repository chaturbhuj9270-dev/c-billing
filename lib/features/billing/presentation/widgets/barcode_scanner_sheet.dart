import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/services/barcode_service.dart';

/// A beautiful bottom sheet for scanning barcodes for fast billing
/// Features:
/// - Camera preview with scan overlay
/// - Flash toggle
/// - Continuous scanning mode
/// - Visual feedback on successful scan
/// - Manual barcode entry option
class BarcodeScannerSheet extends StatefulWidget {
  /// Callback when a product is scanned successfully
  final Function(Map<String, dynamic> productData) onProductScanned;

  /// Callback when a product is removed from bill
  final Function(String productKey)? onProductRemoved;

  /// Callback when scanner is closed
  final VoidCallback? onClose;

  const BarcodeScannerSheet({
    super.key,
    required this.onProductScanned,
    this.onProductRemoved,
    this.onClose,
  });

  /// Show the scanner as a bottom sheet
  static Future<void> show(
    BuildContext context, {
    required Function(Map<String, dynamic> productData) onProductScanned,
    Function(String productKey)? onProductRemoved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BarcodeScannerSheet(
        onProductScanned: onProductScanned,
        onProductRemoved: onProductRemoved,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  final TextEditingController _manualBarcodeController =
      TextEditingController();

  bool _isProcessing = false;
  bool _flashEnabled = false;
  bool _showManualEntry = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  // Scanned items history for this session
  final List<_ScannedItem> _scannedItems = [];

  // Debounce duration to prevent duplicate scans
  static const _scanDebounce = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    // Debounce check
    final now = DateTime.now();
    if (_lastScannedCode == barcode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < _scanDebounce) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = barcode;
      _lastScanTime = now;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Lookup product
    final productData = await BarcodeService.instance.scanForBilling(barcode);

    if (productData != null) {
      // Success!
      HapticFeedback.heavyImpact();

      // Create the unique product key (same format as billing page)
      final productId = productData['productId'] as String;
      final batchId = productData['batchId'] as String?;
      final productKey = batchId != null
          ? '${productId}_batch_$batchId'
          : productId;

      setState(() {
        _scannedItems.insert(
          0,
          _ScannedItem(
            barcode: barcode,
            productName: productData['productName'] ?? 'Unknown',
            productKey: productKey,
            success: true,
            timestamp: now,
          ),
        );
      });

      // Call callback
      widget.onProductScanned(productData);

      // Show success feedback
      _showScanFeedback(true, productData['productName'] ?? 'Product');
    } else {
      // Not found
      setState(() {
        _scannedItems.insert(
          0,
          _ScannedItem(
            barcode: barcode,
            productName: 'Not Found',
            success: false,
            timestamp: now,
          ),
        );
      });

      _showScanFeedback(false, barcode);
    }

    // Reset processing state after a short delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _showScanFeedback(bool success, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success ? 'Added: $message' : 'Product not found: $message',
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: success ? const Color(0xFF1B4D3E) : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFlash() async {
    await _scannerController.toggleTorch();
    setState(() => _flashEnabled = !_flashEnabled);
  }

  void _submitManualBarcode() async {
    final barcode = _manualBarcodeController.text.trim();
    if (barcode.isEmpty) return;

    setState(() => _isProcessing = true);

    final productData = await BarcodeService.instance.scanForBilling(barcode);

    if (productData != null) {
      HapticFeedback.heavyImpact();

      // Create the unique product key (same format as billing page)
      final productId = productData['productId'] as String;
      final batchId = productData['batchId'] as String?;
      final productKey = batchId != null
          ? '${productId}_batch_$batchId'
          : productId;

      setState(() {
        _scannedItems.insert(
          0,
          _ScannedItem(
            barcode: barcode,
            productName: productData['productName'] ?? 'Unknown',
            productKey: productKey,
            success: true,
            timestamp: DateTime.now(),
          ),
        );
      });
      widget.onProductScanned(productData);
      _showScanFeedback(true, productData['productName'] ?? 'Product');
      _manualBarcodeController.clear();
    } else {
      setState(() {
        _scannedItems.insert(
          0,
          _ScannedItem(
            barcode: barcode,
            productName: 'Not Found',
            success: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _showScanFeedback(false, barcode);
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          _buildHandleBar(),

          // Header
          _buildHeader(),

          // Scanner area
          Expanded(
            child: Stack(
              children: [
                // Camera preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                  ),
                ),

                // Scan overlay
                _buildScanOverlay(),

                // Flash and controls
                _buildControls(),

                // Manual entry section (overlays at bottom)
                if (_showManualEntry) _buildManualEntryOverlay(),
              ],
            ),
          ),

          // Scanned items list
          _buildScannedItemsList(),

          // Bottom actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1B4D3E), const Color(0xFF2D6A4F)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Barcode',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Point camera at product barcode',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (widget.onClose != null) {
                  widget.onClose!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - scanAreaSize) / 2;
        final top = (constraints.maxHeight - scanAreaSize) / 2 - 20;

        return Stack(
          children: [
            // Darkened corners
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScanOverlayPainter(
                scanAreaRect: Rect.fromLTWH(
                  left,
                  top,
                  scanAreaSize,
                  scanAreaSize,
                ),
              ),
            ),

            // Scan frame
            Positioned(
              left: left,
              top: top,
              width: scanAreaSize,
              height: scanAreaSize,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isProcessing
                        ? const Color(0xFF1B4D3E)
                        : Colors.white.withOpacity(0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    _buildCorner(Alignment.topLeft),
                    _buildCorner(Alignment.topRight),
                    _buildCorner(Alignment.bottomLeft),
                    _buildCorner(Alignment.bottomRight),

                    // Animated scan line
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanLineAnimation.value * (scanAreaSize - 4),
                          left: 8,
                          right: 8,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF1B4D3E),
                                  const Color(0xFF2D6A4F),
                                  const Color(0xFF1B4D3E),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1B4D3E,
                                  ).withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Processing indicator
            if (_isProcessing)
              Positioned(
                left: left,
                top: top,
                width: scanAreaSize,
                height: scanAreaSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Color(0xFF1B4D3E), width: 4)
                : BorderSide.none,
            bottom: isTop
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF1B4D3E), width: 4),
            left: isLeft
                ? const BorderSide(color: Color(0xFF1B4D3E), width: 4)
                : BorderSide.none,
            right: isLeft
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF1B4D3E), width: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flash toggle
          _buildControlButton(
            icon: _flashEnabled
                ? Icons.flash_on_rounded
                : Icons.flash_off_rounded,
            label: 'Flash',
            isActive: _flashEnabled,
            onTap: _toggleFlash,
          ),
          const SizedBox(width: 24),
          // Manual entry toggle
          _buildControlButton(
            icon: Icons.keyboard_rounded,
            label: 'Manual',
            isActive: _showManualEntry,
            onTap: () => setState(() => _showManualEntry = !_showManualEntry),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF1B4D3E).withOpacity(0.8)
                    : Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF1B4D3E)
                      : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryOverlay() {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Manual Entry',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualBarcodeController,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter barcode number',
                          hintStyle: TextStyle(
                            fontFamily: 'Literata',
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitManualBarcode(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _submitManualBarcode,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1B4D3E),
                                const Color(0xFF2D6A4F),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannedItemsList() {
    if (_scannedItems.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _scannedItems.length,
        itemBuilder: (context, index) {
          final item = _scannedItems[index];
          final isRemoved = item.isRemoved;
          final canRemove =
              item.success && !isRemoved && item.productKey != null;

          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRemoved
                  ? Colors.grey.withOpacity(0.2)
                  : item.success
                  ? const Color(0xFF1B4D3E).withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRemoved
                    ? Colors.grey.withOpacity(0.3)
                    : item.success
                    ? const Color(0xFF1B4D3E).withOpacity(0.5)
                    : Colors.red.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      isRemoved
                          ? Icons.remove_circle_outline_rounded
                          : item.success
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: isRemoved
                          ? Colors.grey
                          : item.success
                          ? const Color(0xFF1B4D3E)
                          : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isRemoved
                            ? '${item.productName} (Removed)'
                            : item.productName,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isRemoved
                              ? Colors.grey[500]
                              : item.success
                              ? Colors.white
                              : Colors.red[200],
                          decoration: isRemoved
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Remove button
                    if (canRemove)
                      GestureDetector(
                        onTap: () => _removeScannedItem(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.barcode,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatTime(item.timestamp),
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _removeScannedItem(int index) {
    final item = _scannedItems[index];
    if (item.productKey == null || item.isRemoved) return;

    HapticFeedback.mediumImpact();

    // Call the removal callback first
    widget.onProductRemoved?.call(item.productKey!);

    setState(() {
      item.isRemoved = true;
    });

    // Show feedback only if still mounted
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.remove_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Removed: ${item.productName}',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            // Items count
            if (_scannedItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_cart_rounded,
                      color: Color(0xFF1B4D3E),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_scannedItems.where((i) => i.success).length} items',
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            // Done button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Dismiss any active snackbars before closing
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B4D3E),
                        const Color(0xFF2D6A4F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Done',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal class to track scanned items
class _ScannedItem {
  final String barcode;
  final String productName;
  final String?
  productKey; // The unique key used in billing (productId_batch_batchId)
  final bool success;
  final DateTime timestamp;
  bool isRemoved; // Track if item was removed from bill

  _ScannedItem({
    required this.barcode,
    required this.productName,
    this.productKey,
    required this.success,
    required this.timestamp,
    this.isRemoved = false,
  });
}

/// Custom painter for the scan overlay (darkened corners)
class _ScanOverlayPainter extends CustomPainter {
  final Rect scanAreaRect;

  _ScanOverlayPainter({required this.scanAreaRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);

    // Draw the darkened area with a hole for the scan area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(16)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.scanAreaRect != scanAreaRect;
  }
}
