import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/bill_repository.dart';

/// Firebase implementation of BillRepository
class FirebaseBillRepository implements BillRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'bills';

  FirebaseBillRepository({
    required FirebaseFirestore firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore,
       _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference get _billsCollection {
    return _firestore.collection('users').doc(_userId).collection(_collection);
  }

  @override
  Future<String> createBill(Bill bill) async {
    try {
      final docRef = await _billsCollection.add(bill.copyWith(id: '').toJson());

      // Update document with its ID
      await docRef.update({'id': docRef.id});

      // Update bill items with the bill ID
      final updatedItems = bill.items
          .map((item) => item.copyWith(billId: docRef.id).toJson())
          .toList();
      await docRef.update({'items': updatedItems});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create bill: $e');
    }
  }

  @override
  Future<Bill?> getBillById(String id) async {
    try {
      final doc = await _billsCollection.doc(id).get();
      if (doc.exists) {
        return Bill.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get bill: $e');
    }
  }

  @override
  Future<List<Bill>> getAllBills() async {
    try {
      try {
        final snapshot = await _billsCollection
            .orderBy('billDate', descending: true)
            .get();
        return snapshot.docs
            .map((doc) => Bill.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Fallback if index not available
        if (e.toString().contains('index') ||
            e.toString().contains('FAILED_PRECONDITION')) {
          print(
            '[DEBUG] Composite index not found, getting bills without ordering',
          );
          final snapshot = await _billsCollection.get();
          final bills = snapshot.docs
              .map((doc) => Bill.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          bills.sort((a, b) => b.billDate.compareTo(a.billDate));
          return bills;
        }
        throw e;
      }
    } catch (e) {
      throw Exception('Failed to get all bills: $e');
    }
  }

  @override
  Future<List<Bill>> getBillsByCustomerId(String customerId) async {
    try {
      try {
        final snapshot = await _billsCollection
            .where('customerId', isEqualTo: customerId)
            .orderBy('billDate', descending: true)
            .get();
        return snapshot.docs
            .map((doc) => Bill.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (e.toString().contains('index') ||
            e.toString().contains('FAILED_PRECONDITION')) {
          final snapshot = await _billsCollection
              .where('customerId', isEqualTo: customerId)
              .get();
          final bills = snapshot.docs
              .map((doc) => Bill.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          bills.sort((a, b) => b.billDate.compareTo(a.billDate));
          return bills;
        }
        throw e;
      }
    } catch (e) {
      throw Exception('Failed to get bills by customer: $e');
    }
  }

  @override
  Future<List<Bill>> getBillsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      try {
        final snapshot = await _billsCollection
            .where(
              'billDate',
              isGreaterThanOrEqualTo: startDate.toIso8601String(),
            )
            .where('billDate', isLessThanOrEqualTo: endDate.toIso8601String())
            .orderBy('billDate', descending: true)
            .get();
        return snapshot.docs
            .map((doc) => Bill.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (e.toString().contains('index') ||
            e.toString().contains('FAILED_PRECONDITION')) {
          final snapshot = await _billsCollection
              .where(
                'billDate',
                isGreaterThanOrEqualTo: startDate.toIso8601String(),
              )
              .where('billDate', isLessThanOrEqualTo: endDate.toIso8601String())
              .get();
          final bills = snapshot.docs
              .map((doc) => Bill.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          bills.sort((a, b) => b.billDate.compareTo(a.billDate));
          return bills;
        }
        throw e;
      }
    } catch (e) {
      throw Exception('Failed to get bills by date range: $e');
    }
  }

  @override
  Future<List<Bill>> getTodaysBills() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getBillsByDateRange(startOfDay, endOfDay);
  }

  @override
  Future<void> updateBill(Bill bill) async {
    try {
      await _billsCollection.doc(bill.id).update(bill.toJson());
    } catch (e) {
      throw Exception('Failed to update bill: $e');
    }
  }

  @override
  Future<void> deleteBill(String id) async {
    try {
      await _billsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete bill: $e');
    }
  }

  @override
  Future<double> getTotalSalesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<Bill> bills;
      if (startDate != null && endDate != null) {
        bills = await getBillsByDateRange(startDate, endDate);
      } else {
        bills = await getAllBills();
      }
      double total = 0.0;
      for (final bill in bills) {
        total += bill.totalAmount;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total sales amount: $e');
    }
  }

  @override
  Future<int> getTotalBillsCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<Bill> bills;
      if (startDate != null && endDate != null) {
        bills = await getBillsByDateRange(startDate, endDate);
      } else {
        bills = await getAllBills();
      }
      return bills.length;
    } catch (e) {
      throw Exception('Failed to get total bills count: $e');
    }
  }

  @override
  Future<List<Bill>> searchBills(String query) async {
    try {
      final allBills = await getAllBills();
      final lowerQuery = query.toLowerCase();
      return allBills.where((bill) {
        final customerName = bill.customerName?.toLowerCase() ?? '';
        final customerContact = bill.customerContact?.toLowerCase() ?? '';
        final billId = bill.id.toLowerCase();
        return customerName.contains(lowerQuery) ||
            customerContact.contains(lowerQuery) ||
            billId.contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search bills: $e');
    }
  }

  /// Get Firestore instance for transaction operations
  FirebaseFirestore get firestore => _firestore;

  /// Get user ID for transaction operations
  String get userId => _userId;
}
