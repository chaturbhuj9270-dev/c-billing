import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/common_widgets/web_pdf_view.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// A reusable page for previewing PDF and CSV files with share and print functionality.
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => FilePreviewPage(
///       file: generatedFile,
///       fileName: 'Inventory Report',
///       fileType: FilePreviewType.pdf, // or FilePreviewType.csv
///     ),
///   ),
/// );
/// ```
class FilePreviewPage extends StatefulWidget {
  /// Local file on mobile and desktop. Omitted on web, where [bytes] is used.
  final File? file;

  /// Document bytes. Required on web, where there is no local file to read.
  final Uint8List? bytes;
  final String fileName;
  final FilePreviewType fileType;
  final String? subtitle;
  final VoidCallback? onClose;

  /// Optional customer phone number for direct WhatsApp sharing
  final String? customerPhone;

  /// Web shows this preview in a dialog. Mobile and desktop use a full page.
  final bool presentedAsDialog;

  const FilePreviewPage({
    super.key,
    this.file,
    this.bytes,
    required this.fileName,
    required this.fileType,
    this.subtitle,
    this.onClose,
    this.customerPhone,
    this.presentedAsDialog = false,
  }) : assert(file != null || bytes != null, 'Provide a file or document bytes');

  /// Opens the preview. On web this is a popup. Other platforms push a page.
  static Future<void> open(
    BuildContext context, {
    File? file,
    Uint8List? bytes,
    required String fileName,
    required FilePreviewType fileType,
    String? subtitle,
    VoidCallback? onClose,
    String? customerPhone,
  }) {
    final page = FilePreviewPage(
      file: file,
      bytes: bytes,
      fileName: fileName,
      fileType: fileType,
      subtitle: subtitle,
      onClose: onClose,
      customerPhone: customerPhone,
      presentedAsDialog: kIsWeb,
    );
    if (!kIsWeb) {
      return Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close preview',
      barrierColor: AppTheme.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, _) {
        final size = MediaQuery.sizeOf(dialogContext);
        final width = size.width >= 1200 ? 1040.0 : size.width - 48;
        final height = size.height >= 760 ? size.height - 72 : size.height - 32;
        return Center(
          child: Material(
            color: AppColors.card(dialogContext),
            elevation: 0,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(width: width, height: height, child: page),
          ),
        );
      },
    );
  }

  void _closePreview(BuildContext context) {
    if (!presentedAsDialog) onClose?.call();
    Navigator.of(context).pop();
  }

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  bool _isLoading = true;
  bool _isSharing = false;
  bool _isSharingWhatsApp = false;
  bool _isPrinting = false;
  List<List<String>>? _csvData;
  String? _errorMessage;
  Uint8List? _pdfBytes; // Pre-loaded PDF bytes

  // PDF page rendering state
  List<Uint8List?> _renderedPages = [];
  int _totalPages = 0;
  int _pagesRendered = 0;
  bool _isRenderingPdf = false;
  String _renderingStatus = '';

  // Zoom controls for CSV
  double _zoomLevel = 1.0;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.25;
  final TransformationController _transformationController =
      TransformationController();

  // Scroll controller for PDF
  final ScrollController _pdfScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pdfScrollController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    if (_zoomLevel < _maxZoom) {
      setState(() {
        _zoomLevel = (_zoomLevel + _zoomStep).clamp(_minZoom, _maxZoom);
        _updateTransformationMatrix();
      });
    }
  }

  void _zoomOut() {
    if (_zoomLevel > _minZoom) {
      setState(() {
        _zoomLevel = (_zoomLevel - _zoomStep).clamp(_minZoom, _maxZoom);
        _updateTransformationMatrix();
      });
    }
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _updateTransformationMatrix() {
    _transformationController.value = Matrix4.identity()
      ..scaleByDouble(_zoomLevel, _zoomLevel, _zoomLevel, 1);
  }

  Future<void> _loadFile() async {
    try {
      if (widget.bytes != null) {
        await _loadFromBytes(widget.bytes!);
        return;
      }

      final file = widget.file;
      if (file == null) {
        throw Exception('No document to preview');
      }

      debugPrint('[FilePreviewPage] Loading file: ${file.path}');
      debugPrint('[FilePreviewPage] File type: ${widget.fileType}');

      if (!file.existsSync()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final fileSize = file.lengthSync();
      debugPrint('[FilePreviewPage] File size: $fileSize bytes');

      if (fileSize == 0) {
        throw Exception('File is empty');
      }

      if (widget.fileType == FilePreviewType.csv) {
        final content = await file.readAsString();
        final lines = const LineSplitter().convert(content);
        _csvData = lines.map((line) => _parseCSVLine(line)).toList();
        setState(() => _isLoading = false);
      } else if (widget.fileType == FilePreviewType.pdf) {
        // Pre-load PDF bytes for faster rendering with retry mechanism
        int retries = 3;
        while (retries > 0) {
          try {
            _pdfBytes = await file.readAsBytes().timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw Exception('PDF file reading timed out'),
            );

            if (_pdfBytes == null || _pdfBytes!.isEmpty) {
              throw Exception('PDF file is empty after reading');
            }

            debugPrint(
              '[FilePreviewPage] PDF bytes loaded: ${_pdfBytes!.length}',
            );

            // Basic PDF validation - check magic bytes
            if (_pdfBytes!.length < 4 ||
                String.fromCharCodes(_pdfBytes!.take(4)) != '%PDF') {
              throw Exception('Invalid PDF file format');
            }

            debugPrint('[FilePreviewPage] PDF file validated successfully');
            break;
          } catch (e) {
            retries--;
            if (retries == 0) rethrow;
            debugPrint(
              '[FilePreviewPage] PDF loading failed, retrying... ($retries attempts left): $e',
            );
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        // Start rendering PDF pages
        setState(() {
          _isLoading = false;
          _isRenderingPdf = true;
          _renderingStatus = 'Preparing document...';
        });

        // Render PDF pages as images (more reliable than PdfPreview)
        await _renderPdfPages();
      }

      debugPrint('[FilePreviewPage] File loaded successfully');
    } catch (e, stack) {
      debugPrint('[FilePreviewPage] Error loading file: $e');
      debugPrint('[FilePreviewPage] Stack: $stack');
      setState(() {
        _isLoading = false;
        _isRenderingPdf = false;
        _errorMessage = 'Error loading file: $e';
      });
    }
  }

  Future<void> _loadFromBytes(Uint8List data) async {
    if (data.isEmpty) {
      throw Exception('Document is empty');
    }

    if (widget.fileType == FilePreviewType.csv) {
      final content = utf8.decode(data);
      final lines = const LineSplitter().convert(content);
      _csvData = lines.map((line) => _parseCSVLine(line)).toList();
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (data.length < 4 || String.fromCharCodes(data.take(4)) != '%PDF') {
      throw Exception('Invalid PDF file format');
    }

    _pdfBytes = data;
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRenderingPdf = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isRenderingPdf = true;
        _renderingStatus = 'Preparing document...';
      });
    }
    await _renderPdfPages();
  }

  /// Render PDF pages as images for reliable display
  Future<void> _renderPdfPages() async {
    if (_pdfBytes == null || _pdfBytes!.isEmpty) {
      setState(() {
        _isRenderingPdf = false;
        _errorMessage = 'PDF data not available for rendering';
      });
      return;
    }

    try {
      debugPrint('[FilePreviewPage] Starting PDF page rendering...');

      // Get screen width for optimal DPI calculation
      final screenWidth = MediaQuery.of(context).size.width;
      final dpi = (screenWidth * 1.5)
          .clamp(150, 300)
          .toDouble(); // Adaptive DPI

      // Collect all pages first to know total count
      final pages = <Uint8List>[];
      int pageCount = 0;
      bool timedOut = false;

      setState(() {
        _renderingStatus = 'Rendering pages...';
      });

      // Use Printing.raster to convert PDF pages to images with timeout
      try {
        await for (final page
            in Printing.raster(
              _pdfBytes!,
              pages: null, // Render all pages
              dpi: dpi,
            ).timeout(
              const Duration(seconds: 30),
              onTimeout: (sink) {
                debugPrint('[FilePreviewPage] PDF rendering timed out');
                timedOut = true;
                sink.close();
              },
            )) {
          // Convert raster page to PNG bytes
          final pngBytes = await page.toPng();
          pages.add(pngBytes);
          pageCount++;

          debugPrint('[FilePreviewPage] Rendered page $pageCount');

          if (mounted) {
            setState(() {
              _totalPages = pageCount;
              _pagesRendered = pageCount;
              _renderingStatus = 'Rendered page $pageCount';
              _renderedPages = List<Uint8List?>.from(pages);
            });
          }
        }
      } catch (e) {
        debugPrint('[FilePreviewPage] PDF rendering error: $e');
        if (pages.isEmpty) rethrow;
        // If we have some pages, continue with what we have
      }

      if (pages.isEmpty) {
        if (timedOut) {
          throw Exception('PDF rendering timed out. Please try again.');
        }
        throw Exception('No pages were rendered from PDF');
      }

      debugPrint('[FilePreviewPage] PDF rendering complete: $pageCount pages');

      if (mounted) {
        setState(() {
          _isRenderingPdf = false;
          _totalPages = pageCount;
          _renderedPages = pages.cast<Uint8List?>();
        });
      }
    } catch (e, stack) {
      debugPrint('[FilePreviewPage] Error rendering PDF pages: $e');
      debugPrint('[FilePreviewPage] Stack: $stack');

      if (mounted) {
        setState(() {
          _isRenderingPdf = false;
          _errorMessage = 'Failed to render PDF: $e';
        });
      }
    }
  }

  List<String> _parseCSVLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  String _downloadName(String extension) {
    final base = widget.fileName.trim().isEmpty ? 'report' : widget.fileName.trim();
    return base.toLowerCase().endsWith('.$extension') ? base : '$base.$extension';
  }

  Future<void> _shareBytes() async {
    final data = _pdfBytes ?? widget.bytes;
    if (data == null) {
      throw Exception('Document is not ready');
    }
    if (widget.fileType == FilePreviewType.pdf) {
      await Printing.sharePdf(
        bytes: data,
        filename: _downloadName('pdf'),
      );
      return;
    }
    downloadWebBytes(data, _downloadName('csv'), 'text/csv');
  }

  Future<void> _handleShare() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);
    try {
      if (widget.file == null) {
        await _shareBytes();
        return;
      }
      await Share.shareXFiles([
        XFile(widget.file!.path),
      ], subject: widget.fileName);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error sharing file: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  /// Share via WhatsApp - opens WhatsApp with customer number if available
  Future<void> _handleWhatsAppShare() async {
    if (_isSharingWhatsApp) return;

    setState(() => _isSharingWhatsApp = true);

    final customerPhone = widget.customerPhone;

    try {
      if (widget.file == null) {
        await _shareBytes();
        return;
      }
      // Check if file exists
      if (!await widget.file!.exists()) {
        _showSnackBar('File not found', isError: true);
        return;
      }

      // Show guidance message
      if (customerPhone != null && customerPhone.isNotEmpty) {
        _showSnackBar('Tap WhatsApp → Select "$customerPhone"', isError: false);
      }

      // Share file directly - this opens share sheet with file attached
      // User selects WhatsApp from sheet, then picks the contact
      await Share.shareXFiles(
        [XFile(widget.file!.path)],
        subject: widget.fileName,
        text: customerPhone != null && customerPhone.isNotEmpty
            ? 'Invoice for $customerPhone'
            : 'Invoice: ${widget.fileName}',
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error sharing: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingWhatsApp = false);
      }
    }
  }

  Future<void> _handlePrint() async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);
    try {
      if (widget.fileType == FilePreviewType.pdf) {
        final bytes = _pdfBytes ?? await widget.file!.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: widget.fileName,
        );
      } else {
        // For CSV, generate a simple PDF for printing
        await Printing.layoutPdf(
          onLayout: (format) async => await _generateCsvPdfForPrint(),
          name: widget.fileName,
        );
      }
      if (mounted) {
        _showSnackBar('Print job sent successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error printing: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  Future<Uint8List> _generateCsvPdfForPrint() async {
    final data = _csvData;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          if (data == null || data.isEmpty) {
            return pw.Text('No data');
          }
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                widget.fileName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                widget.subtitle ?? DateTime.now().toString().split('.').first,
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: data.first,
                data: data.length > 1 ? data.sublist(1) : const <List<String>>[],
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.green800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    GlassyToast.show(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        widget.presentedAsDialog ? _buildDialogHeader() : _buildHeader(),
        if (widget.fileType == FilePreviewType.csv) _buildZoomControls(),
        Expanded(
          child: ColoredBox(
            color: AppColors.scaffold(context),
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                ? _buildErrorState()
                : widget.fileType == FilePreviewType.pdf
                ? _buildPdfPreview()
                : _buildCsvPreview(),
          ),
        ),
        widget.presentedAsDialog ? _buildDialogFooter() : _buildBottomBar(),
      ],
    );

    if (widget.presentedAsDialog) return body;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(top: false, child: body),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(bottom: BorderSide(color: AppTheme.grey200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Zoom out
          _buildZoomButton(
            icon: Icons.remove_rounded,
            onPressed: _zoomLevel > _minZoom ? _zoomOut : null,
          ),
          SizedBox(width: 8),
          // Zoom level indicator
          GestureDetector(
            onTap: _resetZoom,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentSoft(context, 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 16,
                    color: AppColors.accent(context),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '${(_zoomLevel * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Zoom in
          _buildZoomButton(
            icon: Icons.add_rounded,
            onPressed: _zoomLevel < _maxZoom ? _zoomIn : null,
          ),
          const SizedBox(width: 16),
          // Reset button
          TextButton.icon(
            onPressed: _zoomLevel != 1.0 ? _resetZoom : null,
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text(
              'Reset',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: _zoomLevel != 1.0
                  ? AppColors.action(context)
                  : AppTheme.grey,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.action(context).withValues(alpha: 0.1)
                : AppTheme.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? AppColors.action(context) : AppTheme.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final typeLabel = widget.fileType == FilePreviewType.pdf ? 'PDF' : 'CSV';
    return AppTopBar(
      title: widget.fileName,
      subtitle: widget.subtitle ?? '$typeLabel · ${_getFileSizeString()}',
      onBack: () => widget._closePreview(context),
    );
  }

  String _getFileSizeString() {
    try {
      final bytes = widget.file?.lengthSync() ?? widget.bytes?.length ?? 0;
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return '';
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context, 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              color: AppColors.accent(context),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading document...',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.grey700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please wait',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              color: AppTheme.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                color: AppTheme.red,
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Unable to load preview',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.accent(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: AppTheme.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadFile();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action(context),
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    if (kIsWeb && _pdfBytes != null) {
      return buildWebPdfView(_pdfBytes!);
    }

    // Show rendering progress if still rendering
    if (_isRenderingPdf) {
      return _buildPdfRenderingProgress();
    }

    // If no pages rendered, show error
    if (_renderedPages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 48,
                color: AppTheme.orange700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PDF not rendered yet',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.grey700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to retry rendering',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: AppTheme.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isRenderingPdf = true;
                  _renderedPages.clear();
                  _pagesRendered = 0;
                });
                _renderPdfPages();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action(context),
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show rendered PDF pages in a scrollable list
    return Column(
      children: [
        // Page indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            border: Border(bottom: BorderSide(color: AppTheme.grey200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft(context, 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: AppColors.accent(context),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '$_totalPages ${_totalPages == 1 ? 'page' : 'pages'}',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // PDF Pages
        Expanded(
          child: Container(
            color: AppColors.chipFill(context),
            child: ListView.builder(
              controller: _pdfScrollController,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: _renderedPages.length,
              itemBuilder: (context, index) {
                final pageBytes = _renderedPages[index];
                if (pageBytes == null) {
                  return _buildPagePlaceholder(index + 1);
                }
                return _buildPdfPage(pageBytes, index + 1);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfRenderingProgress() {
    final progress = _totalPages > 0 ? _pagesRendered / _totalPages : 0.0;

    return Center(
      child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated PDF icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.action(context).withValues(alpha: 0.1),
                    AppTheme.paletteFF2D6A4F.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 40,
                color: AppColors.accent(context),
              ),
            ),
            SizedBox(height: 24),
            // Progress indicator
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _totalPages > 0 ? progress : null,
                      minHeight: 8,
                      backgroundColor: AppColors.border(context),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.action(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _totalPages > 0
                        ? 'Page $_pagesRendered of $_totalPages'
                        : _renderingStatus,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Rendering PDF...',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                color: AppTheme.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPage(Uint8List pageBytes, int pageNumber) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Page image
            Image.memory(
              pageBytes,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: AppColors.chipFill(context),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 32,
                          color: AppTheme.grey400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load page $pageNumber',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Page number footer
            Container(
              padding: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.scaffold(context),
                border: Border(top: BorderSide(color: AppTheme.grey200)),
              ),
              child: Center(
                child: Text(
                  'Page $pageNumber of $_totalPages',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: AppTheme.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagePlaceholder(int pageNumber) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.accent(context),
              strokeWidth: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'Loading page $pageNumber...',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                color: AppTheme.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCsvPreview() {
    if (_csvData == null || _csvData!.isEmpty) {
      return Center(
        child: Text(
          'No data to display',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            color: AppTheme.grey600,
          ),
        ),
      );
    }

    final headers = _csvData!.isNotEmpty ? _csvData![0] : <String>[];
    final dataRows = _csvData!.length > 1
        ? _csvData!.sublist(1)
        : <List<String>>[];
    final columnCount = headers.length;

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Excel-style toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.paletteFF217346, // Excel green
                border: Border(
                  bottom: BorderSide(color: AppTheme.paletteFF185C37),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.grid_on,
                      color: AppTheme.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fileName,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${dataRows.length} rows × $columnCount columns',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: AppColors.card(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sheet indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.table_rows_outlined,
                          size: 14,
                          color: AppTheme.paletteFF217346,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sheet1',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.paletteFF217346,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Excel-style spreadsheet
            Expanded(child: _buildExcelGrid(headers, dataRows, columnCount)),
          ],
        ),
      ),
    );
  }

  Widget _buildExcelGrid(
    List<String> headers,
    List<List<String>> dataRows,
    int columnCount,
  ) {
    final double rowNumberWidth = 50.0 * _zoomLevel;
    final double cellWidth = 120.0 * _zoomLevel;
    final double cellHeight = 32.0 * _zoomLevel;
    final double headerHeight = 28.0 * _zoomLevel;
    final double fontSize = 11.0 * _zoomLevel;
    final double headerFontSize = 11.0 * _zoomLevel;
    final double padding = 8.0 * _zoomLevel;

    final scrollControllerH = ScrollController();
    final scrollControllerV = ScrollController();

    return Column(
      children: [
        // Column letters header (A, B, C...)
        SizedBox(
          height: headerHeight,
          child: Row(
            children: [
              // Top-left corner cell
              Container(
                width: rowNumberWidth,
                height: headerHeight,
                decoration: BoxDecoration(
                  color: AppTheme.paletteFFE7E6E6,
                  border: Border(
                    right: BorderSide(color: AppTheme.paletteFFB4B4B4),
                    bottom: BorderSide(color: AppTheme.paletteFFB4B4B4),
                  ),
                ),
              ),
              // Column letters
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollControllerH,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(columnCount, (index) {
                      return Container(
                        width: cellWidth,
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: AppTheme.paletteFFE7E6E6,
                          border: Border(
                            right: BorderSide(color: AppTheme.paletteFFB4B4B4),
                            bottom: BorderSide(color: AppTheme.paletteFFB4B4B4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getColumnLetter(index),
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.paletteFF444444,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Data rows with row numbers
        Expanded(
          child: Row(
            children: [
              // Row numbers column (fixed)
              SizedBox(
                width: rowNumberWidth,
                child: ListView.builder(
                  controller: scrollControllerV,
                  itemCount: dataRows.length + 1, // +1 for header row
                  itemBuilder: (context, rowIndex) {
                    return Container(
                      width: rowNumberWidth,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        color: AppTheme.paletteFFE7E6E6,
                        border: Border(
                          right: BorderSide(color: AppTheme.paletteFFB4B4B4),
                          bottom: BorderSide(color: AppTheme.paletteFFD4D4D4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${rowIndex + 1}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.paletteFF444444,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Data cells
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      scrollControllerH.jumpTo(notification.metrics.pixels);
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: cellWidth * columnCount,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification) {
                            scrollControllerV.jumpTo(
                              notification.metrics.pixels,
                            );
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: dataRows.length + 1, // +1 for header row
                          itemBuilder: (context, rowIndex) {
                            final isHeader = rowIndex == 0;
                            final rowData = isHeader
                                ? headers
                                : dataRows[rowIndex - 1];
                            final isEvenRow = rowIndex % 2 == 0;

                            return SizedBox(
                              height: cellHeight,
                              child: Row(
                                children: List.generate(columnCount, (
                                  colIndex,
                                ) {
                                  final cellData = colIndex < rowData.length
                                      ? rowData[colIndex]
                                      : '';
                                  return Container(
                                    width: cellWidth,
                                    height: cellHeight,
                                    decoration: BoxDecoration(
                                      color: isHeader
                                          ? AppTheme.paletteFFF3F3F3
                                          : isEvenRow
                                          ? AppTheme.white
                                          : AppTheme.grey50,
                                      border: Border(
                                        right: BorderSide(
                                          color: AppTheme.grey300,
                                        ),
                                        bottom: BorderSide(
                                          color: AppTheme.grey300,
                                        ),
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      cellData,
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: fontSize,
                                        fontWeight: isHeader
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isHeader
                                            ? AppColors.action(context)
                                            : AppTheme.paletteFF333333,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.chipFill(context),
            border: Border(top: BorderSide(color: AppTheme.paletteFFD4D4D4)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 14,
                color: AppTheme.green700,
              ),
              const SizedBox(width: 6),
              Text(
                'Ready',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  color: AppTheme.grey600,
                ),
              ),
              const Spacer(),
              Text(
                'Σ Sum: ${dataRows.length} rows',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  color: AppTheme.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getColumnLetter(int index) {
    String result = '';
    int temp = index;
    while (temp >= 0) {
      result = String.fromCharCode(65 + (temp % 26)) + result;
      temp = (temp ~/ 26) - 1;
    }
    return result;
  }

  Widget _buildDialogHeader() {
    final isPdf = widget.fileType == FilePreviewType.pdf;
    final detail = widget.subtitle ??
        '${isPdf ? 'PDF' : 'CSV'} · ${_getFileSizeString()}';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context, 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf_outlined : Icons.table_chart_outlined,
              color: AppColors.action(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 13,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => widget._closePreview(context),
            tooltip: 'Close',
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogFooter() {
    final hasPhone =
        widget.customerPhone != null && widget.customerPhone!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          Text(
            _getFileSizeString(),
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 12,
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (hasPhone) ...[
            TextButton.icon(
              onPressed: _isSharingWhatsApp ? null : _handleWhatsAppShare,
              icon: _isSharingWhatsApp
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.paletteFF25D366,
                      ),
                    )
                  : FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: 16,
                      color: AppTheme.paletteFF25D366,
                    ),
              label: Text(
                'WhatsApp',
                style: TextStyle(
                  color: AppTheme.paletteFF25D366,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton.icon(
            onPressed: _isSharing ? null : _handleShare,
            icon: _isSharing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.action(context),
                    ),
                  )
                : Icon(Icons.download_rounded, size: 18),
            label: const Text(
              'Download',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryText(context),
              side: BorderSide(color: AppColors.border(context)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _isPrinting ? null : _handlePrint,
            icon: _isPrinting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  )
                : const Icon(Icons.print_rounded, size: 18),
            label: const Text(
              'Print',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.action(context),
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Share button
          Expanded(
            child: _buildActionButton(
              icon: Icons.share_rounded,
              label: 'Share',
              isLoading: _isSharing,
              onPressed: _handleShare,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 10),
          // WhatsApp button
          Expanded(child: _buildWhatsAppButton()),
          const SizedBox(width: 10),
          // Print button
          Expanded(
            child: _buildActionButton(
              icon: Icons.print_rounded,
              label: 'Print',
              isLoading: _isPrinting,
              onPressed: _handlePrint,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppButton() {
    final hasCustomerPhone =
        widget.customerPhone != null && widget.customerPhone!.isNotEmpty;

    return ElevatedButton(
      onPressed: _isSharingWhatsApp ? null : _handleWhatsAppShare,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.paletteFF25D366,
        foregroundColor: AppTheme.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSharingWhatsApp
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    hasCustomerPhone ? 'Send' : 'WhatsApp',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.action(context) : AppTheme.white,
        foregroundColor: isPrimary ? AppTheme.white : AppColors.action(context),
        elevation: isPrimary ? 2 : 0,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPrimary
              ? BorderSide.none
              : BorderSide(color: AppColors.accent(context), width: 1.5),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isPrimary ? AppTheme.white : AppColors.action(context),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

/// File type for preview
enum FilePreviewType { pdf, csv }
