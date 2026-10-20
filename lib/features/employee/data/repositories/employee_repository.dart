import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/access/access_control_service.dart';
import '../../../../core/access/app_module.dart';
import '../../../../core/access/tenant_context.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/local_database.dart';
import '../../../../firebase_options.dart';
import '../../domain/entities/employee.dart';

// Admin CRUD for shop employees. Creates Auth users under the shop owner tenant.
class EmployeeRepository {
  EmployeeRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _employeesCol {
    final ownerId = TenantContext.dataOwnerId;
    return _firestore.collection('users').doc(ownerId).collection('employees');
  }

  AppDatabase get _db => LocalDatabase.instance.db;

  Future<List<Employee>> getEmployees() async {
    if (!AccessControlService.instance.isOwner) {
      throw StateError('Only the shop admin can manage employees');
    }

    try {
      final snap = await _employeesCol.orderBy('tokenNumber').get();
      final list = snap.docs
          .map((d) => Employee.fromJson(d.data(), id: d.id))
          .toList();
      await _cacheLocal(list);
      return list;
    } catch (e) {
      debugPrint('[EmployeeRepository] remote list failed, using local: $e');
      return _loadLocal();
    }
  }

  // Resolve active employee by billing token (owner or counter staff).
  Future<Employee?> findByToken(int tokenNumber) async {
    if (tokenNumber <= 0) return null;
    try {
      final snap = await _employeesCol
          .where('tokenNumber', isEqualTo: tokenNumber)
          .limit(5)
          .get();
      for (final doc in snap.docs) {
        final emp = Employee.fromJson(doc.data(), id: doc.id);
        if (emp.active) return emp;
      }
    } catch (e) {
      debugPrint('[EmployeeRepository] findByToken remote failed: $e');
    }
    try {
      final rows = await (_db.select(_db.employeeRecords)
            ..where((t) => t.tokenNumber.equals(tokenNumber)))
          .get();
      for (final r in rows) {
        if (!r.active) continue;
        return _fromRecord(r);
      }
    } catch (e) {
      debugPrint('[EmployeeRepository] findByToken local failed: $e');
    }
    return null;
  }

