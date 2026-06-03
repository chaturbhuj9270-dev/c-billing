import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../../../event_order/domain/entities/order_item.dart';
import '../../../event_order/domain/entities/sub_event.dart';
import '../../../event_order/offline/entities/event_order_entity.dart';
import '../../domain/entities/quotation.dart';
import '../entities/quotation_entity.dart';

class QuotationOfflineController extends ChangeNotifier {
  static QuotationOfflineController? _instance;

  final Isar _isar;

  QuotationOfflineController._(this._isar);

  static QuotationOfflineController get instance {
    _instance ??= QuotationOfflineController._(IsarService.instance.isar);
    return _instance!;
  }

  @visibleForTesting
  static void resetInstance() => _instance = null;

  Future<String> _nextQuotationNumber() async {
    final count = await _isar.quotationEntitys.count();
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'Q-$datePart-${(count + 1).toString().padLeft(3, '0')}';
  }

  double _calculateTotal({
    required QuotationType type,
    required List<SubEvent> subEvents,
    required List<OrderItem> items,
    required double eventCharges,
    required double discountPercent,
    required double discountAmount,
  }) {
    var subtotal = 0.0;
    if (type == QuotationType.product) {
      subtotal = items.fold(0.0, (sum, item) => sum + item.total);
    } else if (type == QuotationType.event) {
      subtotal =
          eventCharges + subEvents.fold(0.0, (sum, event) => sum + event.charges);
    } else {
      subtotal =
          eventCharges +
          subEvents.fold(0.0, (sum, event) => sum + event.charges) +
          items.fold(0.0, (sum, item) => sum + item.total);
    }

    if (discountAmount > 0) {
      return (subtotal - discountAmount).clamp(0.0, double.infinity);
    }
    if (discountPercent > 0) {
      return (subtotal - (subtotal * discountPercent / 100))
          .clamp(0.0, double.infinity);
    }
    return subtotal;
  }

  Future<QuotationEntity> addQuotation({
    required QuotationType quotationType,
    String? customerId,
    required String customerName,
    String customerContact = '',
    String? customerAddress,
    required String title,
    String? description,
    required DateTime referenceDate,
    String? eventLocation,
    required DateTime validUntil,
    List<SubEvent> subEvents = const [],
    List<OrderItem> items = const [],
    double eventCharges = 0.0,
    double discountPercent = 0.0,
    double discountAmount = 0.0,
    String? notes,
    QuotationStatus status = QuotationStatus.draft,
    Map<String, dynamic>? customData,
  }) async {
    final now = DateTime.now();
    final quotationNumber = await _nextQuotationNumber();
    final totalAmount = _calculateTotal(
      type: quotationType,
      subEvents: subEvents,
      items: items,
      eventCharges: eventCharges,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
    );

    final entity = QuotationEntity.create(
      quotationNumber: quotationNumber,
      quotationType: quotationType.index,
      customerId: customerId,
      customerName: customerName,
      customerContact: customerContact,
      customerAddress: customerAddress,
      title: title,
      description: description,
      referenceDate: referenceDate,
      eventLocation: eventLocation,
      validUntil: validUntil,
      subEvents: subEvents.map(SubEventEmbedded.fromDomain).toList(),
      items: items.map(OrderItemEmbedded.fromDomain).toList(),
      eventCharges: eventCharges,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      notes: notes,
      status: status.index,
      customDataJson: customData != null && customData.isNotEmpty
          ? jsonEncode(customData)
          : null,
      createdAt: now,
      updatedAt: now,
      syncStatus: QuotationSyncStatus.newRecord,
    );

    await _isar.writeTxn(() async {
      await _isar.quotationEntitys.put(entity);
    });

    notifyListeners();
    return entity;
  }

  Future<QuotationEntity?> updateQuotation({
    required Id id,
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
    String? notes,
    QuotationStatus? status,
    Map<String, dynamic>? customData,
  }) async {
    final existing = await _isar.quotationEntitys.get(id);
    if (existing == null) return null;

    final type = quotationType ?? QuotationType.values[existing.quotationType];
    final updatedSubEvents = subEvents ??
        existing.subEvents.map((e) => e.toDomain()).toList();
    final updatedItems =
        items ?? existing.items.map((e) => e.toDomain()).toList();
    final updatedEventCharges = eventCharges ?? existing.eventCharges;
    final updatedDiscountPercent =
        discountPercent ?? existing.discountPercent;
    final updatedDiscountAmount = discountAmount ?? existing.discountAmount;

    existing.quotationType = type.index;
    existing.customerId = customerId ?? existing.customerId;
    existing.customerName = customerName ?? existing.customerName;
    existing.customerContact = customerContact ?? existing.customerContact;
    existing.customerAddress = customerAddress ?? existing.customerAddress;
    existing.title = title ?? existing.title;
    existing.description = description ?? existing.description;
    existing.referenceDate = referenceDate ?? existing.referenceDate;
    existing.eventLocation = eventLocation ?? existing.eventLocation;
    existing.validUntil = validUntil ?? existing.validUntil;
    existing.subEvents =
        updatedSubEvents.map(SubEventEmbedded.fromDomain).toList();
    existing.items = updatedItems.map(OrderItemEmbedded.fromDomain).toList();
    existing.eventCharges = updatedEventCharges;
    existing.discountPercent = updatedDiscountPercent;
    existing.discountAmount = updatedDiscountAmount;
    existing.totalAmount = _calculateTotal(
      type: type,
      subEvents: updatedSubEvents,
      items: updatedItems,
      eventCharges: updatedEventCharges,
      discountPercent: updatedDiscountPercent,
      discountAmount: updatedDiscountAmount,
    );
    existing.notes = notes ?? existing.notes;
    existing.status = status?.index ?? existing.status;
    if (customData != null) {
      existing.customDataJson = customData.isNotEmpty
          ? jsonEncode(customData)
          : null;
    }
    existing.updatedAt = DateTime.now();
    if (existing.syncStatus == QuotationSyncStatus.synced) {
      existing.syncStatus = QuotationSyncStatus.updated;
    }

    await _isar.writeTxn(() async {
      await _isar.quotationEntitys.put(existing);
    });

    notifyListeners();
    return existing;
  }

  Future<bool> deleteQuotation(Id id) async {
    final existing = await _isar.quotationEntitys.get(id);
    if (existing == null) return false;

    if (existing.syncStatus == QuotationSyncStatus.newRecord) {
      await _isar.writeTxn(() async {
        await _isar.quotationEntitys.delete(id);
      });
    } else {
      existing.syncStatus = QuotationSyncStatus.deleted;
      existing.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.quotationEntitys.put(existing);
      });
    }

    notifyListeners();
    return true;
  }

  Future<List<QuotationEntity>> getAllQuotations() async {
    return _isar.quotationEntitys
        .filter()
        .not()
        .syncStatusEqualTo(QuotationSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Stream<List<QuotationEntity>> watchAllQuotations() {
    return _isar.quotationEntitys
        .filter()
        .not()
        .syncStatusEqualTo(QuotationSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<QuotationEntity?> getQuotationById(Id id) async {
    return _isar.quotationEntitys.get(id);
  }

  Future<int> getTotalCount() async {
    return _isar.quotationEntitys
        .filter()
        .not()
        .syncStatusEqualTo(QuotationSyncStatus.deleted)
        .count();
  }
}
