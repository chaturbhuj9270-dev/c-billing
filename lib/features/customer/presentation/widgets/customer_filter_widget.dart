import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Sort options for customer list
enum CustomerSortField { name, createdDate, pendingAmount }

// Filter widget for customer list Features: Search bar, Sort options
class CustomerFilterWidget extends StatefulWidget {
  final String searchQuery;
  final CustomerSortField sortField;
  final bool sortAscending;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerSortField> onSortFieldChanged;
  final VoidCallback onSortDirectionToggle;
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
    required this.onSearchChanged,
    required this.onSortFieldChanged,
    required this.onSortDirectionToggle,
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

  @override
  Widget build(BuildContext context) {
    if (DesktopCanvas.wide(context)) {
      return Row(
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
      ],
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
}