  Employee _fromRecord(EmployeeRecord r) {
    return Employee(
      id: r.serverId ?? '${r.id}',
      email: r.email,
      displayName: r.displayName,
      phone: r.phone,
      tokenNumber: r.tokenNumber,
      counterAccess: r.counterAccess,
      points: r.points,
      dateOfBirth: r.dateOfBirth,
      address: r.address,
      pinCode: r.pinCode,
      govIdNumber: r.govIdNumber,
      govIdType: r.govIdType,
      salary: r.salary,
      dateOfJoining: r.dateOfJoining,
      allowedModules: r.allowedModulesJson
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      active: r.active,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  // Credit cloth-collection points: ₹1000 sales = 1 point.
  Future<void> addSalesPoints({
    required int tokenNumber,
    required double salesAmount,
  }) async {
    if (tokenNumber <= 0 || salesAmount <= 0) return;
    final points = double.parse((salesAmount / 1000).toStringAsFixed(4));
    if (points <= 0) return;
    final emp = await findByToken(tokenNumber);
    if (emp == null) {
      throw StateError('No active employee for token $tokenNumber');
    }

    try {
      await _employeesCol.doc(emp.id).set({
        'points': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[EmployeeRepository] addSalesPoints remote failed: $e');
    }

    final updated = emp.copyWith(
      points: emp.points + points,
      updatedAt: DateTime.now(),
    );
    await _upsertLocal(updated);
  }

  // Next free token: max(existing) + 1, starting at 1.
  Future<int> nextTokenNumber() async {
    try {
      final snap = await _employeesCol
          .orderBy('tokenNumber', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final raw = snap.docs.first.data()['tokenNumber'];
        final max = raw is int ? raw : int.tryParse('$raw') ?? 0;
        return max + 1;
      }
    } catch (e) {
      debugPrint('[EmployeeRepository] nextToken remote failed: $e');
    }
    try {
      final rows = await _db.select(_db.employeeRecords).get();
      var max = 0;
      for (final r in rows) {
        if (r.tokenNumber > max) max = r.tokenNumber;
      }
      return max + 1;
    } catch (_) {
      return 1;
    }
  }

  Future<Employee> createEmployee({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    required bool counterAccess,
    required List<String> allowedModules,
    DateTime? dateOfBirth,
    String? address,
    String? pinCode,
    String? govIdNumber,
    String? govIdType,
    double? salary,
    DateTime? dateOfJoining,
  }) async {
    if (!AccessControlService.instance.isOwner) {
      throw StateError('Only the shop admin can create employees');
    }
    final ownerId = TenantContext.dataOwnerId;
    final modules = _sanitizeModules(allowedModules, counterAccess: counterAccess);
    final tokenNumber = await nextTokenNumber();
    final profile = <String, dynamic>{
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address?.trim(),
      'pinCode': pinCode?.trim(),
      'govIdNumber': govIdNumber?.trim(),
      'govIdType': govIdType?.trim(),
      'salary': salary,
      'dateOfJoining': dateOfJoining?.toIso8601String(),
    };

    String employeeUid;
    try {
      final callable = _functions.httpsCallable('createEmployee');
      final result = await callable.call(<String, dynamic>{
        'email': email.trim(),
        'password': password,
        'displayName': displayName.trim(),
        'phone': phone?.trim(),
        'tokenNumber': tokenNumber,
        'counterAccess': counterAccess,
        'allowedModules': modules,
        ...profile,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      employeeUid = data['uid'] as String;
    } catch (e) {
      debugPrint(
        '[EmployeeRepository] Cloud Function createEmployee failed, using secondary Auth: $e',
      );
      employeeUid = await _createWithSecondaryAuth(
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
        phone: phone?.trim(),
        tokenNumber: tokenNumber,
        counterAccess: counterAccess,
        modules: modules,
        ownerId: ownerId,
        profile: profile,
      );
    }

    // Ensure profile fields are stored even if CF ignored them.
    await _employeesCol.doc(employeeUid).set(profile, SetOptions(merge: true));

    final employee = Employee(
      id: employeeUid,
      email: email.trim(),
      displayName: displayName.trim(),
      phone: phone?.trim(),
      tokenNumber: tokenNumber,
      counterAccess: counterAccess,
      points: 0,
      dateOfBirth: dateOfBirth,
      address: address?.trim(),
      pinCode: pinCode?.trim(),
      govIdNumber: govIdNumber?.trim(),
      govIdType: govIdType?.trim(),
      salary: salary,
      dateOfJoining: dateOfJoining,
      allowedModules: modules,
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _upsertLocal(employee);
    return employee;
  }

  Future<void> updateEmployee(Employee employee) async {
    if (!AccessControlService.instance.isOwner) {
      throw StateError('Only the shop admin can update employees');
    }
    final modules = _sanitizeModules(
      employee.allowedModules,
      counterAccess: employee.counterAccess,
    );
    final payload = <String, dynamic>{
      'displayName': employee.displayName.trim(),
      'phone': employee.phone?.trim(),
      'tokenNumber': employee.tokenNumber,
      'counterAccess': employee.counterAccess,
      'allowedModules': modules,
      'active': employee.active,
      ...employee.profileToJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final callable = _functions.httpsCallable('updateEmployee');
      await callable.call(<String, dynamic>{
        'employeeUid': employee.id,
        'displayName': employee.displayName.trim(),
        'phone': employee.phone?.trim(),
        'tokenNumber': employee.tokenNumber,
        'counterAccess': employee.counterAccess,
        'allowedModules': modules,
        'active': employee.active,
        ...employee.profileToJson(),
      });
    } catch (e) {
      debugPrint(
        '[EmployeeRepository] CF updateEmployee failed, writing Firestore: $e',
      );
      await _employeesCol.doc(employee.id).set(payload, SetOptions(merge: true));
      await _firestore.collection('users').doc(employee.id).set({
        'displayName': employee.displayName.trim(),
        'phone': employee.phone?.trim(),
        'tokenNumber': employee.tokenNumber,
        'counterAccess': employee.counterAccess,
        'allowedModules': modules,
        'active': employee.active,
        ...employee.profileToJson(),
        'role': 'employee',
        'tenantOwnerId': TenantContext.dataOwnerId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _upsertLocal(employee.copyWith(
      allowedModules: modules,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> setActive(String employeeId, bool active) async {
    final emp = (await getEmployees()).firstWhere((e) => e.id == employeeId);
    await updateEmployee(emp.copyWith(active: active));
  }

  Future<String> _createWithSecondaryAuth({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    required int tokenNumber,
    required bool counterAccess,
    required List<String> modules,
    required String ownerId,
    Map<String, dynamic> profile = const {},
  }) async {
    FirebaseApp? secondary;
    try {
      secondary = await Firebase.initializeApp(
        name: 'employeeCreator',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      secondary = Firebase.app('employeeCreator');
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);
    try {
      String? uid;
      try {
        final cred = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        uid = cred.user?.uid;
        await cred.user?.updateDisplayName(displayName);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          final signedIn = await secondaryAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          uid = signedIn.user?.uid;
          await signedIn.user?.updateDisplayName(displayName);
        } else {
          rethrow;
        }
      }
      if (uid == null || uid.isEmpty) {
        throw StateError('Failed to create employee auth user');
      }

      await _writeEmployeeDocs(
        uid: uid,
        email: email,
        displayName: displayName,
        phone: phone,
        tokenNumber: tokenNumber,
        counterAccess: counterAccess,
        modules: modules,
        ownerId: ownerId,
        profile: profile,
      );

      return uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw StateError(
          'This email is already registered. Use a different email, or the same temporary password used when it was first created.',
        );
      }
      rethrow;
    } finally {
      try {
        await secondaryAuth.signOut();
      } catch (_) {}
    }
  }

  Future<void> _writeEmployeeDocs({
    required String uid,
    required String email,
    required String displayName,
    String? phone,
    required int tokenNumber,
    required bool counterAccess,
    required List<String> modules,
    required String ownerId,
    Map<String, dynamic> profile = const {},
  }) async {
    final now = FieldValue.serverTimestamp();
    await _employeesCol.doc(uid).set({
      'id': uid,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'tokenNumber': tokenNumber,
      'counterAccess': counterAccess,
      'points': 0,
      ...profile,
      'allowedModules': modules,
      'active': true,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'tokenNumber': tokenNumber,
      'counterAccess': counterAccess,
      'points': 0,
      ...profile,
      'allowedModules': modules,
      'active': true,
      'role': 'employee',
      'tenantOwnerId': ownerId,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  List<String> _sanitizeModules(
    List<String> raw, {
    required bool counterAccess,
  }) {
    final grantable = AppModule.grantable.map((m) => m.key).toSet();
    final cleaned = raw.where(grantable.contains).toSet();
    cleaned.add(AppModule.password.key);
    if (!counterAccess) {
      cleaned.remove(AppModule.billing.key);
    }
    return cleaned.toList()..sort();
  }

  Future<void> _cacheLocal(List<Employee> list) async {
    try {
      await _db.delete(_db.employeeRecords).go();
      for (final e in list) {
        await _upsertLocal(e);
      }
    } catch (e) {
      debugPrint('[EmployeeRepository] local cache skipped: $e');
    }
  }

  Future<void> _upsertLocal(Employee e) async {
    try {
      final existing = await (_db.select(
        _db.employeeRecords,
      )..where((t) => t.serverId.equals(e.id))).getSingleOrNull();

      final companion = EmployeeRecordsCompanion.insert(
        serverId: Value(e.id),
        email: e.email,
        displayName: e.displayName,
        phone: Value(e.phone),
        tokenNumber: Value(e.tokenNumber),
        counterAccess: Value(e.counterAccess),
        points: Value(e.points),
        dateOfBirth: Value(e.dateOfBirth),
        address: Value(e.address),
        pinCode: Value(e.pinCode),
        govIdNumber: Value(e.govIdNumber),
        govIdType: Value(e.govIdType),
        salary: Value(e.salary),
        dateOfJoining: Value(e.dateOfJoining),
        allowedModulesJson: Value(e.allowedModules.join(',')),
        active: Value(e.active),
        syncStatus: const Value(1),
        createdAt: e.createdAt ?? DateTime.now(),
        updatedAt: e.updatedAt ?? DateTime.now(),
      );

      if (existing == null) {
        await _db.into(_db.employeeRecords).insert(companion);
      } else {
        await (_db.update(
          _db.employeeRecords,
        )..where((t) => t.id.equals(existing.id))).write(
          EmployeeRecordsCompanion(
            email: Value(e.email),
            displayName: Value(e.displayName),
            phone: Value(e.phone),
            tokenNumber: Value(e.tokenNumber),
            counterAccess: Value(e.counterAccess),
            points: Value(e.points),
            dateOfBirth: Value(e.dateOfBirth),
            address: Value(e.address),
            pinCode: Value(e.pinCode),
            govIdNumber: Value(e.govIdNumber),
            govIdType: Value(e.govIdType),
            salary: Value(e.salary),
            dateOfJoining: Value(e.dateOfJoining),
            allowedModulesJson: Value(e.allowedModules.join(',')),
            active: Value(e.active),
            syncStatus: const Value(1),
            updatedAt: Value(e.updatedAt ?? DateTime.now()),
          ),
        );
      }
    } catch (err) {
      debugPrint('[EmployeeRepository] upsert local failed: $err');
    }
  }

  Future<List<Employee>> _loadLocal() async {
    try {
      final rows = await _db.select(_db.employeeRecords).get();
      return rows.map(_fromRecord).toList()
        ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
    } catch (_) {
      return [];
    }
  }
}
