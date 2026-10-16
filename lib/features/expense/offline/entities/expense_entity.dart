import 'package:isar_community/isar.dart';

part 'expense_entity.g.dart';

/// Expense category enum for filtering
enum ExpenseCategory {
  /// Utility bills (electricity, water, etc.)
  utilities,

  /// Shop maintenance and tools
  shopMaintenance,

  /// Employee salaries and wages
  salary,

  /// Rent payments
  rent,

  /// Transportation and logistics
  transport,

  /// Marketing and advertising
  marketing,

  /// Office supplies
  supplies,

  /// Miscellaneous expenses
  other,
}

/// Sync status for delta sync logic
enum ExpenseSyncStatus {
  /// Newly created locally, not yet on server
  newRecord,

  /// Modified locally after sync
  updated,

  /// Marked for deletion, pending server delete
  deleted,

  /// Fully synced with server
  synced,
}

/// Isar Collection for Expense with offline-first support
@collection
class ExpenseEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Expense title/name
  String title;

  /// Expense description
  String? description;

  /// Expense category (indexed for filtering)
  @Index()
  @Enumerated(EnumType.ordinal)
  ExpenseCategory category;

  /// Amount spent
  double amount;

  /// Payment method (cash, upi, bank, card, etc.)
  String? paymentMethod;

  /// Vendor/payee name
  String? vendorName;

  /// Receipt/invoice number
  String? receiptNumber;

  /// Is this a recurring expense?
  bool isRecurring;

  /// Expense date (indexed for filtering)
  @Index()
  DateTime expenseDate;

  /// Notes/remarks
  String? notes;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  ExpenseSyncStatus syncStatus;

  /// Created timestamp (indexed for sorting)
  @Index()
  DateTime createdAt;

  /// Last update timestamp for conflict resolution
  DateTime updatedAt;

  ExpenseEntity({
    this.serverId,
    required this.title,
    this.description,
    required this.category,
    required this.amount,
    this.paymentMethod,
    this.vendorName,
    this.receiptNumber,
    this.isRecurring = false,
    required this.expenseDate,
    this.notes,
    this.syncStatus = ExpenseSyncStatus.newRecord,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory for creating a new expense
  factory ExpenseEntity.create({
    required String title,
    String? description,
    required ExpenseCategory category,
    required double amount,
    String? paymentMethod,
    String? vendorName,
    String? receiptNumber,
    bool isRecurring = false,
    DateTime? expenseDate,
    String? notes,
  }) {
    final now = DateTime.now();
    return ExpenseEntity(
      title: title,
      description: description,
      category: category,
      amount: amount,
      paymentMethod: paymentMethod,
      vendorName: vendorName,
      receiptNumber: receiptNumber,
      isRecurring: isRecurring,
      expenseDate: expenseDate ?? now,
      notes: notes,
      syncStatus: ExpenseSyncStatus.newRecord,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': serverId,
      'title': title,
      'description': description,
      'category': category.index,
      'categoryName': category.name,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'vendorName': vendorName,
      'receiptNumber': receiptNumber,
      'isRecurring': isRecurring,
      'expenseDate': expenseDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from API response
  static ExpenseEntity fromJson(Map<String, dynamic> json) {
    return ExpenseEntity(
      serverId: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: ExpenseCategory.values[json['category'] as int? ?? 7],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String?,
      vendorName: json['vendorName'] as String?,
      receiptNumber: json['receiptNumber'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      expenseDate: json['expenseDate'] != null
          ? DateTime.parse(json['expenseDate'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      syncStatus: ExpenseSyncStatus.synced,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Copy with modifications
  ExpenseEntity copyWith({
    String? serverId,
    String? title,
    String? description,
    ExpenseCategory? category,
    double? amount,
    String? paymentMethod,
    String? vendorName,
    String? receiptNumber,
    bool? isRecurring,
    DateTime? expenseDate,
    String? notes,
    ExpenseSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseEntity(
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      vendorName: vendorName ?? this.vendorName,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      isRecurring: isRecurring ?? this.isRecurring,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    )..id = id;
  }
}

/// Extension for category display names and icons
extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.shopMaintenance:
        return 'Shop & Tools';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.shopMaintenance:
        return '🔧';
      case ExpenseCategory.salary:
        return '👤';
      case ExpenseCategory.rent:
        return '🏠';
      case ExpenseCategory.transport:
        return '🚚';
      case ExpenseCategory.marketing:
        return '📢';
      case ExpenseCategory.supplies:
        return '📦';
      case ExpenseCategory.other:
        return '📋';
    }
  }
}
