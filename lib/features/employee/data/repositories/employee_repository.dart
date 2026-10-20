import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// FirebaseAuth used for secondary-app employee creation only.
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
      final snap = await _employeesCol.orderBy('displayName').get();
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

  Future<Employee> createEmployee({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    String? counterLabel,
    required List<String> allowedModules,
  }) async {
    if (!AccessControlService.instance.isOwner) {
      throw StateError('Only the shop admin can create employees');
    }
    final ownerId = TenantContext.dataOwnerId;
    final modules = _sanitizeModules(allowedModules);

    String employeeUid;
    try {
      final callable = _functions.httpsCallable('createEmployee');
      final result = await callable.call(<String, dynamic>{
        'email': email.trim(),
        'password': password,
        'displayName': displayName.trim(),
        'phone': phone?.trim(),
        'counterLabel': counterLabel?.trim(),
        'allowedModules': modules,
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
        counterLabel: counterLabel?.trim(),
        modules: modules,
        ownerId: ownerId,
      );
    }

    final employee = Employee(
      id: employeeUid,
      email: email.trim(),
      displayName: displayName.trim(),
      phone: phone?.trim(),
      counterLabel: counterLabel?.trim(),
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
    final modules = _sanitizeModules(employee.allowedModules);
    final payload = <String, dynamic>{
      'displayName': employee.displayName.trim(),
      'phone': employee.phone?.trim(),
      'counterLabel': employee.counterLabel?.trim(),
      'allowedModules': modules,
      'active': employee.active,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final callable = _functions.httpsCallable('updateEmployee');
      await callable.call(<String, dynamic>{
        'employeeUid': employee.id,
        'displayName': employee.displayName.trim(),
        'phone': employee.phone?.trim(),
        'counterLabel': employee.counterLabel?.trim(),
        'allowedModules': modules,
        'active': employee.active,
      });
    } catch (e) {
      debugPrint(
        '[EmployeeRepository] CF updateEmployee failed, writing Firestore: $e',
      );
      await _employeesCol.doc(employee.id).set(payload, SetOptions(merge: true));
      await _firestore.collection('users').doc(employee.id).set({
        'displayName': employee.displayName.trim(),
        'phone': employee.phone?.trim(),
        'counterLabel': employee.counterLabel?.trim(),
        'allowedModules': modules,
        'active': employee.active,
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
    String? counterLabel,
    required List<String> modules,
    required String ownerId,
  }) async {
    // Create Auth user on a secondary app so the admin session stays signed in.
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
        // Previous attempt may have created Auth but failed Firestore writes.
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
        counterLabel: counterLabel,
        modules: modules,
        ownerId: ownerId,
      );

      return uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
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
    String? counterLabel,
    required List<String> modules,
    required String ownerId,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _employeesCol.doc(uid).set({
      'id': uid,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'counterLabel': counterLabel,
      'allowedModules': modules,
      'active': true,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'counterLabel': counterLabel,
      'allowedModules': modules,
      'active': true,
      'role': 'employee',
      'tenantOwnerId': ownerId,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  List<String> _sanitizeModules(List<String> raw) {
    final grantable = AppModule.grantable.map((m) => m.key).toSet();
    final cleaned = raw.where(grantable.contains).toSet();
    // Password always allowed for self-service; dashboard/expenses stay opt-in.
    cleaned.add(AppModule.password.key);
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
        counterLabel: Value(e.counterLabel),
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
            counterLabel: Value(e.counterLabel),
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
      return rows
          .map(
            (r) => Employee(
              id: r.serverId ?? '${r.id}',
              email: r.email,
              displayName: r.displayName,
              phone: r.phone,
              counterLabel: r.counterLabel,
              allowedModules: r.allowedModulesJson
                  .split(',')
                  .where((s) => s.isNotEmpty)
                  .toList(),
              active: r.active,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
