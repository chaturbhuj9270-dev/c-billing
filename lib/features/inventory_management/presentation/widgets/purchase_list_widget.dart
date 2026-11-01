import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/services/language_service.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import 'purchase_card_widget.dart';
import 'purchase_filter_widget.dart';
import 'package:c_billing/common_widgets/desktop_stat_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

class _PurchaseDayGroup {
  final String label;
  final List<PurchaseBatchEntity> items;

  _PurchaseDayGroup({required this.label, required this.items});
}

// Main list widget for displaying purchase history Features: Shimmer loading, empty state, smooth scrolling, real-time updates
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

  // Filter purchases based on date and supplier
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

    final groups = _groupByDate(filteredList);

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      color: AppColors.accent(context),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 100), // Space for FAB
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dateHeader(context, group),
              ...group.items.map(
                (purchase) => PurchaseCardWidget(
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
              ),
            ],
          );
        },
      ),
    );
  }

  List<_PurchaseDayGroup> _groupByDate(List<PurchaseBatchEntity> list) {
    final sorted = [...list]
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    final Map<String, _PurchaseDayGroup> map = {};
    final dateFormat = DateFormat('dd MMM yyyy');

    for (final p in sorted) {
      final key =
          '${p.purchaseDate.year}-${p.purchaseDate.month}-${p.purchaseDate.day}';
      final group = map.putIfAbsent(
        key,
        () => _PurchaseDayGroup(
          label: dateFormat.format(p.purchaseDate),
          items: [],
        ),
      );
      group.items.add(p);
    }
    return map.values.toList();
  }

  Widget _dateHeader(BuildContext context, _PurchaseDayGroup group) {
    final total = group.items.fold<double>(
      0,
      (sum, p) => sum + (p.purchasePrice * p.quantityPurchased),
    );
    final countLabel = group.items.length == 1
        ? '1 purchase'
        : '${group.items.length} purchases';
    final amount = total
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
      child: Row(
        children: [
          Text(
            group.label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.primaryText(context),
            ),
          ),
          const Spacer(),
          Text(
            '$countLabel · ₹$amount',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.mutedText(context),
            ),
          ),
        ],
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
                duration: Duration(milliseconds: 600),
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
                    color: AppColors.accentSoft(context, 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFiltered
                        ? Icons.filter_alt_off_rounded
                        : Icons.shopping_cart_outlined,
                    size: 56,
                    color: AppColors.accentSoft(context, 0.5),
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
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.accent(context),
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
                    color: AppTheme.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Add button hint (only when not filtered)
              if (!isFiltered) ...[
                const SizedBox(height: 32),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context, 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentSoft(context, 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                          color: AppColors.accentSoft(context, 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _localizations.tapToAddFirstPurchase,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.action(context).withValues(alpha: 0.8),
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

// Summary stats widget for purchase header
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

  bool _isWeightUnit(String unit) {
    final u = unit.toLowerCase().trim();
    return u == 'kg' ||
        u == 'g' ||
        u == 'gm' ||
        u.contains('kilogram') ||
        u.contains('gram') ||
        u == 'ltr' ||
        u == 'l' ||
        u == 'ml' ||
        u.contains('liter') ||
        u.contains('litre');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    final filtered = _filteredPurchases;
    final totalAmount = filtered.fold<double>(
      0,
      (total, p) => total + (p.purchasePrice * p.quantityPurchased),
    );

    double weightQty = 0;
    double itemQty = 0;
    for (final p in filtered) {
      if (_isWeightUnit(p.unit)) {
        weightQty += p.quantityPurchased;
      } else {
        itemQty += p.quantityPurchased;
      }
    }

    if (DesktopCanvas.isDesktopPlatform) {
      return DesktopStatBar(
        stats: [
          DesktopStat(
            value: '${filtered.length}',
            label: localizations.purchases,
          ),
          DesktopStat(
            value: weightQty == 0
                ? '0'
                : (weightQty == weightQty.roundToDouble()
                      ? weightQty.toInt().toString()
                      : weightQty.toStringAsFixed(1)),
            label: 'Kg',
          ),
          DesktopStat(
            value: itemQty == 0
                ? '0'
                : (itemQty == itemQty.roundToDouble()
                      ? itemQty.toInt().toString()
                      : itemQty.toStringAsFixed(1)),
            label: 'Items',
          ),
          DesktopStat(
            value: '₹${_compactAmount(totalAmount)}',
            label: localizations.totalValue,
          ),
        ],
      );
    }

    final isDark = AppColors.isDark(context);
    final header = AppColors.headerGradient(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  header.first.withValues(alpha: 0.92),
                  header.last.withValues(alpha: 0.98),
                ]
              : [header.first, header.last],
        ),
        border: isDark
            ? Border.all(color: AppTheme.white.withValues(alpha: 0.12))
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                localizations.totalValue.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: AppTheme.white.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '₹',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_compactAmount(totalAmount)}',
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 30,
              color: AppTheme.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: AppTheme.white.withValues(alpha: 0.16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryStat(
                value: '${filtered.length}',
                label: localizations.purchases,
              ),
              _summaryDivider(),
              _summaryStat(
                value: weightQty == 0
                    ? '0'
                    : (weightQty == weightQty.roundToDouble()
                          ? weightQty.toInt().toString()
                          : weightQty.toStringAsFixed(1)),
                label: 'Kg',
              ),
              _summaryDivider(),
              _summaryStat(
                value: itemQty == 0
                    ? '0'
                    : (itemQty == itemQty.roundToDouble()
                          ? itemQty.toInt().toString()
                          : itemQty.toStringAsFixed(1)),
                label: 'Items',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _compactAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppTheme.white.withValues(alpha: 0.2),
    );
  }

  Widget _summaryStat({required String value, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: AppTheme.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
