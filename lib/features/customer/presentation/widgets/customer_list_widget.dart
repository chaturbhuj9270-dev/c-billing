import 'package:flutter/material.dart';
import '../../../../core/services/communication_service.dart';
import 'customer_filter_widget.dart';
import 'package:c_billing/core/theme/app_theme.dart';

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

    // When pending amount filter is active, show only customers with pending balance
    if (sortField == CustomerSortField.pendingAmount) {
      filtered = filtered.where((c) {
        final pending =
            (c['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;
        return pending != 0.0;
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
        context: context,
        icon: Icons.people_outline_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    final filtered = _filteredAndSortedCustomers;

    // Empty state - no search results
    if (filtered.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.search_off_rounded,
        title: noResultsTitle,
        subtitle: noResultsSubtitle,
      );
    }

    return RefreshIndicator(
      color: AppColors.accent(context),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accentSoft(context, 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.accentSoft(context, 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.secondaryText(context),
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
                color: AppColors.mutedText(context),
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
    final contact = (customer['contact'] ?? '').toString();
    final address = (customer['address'] ?? '').toString();
    final pendingAmount =
        (customer['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;
    final isSynced = customer['isSynced'] as bool? ?? true;

    final accent = Theme.of(context).primaryColor;
    final isDark = AppColors.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: AppTheme.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isNotEmpty ? fullName : '—',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.primaryText(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 13,
                                  color: AppColors.mutedText(context),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    contact.isNotEmpty ? contact : '—',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 12,
                                      color: AppColors.mutedText(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (pendingAmount > 0)
                            Text(
                              '₹${pendingAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.toneRose,
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: AppColors.mutedText(context),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            isSynced ? 'Synced' : pendingLabel,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSynced
                                  ? (isDark
                                        ? AppColors.action(context)
                                        : AppTheme.primaryLight)
                                  : AppTheme.toneAmber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (address.isNotEmpty && address != 'N/A') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.mutedText(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (contact.isNotEmpty ||
                      onFinanceTap != null ||
                      onTransactionsTap != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onTransactionsTap != null)
                          GestureDetector(
                            onTap: onTransactionsTap,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppTheme.toneAmber.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.swap_horiz_rounded,
                                size: 16,
                                color: AppTheme.toneAmber,
                              ),
                            ),
                          ),
                        if (onTransactionsTap != null &&
                            (onFinanceTap != null || contact.isNotEmpty))
                          const SizedBox(width: 8),
                        if (onFinanceTap != null)
                          GestureDetector(
                            onTap: onFinanceTap,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 16,
                                color: accent,
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
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
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
                      AppColors.border(context)!,
                      AppColors.chipFill(context)!,
                      AppColors.border(context)!,
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
            colors: [AppColors.border(context)!, AppColors.chipFill(context)!, AppColors.border(context)!],
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
