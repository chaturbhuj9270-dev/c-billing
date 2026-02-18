import 'package:flutter/material.dart';

/// Sort field options for companies
enum CompanySortField {
  name,
  createdDate,
  companyCode,
}

/// Filter widget for companies
/// Features: Search bar, Sort options, Sort direction toggle
class CompanyFilterWidget extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final CompanySortField sortField;
  final ValueChanged<CompanySortField> onSortFieldChanged;
  final bool sortAscending;
  final VoidCallback onSortDirectionToggle;

  const CompanyFilterWidget({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sortField,
    required this.onSortFieldChanged,
    required this.sortAscending,
    required this.onSortDirectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search companies...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'Literata',
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey[500],
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey[500],
                      ),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Sort options row
        Row(
          children: [
            // Sort field chips
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSortChip(
                      label: 'Name',
                      field: CompanySortField.name,
                      icon: Icons.sort_by_alpha_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildSortChip(
                      label: 'Date',
                      field: CompanySortField.createdDate,
                      icon: Icons.calendar_today_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildSortChip(
                      label: 'Code',
                      field: CompanySortField.companyCode,
                      icon: Icons.qr_code_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Sort direction toggle
            GestureDetector(
              onTap: onSortDirectionToggle,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                  color: const Color(0xFF1B4D3E),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip({
    required String label,
    required CompanySortField field,
    required IconData icon,
  }) {
    final isSelected = sortField == field;
    
    return GestureDetector(
      onTap: () => onSortFieldChanged(field),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B4D3E)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B4D3E)
                : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
