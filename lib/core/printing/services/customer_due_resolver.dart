import 'package:flutter/foundation.dart';

import '../../../features/customer/offline/controllers/customer_offline_controller.dart';
import '../bill_print_math.dart';
import '../models/print_bill_data.dart';

/// Fills `PrintBillData.totalDueAmount` with the customer's total pending
/// amount till date (read-only, local DB only - no Firestore reads, no ledger
/// writes). Used by every print renderer so all print paths agree.
///
/// Only bills that carry a [PrintBillData.customerId] are touched; walk-in
/// bills, return slips, quotations and event invoices print exactly as before.
class CustomerDueResolver {
  CustomerDueResolver._();

  /// Test hook: replaces the local lookup. Return null when unknown.
  @visibleForTesting
  static Future<double?> Function(String customerId)? debugLookup;

  static Future<PrintBillData> apply(PrintBillData data) async {
    if (data.isReturnBill || data.isQuotation) return data;
    final key = data.customerId;
    if (key == null || key.isEmpty) return data;
    try {
      final pending = await (debugLookup?.call(key) ?? _lookup(key)).timeout(
        const Duration(seconds: 3),
      );
      final due = resolveTotalDue(
        customerPending: pending,
        billPending: data.pendingAmount ?? 0,
        fallback: data.totalDueAmount,
      );
      if (due == data.totalDueAmount) return data;
      return data.withTotalDue(due);
    } catch (e) {
      debugPrint('[CustomerDueResolver] using bill pending only: $e');
      return data;
    }
  }

  static Future<double?> _lookup(String key) async {
    final controller = CustomerOfflineController.instance;
    var customer = await controller.getCustomerByServerId(key);
    if (customer == null) {
      var localId = int.tryParse(key);
      if (localId == null && key.startsWith('local_')) {
        localId = int.tryParse(key.substring(6));
      }
      if (localId != null) customer = await controller.getCustomerById(localId);
    }
    return customer?.currentPendingAmount;
  }
}
