import '../../../event_order/domain/entities/order_item.dart';
import '../../../event_order/domain/entities/sub_event.dart';

/// Type of quotation content
enum QuotationType {
  /// Product-only quotation
  product,

  /// Event quotation with sub-events
  event,

  /// Both products and event items
  hybrid;

  String get displayName {
    switch (this) {
      case QuotationType.product:
        return 'Products';
      case QuotationType.event:
        return 'Event';
      case QuotationType.hybrid:
        return 'Event + Products';
    }
  }
}

/// Lifecycle status of a quotation
enum QuotationStatus {
  draft,
  sent,
  accepted,
  rejected,
  expired,
  converted;

  String get displayName {
    switch (this) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
      case QuotationStatus.accepted:
        return 'Accepted';
      case QuotationStatus.rejected:
        return 'Rejected';
      case QuotationStatus.expired:
        return 'Expired';
      case QuotationStatus.converted:
        return 'Converted';
    }
  }
}

/// Customer quotation with optional products and/or event details
class Quotation {
  final String id;
  final String quotationNumber;
  final QuotationType quotationType;
  final String? customerId;
  final String customerName;
  final String customerContact;
  final String? customerAddress;
  final String title;
  final String? description;
  final DateTime referenceDate;
  final String? eventLocation;
  final DateTime validUntil;
  final List<SubEvent> subEvents;
  final List<OrderItem> items;
  final double eventCharges;
  final double discountPercent;
  final double discountAmount;
  final double totalAmount;
  final String? notes;
  final QuotationStatus status;
  final String? convertedBillId;
  final String? convertedEventOrderId;
  final Map<String, dynamic> customData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Quotation({
    required this.id,
    required this.quotationNumber,
    required this.quotationType,
    this.customerId,
    required this.customerName,
    this.customerContact = '',
    this.customerAddress,
    required this.title,
    this.description,
    required this.referenceDate,
    this.eventLocation,
    required this.validUntil,
    this.subEvents = const [],
    this.items = const [],
    this.eventCharges = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    required this.totalAmount,
    this.notes,
    this.status = QuotationStatus.draft,
    this.convertedBillId,
    this.convertedEventOrderId,
    this.customData = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  double get subEventsTotal =>
      subEvents.fold(0.0, (sum, event) => sum + event.charges);

  double get productsTotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get subtotalBeforeDiscount =>
      eventCharges + subEventsTotal + productsTotal;

  Quotation copyWith({
    String? id,
    String? quotationNumber,
    QuotationType? quotationType,
    String? customerId,
    String? customerName,
    String? customerContact,
    String? customerAddress,
    String? title,
    String? description,
    DateTime? referenceDate,
    String? eventLocation,
    DateTime? validUntil,
    List<SubEvent>? subEvents,
    List<OrderItem>? items,
    double? eventCharges,
    double? discountPercent,
    double? discountAmount,
    double? totalAmount,
    String? notes,
    QuotationStatus? status,
    String? convertedBillId,
    String? convertedEventOrderId,
    Map<String, dynamic>? customData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      quotationType: quotationType ?? this.quotationType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      customerAddress: customerAddress ?? this.customerAddress,
      title: title ?? this.title,
      description: description ?? this.description,
      referenceDate: referenceDate ?? this.referenceDate,
      eventLocation: eventLocation ?? this.eventLocation,
      validUntil: validUntil ?? this.validUntil,
      subEvents: subEvents ?? this.subEvents,
      items: items ?? this.items,
      eventCharges: eventCharges ?? this.eventCharges,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      convertedBillId: convertedBillId ?? this.convertedBillId,
      convertedEventOrderId:
          convertedEventOrderId ?? this.convertedEventOrderId,
      customData: customData ?? this.customData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
