import 'package:flutter/material.dart';

/// Summary widget for company statistics
/// Displays: Total companies, Active companies, Synced status
class CompanySummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> companies;
  final String searchQuery;

  const CompanySummaryWidget({
    super.key,
    required this.companies,
    this.searchQuery = '',
  });

  List<Map<String, dynamic>> get _filteredCompanies {
    if (searchQuery.isEmpty) return companies;
    
    final query = searchQuery.toLowerCase();
    return companies.where((c) {
      final name = (c['companyName'] ?? '').toString().toLowerCase();
      final contact = (c['contact'] ?? '').toString().toLowerCase();
      final companyCode = (c['companyCode'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          contact.contains(query) ||
          companyCode.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCompanies;
    final activeCount = filtered.where((c) => c['isActive'] != false).length;
    final unsyncedCount = filtered.where((c) => c['isSynced'] != true).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B4D3E),
            const Color(0xFF1B4D3E).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.business_rounded,
            label: 'Companies',
            value: '${filtered.length}',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.check_circle_rounded,
            label: 'Active',
            value: '$activeCount',
            valueColor: activeCount > 0 ? Colors.green[300] : null,
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              icon: unsyncedCount > 0
                  ? Icons.cloud_off_rounded
                  : Icons.cloud_done_rounded,
              label: unsyncedCount > 0 ? 'Unsynced' : 'All Synced',
              value: unsyncedCount > 0 ? '$unsyncedCount' : '✓',
              valueColor: unsyncedCount > 0 ? Colors.orange[300] : Colors.green[300],
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isExpanded = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: valueColor ?? Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}
