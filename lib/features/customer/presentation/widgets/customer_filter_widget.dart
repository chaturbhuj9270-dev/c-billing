import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Sort options for customer list
enum CustomerSortField { name, createdDate, pendingAmount }

/// Customer creation date of a list row (DateTime or ISO string), or null.
DateTime? customerCreatedAt(Map<String, dynamic> customer) {
  final v = customer['createdAt'];
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

/// True when [customer] was created inside [range] (whole days, inclusive).
/// With no range every customer matches. A customer without a creation date
/// cannot be placed in a period, so it is hidden while a range is applied.
bool customerCreatedInRange(
  Map<String, dynamic> customer,
  DateTimeRange? range,
) {
  if (range == null) return true;
  final created = customerCreatedAt(customer);
  if (created == null) return false;
  final local = created.toLocal();
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final endExclusive = DateTime(
    range.end.year,
    range.end.month,
    range.end.day,
  ).add(const Duration(days: 1));
  return !local.isBefore(start) && local.isBefore(endExclusive);
}

// Filter widget for customer list Features: Search bar, Sort options, created-date range
class CustomerFilterWidget extends StatefulWidget {
  final String searchQuery;
  final CustomerSortField sortField;
  final bool sortAscending;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerSortField> onSortFieldChanged;
  final VoidCallback onSortDirectionToggle;
  final VoidCallback? onClearSearch;

  /// Optional created-date range filter. The calendar button only shows when
  /// [onDateRangeChanged] is given, so existing callers are unchanged.
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?>? onDateRangeChanged;
  final String dateFilterLabel;
  final String dateFilterClearLabel;

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
    required this.onSearchChanged,
    required this.onSortFieldChanged,
    required this.onSortDirectionToggle,
    this.onClearSearch,
    this.dateRange,
    this.onDateRangeChanged,
    this.dateFilterLabel = 'Select date range',
    this.dateFilterClearLabel = 'Clear',
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: widget.dateRange,
      helpText: widget.dateFilterLabel,
    );
    if (picked != null) widget.onDateRangeChanged?.call(picked);
  }

  String _rangeText(DateTimeRange r) {
    final f = DateFormat('dd MMM yyyy');
    return '${f.format(r.start)} - ${f.format(r.end)}';
  }

  Widget _buildDateButton() {
    final active = widget.dateRange != null;
    return Tooltip(
      message: widget.dateFilterLabel,
      child: GestureDetector(
        onTap: _pickDateRange,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active
                ? AppColors.selectedFill(context)
                : AppColors.chipFill(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppColors.selectedFill(context)
                  : AppColors.border(context),
            ),
          ),
          child: Icon(
            Icons.date_range_rounded,
            size: 20,
            color: active
                ? AppColors.selectedOnFill(context)
                : AppColors.secondaryText(context),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRangeChip() {
    final range = widget.dateRange!;
    return GestureDetector(
      onTap: _pickDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.selectedFill(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 15,
              color: AppColors.selectedOnFill(context),
            ),
            const SizedBox(width: 6),
            Text(
              _rangeText(range),
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.selectedOnFill(context),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: widget.dateFilterClearLabel,
              child: GestureDetector(
                onTap: () => widget.onDateRangeChanged?.call(null),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.selectedOnFill(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDateFilter = widget.onDateRangeChanged != null;
    if (DesktopCanvas.wide(context)) {
      return Row(
        children: [
          Expanded(flex: 3, child: _buildSearchBar()),
          const SizedBox(width: 12),
          if (hasDateFilter) ...[
            if (widget.dateRange != null) ...[
              _buildActiveRangeChip(),
              const SizedBox(width: 8),
            ],
            _buildDateButton(),
            const SizedBox(width: 12),
          ],
          _sortChip(
            label: widget.sortByNameLabel,
            selected: widget.sortField == CustomerSortField.name,
            onTap: () => widget.onSortFieldChanged(CustomerSortField.name),
            icon: Icons.sort_by_alpha_rounded,
          ),
          const SizedBox(width: 8),
          _sortChip(
            label: widget.sortByPendingLabel,
            selected: widget.sortField == CustomerSortField.pendingAmount,
            onTap: () =>
                widget.onSortFieldChanged(CustomerSortField.pendingAmount),
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(width: 8),
          _sortChip(
            label: widget.sortByDateLabel,
            selected: widget.sortField == CustomerSortField.createdDate,
            onTap: () =>
                widget.onSortFieldChanged(CustomerSortField.createdDate),
            icon: Icons.calendar_today_rounded,
          ),
        ],
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar row
          Row(
            children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 10),
              if (hasDateFilter) ...[
                _buildDateButton(),
                const SizedBox(width: 10),
              ],
              _buildSortDirectionButton(),
            ],
          ),
          if (hasDateFilter && widget.dateRange != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildActiveRangeChip(),
            ),
          ],
          const SizedBox(height: 12),
          // Sort chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip(
                  label: widget.sortByNameLabel,
                  isSelected: widget.sortField == CustomerSortField.name,
                  onTap: () =>
                      widget.onSortFieldChanged(CustomerSortField.name),
                  icon: Icons.sort_by_alpha_rounded,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  label: widget.sortByPendingLabel,
                  isSelected:
                      widget.sortField == CustomerSortField.pendingAmount,
                  onTap: () => widget.onSortFieldChanged(
                    CustomerSortField.pendingAmount,
                  ),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  label: widget.sortByDateLabel,
                  isSelected: widget.sortField == CustomerSortField.createdDate,
                  onTap: () =>
                      widget.onSortFieldChanged(CustomerSortField.createdDate),
                  icon: Icons.calendar_today_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.scaffold(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Literata',
          color: AppColors.accent(context),
        ),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: TextStyle(
            color: AppTheme.grey400,
            fontFamily: 'Literata',
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.grey,
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
                    color: AppTheme.grey,
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
          setState(() {}); // Rebuild to show/hide clear button
        },
      ),
    );
  }

  Widget _buildSortDirectionButton() {
    return GestureDetector(
      onTap: widget.onSortDirectionToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.selectedFill(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: widget.sortAscending ? 0 : 0.5,
            child: Icon(
              Icons.arrow_upward_rounded,
              color: AppColors.selectedOnFill(context),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sortChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final dark = AppColors.isDark(context);
    final fill = selected
        ? (dark ? AppTheme.darkAction : AppTheme.paletteFFD7EDE3)
        : AppColors.card(context);
    final ink = selected
        ? (dark ? AppTheme.white : AppColors.action(context))
        : AppColors.secondaryText(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.paletteFFD7EDE3
                : AppColors.border(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final selected = AppColors.selectedFill(context);
    final onSelected = AppColors.selectedOnFill(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selected : AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? selected : AppColors.border(context),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? onSelected : AppColors.secondaryText(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? onSelected
                    : AppColors.secondaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
