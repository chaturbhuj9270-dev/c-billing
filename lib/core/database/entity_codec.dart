import 'dart:convert';

import '../../features/billing/domain/entities/bill_extra_charge.dart';
import '../../features/billing/offline/entities/bill_entity.dart';
import '../../features/event_order/offline/entities/event_order_entity.dart';

T enumAt<T>(List<T> values, int index) {
  if (values.isEmpty) {
    throw StateError('Empty enum list');
  }
  if (index < 0 || index >= values.length) return values.first;
  return values[index];
}

String encodeBillItems(List<BillItemEmbedded> items) {
  return jsonEncode(items.map((item) => item.toJson()).toList());
}

List<BillItemEmbedded> decodeBillItems(String raw) {
  if (raw.isEmpty) return [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return [];
  return decoded
      .whereType<Map>()
      .map((item) => BillItemEmbedded.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

String encodeExtraCharges(List<BillExtraCharge> charges) {
  return jsonEncode(charges.map((c) => c.toJson()).toList());
}

List<BillExtraCharge> decodeExtraCharges(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => BillExtraCharge.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.label.trim().isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

String encodeSubEvents(List<SubEventEmbedded> events) {
  return jsonEncode(events.map(_subEventToJson).toList());
}

List<SubEventEmbedded> decodeSubEvents(String raw) {
  if (raw.isEmpty) return [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return [];
  return decoded.whereType<Map>().map((item) {
    final json = Map<String, dynamic>.from(item);
    return SubEventEmbedded(
      id: json['id'] as String?,
      name: json['name'] as String?,
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
      charges: (json['charges'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      customDataJson: json['customDataJson'] as String?,
    );
  }).toList();
}

Map<String, dynamic> _subEventToJson(SubEventEmbedded event) {
  return {
    'id': event.id,
    'name': event.name,
    'date': event.date?.toIso8601String(),
    'charges': event.charges,
    'notes': event.notes,
    'customDataJson': event.customDataJson,
  };
}

String encodeOrderItems(List<OrderItemEmbedded> items) {
  return jsonEncode(items.map(_orderItemToJson).toList());
}

List<OrderItemEmbedded> decodeOrderItems(String raw) {
  if (raw.isEmpty) return [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return [];
  return decoded.whereType<Map>().map((item) {
    final json = Map<String, dynamic>.from(item);
    return OrderItemEmbedded(
      id: json['id'] as String?,
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      hsnCode: json['hsnCode'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      cgstPercent: (json['cgstPercent'] as num?)?.toDouble() ?? 0,
      sgstPercent: (json['sgstPercent'] as num?)?.toDouble() ?? 0,
      cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0,
      sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }).toList();
}

Map<String, dynamic> _orderItemToJson(OrderItemEmbedded item) {
  return {
    'id': item.id,
    'productId': item.productId,
    'productName': item.productName,
    'hsnCode': item.hsnCode,
    'quantity': item.quantity,
    'rate': item.rate,
    'discountPercent': item.discountPercent,
    'discountAmount': item.discountAmount,
    'cgstPercent': item.cgstPercent,
    'sgstPercent': item.sgstPercent,
    'cgstAmount': item.cgstAmount,
    'sgstAmount': item.sgstAmount,
    'taxAmount': item.taxAmount,
    'subtotal': item.subtotal,
    'total': item.total,
  };
}
