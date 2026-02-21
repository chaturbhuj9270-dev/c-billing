import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';

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
  final File file;
  final String fileName;
  final FilePreviewType fileType;
  final String? subtitle;
  final VoidCallback? onClose;

  const FilePreviewPage({
    super.key,
    required this.file,
    required this.fileName,
    required this.fileType,
    this.subtitle,
    this.onClose,
  });

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  bool _isLoading = true;
  bool _isSharing = false;
  bool _isPrinting = false;
  List<List<String>>? _csvData;
  String? _errorMessage;
  Uint8List? _pdfBytes; // Pre-loaded PDF bytes
  
  // Zoom controls
  double _zoomLevel = 1.0;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.25;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _transformationController.dispose();
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
    _transformationController.value = Matrix4.identity()..scale(_zoomLevel);
  }

  Future<void> _loadFile() async {
    try {
      debugPrint('[FilePreviewPage] Loading file: ${widget.file.path}');
      debugPrint('[FilePreviewPage] File type: ${widget.fileType}');
      
      // Check if file exists
      if (!widget.file.existsSync()) {
        throw Exception('File does not exist: ${widget.file.path}');
      }
      
      final fileSize = widget.file.lengthSync();
      debugPrint('[FilePreviewPage] File size: $fileSize bytes');
      
      if (fileSize == 0) {
        throw Exception('File is empty');
      }
      
      if (widget.fileType == FilePreviewType.csv) {
        final content = await widget.file.readAsString();
        final lines = const LineSplitter().convert(content);
        _csvData = lines.map((line) => _parseCSVLine(line)).toList();
      } else if (widget.fileType == FilePreviewType.pdf) {
        // Pre-load PDF bytes for faster rendering with retry mechanism
        int retries = 3;
        while (retries > 0) {
          try {
            _pdfBytes = await widget.file.readAsBytes().timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw Exception('PDF file reading timed out'),
            );
            
            if (_pdfBytes == null || _pdfBytes!.isEmpty) {
              throw Exception('PDF file is empty after reading');
            }
            
            debugPrint('[FilePreviewPage] PDF bytes loaded: ${_pdfBytes!.length}');
            
            // Basic PDF validation - check magic bytes
            if (_pdfBytes!.length < 4 || 
                String.fromCharCodes(_pdfBytes!.take(4)) != '%PDF') {
              throw Exception('Invalid PDF file format');
            }
            
            // Additional PDF validation - check for PDF trailer
            final pdfString = String.fromCharCodes(_pdfBytes!);
            if (!pdfString.contains('%%EOF')) {
              throw Exception('Incomplete PDF file - missing EOF marker');
            }
            
            debugPrint('[FilePreviewPage] PDF file validated successfully');
            break;
          } catch (e) {
            retries--;
            if (retries == 0) rethrow;
            debugPrint('[FilePreviewPage] PDF loading failed, retrying... ($retries attempts left): $e');
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      
      setState(() => _isLoading = false);
      debugPrint('[FilePreviewPage] File loaded successfully');
    } catch (e, stack) {
      debugPrint('[FilePreviewPage] Error loading file: $e');
      debugPrint('[FilePreviewPage] Stack: $stack');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading file: $e';
      });
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

  Future<void> _handleShare() async {
    if (_isSharing) return;
    
    setState(() => _isSharing = true);
    try {
      await Share.shareXFiles(
        [XFile(widget.file.path)],
        subject: widget.fileName,
      );
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

  Future<void> _handlePrint() async {
    if (_isPrinting) return;
    
    setState(() => _isPrinting = true);
    try {
      if (widget.fileType == FilePreviewType.pdf) {
        final bytes = await widget.file.readAsBytes();
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
    // Use pdf package to create a simple table from CSV
    final pdf = await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: _generateHtmlFromCsv(),
    );
    return pdf;
  }

  String _generateHtmlFromCsv() {
    if (_csvData == null || _csvData!.isEmpty) return '<p>No data</p>';
    
    final buffer = StringBuffer();
    buffer.writeln('''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; padding: 20px; }
    h1 { color: #1B4D3E; font-size: 18px; margin-bottom: 5px; }
    h2 { color: #666; font-size: 12px; margin-bottom: 20px; font-weight: normal; }
    table { width: 100%; border-collapse: collapse; font-size: 10px; }
    th { background-color: #1B4D3E; color: white; padding: 8px; text-align: left; }
    td { padding: 6px 8px; border-bottom: 1px solid #ddd; }
    tr:nth-child(even) { background-color: #f9f9f9; }
  </style>
</head>
<body>
  <h1>${widget.fileName}</h1>
  <h2>${widget.subtitle ?? DateTime.now().toString().split('.')[0]}</h2>
  <table>
''');

    // Headers
    if (_csvData!.isNotEmpty) {
      buffer.writeln('<tr>');
      for (final header in _csvData![0]) {
        buffer.writeln('<th>${_escapeHtml(header)}</th>');
      }
      buffer.writeln('</tr>');
    }

    // Data rows
    for (var i = 1; i < _csvData!.length; i++) {
      buffer.writeln('<tr>');
      for (final cell in _csvData![i]) {
        buffer.writeln('<td>${_escapeHtml(cell)}</td>');
      }
      buffer.writeln('</tr>');
    }

    buffer.writeln('''
  </table>
</body>
</html>
''');
    return buffer.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Literata'),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B4D3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildZoomControls(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : widget.fileType == FilePreviewType.pdf
                          ? _buildPdfPreview()
                          : _buildCsvPreview(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Zoom out
          _buildZoomButton(
            icon: Icons.remove_rounded,
            onPressed: _zoomLevel > _minZoom ? _zoomOut : null,
          ),
          const SizedBox(width: 8),
          // Zoom level indicator
          GestureDetector(
            onTap: _resetZoom,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 16,
                    color: const Color(0xFF1B4D3E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(_zoomLevel * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B4D3E),
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
                  ? const Color(0xFF1B4D3E)
                  : Colors.grey,
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEnabled 
                ? const Color(0xFF1B4D3E).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? const Color(0xFF1B4D3E) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              widget.onClose?.call();
              Navigator.of(context).pop();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF1B4D3E),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4D3E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  )
                else
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.fileType == FilePreviewType.pdf
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.fileType == FilePreviewType.pdf ? 'PDF' : 'CSV',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.fileType == FilePreviewType.pdf
                                ? Colors.red[700]
                                : Colors.green[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getFileSizeString(),
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFileSizeString() {
    try {
      final bytes = widget.file.lengthSync();
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF1B4D3E),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading preview...',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 14,
              color: Colors.grey[600],
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load preview',
              style: const TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: Colors.grey[600],
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
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    // If PDF bytes not loaded, show error
    if (_pdfBytes == null || _pdfBytes!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'PDF data not available',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: _minZoom,
          maxScale: _maxZoom,
          onInteractionUpdate: (details) {
            final scale = _transformationController.value.getMaxScaleOnAxis();
            if ((scale - _zoomLevel).abs() > 0.01) {
              setState(() => _zoomLevel = scale.clamp(_minZoom, _maxZoom));
            }
          },
          child: PdfPreview(
            build: (format) async => _pdfBytes!,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            pdfFileName: widget.fileName,
            loadingWidget: _buildLoadingState(),
            scrollViewDecoration: const BoxDecoration(color: Colors.white),
            pdfPreviewPageDecoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
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
            color: Colors.grey[600],
          ),
        ),
      );
    }

    final headers = _csvData!.isNotEmpty ? _csvData![0] : <String>[];
    final dataRows = _csvData!.length > 1 ? _csvData!.sublist(1) : <List<String>>[];
    final columnCount = headers.length;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                color: const Color(0xFF217346), // Excel green
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF185C37),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.grid_on,
                      color: Colors.white,
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
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${dataRows.length} rows × ${columnCount} columns',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sheet indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.table_rows_outlined, size: 14, color: const Color(0xFF217346)),
                        const SizedBox(width: 4),
                        Text(
                          'Sheet1',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF217346),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Excel-style spreadsheet
            Expanded(
              child: _buildExcelGrid(headers, dataRows, columnCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcelGrid(List<String> headers, List<List<String>> dataRows, int columnCount) {
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
                  color: const Color(0xFFE7E6E6),
                  border: Border(
                    right: BorderSide(color: const Color(0xFFB4B4B4)),
                    bottom: BorderSide(color: const Color(0xFFB4B4B4)),
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
                          color: const Color(0xFFE7E6E6),
                          border: Border(
                            right: BorderSide(color: const Color(0xFFB4B4B4)),
                            bottom: BorderSide(color: const Color(0xFFB4B4B4)),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getColumnLetter(index),
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF444444),
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
                        color: const Color(0xFFE7E6E6),
                        border: Border(
                          right: BorderSide(color: const Color(0xFFB4B4B4)),
                          bottom: BorderSide(color: const Color(0xFFD4D4D4)),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${rowIndex + 1}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF444444),
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
                            scrollControllerV.jumpTo(notification.metrics.pixels);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: dataRows.length + 1, // +1 for header row
                          itemBuilder: (context, rowIndex) {
                            final isHeader = rowIndex == 0;
                            final rowData = isHeader ? headers : dataRows[rowIndex - 1];
                            final isEvenRow = rowIndex % 2 == 0;

                            return SizedBox(
                              height: cellHeight,
                              child: Row(
                                children: List.generate(columnCount, (colIndex) {
                                  final cellData = colIndex < rowData.length ? rowData[colIndex] : '';
                                  return Container(
                                    width: cellWidth,
                                    height: cellHeight,
                                    decoration: BoxDecoration(
                                      color: isHeader
                                          ? const Color(0xFFF3F3F3)
                                          : isEvenRow
                                              ? Colors.white
                                              : const Color(0xFFFAFAFA),
                                      border: Border(
                                        right: BorderSide(color: const Color(0xFFE0E0E0)),
                                        bottom: BorderSide(color: const Color(0xFFE0E0E0)),
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: padding),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      cellData,
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: fontSize,
                                        fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                                        color: isHeader ? const Color(0xFF1B4D3E) : const Color(0xFF333333),
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
            color: const Color(0xFFF3F3F3),
            border: Border(
              top: BorderSide(color: const Color(0xFFD4D4D4)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: Colors.green[700]),
              const SizedBox(width: 6),
              Text(
                'Ready',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                'Σ Sum: ${dataRows.length} rows',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  color: Colors.grey[600],
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

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
          const SizedBox(width: 12),
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
        backgroundColor: isPrimary ? const Color(0xFF1B4D3E) : Colors.white,
        foregroundColor: isPrimary ? Colors.white : const Color(0xFF1B4D3E),
        elevation: isPrimary ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isPrimary ? Colors.white : const Color(0xFF1B4D3E),
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
enum FilePreviewType {
  pdf,
  csv,
}
