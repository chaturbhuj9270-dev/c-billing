import 'dart:async';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:c_billing/common_widgets/file_preview_page.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/printing/printing.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/features/billing/data/services/bill_sync_service.dart';
import 'package:c_billing/features/billing/domain/entities/bill.dart';
import 'package:c_billing/features/billing/offline/controllers/bill_offline_controller.dart';
import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';
import 'package:c_billing/features/customer/data/services/customer_transaction_sync_service.dart';
import 'package:c_billing/features/customer/offline/controllers/customer_transaction_offline_controller.dart';
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/features/shop/domain/entities/shop.dart';

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

String _upiQueryValue(String value) {
  return Uri.encodeQueryComponent(value).replaceAll('+', '%20');
}

/// Amount the customer should pay for this bill (net of returns).
double billAmountToPay(Bill bill) {
  final returned = bill.totalReturnedAmount;
  return (bill.finalAmount - returned).clamp(0.0, double.infinity);
}

/// Shows a dynamic UPI payment QR with bill amount embedded (`am=`).
///
/// After **Payment Received**, marks the bill paid (if needed) and opens the
/// printable receipt preview.
Future<void> showBillPaymentQrSheet({
  required BuildContext context,
  required Bill bill,
  ShopRepository? shopRepository,
}) async {
  final localizations = AppLocalizations(
    LanguageService.instance.currentLanguage,
  );
  final amount = billAmountToPay(bill);
  if (amount <= 0) {
    GlassyToast.show(context, localizations.noAmountToCollect, isError: true);
    return;
  }

  GlassyToast.show(
    context,
    localizations.preparingPaymentQr,
    icon: Icons.qr_code_2_rounded,
  );

  Shop shop = Shop.empty;
  final repo = shopRepository ?? ShopRepository();
  try {
    shop = await repo.getShopDetails(forceRefresh: true);
  } catch (e) {
    debugPrint('[BillPaymentQr] Failed to load shop: $e');
  }

  if (!context.mounted) return;
  GlassyToast.dismiss();

  final upiId = shop.upiId?.trim() ?? '';
  if (upiId.isEmpty || !_looksLikeUpiId(upiId)) {
    GlassyToast.show(
      context,
      localizations.addUpiIdInShopDetails,
      isError: true,
    );
    return;
  }

  final payeeName = (shop.accountHolderName?.trim().isNotEmpty ?? false)
      ? shop.accountHolderName!.trim()
      : (shop.shopName.trim().isNotEmpty ? shop.shopName.trim() : 'Merchant');

  final upiData = buildUpiPaymentUri(
    upiId: upiId,
    payeeName: payeeName,
    amount: amount,
    note: 'Bill ${bill.billNumber}',
    transactionRef:
        'BILL${bill.billNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}',
  );

  debugPrint('[BillPaymentQr] URI: $upiData');

  final paidBill = await showAppBottomSheet<Bill>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppTheme.transparent,
    builder: (ctx) {
      return _BillPaymentQrSheet(
        bill: bill,
        amount: amount,
        upiId: upiId,
        upiData: upiData,
        localizations: localizations,
      );
    },
  );

  if (paidBill == null || !context.mounted) return;
  await _openPaymentReceiptPreview(
    context: context,
    bill: paidBill,
    shopRepository: repo,
    localizations: localizations,
  );
}

Future<void> _openPaymentReceiptPreview({
  required BuildContext context,
  required Bill bill,
  required ShopRepository shopRepository,
  required AppLocalizations localizations,
}) async {
  try {
    GlassyToast.show(
      context,
      localizations.preparingPdf,
      icon: Icons.receipt_long_rounded,
    );

    final printData = PrintBillData.fromBill(
      bill,
      totalDueAmount: bill.pendingAmount > 0 ? bill.pendingAmount : null,
    );
    final shop = await shopRepository.getShopDetails();

    if (kIsWeb) {
      final bytes = await PdfBillService().buildPdfBytes(
        billData: printData,
        shopDetails: shop,
      );
      if (!context.mounted) return;
      GlassyToast.dismiss();
      await FilePreviewPage.open(
        context,
        bytes: bytes,
        fileName: '${localizations.bills} - ${bill.billNumber}',
        fileType: FilePreviewType.pdf,
        subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
        customerPhone: bill.customerContact,
        details: FilePreviewDetails(
          title: localizations.paymentReceipt,
          documentNo: bill.billNumber,
          dateLabel: DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
          customer: (bill.customerName?.trim().isNotEmpty ?? false)
              ? bill.customerName!.trim()
              : 'Walk-in customer',
          itemsQty: '${bill.items.length} · ${bill.totalQuantity}',
          amount: '₹${bill.finalAmount.toStringAsFixed(2)}',
        ),
      );
      return;
    }

    final file = await PdfBillService().savePdfToFile(
      billData: printData,
      shopDetails: shop,
    );
    if (!context.mounted) return;
    GlassyToast.dismiss();
    await FilePreviewPage.open(
      context,
      file: file,
      fileName: '${localizations.bills} - ${bill.billNumber}',
      fileType: FilePreviewType.pdf,
      subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
      customerPhone: bill.customerContact,
      details: FilePreviewDetails(
        title: localizations.paymentReceipt,
        documentNo: bill.billNumber,
        dateLabel: DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
        customer: (bill.customerName?.trim().isNotEmpty ?? false)
            ? bill.customerName!.trim()
            : 'Walk-in customer',
        itemsQty: '${bill.items.length} · ${bill.totalQuantity}',
        amount: '₹${bill.finalAmount.toStringAsFixed(2)}',
      ),
    );
  } catch (e) {
    debugPrint('[BillPaymentQr] Receipt preview failed: $e');
    if (context.mounted) {
      GlassyToast.dismiss();
      GlassyToast.show(
        context,
        '${localizations.failedToGeneratePdf}: $e',
        isError: true,
      );
    }
  }
}

