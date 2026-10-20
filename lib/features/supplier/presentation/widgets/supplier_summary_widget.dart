import 'package:flutter/material.dart';
import 'package:c_billing/common_widgets/desktop_stat_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Summary widget for supplier statistics Displays: Total suppliers, Active suppliers, Synced status
class SupplierSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> suppliers;
  final String searchQuery;

  const SupplierSummaryWidget({
    super.key,
    required this.suppliers,
    this.searchQuery = '',
  });

  List<Map<String, dynamic>> get _filteredSuppliers {
    if (searchQuery.isEmpty) return suppliers;
    
    final query = searchQuery.toLowerCase();
    return suppliers.where((s) {
      final firstName = (s['firstName'] ?? '').toString().toLowerCase();
      final lastName = (s['lastName'] ?? '').toString().toLowerCase();
      final contact = (s['contact'] ?? '').toString().toLowerCase();
      final supplierCode = (s['supplierCode'] ?? '').toString().toLowerCase();
      final fullName = '$firstName $lastName';
      return firstName.contains(query) ||
          lastName.contains(query) ||
          fullName.contains(query) ||
          contact.contains(query) ||
          supplierCode.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSuppliers;
    final activeCount = filtered.where((s) => s['isActive'] != false).length;
    final unsyncedCount = filtered.where((s) => s['isSynced'] != true).length;

    if (DesktopCanvas.isDesktopPlatform) {
      return DesktopStatBar(
        stats: [
          DesktopStat(value: '${filtered.length}', label: 'Suppliers'),
          DesktopStat(value: '$activeCount', label: 'Active'),
          DesktopStat(
            value: unsyncedCount > 0 ? '$unsyncedCount' : 'All Synced',
            label: unsyncedCount > 0 ? 'Unsynced' : 'Cloud sync',
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
            color: AppTheme.black.withValues(
              alpha: AppColors.isDark(context) ? 0.45 : 0.3,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.local_shipping_rounded,
            label: 'Suppliers',
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
                  ? Icons.cloud_off_rounded
                  : Icons.cloud_done_rounded,
              label: unsyncedCount > 0 ? 'Unsynced' : 'All Synced',
              value: unsyncedCount > 0 ? '$unsyncedCount' : '✓',
              valueColor: unsyncedCount > 0 ? AppTheme.orange300 : AppTheme.green300,
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
