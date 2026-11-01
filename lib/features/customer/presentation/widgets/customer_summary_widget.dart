import 'package:flutter/material.dart';
import 'package:c_billing/common_widgets/desktop_stat_bar.dart';
import 'package:c_billing/common_widgets/glass_summary_card.dart';
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

    return GlassSummaryCard(
      title: pendingLabel,
      amount: totalPending.round() == 0
          ? '₹0'
          : '₹${_formatAmount(totalPending)}',
      trailing: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.white.withValues(alpha: isDark ? 0.16 : 0.28),
          border: Border.all(
            color: AppTheme.white.withValues(alpha: 0.45),
          ),
        ),
        child: Icon(
          Icons.people_alt_rounded,
          size: 18,
          color: AppTheme.white.withValues(alpha: 0.95),
        ),
      ),
      stats: [
        GlassSummaryStat(
          value: '${filtered.length}',
          label: customersLabel,
        ),
        GlassSummaryStat(
          value: totalPending.round() == 0
              ? '₹0'
              : '₹${_formatAmount(totalPending)}',
          label: pendingLabel,
        ),
        GlassSummaryStat(
          value: synced ? syncedLabel : '$unsyncedCount',
          label: 'Cloud',
        ),
      ],
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
