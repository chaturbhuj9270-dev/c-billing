import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../entities/company_entity.dart';

// Offline-first controller for Company CRUD operations. All operations go to the local database first, then sync in the background.
class CompanyOfflineController extends ChangeNotifier {
  static CompanyOfflineController? _instance;

  final AppDatabase _db;

  CompanyOfflineController._(this._db);

  static CompanyOfflineController get instance {
    _instance ??= CompanyOfflineController._(LocalDatabase.instance.db);
    return _instance!;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  Future<bool> isCompanyCodeTaken(String code, {int? excludeId}) async {
    if (code.trim().isEmpty) return false;

    final needle = code.toLowerCase();
    final existing = (await _db.loadCompanies()).where(
      (company) =>
          company.syncStatus != CompanySyncStatus.deleted &&
          company.companyCode.toLowerCase() == needle,
    );
    if (excludeId != null) {
      return existing.any((company) => company.id != excludeId);
    }
    return existing.isNotEmpty;
  }

  Future<CompanyEntity> addCompany({
    required String companyName,
    String companyCode = '',
    String gstCode = '',
    String contact = '',
    String address = '',
  }) async {
    if (companyCode.isNotEmpty) {
      final codeTaken = await isCompanyCodeTaken(companyCode);
      if (codeTaken) {
        throw Exception('Company code "$companyCode" already exists');
      }
    }

    final company = CompanyEntity.create(
      companyName: companyName,
      companyCode: companyCode,
      gstCode: gstCode,
      contact: contact,
      address: address,
      syncStatus: CompanySyncStatus.newRecord,
    );

    await _db.saveCompany(company);

    debugPrint('[CompanyOffline] Company added: ${company.id}, status: NEW');
    notifyListeners();
    return company;
  }

  Future<List<CompanyEntity>> getAllCompanies() async {
    final companies = (await _db.loadCompanies())
        .where((company) => company.syncStatus != CompanySyncStatus.deleted)
        .toList();
    companies.sort((a, b) => a.companyName.compareTo(b.companyName));
    return companies;
  }

  Stream<List<CompanyEntity>> watchAllCompanies() {
    return _db.watchCompanies().map((rows) {
      final companies = rows
          .where((company) => company.syncStatus != CompanySyncStatus.deleted)
          .toList();
      companies.sort((a, b) => a.companyName.compareTo(b.companyName));
      return companies;
    });
  }

  Future<CompanyEntity?> getCompanyById(int id) async {
    for (final company in await _db.loadCompanies()) {
      if (company.id == id) return company;
    }
    return null;
  }

  Future<CompanyEntity?> getCompanyByServerId(String serverId) async {
    for (final company in await _db.loadCompanies()) {
      if (company.serverId == serverId) return company;
    }
    return null;
  }

  Future<CompanyEntity?> getCompanyByContact(String contact) async {
    for (final company in await _db.loadCompanies()) {
      if (company.contact == contact &&
          company.syncStatus != CompanySyncStatus.deleted) {
        return company;
      }
    }
    return null;
  }

  Future<List<CompanyEntity>> searchByName(String query) async {
    if (query.isEmpty) return getAllCompanies();

    final needle = query.toLowerCase();
    final companies = (await _db.loadCompanies()).where((company) {
      if (company.syncStatus == CompanySyncStatus.deleted) return false;
      return company.companyName.toLowerCase().contains(needle) ||
          company.contact.contains(query);
    }).toList();
    companies.sort((a, b) => a.companyName.compareTo(b.companyName));
    return companies;
  }

  Future<CompanyEntity?> updateCompany({
    required int id,
    String? companyName,
    String? companyCode,
    String? gstCode,
    String? contact,
    String? address,
    bool? isActive,
  }) async {
    final existing = await getCompanyById(id);
    if (existing == null) {
      debugPrint('[CompanyOffline] Company not found: $id');
      return null;
    }

    if (companyCode != null && companyCode != existing.companyCode) {
      final codeTaken = await isCompanyCodeTaken(companyCode, excludeId: id);
      if (codeTaken) {
        throw Exception('Company code "$companyCode" already exists');
      }
    }

    final CompanySyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case CompanySyncStatus.newRecord:
        newSyncStatus = CompanySyncStatus.newRecord;
        break;
      case CompanySyncStatus.synced:
      case CompanySyncStatus.updated:
        newSyncStatus = CompanySyncStatus.updated;
        break;
      case CompanySyncStatus.deleted:
        newSyncStatus = CompanySyncStatus.deleted;
        break;
    }

    final updated = existing.copyWith(
      companyName: companyName,
      companyCode: companyCode,
      gstCode: gstCode,
      contact: contact,
      address: address,
      isActive: isActive,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _db.saveCompany(updated);

    debugPrint(
      '[CompanyOffline] Company updated: ${updated.id}, syncStatus: ${updated.syncStatus}',
    );
    notifyListeners();
    return updated;
  }

  Future<void> deleteCompany(int id) async {
    final existing = await getCompanyById(id);
    if (existing == null) {
      debugPrint('[CompanyOffline] Company not found for delete: $id');
      return;
    }

    if (existing.syncStatus == CompanySyncStatus.newRecord) {
      await _db.deleteCompanyById(id);
      debugPrint(
        '[CompanyOffline] Company hard deleted (was never synced): $id',
      );
    } else {
      final deleted = existing.copyWith(
        syncStatus: CompanySyncStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await _db.saveCompany(deleted);
      debugPrint('[CompanyOffline] Company marked for deletion: $id');
    }

    notifyListeners();
  }

  Future<void> permanentlyDelete(int id) async {
    await _db.deleteCompanyById(id);
    debugPrint('[CompanyOffline] Company permanently deleted: $id');
    notifyListeners();
  }

  Future<List<CompanyEntity>> getCompaniesNeedingSync() async {
    return (await _db.loadCompanies())
        .where((company) => company.syncStatus != CompanySyncStatus.synced)
        .toList();
  }

  Future<int> getUnsyncedCount() async {
    return (await getCompaniesNeedingSync()).length;
  }

  Future<void> markAsSynced(int id, String serverId) async {
    final existing = await getCompanyById(id);
    if (existing == null) return;

    final synced = existing.copyWith(
      serverId: serverId,
      syncStatus: CompanySyncStatus.synced,
    );

    await _db.saveCompany(synced);

    debugPrint('[CompanyOffline] Company marked as synced: $id -> $serverId');
  }

  Future<void> importFromServer(
    List<Map<String, dynamic>> serverCompanies,
  ) async {
    debugPrint(
      '[CompanyOffline] Starting import of ${serverCompanies.length} companies',
    );
    var newCount = 0;
    var updatedCount = 0;
    var skippedCount = 0;

    await _db.transaction(() async {
      for (final data in serverCompanies) {
        final serverId = data['id'] as String?;
        final companyName = (data['companyName'] ?? '').toString();

        if (serverId == null) {
          debugPrint(
            '[CompanyOffline] Skipping company with null serverId: $companyName',
          );
          skippedCount++;
          continue;
        }

        final all = await _db.loadCompanies();
        CompanyEntity? existing;
        for (final company in all) {
          if (company.serverId == serverId) {
            existing = company;
            break;
          }
        }

        if (existing == null) {
          final companyCode = (data['companyCode'] ?? '').toString();
          if (companyCode.isNotEmpty) {
            final needle = companyCode.toLowerCase();
            for (final company in all) {
              if (company.companyCode.toLowerCase() == needle) {
                existing = company;
                break;
              }
            }
          }
          if (existing == null && companyName.isNotEmpty) {
            final needle = companyName.toLowerCase();
            for (final company in all) {
              if (company.companyName.toLowerCase() == needle) {
                existing = company;
                break;
              }
            }
          }
          if (existing != null && existing.serverId == null) {
            existing.serverId = serverId;
            existing.syncStatus = CompanySyncStatus.synced;
            await _db.saveCompany(existing);
            debugPrint(
              '[CompanyOffline] Linked local company: $companyName -> $serverId',
            );
            continue;
          }
        }

        if (existing == null) {
          final company = CompanyEntity.fromServer(data);
          await _db.saveCompany(company);
          newCount++;
          debugPrint(
            '[CompanyOffline] Added new company: $companyName ($serverId)',
          );
        } else if (existing.syncStatus == CompanySyncStatus.synced) {
          final updated = CompanyEntity.fromServer(data);
          updated.id = existing.id;
          await _db.saveCompany(updated);
          updatedCount++;
        } else {
          skippedCount++;
          debugPrint('[CompanyOffline] Skipped (local changes): $companyName');
        }
      }
    });

    debugPrint(
      '[CompanyOffline] Import complete: $newCount new, $updatedCount updated, $skippedCount skipped',
    );

    final totalCount = await _db.countCompanies();
    debugPrint(
      '[CompanyOffline] Total companies in local database after import: $totalCount',
    );

    notifyListeners();
  }

  Future<int> getTotalCount() async {
    return (await _db.loadCompanies())
        .where((company) => company.syncStatus != CompanySyncStatus.deleted)
        .length;
  }

  Future<void> clearAll() async {
    await _db.clearCompanies();
    debugPrint('[CompanyOffline] All companies cleared');
    notifyListeners();
  }
}
