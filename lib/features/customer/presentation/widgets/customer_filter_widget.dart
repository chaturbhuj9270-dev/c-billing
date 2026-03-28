import 'package:flutter/material.dart';

/// Sort options for customer list
enum CustomerSortField { name, createdDate, pendingAmount }

/// Filter widget for customer list
/// Features: Search bar, Sort options
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              _buildSortDirectionButton(),
            ],
          ),
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
                  label: widget.sortByDateLabel,
                  isSelected: widget.sortField == CustomerSortField.createdDate,
                  onTap: () =>
                      widget.onSortFieldChanged(CustomerSortField.createdDate),
                  icon: Icons.calendar_today_rounded,
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Literata',
          color: Color(0xFF1B4D3E),
        ),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontFamily: 'Literata',
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[500],
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
                    color: Colors.grey[500],
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
          color: const Color(0xFF1B4D3E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: widget.sortAscending ? 0 : 0.5,
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
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
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
