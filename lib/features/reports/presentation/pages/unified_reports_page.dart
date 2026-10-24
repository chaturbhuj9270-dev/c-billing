import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/common_widgets/file_preview_page.dart';
import 'package:c_billing/common_widgets/range_calendar_sheet.dart';
import 'package:c_billing/core/access/access_control_service.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

import '../../data/services/unified_report_data_service.dart';
import '../../data/services/unified_report_export_service.dart';
import '../../domain/models/unified_report_kind.dart';

/// Common Reports hub — generate PDF or Excel for every major module.
class UnifiedReportsPage extends StatefulWidget {
  final bool isEmbedded;

  const UnifiedReportsPage({super.key, this.isEmbedded = false});

  @override
  State<UnifiedReportsPage> createState() => _UnifiedReportsPageState();
}

class _UnifiedReportsPageState extends State<UnifiedReportsPage> {
  UnifiedReportKind? _selected;
  UnifiedExportFormat _format = UnifiedExportFormat.pdf;
  int _preset = 2; // This month
  DateTimeRange _range = _thisMonth();
  bool _generating = false;

  static DateTimeRange _thisMonth() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  List<UnifiedReportKind> get _allowedKinds {
    final access = AccessControlService.instance;
    return UnifiedReportKind.values
        .where((k) => access.canAccess(k.requiredModule))
        .toList();
  }

  String get _rangeLabel {
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(_range.start)} – ${fmt.format(_range.end)}';
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showAppRangeCalendar(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preset = 4;
      _range = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        ),
      );
    });
  }

  void _applyPreset(int index) {
    final now = DateTime.now();
    late DateTimeRange range;
    switch (index) {
      case 0: // Today
        range = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      case 1: // This week (Mon–today)
        final weekday = now.weekday;
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
        range = DateTimeRange(
          start: start,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      case 2: // This month
        range = _thisMonth();
        break;
      case 3: // This year
        range = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      default:
        _pickCustomRange();
        return;
    }
    setState(() {
      _preset = index;
      _range = range;
    });
  }

  Future<void> _generate() async {
    final kind = _selected;
    if (kind == null) {
      GlassyToast.show(context, 'Select a report type first', isError: true);
      return;
    }
    if (_generating) return;
    setState(() => _generating = true);
    GlassyToast.show(
      context,
      'Preparing ${kind.title} (${_format.label})…',
      icon: Icons.hourglass_top_rounded,
    );

    try {
      final table = await UnifiedReportDataService.instance.build(
        kind: kind,
        start: _range.start,
        end: _range.end,
      );
      final result = await UnifiedReportExportService.instance.export(
        table: table,
        format: _format,
      );

      if (!mounted) return;
      GlassyToast.dismiss();

      final isPdf = _format == UnifiedExportFormat.pdf;
      File? file;
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        file = File('${dir.path}/${result.fileName}');
        await file.writeAsBytes(result.bytes, flush: true);
      }
      if (!mounted) return;

      await FilePreviewPage.open(
        context,
        file: file,
        bytes: result.bytes,
        fileName: result.fileName,
        fileType: isPdf ? FilePreviewType.pdf : FilePreviewType.csv,
        subtitle: table.filterDescription,
        details: FilePreviewDetails(
          title: 'Report preview',
          documentNo: table.title,
          dateLabel: table.filterDescription,
          itemsQty: '${table.rows.length} rows',
          amount: table.summaryLine,
        ),
      );
    } catch (e, st) {
      debugPrint('[UnifiedReports] generate failed: $e\n$st');
      if (mounted) {
        GlassyToast.dismiss();
        GlassyToast.show(
          context,
          'Could not generate report: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kinds = _allowedKinds;
    final muted = AppColors.mutedText(context);
    final action = AppColors.action(context);

    final list = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(
          '1. Choose report',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 10),
        if (kinds.isEmpty)
          Text(
            'No report modules available for this account.',
            style: TextStyle(fontFamily: 'Literata', color: muted),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final k in kinds)
                _ReportTypeChip(
                  kind: k,
                  selected: _selected == k,
                  onTap: () => setState(() => _selected = k),
                ),
            ],
          ),
        const SizedBox(height: 22),
        Text(
          '2. Period',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        if (_selected?.usesDateRange ?? true) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in [
                (0, 'Today'),
                (1, 'This week'),
                (2, 'This month'),
                (3, 'This year'),
                (4, 'Custom'),
              ])
                ChoiceChip(
                  label: Text(
                    e.$2,
                    style: const TextStyle(fontFamily: 'Literata'),
                  ),
                  selected: _preset == e.$1,
                  onSelected: (_) => _applyPreset(e.$1),
                  selectedColor: action.withValues(alpha: 0.2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _rangeLabel,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: muted,
            ),
          ),
        ] else
          Text(
            'Snapshot report — date range not required.',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: muted,
            ),
          ),
        const SizedBox(height: 22),
        Text(
          '3. Format',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < UnifiedExportFormat.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _FormatCard(
                  format: UnifiedExportFormat.values[i],
                  selected: _format == UnifiedExportFormat.values[i],
                  onTap: () => setState(
                    () => _format = UnifiedExportFormat.values[i],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _generating || kinds.isEmpty || _selected == null
                ? null
                : _generate,
            style: FilledButton.styleFrom(
              backgroundColor: action,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  )
                : Icon(_format.icon, size: 20),
            label: Text(
              _generating
                  ? 'Generating…'
                  : 'Generate ${_format.label} report',
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Existing module Download buttons still work as before. '
          'This hub centralises exports without replacing them.',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            color: muted,
          ),
        ),
      ],
    );

    if (widget.isEmbedded) return list;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          AppTopBar(
            title: 'Reports',
            subtitle: 'PDF and Excel for every module',
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }
}

class _ReportTypeChip extends StatelessWidget {
  final UnifiedReportKind kind;
  final bool selected;
  final VoidCallback onTap;

  const _ReportTypeChip({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 168,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? kind.color.withValues(alpha: 0.14)
                : AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kind.color : AppColors.border(context),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(kind.icon, color: kind.color, size: 22),
              const SizedBox(height: 8),
              Text(
                kind.title,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primaryText(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                kind.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  color: AppColors.mutedText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final UnifiedExportFormat format;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final action = AppColors.action(context);
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? action.withValues(alpha: 0.14)
                : AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? action : AppColors.border(context),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                format.icon,
                color: selected ? action : AppColors.mutedText(context),
              ),
              const SizedBox(height: 6),
              Text(
                format.label,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primaryText(context)
                      : AppColors.mutedText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
