import 'package:flutter/material.dart';
import '../../../../core/services/communication_service.dart';
import 'supplier_filter_widget.dart';

/// Enhanced list widget for displaying suppliers
/// Features: Shimmer loading, Enhanced cards with sync icons, Empty states
class SupplierListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> suppliers;
  final bool isLoading;
  final String searchQuery;
  final SupplierSortField sortField;
  final bool sortAscending;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onSupplierTap;
  final void Function(Map<String, dynamic>)? onSupplierLongPress;
  
  // Labels
  final String emptyTitle;
  final String emptySubtitle;
  final String noResultsTitle;
  final String noResultsSubtitle;

  const SupplierListWidget({
    super.key,
    required this.suppliers,
    required this.isLoading,
    required this.searchQuery,
    required this.sortField,
    required this.sortAscending,
    required this.onRefresh,
    required this.onSupplierTap,
    this.onSupplierLongPress,
    this.emptyTitle = 'No suppliers yet',
    this.emptySubtitle = 'Add your first supplier to get started',
    this.noResultsTitle = 'No results found',
    this.noResultsSubtitle = 'Try a different search term',
  });

  List<Map<String, dynamic>> get _filteredAndSortedSuppliers {
    var filtered = suppliers.toList();

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((s) {
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

    // Apply sort
    filtered.sort((a, b) {
      int result;
      switch (sortField) {
        case SupplierSortField.name:
          final aName =
              '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.toLowerCase();
          final bName =
              '${b['firstName'] ?? ''} ${b['lastName'] ?? ''}'.toLowerCase();
          result = aName.compareTo(bName);
          break;
        case SupplierSortField.createdDate:
          final aDate = a['createdAt'] as DateTime? ?? DateTime(2000);
          final bDate = b['createdAt'] as DateTime? ?? DateTime(2000);
          result = aDate.compareTo(bDate);
          break;
        case SupplierSortField.contact:
          final aContact = (a['contact'] ?? '').toString();
          final bContact = (b['contact'] ?? '').toString();
          result = aContact.compareTo(bContact);
          break;
        case SupplierSortField.supplierCode:
          final aCode = (a['supplierCode'] ?? '').toString();
          final bCode = (b['supplierCode'] ?? '').toString();
          result = aCode.compareTo(bCode);
          break;
      }
      return sortAscending ? result : -result;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Show shimmer while loading
    if (isLoading && suppliers.isEmpty) {
      return _buildShimmerList();
    }

    // Empty state - no suppliers at all
    if (suppliers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    final filtered = _filteredAndSortedSuppliers;

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
            child: _SupplierCard(
              supplier: filtered[index],
              onTap: () => onSupplierTap(filtered[index]),
              onLongPress: onSupplierLongPress != null
                  ? () => onSupplierLongPress!(filtered[index])
                  : null,
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
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 48,
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.4),
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

/// Enhanced supplier card widget
class _SupplierCard extends StatelessWidget {
  final Map<String, dynamic> supplier;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SupplierCard({
    required this.supplier,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${supplier['firstName'] ?? ''} ${supplier['lastName'] ?? ''}'.trim();
    final firstName = (supplier['firstName'] ?? '').toString();
    final contact = (supplier['contact'] ?? '').toString();
    final address = (supplier['address'] ?? '').toString();
    final supplierCode = (supplier['supplierCode'] ?? '').toString();
    final isActive = supplier['isActive'] as bool? ?? true;
    final isSynced = supplier['isSynced'] as bool? ?? true;

    const accentColors = [
      Color(0xFF1B4D3E),
      Color(0xFF0F3B2F),
      Color(0xFF2C6F5E),
      Color(0xFF1A5E52),
    ];
    final accentColor =
        accentColors[((supplier['id'] ?? '').hashCode.abs()) % 4];
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';

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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
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
                        colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
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
                  // Name + Contact + Code
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
                                color: isSynced
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Contact and Code
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 13,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                contact.isNotEmpty ? contact : '—',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontFamily: 'Literata',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (supplierCode.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$supplierCode',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B4D3E),
                                    fontFamily: 'Literata',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge or arrow
                  if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          fontFamily: 'Literata',
                        ),
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
              // Address row (if exists)
              if (address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Literata',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Communication action icons (call, SMS, WhatsApp)
              if (contact.isNotEmpty) ...[  
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CommunicationActionIcons(
                      phoneNumber: contact,
                      iconSize: 16,
                      containerSize: 32,
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

/// Shimmer loading card
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
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar shimmer
              _buildShimmerBox(52, 52, isCircle: true),
              const SizedBox(width: 12),
              // Content shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(150, 16),
                    const SizedBox(height: 8),
                    _buildShimmerBox(100, 12),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildShimmerBox(24, 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox(double width, double height, {bool isCircle = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: isCircle ? null : BorderRadius.circular(8),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
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
    );
  }
}
