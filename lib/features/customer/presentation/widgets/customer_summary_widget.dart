import 'package:flutter/material.dart';
import 'package:c_billing/common_widgets/desktop_stat_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Summary widget for customer statistics Displays: Total customers, Pending amount, Synced status
class CustomerSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  final String searchQuery;

  // Labels
  final String customersLabel;
  final String pendingLabel;
  final String syncedLabel;
  final String unsyncedLabel;

  const CustomerSummaryWidget({
    super.key,
    required this.customers,
    this.searchQuery = '',
    this.customersLabel = 'Customers',
    this.pendingLabel = 'Pending',
    this.syncedLabel = 'Synced',
    this.unsyncedLabel = 'Unsynced',
  });

  List<Map<String, dynamic>> get _filteredCustomers {
    if (searchQuery.isEmpty) return customers;

    final query = searchQuery.toLowerCase();
    return customers.where((c) {
      final firstName = (c['firstName'] ?? '').toString().toLowerCase();
      final lastName = (c['lastName'] ?? '').toString().toLowerCase();
      final contact = (c['contact'] ?? '').toString().toLowerCase();
      final fullName = '$firstName $lastName';
      return firstName.contains(query) ||
          lastName.contains(query) ||
          fullName.contains(query) ||
          contact.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCustomers;
    final totalPending = filtered.fold<double>(
      0,
      (total, c) =>
          total + ((c['currentPendingAmount'] as num?)?.toDouble() ?? 0.0),
    );
    final unsyncedCount = filtered.where((c) => c['isSynced'] != true).length;
    final synced = unsyncedCount == 0;

    if (DesktopCanvas.wide(context)) {
      return _buildWideCards(
        context,
        count: filtered.length,
        totalPending: totalPending,
        unsyncedCount: unsyncedCount,
      );
    }

    final isDark = AppColors.isDark(context);
    final accent = AppColors.action(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statTile(
              context,
              icon: Icons.people_alt_rounded,
              iconColor: accent,
              value: '${filtered.length}',
              label: customersLabel,
            ),
          ),
          _divider(context),
          Expanded(
            child: _statTile(
              context,
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppTheme.toneRose,
              value: totalPending.round() == 0
                  ? '₹0'
                  : '₹${_formatAmount(totalPending)}',
              label: pendingLabel,
              valueColor: totalPending.round() != 0 ? AppTheme.toneRose : null,
            ),
          ),
          _divider(context),
          Expanded(
            child: _statTile(
              context,
              icon: synced
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_upload_rounded,
              iconColor: synced ? accent : AppTheme.toneAmber,
              value: synced ? syncedLabel : '$unsyncedCount',
              label: 'Cloud',
              valueColor: synced ? accent : AppTheme.toneAmber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideCards(
    BuildContext context, {
    required int count,
    required double totalPending,
    required int unsyncedCount,
  }) {
    final synced = unsyncedCount == 0;
    return DesktopStatBar(
      stats: [
        DesktopStat(value: '$count', label: customersLabel),
        DesktopStat(
          value: totalPending.round() == 0
              ? '₹0'
              : '₹${_formatAmount(totalPending)}',
          label: pendingLabel,
        ),
        DesktopStat(
          value: synced ? syncedLabel : '$unsyncedCount',
          label: synced ? syncedLabel : unsyncedLabel,
        ),
      ],
    );
  }

  Widget _statTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(
              alpha: AppColors.isDark(context) ? 0.18 : 0.12,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: valueColor ?? AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: AppColors.mutedText(context),
          ),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.border(context),
    );
  }

  String _formatAmount(double amount) {
    final whole = amount.round().abs().toString();
    final buf = StringBuffer(amount < 0 ? '-' : '');
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return buf.toString();
  }
}
