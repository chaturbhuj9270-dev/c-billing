import 'package:flutter/material.dart';
import '../../../../core/services/communication_service.dart';
import 'customer_filter_widget.dart';

/// Enhanced list widget for displaying customers
/// Features: Shimmer loading, Enhanced cards, Empty states
class CustomerListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  final bool isLoading;
  final String searchQuery;
  final CustomerSortField sortField;
  final bool sortAscending;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onCustomerTap;
  final void Function(Map<String, dynamic>)? onCustomerLongPress;
  final void Function(Map<String, dynamic>)? onFinanceTap;
  final void Function(Map<String, dynamic>)? onTransactionsTap;

  // Labels
  final String emptyTitle;
  final String emptySubtitle;
  final String noResultsTitle;
  final String noResultsSubtitle;
  final String pendingLabel;

  const CustomerListWidget({
    super.key,
    required this.customers,
    required this.isLoading,
    required this.searchQuery,
    required this.sortField,
    required this.sortAscending,
    required this.onRefresh,
    required this.onCustomerTap,
    this.onCustomerLongPress,
    this.onFinanceTap,
    this.onTransactionsTap,
    this.emptyTitle = 'No customers yet',
    this.emptySubtitle = 'Add your first customer to get started',
    this.noResultsTitle = 'No results found',
    this.noResultsSubtitle = 'Try a different search term',
    this.pendingLabel = 'pending',
  });

  List<Map<String, dynamic>> get _filteredAndSortedCustomers {
    var filtered = customers.toList();

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((c) {
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

    // Apply sort
    filtered.sort((a, b) {
      int result;
      switch (sortField) {
        case CustomerSortField.name:
          final aName = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'
              .toLowerCase();
          final bName = '${b['firstName'] ?? ''} ${b['lastName'] ?? ''}'
              .toLowerCase();
          result = aName.compareTo(bName);
          break;
        case CustomerSortField.createdDate:
          final aDate = a['createdAt'] as DateTime? ?? DateTime(2000);
          final bDate = b['createdAt'] as DateTime? ?? DateTime(2000);
          result = aDate.compareTo(bDate);
          break;
        case CustomerSortField.pendingAmount:
          final aPending =
              (a['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;
          final bPending =
              (b['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;
          result = aPending.compareTo(bPending);
          break;
      }
      return sortAscending ? result : -result;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Show shimmer while loading
    if (isLoading && customers.isEmpty) {
      return _buildShimmerList();
    }

    // Empty state - no customers at all
    if (customers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    final filtered = _filteredAndSortedCustomers;

    // Empty state - no search results
    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: noResultsTitle,
        subtitle: noResultsSubtitle,
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1B4D3E),
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: _CustomerCard(
              customer: filtered[index],
              onTap: () => onCustomerTap(filtered[index]),
              onLongPress: onCustomerLongPress != null
                  ? () => onCustomerLongPress!(filtered[index])
                  : null,
              onFinanceTap: onFinanceTap != null
                  ? () => onFinanceTap!(filtered[index])
                  : null,
              onTransactionsTap: onTransactionsTap != null
                  ? () => onTransactionsTap!(filtered[index])
                  : null,
              pendingLabel: pendingLabel,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const _ShimmerCard();
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 48,
                color: const Color(0xFF1B4D3E).withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced customer card widget
class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFinanceTap;
  final VoidCallback? onTransactionsTap;
  final String pendingLabel;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    this.onLongPress,
    this.onFinanceTap,
    this.onTransactionsTap,
    this.pendingLabel = 'pending',
  });

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
    final firstName = (customer['firstName'] ?? '').toString();
    final contact = (customer['contact'] ?? '').toString();
    final address = (customer['address'] ?? '').toString();
    final pendingAmount =
        (customer['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;
    final isSynced = customer['isSynced'] as bool? ?? true;

    const accentColors = [
      Color(0xFF1B4D3E),
      Color(0xFF0F3B2F),
      Color(0xFF2C6F5E),
      Color(0xFF1A5E52),
    ];
    final accentColor =
        accentColors[((customer['id'] ?? '').hashCode.abs()) % 4];
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Avatar + Info + Arrow
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with gradient
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentColor, accentColor.withOpacity(0.7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + Contact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fullName.isNotEmpty ? fullName : '—',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B4D3E),
                                  fontFamily: 'Literata',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Sync status icon - always show (green for synced, orange for pending)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                isSynced
                                    ? Icons.cloud_done_rounded
                                    : Icons.cloud_upload_rounded,
                                size: 16,
                                color: isSynced ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Contact
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 13,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              contact.isNotEmpty ? contact : '—',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Pending amount badge or arrow
                  if (pendingAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red[100]!, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${pendingAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.red[700],
                              fontFamily: 'Literata',
                            ),
                          ),
                          Text(
                            pendingLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.red[400],
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: Colors.grey[400],
                    ),
                ],
              ),
              // Address row
              if (address.isNotEmpty && address != 'N/A') ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Literata',
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Action icons row (Transactions + Finance + Communication)
              if (contact.isNotEmpty ||
                  onFinanceTap != null ||
                  onTransactionsTap != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Transactions button
                    if (onTransactionsTap != null)
                      GestureDetector(
                        onTap: onTransactionsTap,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    if (onTransactionsTap != null &&
                        (onFinanceTap != null || contact.isNotEmpty))
                      const SizedBox(width: 8),
                    // Finance/History button
                    if (onFinanceTap != null)
                      GestureDetector(
                        onTap: onFinanceTap,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4D3E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ),
                    if (onFinanceTap != null && contact.isNotEmpty)
                      const SizedBox(width: 8),
                    if (contact.isNotEmpty)
                      CommunicationActionIcons(
                        phoneNumber: contact,
                        iconSize: 16,
                        containerSize: 34,
                        spacing: 8,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading card for customer list
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar placeholder
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                    ],
                    stops: [
                      (_animation.value - 0.3).clamp(0.0, 1.0),
                      _animation.value.clamp(0.0, 1.0),
                      (_animation.value + 0.3).clamp(0.0, 1.0),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(height: 16, width: 120),
                  const SizedBox(height: 8),
                  _buildShimmerBox(height: 12, width: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height, required double width}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
            stops: [
              (_animation.value - 0.3).clamp(0.0, 1.0),
              _animation.value.clamp(0.0, 1.0),
              (_animation.value + 0.3).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}
