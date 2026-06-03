import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../common_widgets/file_preview_page.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/printing/models/print_bill_data.dart';
import '../../../../core/printing/services/pdf_bill_service.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../../shop/data/repositories/shop_repository.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../domain/entities/quotation.dart';

/// Builds print/PDF data and preview for quotations (billing layout, quotation tag).
class QuotationPrintService {
  QuotationPrintService._();
  static final QuotationPrintService instance = QuotationPrintService._();

  static bool _pdfGenerationInProgress = false;
  final _pdfService = PdfBillService();
  final _shopRepository = ShopRepository();

  PrintBillData createPrintData(Quotation quotation) {
    final items = <PrintBillItem>[];

    if (quotation.quotationType != QuotationType.product &&
        quotation.eventCharges > 0) {
      items.add(
        PrintBillItem(
          name: 'Event Charges',
          quantity: 1,
          rate: quotation.eventCharges,
          amount: quotation.eventCharges,
        ),
      );
    }

    for (final sub in quotation.subEvents) {
      if (sub.charges > 0) {
        items.add(
          PrintBillItem(
            name: sub.name,
            quantity: 1,
            rate: sub.charges,
            amount: sub.charges,
          ),
        );
      }
    }

    for (final item in quotation.items) {
      items.add(PrintBillItem.fromOrderItem(item));
    }

    final discountAmount = quotation.discountAmount;
    final discountPercent = quotation.discountPercent;

    return PrintBillData(
      billNumber: quotation.quotationNumber,
      dateTime: quotation.referenceDate,
      customerName: quotation.customerName,
      customerPhone: quotation.customerContact,
      items: items,
      subtotal: quotation.subtotalBeforeDiscount,
      discountAmount: discountAmount > 0 ? discountAmount : null,
      discountPercent: discountPercent > 0 ? discountPercent : null,
      grandTotal: quotation.totalAmount,
      notes: quotation.notes,
      isQuotation: true,
      validUntil: quotation.validUntil,
      quotationTitle: quotation.title,
    );
  }

  Future<void> showQuotationPdfPreview({
    required BuildContext context,
    required Quotation quotation,
    required AppLocalizations localizations,
  }) async {
    if (_pdfGenerationInProgress) return;

    _pdfGenerationInProgress = true;
    try {
      if (context.mounted) {
        GlassyToast.show(
          context,
          localizations.preparingPdf,
          icon: Icons.hourglass_top_rounded,
        );
      }

      final printData = createPrintData(quotation);
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 10),
        onTimeout: () => Shop.empty,
      );

      final file = await _pdfService
          .savePdfToFile(billData: printData, shopDetails: shop)
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () =>
                throw Exception('PDF generation timed out after 90 seconds'),
          );

      if (!file.existsSync() || file.lengthSync() == 0) {
        throw Exception('PDF file was not created successfully');
      }

      if (context.mounted) {
        GlassyToast.dismiss();
      }

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilePreviewPage(
            file: file,
            fileName:
                '${localizations.quotation} - ${quotation.quotationNumber}',
            fileType: FilePreviewType.pdf,
            subtitle: DateFormat('dd MMM yyyy').format(quotation.referenceDate),
            customerPhone: quotation.customerContact,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        GlassyToast.dismiss();
        GlassyToast.show(
          context,
          '${localizations.failedToGeneratePdf}: $e',
          isError: true,
        );
      }
    } finally {
      _pdfGenerationInProgress = false;
    }
  }
}
