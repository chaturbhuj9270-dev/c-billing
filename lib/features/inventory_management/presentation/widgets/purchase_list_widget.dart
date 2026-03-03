import 'package:flutter/material.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/services/language_service.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import 'purchase_card_widget.dart';
import 'purchase_filter_widget.dart';

/// Main list widget for displaying purchase history
/// Features: Shimmer loading, empty state, smooth scrolling, real-time updates
class PurchaseListWidget extends StatefulWidget {
  final List<PurchaseBatchEntity> purchases;
  final bool isLoading;
  final PurchaseDateFilter dateFilter;
  final String? supplierFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final VoidCallback? onRefresh;
  final Function(PurchaseBatchEntity)? onPurchaseTap;
  final Function(PurchaseBatchEntity)? onPurchaseLongPress;
  final String emptyTitle;
  final String emptySubtitle;

  const PurchaseListWidget({
    super.key,
    required this.purchases,
    this.isLoading = false,
    this.dateFilter = PurchaseDateFilter.all,
    this.supplierFilter,
    this.customStartDate,
    this.customEndDate,
    this.onRefresh,
    this.onPurchaseTap,
    this.onPurchaseLongPress,
    this.emptyTitle = 'No Purchases Found',
    this.emptySubtitle = 'Your purchase history will appear here',
  });

  @override
  State<PurchaseListWidget> createState() => _PurchaseListWidgetState();
}

class _PurchaseListWidgetState extends State<PurchaseListWidget> {
  final ScrollController _scrollController = ScrollController();
  late AppLocalizations _localizations;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Filter purchases based on date and supplier
  List<PurchaseBatchEntity> get _filteredPurchases {
    var filtered = widget.purchases;

    // Apply date filter
    if (widget.dateFilter == PurchaseDateFilter.today) {
      final today = DateTime.now();
      filtered = filtered.where((p) {
        return p.purchaseDate.year == today.year &&
            p.purchaseDate.month == today.month &&
            p.purchaseDate.day == today.day;
      }).toList();
    } else if (widget.dateFilter == PurchaseDateFilter.thisMonth) {
      final now = DateTime.now();
      filtered = filtered.where((p) {
        return p.purchaseDate.year == now.year &&
            p.purchaseDate.month == now.month;
      }).toList();
    } else if (widget.dateFilter == PurchaseDateFilter.thisYear) {
      final now = DateTime.now();
      filtered = filtered.where((p) {
        return p.purchaseDate.year == now.year;
      }).toList();
    } else if (widget.dateFilter == PurchaseDateFilter.custom &&
        widget.customStartDate != null) {
      final start = DateTime(
        widget.customStartDate!.year,
        widget.customStartDate!.month,
        widget.customStartDate!.day,
      );
      final end = widget.customEndDate != null
          ? DateTime(
              widget.customEndDate!.year,
              widget.customEndDate!.month,
              widget.customEndDate!.day,
              23,
              59,
              59,
            )
          : DateTime(start.year, start.month, start.day, 23, 59, 59);
      filtered = filtered.where((p) {
        return p.purchaseDate.isAfter(
              start.subtract(const Duration(seconds: 1)),
            ) &&
            p.purchaseDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    // Apply supplier filter
    if (widget.supplierFilter != null && widget.supplierFilter!.isNotEmpty) {
      filtered = filtered
          .where((p) => p.supplierId == widget.supplierFilter)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    if (widget.isLoading) {
      return _buildShimmerList();
    }

    final filteredList = _filteredPurchases;

    if (filteredList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      color: const Color(0xFF1B4D3E),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 100), // Space for FAB
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final purchase = filteredList[index];
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: PurchaseCardWidget(
              key: ValueKey(purchase.id),
              purchase: purchase,
              onTap: widget.onPurchaseTap != null
                  ? () => widget.onPurchaseTap!(purchase)
                  : null,
              onLongPress: widget.onPurchaseLongPress != null
                  ? () => widget.onPurchaseLongPress!(purchase)
                  : null,
              showSyncStatus: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: const PurchaseCardShimmer(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isFiltered =
        widget.dateFilter != PurchaseDateFilter.all ||
        widget.supplierFilter != null;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon container
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFiltered
                        ? Icons.filter_alt_off_rounded
                        : Icons.shopping_cart_outlined,
                    size: 56,
                    color: const Color(0xFF1B4D3E).withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  isFiltered
                      ? _localizations.noMatchingPurchases
                      : widget.emptyTitle,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF1B4D3E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Text(
                  isFiltered
                      ? _localizations.tryAdjustingFilters
                      : widget.emptySubtitle,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Add button hint (only when not filtered)
              if (!isFiltered) ...[
                const SizedBox(height: 32),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1B4D3E).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                          color: const Color(0xFF1B4D3E).withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _localizations.tapToAddFirstPurchase,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: const Color(0xFF1B4D3E).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary stats widget for purchase header
class PurchaseSummaryWidget extends StatelessWidget {
  final List<PurchaseBatchEntity> purchases;
  final PurchaseDateFilter dateFilter;
  final String? supplierFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const PurchaseSummaryWidget({
    super.key,
    required this.purchases,
    this.dateFilter = PurchaseDateFilter.all,
    this.supplierFilter,
    this.customStartDate,
    this.customEndDate,
  });

  List<PurchaseBatchEntity> get _filteredPurchases {
    var filtered = purchases;

    if (dateFilter == PurchaseDateFilter.today) {
      final today = DateTime.now();
      filtered = filtered.where((p) {
        return p.purchaseDate.year == today.year &&
            p.purchaseDate.month == today.month &&
            p.purchaseDate.day == today.day;
      }).toList();
    } else if (dateFilter == PurchaseDateFilter.thisMonth) {
      final now = DateTime.now();
      filtered = filtered.where((p) {
        return p.purchaseDate.year == now.year &&
            p.purchaseDate.month == now.month;
      }).toList();
    } else if (dateFilter == PurchaseDateFilter.thisYear) {
      final now = DateTime.now();
      filtered = filtered.where((p) {
        return p.purchaseDate.year == now.year;
      }).toList();
    } else if (dateFilter == PurchaseDateFilter.custom &&
        customStartDate != null) {
      final start = DateTime(
        customStartDate!.year,
        customStartDate!.month,
        customStartDate!.day,
      );
      final end = customEndDate != null
          ? DateTime(
              customEndDate!.year,
              customEndDate!.month,
              customEndDate!.day,
              23,
              59,
              59,
            )
          : DateTime(start.year, start.month, start.day, 23, 59, 59);
      filtered = filtered.where((p) {
        return p.purchaseDate.isAfter(
              start.subtract(const Duration(seconds: 1)),
            ) &&
            p.purchaseDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    if (supplierFilter != null && supplierFilter!.isNotEmpty) {
      filtered = filtered.where((p) => p.supplierId == supplierFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    final filtered = _filteredPurchases;
    final totalAmount = filtered.fold<double>(
      0,
      (sum, p) => sum + (p.purchasePrice * p.quantityPurchased),
    );
    final totalQuantity = filtered.fold<int>(
      0,
      (sum, p) => sum + p.quantityPurchased,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B4D3E),
            const Color(0xFF1B4D3E).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.receipt_long_rounded,
            label: _localizations.purchases,
            value: '${filtered.length}',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.inventory_2_rounded,
            label: _localizations.totalQty,
            value: '$totalQuantity',
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              icon: Icons.currency_rupee_rounded,
              label: _localizations.totalValue,
              value: '₹${totalAmount.toStringAsFixed(0)}',
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
    bool isExpanded = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
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
      color: Colors.white.withOpacity(0.2),
    );
  }
}
