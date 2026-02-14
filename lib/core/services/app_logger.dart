import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Log entry level
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// A single log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String get formattedTimestamp => DateFormat('HH:mm:ss.SSS').format(timestamp);

  String get levelIcon {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.write('[$formattedTimestamp] $levelIcon [$tag] $message');
    if (error != null) {
      buffer.write('\n  Error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n  Stack: ${stackTrace.toString().split('\n').take(5).join('\n  ')}');
    }
    return buffer.toString();
  }
}

/// Centralized app logger with in-memory storage
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  final _logs = Queue<LogEntry>();
  static const _maxLogs = 1000;
  final _controller = StreamController<LogEntry>.broadcast();

  /// Stream of log entries
  Stream<LogEntry> get logStream => _controller.stream;

  /// Get all logs
  List<LogEntry> get logs => _logs.toList();

  /// Get logs filtered by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get logs filtered by tag
  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag.toLowerCase().contains(tag.toLowerCase())).toList();
  }

  /// Clear all logs
  void clear() {
    _logs.clear();
  }

  void _addLog(LogEntry entry) {
    if (_logs.length >= _maxLogs) {
      _logs.removeFirst();
    }
    _logs.add(entry);
    _controller.add(entry);
    
    // Also print to console
    if (kDebugMode) {
      print(entry.toFormattedString());
    }
  }

  /// Log debug message
  void debug(String tag, String message) {
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.debug,
      tag: tag,
      message: message,
    ));
  }

  /// Log info message
  void info(String tag, String message) {
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      tag: tag,
      message: message,
    ));
  }

  /// Log warning message
  void warning(String tag, String message, {Object? error}) {
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.warning,
      tag: tag,
      message: message,
      error: error,
    ));
  }

  /// Log error message
  void error(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    ));
  }

  /// Export logs as formatted text
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('='.padRight(80, '='));
    buffer.writeln('C-BILLING APP LOGS');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('Total Entries: ${_logs.length}');
    buffer.writeln('='.padRight(80, '='));
    buffer.writeln();
    
    for (final log in _logs) {
      buffer.writeln(log.toFormattedString());
      buffer.writeln('-'.padRight(80, '-'));
    }
    
    return buffer.toString();
  }

  void dispose() {
    _controller.close();
  }
}
