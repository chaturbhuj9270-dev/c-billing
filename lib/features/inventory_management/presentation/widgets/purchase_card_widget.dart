import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/sync_status_icon.dart';

// Modern card widget for displaying individual purchase items Features: Subtle shadows, proper spacing, responsive layout
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

  // Calculate total amount for this batch
  double get totalAmount => purchase.purchasePrice * purchase.quantityPurchased;

  String get _qtyText {
    final q = purchase.quantityPurchased;
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toStringAsFixed(2);
  }

  String get _unitText {
    final u = purchase.unit.trim();
    return u.isEmpty ? 'ITEM' : u.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final accent = AppColors.action(context);
    final isDark = AppColors.isDark(context);
    final synced = purchase.syncStatus == BatchSyncStatus.synced;
    final rateUnit = purchase.unit.trim().isEmpty ? 'unit' : purchase.unit;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading qty + unit box (mockup).
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.indigo400.withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _qtyText,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.05,
                              color: isDark
                                  ? AppTheme.white
                                  : AppTheme.indigo400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _unitText,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              letterSpacing: 0.3,
                              height: 1.1,
                              color: (isDark
                                      ? AppTheme.white
                                      : AppTheme.indigo400)
                                  .withValues(alpha: 0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.primaryText(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (purchase.companyName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              purchase.companyName,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedText(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          // Icon only, theme color (see SyncStatusIcon).
                          SyncStatusIcon(
                            isSynced: synced,
                            size: 16,
                            padded: false,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.toneAmber.withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sell_outlined,
                            size: 13,
                            color: AppTheme.toneAmber,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '₹${purchase.purchasePrice.toStringAsFixed(2)} / $rateUnit',
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppTheme.toneAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (purchase.supplierName != null &&
                        purchase.supplierName!.isNotEmpty) ...[
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.mutedText(context),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          purchase.supplierName!,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: AppColors.mutedText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.mutedText(context),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      timeFormat.format(purchase.purchaseDate),
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
    );
  }
}

// Shimmer loading card placeholder
class PurchaseCardShimmer extends StatelessWidget {
  const PurchaseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
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
              _shimmerBox(56, 56, 14),
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
              _shimmerBox(72, 18, 4),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _shimmerBox(100, 28, 14),
              const SizedBox(width: 10),
              _shimmerBox(90, 14, 4),
              const Spacer(),
              _shimmerBox(60, 14, 4),
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