bool _looksLikeUpiId(String value) {
  return RegExp(r'^[\w.\-]{2,}@[\w.\-]{2,}$').hasMatch(value);
}

class _BillPaymentQrSheet extends StatefulWidget {
  final Bill bill;
  final double amount;
  final String upiId;
  final String upiData;
  final AppLocalizations localizations;

  const _BillPaymentQrSheet({
    required this.bill,
    required this.amount,
    required this.upiId,
    required this.upiData,
    required this.localizations,
  });

  @override
  State<_BillPaymentQrSheet> createState() => _BillPaymentQrSheetState();
}

class _BillPaymentQrSheetState extends State<_BillPaymentQrSheet> {
  bool _isProcessing = false;

  Future<BillEntity?> _resolveBillEntity(Bill bill) async {
    final ctrl = BillOfflineController.instance;
    final byServer = await ctrl.getBillByServerId(bill.id);
    if (byServer != null) return byServer;
    final localId = int.tryParse(bill.id);
    if (localId != null) return ctrl.getBillById(localId);
    return null;
  }

  Future<void> _onPaymentReceived() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final l10n = widget.localizations;
    Bill paidBill = widget.bill;

    try {
      final entity = await _resolveBillEntity(widget.bill);
      if (entity != null) {
        final due = entity.pendingAmount > 0.009 ? entity.pendingAmount : 0.0;

        if (due > 0.009) {
          final chargeable = entity.paidAmount + entity.pendingAmount;
          await BillOfflineController.instance.updatePayment(
            id: entity.id,
            paidAmount: chargeable,
            paymentStatus: BillPaymentStatus.paid,
          );

          final customerId = entity.customerId;
          if (customerId != null && customerId.isNotEmpty) {
            await CustomerTransactionOfflineController.instance
                .addPaymentTransaction(
              customerId: customerId,
              customerName: entity.customerName ?? '',
              amount: due,
              paymentMethod: 'UPI',
              description: 'UPI payment for ${widget.bill.billNumber}',
            );
          }

          unawaited(CustomerTransactionSyncService.instance.syncNow());
          unawaited(BillSyncService.instance.syncNow());
          DashboardRefreshService.instance.notifyDataChanged(
            DataChangeType.bill,
          );
        }

        final latest = await BillOfflineController.instance.getBillById(
          entity.id,
        );
        if (latest != null) {
          paidBill = Bill.fromBillEntity(latest);
        }
      }

      if (!mounted) return;
      GlassyToast.show(
        context,
        l10n.paymentReceivedReceiptReady,
        icon: Icons.check_circle_rounded,
      );
      Navigator.of(context).pop(paidBill);
    } catch (e) {
      debugPrint('[BillPaymentQr] Payment received failed: $e');
      if (mounted) {
        GlassyToast.show(context, '${l10n.error}: $e', isError: true);
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.localizations;
    final side = DesktopCanvas.isDesktopPlatform;

    return GlassDraggableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(20, side ? 12 : 8, 20, 28),
          children: [
            if (!side) const GlassSheetHandle(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft(context, 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.action(context),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.viewQr,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.bills} ${widget.bill.billNumber}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/app_logo.png',
                  height: 36,
                  width: 36,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.headerGradient(context),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.amountToPay,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: BarcodeWidget(
                    barcode: Barcode.qrCode(
                      errorCorrectLevel: BarcodeQRCorrectionLevel.medium,
                    ),
                    data: widget.upiData,
                    drawText: false,
                    color: AppTheme.black,
                    backgroundColor: AppTheme.white,
                    errorBuilder: (context, error) => _QrPlaceholder(
                      message: l10n.failedToGenerateQr,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.scanQrToPayBillAmount,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.payViaAnyUPIApp,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                color: AppColors.mutedText(context),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.upiId));
                  if (context.mounted) {
                    GlassyToast.show(context, l10n.upiIdCopied);
                  }
                },
                icon: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppColors.action(context),
                ),
                label: Text(
                  widget.upiId,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    color: AppColors.action(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _onPaymentReceived,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isProcessing ? l10n.generatingLabel : l10n.paymentReceived,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.action(context),
                  foregroundColor: AppTheme.white,
                  disabledBackgroundColor: AppColors.action(
                    context,
                  ).withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  final String message;

  const _QrPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_outlined, size: 48, color: AppTheme.grey400),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              color: AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
