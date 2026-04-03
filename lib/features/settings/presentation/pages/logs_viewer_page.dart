import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:c_billing/core/services/app_logger.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

class LogsViewerPage extends StatefulWidget {
  const LogsViewerPage({super.key});

  @override
  State<LogsViewerPage> createState() => _LogsViewerPageState();
}

class _LogsViewerPageState extends State<LogsViewerPage> {
  final _logger = AppLogger();
  final _searchController = TextEditingController();
  late AppLocalizations _localizations;
  List<LogEntry> _displayedLogs = [];
  LogLevel? _filterLevel;
  bool _autoScroll = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _displayedLogs = _logger.logs;

    // Listen to new logs
    _logger.logStream.listen((_) {
      if (mounted) {
        setState(() {
          _applyFilters();
        });
        if (_autoScroll && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    var logs = _logger.logs;

    // Filter by level
    if (_filterLevel != null) {
      logs = logs.where((log) => log.level == _filterLevel).toList();
    }

    // Filter by search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      logs = logs.where((log) {
        return log.tag.toLowerCase().contains(query) ||
            log.message.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _displayedLogs = logs;
    });
  }

  Future<void> _shareLogs() async {
    try {
      final logsText = _logger.exportLogs();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'c_billing_logs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(logsText);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: _localizations.cBillingAppLogs,
        text: _localizations.appLogsExported,
      );
    } catch (e) {
      if (mounted) {
        GlassyToast.show(context, '${_localizations.errorSharingLogs}: $e', isError: true);
      }
    }
  }

  void _copyToClipboard() {
    final logsText = _logger.exportLogs();
    Clipboard.setData(ClipboardData(text: logsText));
    GlassyToast.show(context, _localizations.logsCopied);
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _localizations.clearLogsConfirm,
          style: TextStyle(fontFamily: 'Literata'),
        ),
        content: Text(
          _localizations.clearLogsMessage,
          style: TextStyle(fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _localizations.cancel,
              style: TextStyle(fontFamily: 'Literata'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _logger.clear();
              setState(() {
                _displayedLogs = [];
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _localizations.clear,
              style: TextStyle(fontFamily: 'Literata'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _localizations.appLogs,
          style: TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Auto-scroll toggle
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.arrow_downward
                  : Icons.arrow_downward_outlined,
            ),
            tooltip: _autoScroll
                ? _localizations.disableAutoScroll
                : _localizations.enableAutoScroll,
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),
          // Copy
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: _localizations.copyLogs,
            onPressed: _copyToClipboard,
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: _localizations.shareLogs,
            onPressed: _shareLogs,
          ),
          // Clear
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: _localizations.clearLogs,
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats + Filter bar
          Container(
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
                // Stats
                Row(
                  children: [
                    _buildStatChip(
                      _localizations.total,
                      _logger.logs.length,
                      Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      _localizations.debug,
                      _logger.getLogsByLevel(LogLevel.debug).length,
                      Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      _localizations.info,
                      _logger.getLogsByLevel(LogLevel.info).length,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      _localizations.warn,
                      _logger.getLogsByLevel(LogLevel.warning).length,
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      _localizations.error,
                      _logger.getLogsByLevel(LogLevel.error).length,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search + Filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _applyFilters(),
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: _localizations.searchLogs,
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Level filter dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<LogLevel?>(
                        value: _filterLevel,
                        hint: Text(
                          _localizations.level,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 13,
                          ),
                        ),
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              _localizations.all,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ...LogLevel.values.map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(
                                level.name.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterLevel = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Logs list
          Expanded(
            child: _displayedLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _localizations.noLogsToDisplay,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _displayedLogs.length,
                    itemBuilder: (context, index) {
                      final log = _displayedLogs[index];
                      return _buildLogCard(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(LogEntry log) {
    final color = _getLevelColor(log.level);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(log.levelIcon, style: const TextStyle(fontSize: 16)),
          ),
        ),
        title: Text(
          log.tag,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              log.message,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              log.formattedTimestamp,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  log.message,
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 12),
                ),
                if (log.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_localizations.error}:',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    log.error.toString(),
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  ),
                ],
                if (log.stackTrace != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_localizations.stackTrace}:',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    log.stackTrace.toString().split('\n').take(10).join('\n'),
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 10,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
