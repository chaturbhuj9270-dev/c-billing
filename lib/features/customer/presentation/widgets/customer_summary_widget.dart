import 'package:flutter/material.dart';

/// Summary widget for customer statistics
/// Displays: Total customers, Pending amount, Synced status
class CustomerSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  final String searchQuery;

  // Labels
  final String customersLabel;
  final String pendingLabel;
  final String unsyncedLabel;
  final String allSyncedLabel;

  const CustomerSummaryWidget({
    super.key,
    required this.customers,
    this.searchQuery = '',
    this.customersLabel = 'Customers',
    this.pendingLabel = 'Pending',
    this.unsyncedLabel = 'Unsynced',
    this.allSyncedLabel = 'All Synced',
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
      (sum, c) =>
          sum + ((c['currentPendingAmount'] as num?)?.toDouble() ?? 0.0),
    );
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
            icon: Icons.people_rounded,
            label: customersLabel,
            value: '${filtered.length}',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.account_balance_wallet_rounded,
            label: pendingLabel,
            value: '₹${totalPending.toStringAsFixed(0)}',
            valueColor: totalPending > 0 ? Colors.amber[300] : null,
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              icon: unsyncedCount > 0
                  ? Icons.cloud_off_rounded
                  : Icons.cloud_done_rounded,
              label: unsyncedCount > 0 ? unsyncedLabel : allSyncedLabel,
              value: unsyncedCount > 0 ? '$unsyncedCount' : '✓',
              valueColor: unsyncedCount > 0
                  ? Colors.orange[300]
                  : Colors.green[300],
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
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
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
