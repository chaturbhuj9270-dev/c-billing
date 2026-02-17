import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../offline/entities/purchase_batch_entity.dart';

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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              splashColor: const Color(0xFF1B4D3E).withOpacity(0.1),
              highlightColor: const Color(0xFF1B4D3E).withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Product name + Total amount
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product icon container
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4D3E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFF1B4D3E),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Product name and company
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                purchase.productName,
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF1B4D3E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (purchase.companyName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      size: 12,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        purchase.companyName,
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          color: Colors.grey[600],
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
                        // Total amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                            if (showSyncStatus)
                              _buildSyncBadge(),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Details row
                    Row(
                      children: [
                        // Quantity
                        _buildDetailChip(
                          icon: Icons.layers_rounded,
                          label: '${purchase.quantityPurchased} ${purchase.unit}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        // Price per unit
                        _buildDetailChip(
                          icon: Icons.currency_rupee_rounded,
                          label: '${purchase.purchasePrice.toStringAsFixed(2)}/unit',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Bottom row: Supplier + Date
                    Row(
                      children: [
                        // Supplier
                        if (purchase.supplierName != null && purchase.supplierName!.isNotEmpty) ...[
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              purchase.supplierName!,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        
                        // Date and time
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(purchase.purchaseDate),
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                timeFormat.format(purchase.purchaseDate),
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
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

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color.withOpacity(0.8),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBadge() {
    Color badgeColor;
    IconData badgeIcon;
    
    switch (purchase.syncStatus) {
      case BatchSyncStatus.synced:
        badgeColor = Colors.green;
        badgeIcon = Icons.cloud_done_rounded;
        break;
      case BatchSyncStatus.newRecord:
      case BatchSyncStatus.updated:
        badgeColor = Colors.orange;
        badgeIcon = Icons.cloud_upload_rounded;
        break;
      case BatchSyncStatus.deleted:
        badgeColor = Colors.red;
        badgeIcon = Icons.delete_outline_rounded;
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Icon(
        badgeIcon,
        size: 14,
        color: badgeColor,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.grey[200]),
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
              const Spacer(),
              _shimmerBox(100, 24, 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
