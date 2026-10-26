import 'package:flutter/material.dart';
import 'package:c_billing/common_widgets/desktop_stat_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Summary widget for company statistics Displays: Total companies, Active companies, Synced status
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

    if (DesktopCanvas.isDesktopPlatform) {
      return DesktopStatBar(
        stats: [
          DesktopStat(value: '${filtered.length}', label: 'Companies'),
          DesktopStat(value: '$activeCount', label: 'Active'),
          DesktopStat(
            value: unsyncedCount > 0 ? '$unsyncedCount' : '✓',
            label: 'Cloud',
          ),
        ],
      );
    }

    final header = AppColors.headerGradient(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [header.first, header.last],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: AppColors.isDark(context) ? 0.45 : 0.3),
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
            valueColor: activeCount > 0 ? AppTheme.green300 : null,
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              icon: unsyncedCount > 0
                  ? Icons.cloud_upload_rounded
                  : Icons.cloud_done_rounded,
              label: 'Cloud',
              value: unsyncedCount > 0 ? '$unsyncedCount' : '✓',
              valueColor: unsyncedCount > 0 ? AppTheme.toneAmber : null,
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
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.white,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: valueColor ?? AppTheme.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: AppTheme.white.withValues(alpha: 0.7),
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
      color: AppTheme.white.withValues(alpha: 0.2),
    );
  }
}
