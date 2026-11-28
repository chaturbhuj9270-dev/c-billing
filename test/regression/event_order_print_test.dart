// Regression guard: event / order invoice POS mapping and format setting.
// Feature: event-order-invoice.
import 'package:c_billing/features/event_order/data/services/event_order_format_settings.dart';
import 'package:c_billing/features/event_order/data/services/event_order_pdf_service.dart';
import 'package:c_billing/features/event_order/domain/entities/event_order.dart';
import 'package:c_billing/features/event_order/domain/entities/order_item.dart';
import 'package:c_billing/features/event_order/domain/entities/sub_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 3, 1);

EventOrder _event() => EventOrder(
      id: 'e1',
      orderType: OrderType.event,
      customerName: 'Asha',
      customerContact: '9999999999',
      orderName: 'Wedding',
      eventDate: _now,
      subEvents: [
        SubEvent(id: 's1', name: 'Haldi', date: _now, charges: 300),
        SubEvent(id: 's2', name: 'Sangeet', date: _now, charges: 200),
      ],
      eventCharges: 500,
      totalAmount: 1000,
      advanceAmount: 400,
      remainingAmount: 600,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  final svc = EventOrderPdfService();

  test('event totals: charges + sub-events, balance = total - advance', () {
    final d = svc.createPrintData(_event());
    expect(d.grandTotal, 1000);
    expect(d.paidAmount, 400);
    expect(d.pendingAmount, 600);
    expect(d.qrAmountOverride, 600);
    expect(d.numberLabel, 'Event');
    expect(d.documentHeaderTitle, 'EVENT INVOICE');
    expect(d.items.length, 3); // Event Charges + 2 sub-events
    expect(d.items.fold<double>(0, (t, i) => t + i.amount), 1000);
  });

  test('fully paid order has no pending and no payment QR amount', () {
    final e = EventOrder(
      id: 'e2',
      orderType: OrderType.event,
      customerName: 'A',
      customerContact: '1',
      orderName: 'X',
      eventDate: _now,
      eventCharges: 500,
      totalAmount: 500,
      advanceAmount: 500,
      remainingAmount: 0,
      createdAt: _now,
      updatedAt: _now,
    );
    final d = svc.createPrintData(e);
    expect(d.pendingAmount, 0);
    expect(d.qrAmountOverride, 0);
  });

  test('sales order uses Order labels', () {
    final item = OrderItem(
      id: 'i1',
      productId: 'p1',
      productName: 'Cake',
      quantity: 2,
      rate: 100,
      subtotal: 200,
      total: 200,
    );
    final e = EventOrder(
      id: 'o1',
      orderType: OrderType.salesOrder,
      customerName: 'A',
      customerContact: '1',
      orderName: 'Order 1',
      eventDate: _now,
      items: [item],
      totalAmount: 200,
      remainingAmount: 200,
      createdAt: _now,
      updatedAt: _now,
    );
    final d = svc.createPrintData(e);
    expect(d.numberLabel, 'Order');
    expect(d.documentHeaderTitle, 'ORDER INVOICE');
    expect(d.grandTotal, 200);
  });

  group('format setting', () {
    test('defaults to normal so existing users see no change', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await EventOrderFormatSettings.getFormatType(), 'normal');
    });

    test('round-trips pos and ignores garbage', () async {
      SharedPreferences.setMockInitialValues({});
      await EventOrderFormatSettings.setFormatType('pos');
      expect(await EventOrderFormatSettings.getFormatType(), 'pos');
      await EventOrderFormatSettings.setFormatType('bogus');
      expect(await EventOrderFormatSettings.getFormatType(), 'normal');
    });
  });
}
