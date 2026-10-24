import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/features/billing/domain/entities/bill_item.dart';
import 'package:c_billing/features/billing/domain/entities/bill_tax_settings.dart';

/// Local parked (held) bill carts — no stock / ledger until Print Bill.
class HeldBillDraft {
  final String id;
  final DateTime heldAt;
  final String? customerId;
  final String? customerName;
  final String? customerContact;
  final List<BillItem> items;
  final double discountValue;
  final bool isPercentageDiscount;
  final bool extraChargesEnabled;
  final List<Map<String, dynamic>> extraCharges; // {label, amount}
  final GstMode gstMode;
  final bool isFullPayment;
  final double receivedAmount;
  final String paymentMode; // PaymentMode.value
  final String? notes;

  const HeldBillDraft({
    required this.id,
    required this.heldAt,
    this.customerId,
    this.customerName,
    this.customerContact,
    required this.items,
    this.discountValue = 0,
    this.isPercentageDiscount = true,
    this.extraChargesEnabled = false,
    this.extraCharges = const [],
    this.gstMode = GstMode.noGst,
    this.isFullPayment = true,
    this.receivedAmount = 0,
    this.paymentMode = 'CASH',
    this.notes,
  });

  double get itemsTotal =>
      items.fold(0.0, (s, i) => s + i.subtotal);

  String get displayTitle {
    final name = customerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final phone = customerContact?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    return 'Walk-in';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'heldAt': heldAt.toIso8601String(),
    'customerId': customerId,
    'customerName': customerName,
    'customerContact': customerContact,
    'items': items.map((i) => i.toJson()).toList(),
    'discountValue': discountValue,
    'isPercentageDiscount': isPercentageDiscount,
    'extraChargesEnabled': extraChargesEnabled,
    'extraCharges': extraCharges,
    'gstMode': gstMode.name,
    'isFullPayment': isFullPayment,
    'receivedAmount': receivedAmount,
    'paymentMode': paymentMode,
    'notes': notes,
  };

  factory HeldBillDraft.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <BillItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          items.add(BillItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    final rawCharges = json['extraCharges'];
    final charges = <Map<String, dynamic>>[];
    if (rawCharges is List) {
      for (final e in rawCharges) {
        if (e is Map) charges.add(Map<String, dynamic>.from(e));
      }
    }
    GstMode mode = GstMode.noGst;
    final modeName = json['gstMode'] as String?;
    if (modeName != null) {
      for (final m in GstMode.values) {
        if (m.name == modeName) {
          mode = m;
          break;
        }
      }
    }
    return HeldBillDraft(
      id: (json['id'] ?? '').toString(),
      heldAt: DateTime.tryParse('${json['heldAt']}') ?? DateTime.now(),
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      customerContact: json['customerContact'] as String?,
      items: items,
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      isPercentageDiscount: json['isPercentageDiscount'] as bool? ?? true,
      extraChargesEnabled: json['extraChargesEnabled'] as bool? ?? false,
      extraCharges: charges,
      gstMode: mode,
      isFullPayment: json['isFullPayment'] as bool? ?? true,
      receivedAmount: (json['receivedAmount'] as num?)?.toDouble() ?? 0,
      paymentMode: (json['paymentMode'] as String?) ?? 'CASH',
      notes: json['notes'] as String?,
    );
  }
}

class HeldBillStore {
  static const _prefsKey = 'held_bill_drafts_v1';
  static const maxHolds = 20;

  static Future<List<HeldBillDraft>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => HeldBillDraft.fromJson(Map<String, dynamic>.from(e)))
          .where((d) => d.id.isNotEmpty && d.items.isNotEmpty)
          .toList()
        ..sort((a, b) => b.heldAt.compareTo(a.heldAt));
    } catch (e) {
      debugPrint('[HeldBillStore] load failed: $e');
      return [];
    }
  }

  static Future<void> _saveAll(List<HeldBillDraft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(drafts.map((d) => d.toJson()).toList()),
    );
  }

  static Future<HeldBillDraft> add(HeldBillDraft draft) async {
    final all = await loadAll();
    all.insert(0, draft);
    while (all.length > maxHolds) {
      all.removeLast();
    }
    await _saveAll(all);
    return draft;
  }

  static Future<void> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((d) => d.id == id);
    await _saveAll(all);
  }

  static Future<int> count() async => (await loadAll()).length;
}
