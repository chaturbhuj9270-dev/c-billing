// Regression guard: customer pending report + WhatsApp message.
// Feature: customer-pending-report. The report is read-only and must always add
// up to the pending total shown on the customer card (the ledger value).
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/services/whatsapp_share_service.dart';
import 'package:c_billing/features/customer/data/services/customer_pending_report_service.dart';
import 'package:c_billing/features/shop/domain/entities/shop.dart';
import 'package:flutter_test/flutter_test.dart';

CustomerPendingReport _report({
  required double total,
  List<PendingBillRow> bills = const [],
  List<PendingEventRow> events = const [],
}) {
  return CustomerPendingReport(
    customerName: 'Vasant Shende',
    phone: '9876543210',
    generatedAt: DateTime(2026, 11, 27),
    bills: bills,
    events: events,
    totalPending: total,
  );
}

void main() {
  final bill = PendingBillRow(
    billNo: '#12',
    date: DateTime(2026, 11, 1),
    total: 500,
    paid: 300,
    pending: 200,
  );
  final event = PendingEventRow(
    name: 'Wedding',
    date: DateTime(2026, 11, 5),
    total: 1000,
    paid: 400,
    pending: 600,
  );

  test('other amount makes the statement add up to the ledger total', () {
    final r = _report(total: 1000, bills: [bill], events: [event]);
    expect(r.billsListedTotal, 200);
    expect(r.eventsListedTotal, 600);
    expect(r.otherAmount, 200); // opening balance / adjustment
    expect(r.hasOther, isTrue);
  });

  test('no other amount when bills and events explain the total', () {
    final r = _report(total: 800, bills: [bill], events: [event]);
    expect(r.hasOther, isFalse);
  });

  test('amount formatting', () {
    expect(CustomerPendingReportService.formatAmount(200), '200');
    expect(CustomerPendingReportService.formatAmount(200.5), '200.50');
    expect(CustomerPendingReportService.formatAmountGrouped(2500), '2,500');
    expect(CustomerPendingReportService.formatAmountGrouped(200), '200');
    expect(
      CustomerPendingReportService.formatAmountGrouped(125000),
      '1,25,000',
    );
    expect(
      CustomerPendingReportService.formatAmountGrouped(1234567.5),
      '12,34,567.50',
    );
  });

  test('statement PDF is generated', () async {
    final bytes = await CustomerPendingReportService.instance.buildPdf(
      _report(total: 800, bills: [bill], events: [event]),
      Shop.empty,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('statement PDF carries the reminder message inside it', () async {
    final report = _report(total: 800, bills: [bill], events: [event]);
    final plain = await CustomerPendingReportService.instance.buildPdf(
      report,
      Shop.empty,
    );
    final withNote = await CustomerPendingReportService.instance.buildPdf(
      report,
      Shop.empty,
      message:
          'Dear Customer, your pending payment of ₹2,500 is outstanding.\n\n'
          'Thank you!',
    );
    expect(String.fromCharCodes(withNote.take(4)), '%PDF');
    expect(withNote.length, greaterThan(plain.length));
  });

  test('WhatsApp number is normalised with country code', () {
    expect(WhatsAppShareService.normalizePhone('98765 43210'), '919876543210');
    expect(
      WhatsAppShareService.normalizePhone('+91 98765-43210'),
      '919876543210',
    );
    expect(
      WhatsAppShareService.normalizePhone('00919876543210'),
      '919876543210',
    );
  });

  test('message is localised in all three languages with amount and shop', () {
    for (final lang in ['English', 'Hindi', 'Marathi']) {
      final msg = AppLocalizations.of(lang).customerPendingWhatsAppMessage(
        'Vasant',
        'My Shop',
        '200',
        '27 Nov 2026',
      );
      expect(msg, contains('My Shop'));
      expect(msg, contains('₹200'));
    }
    final en = AppLocalizations.of(
      'English',
    ).customerPendingWhatsAppMessage('Vasant', 'My Shop', '200', '27 Nov 2026');
    expect(en, contains('Dear Customer'));
    expect(
      en,
      contains('Kindly clear the amount at your earliest convenience'),
    );
    expect(en, contains('If already paid, please ignore this message.'));
    expect(en, contains('Thank you for your support and business!'));
    expect(en, contains('₹200 with My Shop'));
  });

  test('second-step prompt text exists in all three languages', () {
    final seen = <String>{};
    for (final lang in ['English', 'Hindi', 'Marathi']) {
      final l10n = AppLocalizations.of(lang);
      expect(l10n.customerReportSendMessageTitle, isNotEmpty);
      expect(l10n.customerReportSendMessageBody, isNotEmpty);
      expect(l10n.customerReportSendMessage, isNotEmpty);
      seen.add(l10n.customerReportSendMessageTitle);
    }
    expect(seen.length, 3);
  });

  test('return hint exists in all three languages and differs', () {
    final hints = {
      for (final lang in ['English', 'Hindi', 'Marathi'])
        AppLocalizations.of(lang).customerReportSendPdfHint,
    };
    expect(hints.length, 3);
    expect(hints.every((h) => h.isNotEmpty), isTrue);
    final opening = {
      for (final lang in ['English', 'Hindi', 'Marathi'])
        AppLocalizations.of(lang).customerReportOpeningPdf,
    };
    expect(opening.length, 3);
  });
}
