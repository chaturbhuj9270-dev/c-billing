/// Shared UPI payment URI helpers for Scan QR and printed bill QR codes.
library;

/// Builds a UPI pay URI with a fixed amount so UPI apps autofill (and usually lock) it.
String buildUpiPaymentUri({
  required String upiId,
  required String payeeName,
  required double amount,
  String? note,
  String? transactionRef,
}) {
  final pa = upiId.trim();
  final pn = _upiQueryValue(
    payeeName.trim().isEmpty ? 'Merchant' : payeeName.trim(),
  );
  final am = amount.toStringAsFixed(2);
  final buffer = StringBuffer('upi://pay?pa=$pa&pn=$pn&am=$am&cu=INR');

  final trimmedNote = note?.trim();
  if (trimmedNote != null && trimmedNote.isNotEmpty) {
    buffer.write('&tn=${_upiQueryValue(trimmedNote)}');
  }

  final tr = transactionRef?.trim();
  if (tr != null && tr.isNotEmpty) {
    buffer.write('&tr=${_upiQueryValue(tr)}');
  }

  return buffer.toString();
}

bool looksLikeUpiId(String value) {
  return RegExp(r'^[\w.\-]{2,}@[\w.\-]{2,}$').hasMatch(value.trim());
}

/// Net amount the customer should pay for this bill (grand total minus returns).
double billPrintAmountToPay({
  required double grandTotal,
  double returnedAmount = 0,
}) {
  return (grandTotal - returnedAmount).clamp(0.0, double.infinity);
}

String upiPayeeName({
  String? accountHolderName,
  String? shopName,
}) {
  final holder = accountHolderName?.trim() ?? '';
  if (holder.isNotEmpty) return holder;
  final shop = shopName?.trim() ?? '';
  if (shop.isNotEmpty) return shop;
  return 'Merchant';
}

String _upiQueryValue(String value) {
  return Uri.encodeQueryComponent(value).replaceAll('+', '%20');
}
