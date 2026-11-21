import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/common_widgets/range_calendar_sheet.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Sort options for customer list
enum CustomerSortField { name, createdDate, pendingAmount }

/// Filters customers by creation date.
enum CustomerDateFilter { all, thisMonth, thisYear, lastYear, custom }

/// Parse customer `createdAt` from map (DateTime or ISO string).
DateTime? parseCustomerCreatedAt(Map<String, dynamic> customer) {
  final raw = customer['createdAt'];
  if (raw is DateTime) return raw;
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}

/// Whether [createdAt] falls inside the selected creation-date filter.
bool customerMatchesDateFilter({
  required DateTime? createdAt,
  required CustomerDateFilter filter,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  if (filter == CustomerDateFilter.all) return true;
  if (createdAt == null) return false;

  final now = DateTime.now();
  switch (filter) {
    case CustomerDateFilter.all:
      return true;
    case CustomerDateFilter.thisMonth:
      return createdAt.year == now.year && createdAt.month == now.month;
    case CustomerDateFilter.thisYear:
      return createdAt.year == now.year;
    case CustomerDateFilter.lastYear:
      return createdAt.year == now.year - 1;
    case CustomerDateFilter.custom:
      if (customStart == null || customEnd == null) return true;
      final start = DateTime(
        customStart.year,
        customStart.month,
        customStart.day,
      );
      final end = DateTime(
        customEnd.year,
        customEnd.month,
        customEnd.day,
        23,
        59,
        59,
      );
      return !createdAt.isBefore(start) && !createdAt.isAfter(end);
  }
}

// Filter widget for customer list: search, sort, creation-date filter
class CustomerFilterWidget extends StatefulWidget {
  final String searchQuery;
  final CustomerSortField sortField;
  final bool sortAscending;
  final CustomerDateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerSortField> onSortFieldChanged;
  final VoidCallback onSortDirectionToggle;
  final ValueChanged<CustomerDateFilter> onDateFilterChanged;
  final void Function(DateTime start, DateTime end) onCustomDateRangeSelected;
  final VoidCallback? onClearSearch;

  // Labels
  final String searchHint;
  final String sortByNameLabel;
  final String sortByDateLabel;
  final String sortByPendingLabel;

  const CustomerFilterWidget({
    super.key,
    required this.searchQuery,
    required this.sortField,
    required this.sortAscending,
    required this.dateFilter,
    this.customStartDate,
    this.customEndDate,
    required this.onSearchChanged,
    required this.onSortFieldChanged,
    required this.onSortDirectionToggle,
    required this.onDateFilterChanged,
    required this.onCustomDateRangeSelected,
    this.onClearSearch,
    this.searchHint = 'Search customers...',
    this.sortByNameLabel = 'Name',
    this.sortByDateLabel = 'Date',
    this.sortByPendingLabel = 'Pending',
  });

  @override
  State<CustomerFilterWidget> createState() => _CustomerFilterWidgetState();
}

class _CustomerFilterWidgetState extends State<CustomerFilterWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant CustomerFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showAppRangeCalendar(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: widget.customStartDate != null &&
              widget.customEndDate != null
          ? DateTimeRange(
              start: widget.customStartDate!,
              end: widget.customEndDate!,
            )
          : null,
    );
    if (picked == null) return;
    widget.onCustomDateRangeSelected(picked.start, picked.end);
  }

  String get _customChipLabel {
    if (widget.customStartDate == null || widget.customEndDate == null) {
      return 'Custom';
    }
    final fmt = DateFormat('dd MMM');
    return '${fmt.format(widget.customStartDate!)} – ${fmt.format(widget.customEndDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    if (DesktopCanvas.wide(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: _buildSearchBar()),
              const SizedBox(width: 12),
              _buildSortChip(
                label: widget.sortByNameLabel,
                isSelected: widget.sortField == CustomerSortField.name,
                onTap: () => widget.onSortFieldChanged(CustomerSortField.name),
              ),
              const SizedBox(width: 8),
              _buildSortChip(
                label: widget.sortByPendingLabel,
                isSelected: widget.sortField == CustomerSortField.pendingAmount,
                onTap: () =>
                    widget.onSortFieldChanged(CustomerSortField.pendingAmount),
              ),
              const SizedBox(width: 8),
              _buildSortChip(
                label: widget.sortByDateLabel,
                isSelected: widget.sortField == CustomerSortField.createdDate,
                onTap: () =>
                    widget.onSortFieldChanged(CustomerSortField.createdDate),
              ),
              const SizedBox(width: 8),
              _buildSortDirectionButton(),
            ],
          ),
          const SizedBox(height: 10),
          _buildDateFilterRow(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSearchBar()),
            const SizedBox(width: 10),
            _buildSortDirectionButton(),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSortChip(
                label: widget.sortByNameLabel,
                isSelected: widget.sortField == CustomerSortField.name,
                onTap: () =>
                    widget.onSortFieldChanged(CustomerSortField.name),
              ),
              const SizedBox(width: 8),
              _buildSortChip(
                label: widget.sortByPendingLabel,
                isSelected:
                    widget.sortField == CustomerSortField.pendingAmount,
                onTap: () => widget.onSortFieldChanged(
                  CustomerSortField.pendingAmount,
                ),
              ),
              const SizedBox(width: 8),
              _buildSortChip(
                label: widget.sortByDateLabel,
                isSelected: widget.sortField == CustomerSortField.createdDate,
                onTap: () =>
                    widget.onSortFieldChanged(CustomerSortField.createdDate),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildDateFilterRow(),
      ],
    );
  }

  Widget _buildDateFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: AppColors.mutedText(context),
          ),
          const SizedBox(width: 8),
          _buildDateChip(
            label: 'All',
            selected: widget.dateFilter == CustomerDateFilter.all,
            onTap: () => widget.onDateFilterChanged(CustomerDateFilter.all),
          ),
          const SizedBox(width: 8),
          _buildDateChip(
            label: 'This Month',
            selected: widget.dateFilter == CustomerDateFilter.thisMonth,
            onTap: () =>
                widget.onDateFilterChanged(CustomerDateFilter.thisMonth),
          ),
          const SizedBox(width: 8),
          _buildDateChip(
            label: 'This Year',
            selected: widget.dateFilter == CustomerDateFilter.thisYear,
            onTap: () =>
                widget.onDateFilterChanged(CustomerDateFilter.thisYear),
          ),
          const SizedBox(width: 8),
          _buildDateChip(
            label: 'Last Year',
            selected: widget.dateFilter == CustomerDateFilter.lastYear,
            onTap: () =>
                widget.onDateFilterChanged(CustomerDateFilter.lastYear),
          ),
          const SizedBox(width: 8),
          _buildDateChip(
            label: _customChipLabel,
            selected: widget.dateFilter == CustomerDateFilter.custom,
            onTap: _pickCustomRange,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = AppColors.isDark(context);
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.16 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Literata',
          color: AppColors.primaryText(context),
        ),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: TextStyle(
            color: AppColors.mutedText(context),
            fontFamily: 'Literata',
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.mutedText(context),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                    widget.onClearSearch?.call();
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.mutedText(context),
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
        onChanged: (value) {
          widget.onSearchChanged(value);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSortDirectionButton() {
    final accent = AppColors.action(context);
    return GestureDetector(
      onTap: widget.onSortDirectionToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: widget.sortAscending ? 0 : 0.5,
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: AppTheme.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final accent = AppColors.action(context);
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? accent : AppColors.border(context),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected ? accent : AppColors.secondaryText(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = AppColors.action(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : AppColors.isDark(context)
                  ? AppTheme.white.withValues(alpha: 0.06)
                  : AppTheme.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: selected
                ? AppTheme.white
                : AppColors.secondaryText(context),
          ),
        ),
      ),
    );
  }
}
