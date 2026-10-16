import 'dart:convert';
import 'package:isar_community/isar.dart';
import '../../../event_order/offline/entities/event_order_entity.dart';
import '../../domain/entities/quotation.dart';

part 'quotation_entity.g.dart';

enum QuotationSyncStatus { newRecord, updated, deleted, synced }

@collection
class QuotationEntity {
  Id id = Isar.autoIncrement;

  @Index()
  String? serverId;

  @Index()
  String quotationNumber;

  /// 0=product, 1=event, 2=hybrid
  int quotationType;

  @Index()
  String? customerId;

  String customerName;
  String customerContact;
  String? customerAddress;

  @Index()
  String title;

  String? description;

  @Index()
  DateTime referenceDate;

  String? eventLocation;

  @Index()
  DateTime validUntil;

  List<SubEventEmbedded> subEvents;
  List<OrderItemEmbedded> items;

  double eventCharges;
  double discountPercent;
  double discountAmount;
  double totalAmount;

  String? notes;

  /// 0=draft, 1=sent, 2=accepted, 3=rejected, 4=expired, 5=converted
  @Index()
  int status;

  String? convertedBillId;
  String? convertedEventOrderId;

  String? customDataJson;

  @Index()
  DateTime createdAt;

  DateTime updatedAt;

  @Enumerated(EnumType.ordinal)
  QuotationSyncStatus syncStatus;

  QuotationEntity({
    this.serverId,
    this.quotationNumber = '',
    this.quotationType = 0,
    this.customerId,
    this.customerName = '',
    this.customerContact = '',
    this.customerAddress,
    this.title = '',
    this.description,
    required this.referenceDate,
    this.eventLocation,
    required this.validUntil,
    required this.subEvents,
    required this.items,
    this.eventCharges = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.notes,
    this.status = 0,
    this.convertedBillId,
    this.convertedEventOrderId,
    this.customDataJson,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = QuotationSyncStatus.newRecord,
  });

  QuotationEntity.create({
    this.serverId,
    required this.quotationNumber,
    this.quotationType = 0,
    this.customerId,
    this.customerName = '',
    this.customerContact = '',
    this.customerAddress,
    this.title = '',
    this.description,
    DateTime? referenceDate,
    this.eventLocation,
    DateTime? validUntil,
    List<SubEventEmbedded>? subEvents,
    List<OrderItemEmbedded>? items,
    this.eventCharges = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.notes,
    this.status = 0,
    this.convertedBillId,
    this.convertedEventOrderId,
    this.customDataJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = QuotationSyncStatus.newRecord,
  })  : referenceDate = referenceDate ?? DateTime.now(),
        validUntil =
            validUntil ?? DateTime.now().add(const Duration(days: 15)),
        subEvents = subEvents ?? [],
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Quotation toDomain() {
    Map<String, dynamic> customData = {};
    if (customDataJson != null && customDataJson!.isNotEmpty) {
      try {
        customData = jsonDecode(customDataJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return Quotation(
      id: serverId ?? 'local_$id',
      quotationNumber: quotationNumber,
      quotationType: QuotationType.values[quotationType.clamp(
        0,
        QuotationType.values.length - 1,
      )],
      customerId: customerId,
      customerName: customerName,
      customerContact: customerContact,
      customerAddress: customerAddress,
      title: title,
      description: description,
      referenceDate: referenceDate,
      eventLocation: eventLocation,
      validUntil: validUntil,
      subEvents: subEvents.map((e) => e.toDomain()).toList(),
      items: items.map((e) => e.toDomain()).toList(),
      eventCharges: eventCharges,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      notes: notes,
      status: QuotationStatus.values[status.clamp(
        0,
        QuotationStatus.values.length - 1,
      )],
      convertedBillId: convertedBillId,
      convertedEventOrderId: convertedEventOrderId,
      customData: customData,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static QuotationEntity fromDomain(Quotation quotation, {Id? localId}) {
    return QuotationEntity(
      serverId: quotation.id.startsWith('local_') ? null : quotation.id,
      quotationNumber: quotation.quotationNumber,
      quotationType: quotation.quotationType.index,
      customerId: quotation.customerId,
      customerName: quotation.customerName,
      customerContact: quotation.customerContact,
      customerAddress: quotation.customerAddress,
      title: quotation.title,
      description: quotation.description,
      referenceDate: quotation.referenceDate,
      eventLocation: quotation.eventLocation,
      validUntil: quotation.validUntil,
      subEvents: quotation.subEvents
          .map(SubEventEmbedded.fromDomain)
          .toList(),
      items: quotation.items.map(OrderItemEmbedded.fromDomain).toList(),
      eventCharges: quotation.eventCharges,
      discountPercent: quotation.discountPercent,
      discountAmount: quotation.discountAmount,
      totalAmount: quotation.totalAmount,
      notes: quotation.notes,
      status: quotation.status.index,
      convertedBillId: quotation.convertedBillId,
      convertedEventOrderId: quotation.convertedEventOrderId,
      customDataJson: quotation.customData.isNotEmpty
          ? jsonEncode(quotation.customData)
          : null,
      createdAt: quotation.createdAt,
      updatedAt: quotation.updatedAt,
    )..id = localId ?? Isar.autoIncrement;
  }
}
