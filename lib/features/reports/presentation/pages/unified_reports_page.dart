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
import 'package:c_billing/core/ui/desktop_canvas.dart';
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
  UnifiedReportCategory? _categoryFilter; // null = All
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static DateTimeRange _thisMonth() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  @override
  void initState() {
    super.initState();
    final kinds = _allowedKinds;
    if (kinds.isNotEmpty) {
      _selected = kinds.first;
    }
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UnifiedReportKind> get _allowedKinds {
    final access = AccessControlService.instance;
    return UnifiedReportKind.values
        .where((k) => access.canAccess(k.requiredModule))
        .toList();
  }

  List<UnifiedReportKind> get _filteredKinds {
    return _allowedKinds.where((k) {
      if (_categoryFilter != null && k.category != _categoryFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      return k.title.toLowerCase().contains(_searchQuery) ||
          k.subtitle.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  String get _rangeLabel {
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(_range.start)} – ${fmt.format(_range.end)}';
  }

  String get _shortRangeLabel {
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(_range.start)} - ${fmt.format(_range.end)}';
  }

  String get _statusSummary {
    final kind = _selected;
    if (kind == null) return 'Select a report to continue';
    final period = kind.usesDateRange ? _shortRangeLabel : 'Snapshot';
    return '${kind.title} · $period · ${_format.label}';
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

  bool get _useSplitLayout {
    if (!DesktopCanvas.isDesktopPlatform && !widget.isEmbedded) {
      return MediaQuery.sizeOf(context).width >= 900;
    }
    return MediaQuery.sizeOf(context).width >= 860;
  }

  @override
  Widget build(BuildContext context) {
    final body = _useSplitLayout ? _buildSplitLayout() : _buildPhoneLayout();

    if (widget.isEmbedded) {
      return ColoredBox(
        color: AppColors.scaffold(context),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          AppTopBar(
            title: 'Business reports',
            subtitle: 'PDF and Excel for every module',
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildSplitLayout() {
    return Column(
      children: [
        if (widget.isEmbedded) _buildEmbeddedHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 360,
                child: _buildChooserPanel(scrollable: true),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.border(context),
              ),
              Expanded(child: _buildConfigPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (widget.isEmbedded) ...[
          _buildEmbeddedHeader(compact: true),
          const SizedBox(height: 8),
        ],
        _buildChooserPanel(scrollable: false),
        const SizedBox(height: 20),
        _buildConfigBody(),
        const SizedBox(height: 20),
        _buildActionButtons(fullWidth: true),
      ],
    );
  }

  Widget _buildEmbeddedHeader({bool compact = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, compact ? 12 : 18, 20, compact ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business reports',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: compact ? 22 : 26,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PDF and Excel for every module.',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: AppColors.mutedText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChooserPanel({required bool scrollable}) {
    final kinds = _filteredKinds;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isEmbedded || !scrollable)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Choose report',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
        if (widget.isEmbedded && scrollable)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Choose report',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: scrollable ? 20 : 0),
          child: _buildSearchField(),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: scrollable ? 20 : 0),
          child: _buildCategoryChips(),
        ),
        const SizedBox(height: 16),
        if (kinds.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scrollable ? 20 : 0),
            child: Text(
              _allowedKinds.isEmpty
                  ? 'No report modules available for this account.'
                  : 'No reports match your search.',
              style: TextStyle(
                fontFamily: 'Literata',
                color: AppColors.mutedText(context),
              ),
            ),
          )
        else if (scrollable)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              children: _buildGroupedReportTiles(kinds),
            ),
          )
        else
          ..._buildGroupedReportTiles(kinds),
      ],
    );

    if (!scrollable) return content;

    return ColoredBox(
      color: AppColors.isDark(context)
          ? AppTheme.darkSurface
          : AppColors.card(context),
      child: content,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: TextStyle(
        fontFamily: 'Literata',
        fontSize: 14,
        color: AppColors.primaryText(context),
      ),
      decoration: InputDecoration(
        hintText: 'Search reports',
        hintStyle: TextStyle(
          fontFamily: 'Literata',
          color: AppColors.mutedText(context),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.mutedText(context),
        ),
        filled: true,
        fillColor: AppColors.isDark(context)
            ? AppTheme.darkScaffold
            : AppColors.scaffold(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.action(context), width: 1.4),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final items = <(UnifiedReportCategory?, String)>[
      (null, 'All'),
      (UnifiedReportCategory.sales, 'Sales'),
      (UnifiedReportCategory.purchases, 'Purchases'),
      (UnifiedReportCategory.inventory, 'Inventory'),
      (UnifiedReportCategory.accounts, 'Accounts'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            _FilterChip(
              label: item.$2,
              selected: _categoryFilter == item.$1,
              onTap: () => setState(() {
                _categoryFilter = item.$1;
                final filtered = _filteredKinds;
                if (_selected != null && !filtered.contains(_selected)) {
                  _selected = filtered.isEmpty ? null : filtered.first;
                }
              }),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildGroupedReportTiles(List<UnifiedReportKind> kinds) {
    final order = [
      UnifiedReportCategory.sales,
      UnifiedReportCategory.purchases,
      UnifiedReportCategory.inventory,
      UnifiedReportCategory.accounts,
    ];
    final widgets = <Widget>[];
    for (final cat in order) {
      final group = kinds.where((k) => k.category == cat).toList();
      if (group.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
          child: Text(
            _categoryLabel(cat),
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.mutedText(context),
            ),
          ),
        ),
      );
      for (final kind in group) {
        widgets.add(
          _ReportListTile(
            kind: kind,
            selected: _selected == kind,
            onTap: () => setState(() => _selected = kind),
          ),
        );
      }
    }
    return widgets;
  }

  String _categoryLabel(UnifiedReportCategory cat) {
    switch (cat) {
      case UnifiedReportCategory.sales:
        return 'Sales';
      case UnifiedReportCategory.purchases:
        return 'Purchases';
      case UnifiedReportCategory.inventory:
        return 'Inventory';
      case UnifiedReportCategory.accounts:
        return 'Accounts';
    }
  }

  Widget _buildConfigPanel() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
            child: _buildConfigBody(),
          ),
        ),
        _buildFooterBar(),
      ],
    );
  }

  Widget _buildConfigBody() {
    final kind = _selected;
    final muted = AppColors.mutedText(context);
    final action = AppColors.action(context);

    if (kind == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'Select a report from the left to configure export.',
            style: TextStyle(fontFamily: 'Literata', color: muted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kind.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(kind.icon, color: kind.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.title,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kind.subtitle,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Period',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 10),
        if (kind.usesDateRange) ...[
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
                _FilterChip(
                  label: e.$2,
                  selected: _preset == e.$1,
                  onTap: () => _applyPreset(e.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickCustomRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 18, color: action),
                  const SizedBox(width: 8),
                  Text(
                    _rangeLabel,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                ],
              ),
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
        const SizedBox(height: 24),
        Text(
          'Format',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            fontSize: 14,
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
        const SizedBox(height: 24),
        Text(
          'Report includes',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in kind.includeLabels)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.isDark(context)
                      ? AppTheme.darkScaffold
                      : AppColors.chipFill(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText(context),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _statusSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                color: AppColors.mutedText(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildActionButtons(fullWidth: false),
        ],
      ),
    );
  }

  Widget _buildActionButtons({required bool fullWidth}) {
    final canRun =
        !_generating && _allowedKinds.isNotEmpty && _selected != null;
    final previewBtn = OutlinedButton.icon(
      onPressed: canRun ? _generate : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.action(context),
        side: BorderSide(color: AppColors.border(context)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: const Text(
        'Preview',
        style: TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final generateBtn = FilledButton.icon(
      onPressed: canRun ? _generate : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.action(context),
        foregroundColor: AppTheme.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: _generating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.white,
              ),
            )
          : Icon(_format.icon, size: 18),
      label: Text(
        _generating ? 'Generating…' : 'Generate ${_format.label}',
        style: const TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (fullWidth) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: previewBtn),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: generateBtn),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        previewBtn,
        const SizedBox(width: 10),
        generateBtn,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
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
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? action.withValues(alpha: AppColors.isDark(context) ? 0.28 : 0.16)
                : AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? action : AppColors.border(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.primaryText(context)
                  : AppColors.secondaryText(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  final UnifiedReportKind kind;
  final bool selected;
  final VoidCallback onTap;

  const _ReportListTile({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final action = AppColors.action(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? action.withValues(
                      alpha: AppColors.isDark(context) ? 0.22 : 0.12,
                    )
                  : AppTheme.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? action.withValues(alpha: 0.35) : AppTheme.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kind.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(kind.icon, color: kind.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kind.title,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kind.subtitle,
                        maxLines: 1,
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
              ],
            ),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                format.icon,
                color: selected ? action : AppColors.mutedText(context),
              ),
              const SizedBox(width: 8),
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
              if (selected) ...[
                const Spacer(),
                Icon(Icons.check_circle_rounded, color: action, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
