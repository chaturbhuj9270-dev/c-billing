/// Shared maths for the value of goods returned from a bill.
///
/// A return never changes `Bill.finalAmount` (the original invoice stays as it
/// was); it only raises `returnedQuantity` on the items. Every report that
/// shows "sales" must therefore subtract the returned value itself, using the
/// SAME ratio the customer ledger refund uses
/// (`InventoryIntegrationService.processReturn`: finalAmount / totalAmount), so
/// the dashboard, invoice totals and customer ledger always agree.
class SaleReturnMath {
  SaleReturnMath._();

  /// Share of an item's selling price that the customer was actually charged
  /// (covers discount, exclusive tax and extra charges).
  static double chargeRatio({
    required double totalAmount,
    required double finalAmount,
  }) => totalAmount > 0 ? finalAmount / totalAmount : 1.0;

  /// Value refunded for [returnedQuantity] units at [sellingPrice].
  static double returnedValue({
    required double sellingPrice,
    required double returnedQuantity,
    required double chargeRatio,
  }) => sellingPrice * returnedQuantity * chargeRatio;

  /// Sales of one bill after returns, never below zero.
  static double netSales({
    required double finalAmount,
    required double returnedValue,
  }) {
    final net = finalAmount - returnedValue;
    return net < 0.005 ? 0.0 : net;
  }
}
