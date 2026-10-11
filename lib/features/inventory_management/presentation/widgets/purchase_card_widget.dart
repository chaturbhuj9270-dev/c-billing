import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// Modern card widget for displaying individual purchase items
/// Features: Subtle shadows, proper spacing, responsive layout
class PurchaseCardWidget extends StatelessWidget {
  final PurchaseBatchEntity purchase;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showSyncStatus;

  const PurchaseCardWidget({
    super.key,
    required this.purchase,
    this.onTap,
    this.onLongPress,
    this.showSyncStatus = false,
  });

  /// Calculate total amount for this batch
  double get totalAmount => purchase.purchasePrice * purchase.quantityPurchased;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final accent = Theme.of(context).primaryColor;
    final isDark = AppColors.isDark(context);
    final synced = purchase.syncStatus == BatchSyncStatus.synced;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
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
                            Icons.inventory_2_outlined,
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
                                purchase.productName,
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.primaryText(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (purchase.companyName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 13,
                                      color: AppColors.mutedText(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        purchase.companyName,
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
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.primaryText(context),
                              ),
                            ),
                            if (showSyncStatus) ...[
                              const SizedBox(height: 4),
                              Text(
                                synced ? 'Synced' : 'Pending',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: synced
                                      ? (isDark
                                            ? AppTheme.mint
                                            : AppTheme.primaryLight)
                                      : AppTheme.toneAmber,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildDetailChip(
                          context,
                          icon: Icons.layers_outlined,
                          label:
                              '${purchase.quantityPurchased} ${purchase.unit}',
                          background: AppTheme.paletteFFEEF0FF,
                          foreground: AppTheme.indigo400,
                        ),
                        const SizedBox(width: 8),
                        _buildDetailChip(
                          context,
                          icon: Icons.sell_outlined,
                          label:
                              '₹${purchase.purchasePrice.toStringAsFixed(2)}/unit',
                          background: AppTheme.paletteFFFFF4E5,
                          foreground: AppTheme.toneAmber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (purchase.supplierName != null &&
                            purchase.supplierName!.isNotEmpty) ...[
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: AppColors.mutedText(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              purchase.supplierName!,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: AppColors.mutedText(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        Text(
                          '${dateFormat.format(purchase.purchaseDate)} · ${timeFormat.format(purchase.purchaseDate)}',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? foreground.withValues(alpha: 0.16) : background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading card placeholder
class PurchaseCardShimmer extends StatelessWidget {
  const PurchaseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(44, 44, 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(double.infinity, 16, 4),
                    const SizedBox(height: 6),
                    _shimmerBox(100, 12, 4),
                  ],
                ),
              ),
              _shimmerBox(80, 20, 4),
            ],
          ),
          SizedBox(height: 14),
          Container(height: 1, color: AppColors.border(context)),
          const SizedBox(height: 14),
          Row(
            children: [
              _shimmerBox(80, 28, 8),
              const SizedBox(width: 10),
              _shimmerBox(100, 28, 8),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _shimmerBox(120, 14, 4),
              Spacer(),
              _shimmerBox(100, 24, 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    return Builder(
      builder: (context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border(context),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
