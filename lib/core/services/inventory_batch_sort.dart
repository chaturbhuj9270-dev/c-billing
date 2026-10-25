import 'package:c_billing/core/services/purchase_settings_service.dart';
import 'package:c_billing/features/inventory_management/domain/entities/purchase_batch.dart';
import 'package:c_billing/features/inventory_management/offline/entities/purchase_batch_entity.dart';

/// Sorts purchase batches for sale consumption: FIFO (purchase date) or FEFO (expiry first).
class InventoryBatchSort {
  InventoryBatchSort._();

  static int compareEntities(
    PurchaseBatchEntity a,
    PurchaseBatchEntity b, {
    bool? useFefo,
  }) {
    final fefo = useFefo ?? PurchaseSettingsService.instance.useFefo;
    if (fefo) {
      final byExpiry = _compareNullableDates(a.expiryDate, b.expiryDate);
      if (byExpiry != 0) return byExpiry;
    }
    return a.purchaseDate.compareTo(b.purchaseDate);
  }

  static int compareBatches(
    PurchaseBatch a,
    PurchaseBatch b, {
    bool? useFefo,
  }) {
    final fefo = useFefo ?? PurchaseSettingsService.instance.useFefo;
    if (fefo) {
      final byExpiry = _compareNullableDates(a.expiryDate, b.expiryDate);
      if (byExpiry != 0) return byExpiry;
    }
    return a.purchaseDate.compareTo(b.purchaseDate);
  }

  /// Earliest expiry first; batches without expiry sort last.
  static int _compareNullableDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}
