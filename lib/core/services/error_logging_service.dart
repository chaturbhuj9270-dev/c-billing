import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

/// Service for logging and collecting UI/Flutter errors
class ErrorLoggingService {
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  
  factory ErrorLoggingService() => _instance;
  
  ErrorLoggingService._internal();
  
  static ErrorLoggingService get instance => _instance;
  
  /// List of collected error logs
  final List<ErrorLog> _errorLogs = [];
  
  /// Maximum number of logs to keep
  static const int _maxLogs = 100;
  
  /// Get all error logs
  List<ErrorLog> get errorLogs => List.unmodifiable(_errorLogs);
  
  /// Get logs as a formatted string
  String getLogsAsString() {
    if (_errorLogs.isEmpty) {
      return 'No errors logged.';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('=== C-BILLING ERROR LOG ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Errors: ${_errorLogs.length}');
    buffer.writeln('');
    
    for (int i = 0; i < _errorLogs.length; i++) {
      final log = _errorLogs[i];
      buffer.writeln('--- Error ${i + 1} ---');
      buffer.writeln('Time: ${log.timestamp.toIso8601String()}');
      buffer.writeln('Type: ${log.errorType}');
      buffer.writeln('Message: ${log.message}');
      if (log.stackTrace != null) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(log.stackTrace);
      }
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
  
  /// Log a Flutter error
  void logFlutterError(FlutterErrorDetails details) {
    final log = ErrorLog(
      timestamp: DateTime.now(),
      errorType: 'FlutterError',
      message: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
      context: details.context?.toString(),
    );
    _addLog(log);
    
    // Also print to console in debug mode
    if (kDebugMode) {
      print('[ErrorLogging] Flutter Error: ${details.exceptionAsString()}');
    }
  }
  
  /// Log a general error
  void logError(String errorType, dynamic error, [StackTrace? stackTrace]) {
    final log = ErrorLog(
      timestamp: DateTime.now(),
      errorType: errorType,
      message: error.toString(),
      stackTrace: stackTrace?.toString(),
    );
    _addLog(log);
    
    if (kDebugMode) {
      print('[ErrorLogging] $errorType: $error');
    }
  }
  
  /// Log a UI overflow or rendering error
  void logUIError(String message, [String? details]) {
    final log = ErrorLog(
      timestamp: DateTime.now(),
      errorType: 'UIError',
      message: message,
      context: details,
    );
    _addLog(log);
    
    if (kDebugMode) {
      print('[ErrorLogging] UI Error: $message');
    }
  }
  
  void _addLog(ErrorLog log) {
    _errorLogs.add(log);
    
    // Keep only the last N logs
    while (_errorLogs.length > _maxLogs) {
      _errorLogs.removeAt(0);
    }
  }
  
  /// Clear all logs
  void clearLogs() {
    _errorLogs.clear();
  }
  
  /// Copy logs to clipboard
  Future<void> copyLogsToClipboard() async {
    final logsString = getLogsAsString();
    await Clipboard.setData(ClipboardData(text: logsString));
  }

  /// Share logs as a .txt file
  Future<void> shareLogsAsFile() async {
    try {
      final logsString = getLogsAsString();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${tempDir.path}/c_billing_logs_$timestamp.txt');
      await file.writeAsString(logsString);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'C-Billing Error Logs',
        text: 'Error logs from C-Billing app',
      );
    } catch (e) {
      print('[ErrorLogging] Error sharing logs: $e');
      // Fallback to sharing text directly
      final logsString = getLogsAsString();
      await Share.share(logsString, subject: 'C-Billing Error Logs');
    }
  }

  /// Initialize global error handling
  static void initialize() {
    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorLoggingService.instance.logFlutterError(details);
      
      // Also use default handler to show error in debug mode
      FlutterError.presentError(details);
    };
    
    // Capture async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorLoggingService.instance.logError('AsyncError', error, stack);
      return true;
    };
    
    print('[ErrorLogging] Error logging service initialized');
  }
  
  /// Show a dialog to view and copy logs
  static void showLogsDialog(BuildContext context) {
    final logs = ErrorLoggingService.instance.getLogsAsString();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bug_report, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Error Logs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              logs,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          // Left side - Clear button
          TextButton(
            onPressed: () {
              ErrorLoggingService.instance.clearLogs();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logs cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          // Right side - Share and Copy buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Share button
              TextButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await ErrorLoggingService.instance.shareLogsAsFile();
                },
                icon: const Icon(Icons.share, size: 16, color: Color(0xFF1976D2)),
                label: const Text(
                  'Share',
                  style: TextStyle(color: Color(0xFF1976D2), fontSize: 13),
                ),
              ),
              // Copy button
              TextButton.icon(
                onPressed: () async {
                  await ErrorLoggingService.instance.copyLogsToClipboard();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logs copied to clipboard'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 16, color: Color(0xFF1B4D3E)),
                label: const Text(
                  'Copy',
                  style: TextStyle(color: Color(0xFF1B4D3E), fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ErrorLog {
  final DateTime timestamp;
  final String errorType;
  final String message;
  final String? stackTrace;
  final String? context;
  
  ErrorLog({
    required this.timestamp,
    required this.errorType,
    required this.message,
    this.stackTrace,
    this.context,
  });
  
  @override
  String toString() {
    return '[$timestamp] $errorType: $message';
  }
}
