import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/company_entity.dart';

/// Offline-first controller for Company CRUD operations
/// All operations go to local Isar first, then sync in background
class CompanyOfflineController extends ChangeNotifier {
  static CompanyOfflineController? _instance;
  
  final Isar _isar;

  CompanyOfflineController._(this._isar);

  /// Get the singleton instance
  static CompanyOfflineController get instance {
    if (_instance == null) {
      final isar = IsarService.instance.isar;
      _instance = CompanyOfflineController._(isar);
    }
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  /// Check if a company code already exists (for uniqueness validation)
  /// Empty codes are allowed (not enforced as unique)
  Future<bool> isCompanyCodeTaken(String code, {Id? excludeId}) async {
    if (code.trim().isEmpty) return false; // Empty codes are allowed
    
    final existing = await _isar.companyEntitys
        .filter()
        .companyCodeEqualTo(code, caseSensitive: false)
        .not()
        .syncStatusEqualTo(CompanySyncStatus.deleted)
        .findAll();
    if (excludeId != null) {
      return existing.any((e) => e.id != excludeId);
    }
    return existing.isNotEmpty;
  }

  /// Add a new company locally
  /// Sets syncStatus to NEW for background sync
  Future<CompanyEntity> addCompany({
    required String companyName,
    required String companyCode,
    String contact = '',
    String address = '',
  }) async {
    // Validate uniqueness of company code
    final codeTaken = await isCompanyCodeTaken(companyCode);
    if (codeTaken) {
      throw Exception('Company code "$companyCode" already exists');
    }

    final company = CompanyEntity.create(
      companyName: companyName,
      companyCode: companyCode,
      contact: contact,
      address: address,
      syncStatus: CompanySyncStatus.newRecord,
    );

    await _isar.writeTxn(() async {
      await _isar.companyEntitys.put(company);
    });

    debugPrint('[CompanyOffline] Company added: ${company.id}, status: NEW');
    notifyListeners();
    return company;
  }

  // ==================== READ ====================

  /// Get all companies (excluding deleted)
  Future<List<CompanyEntity>> getAllCompanies() async {
    return await _isar.companyEntitys
        .filter()
        .not()
        .syncStatusEqualTo(CompanySyncStatus.deleted)
        .sortByCompanyName()
        .findAll();
  }

  /// Watch all companies for real-time updates (excluding deleted)
  Stream<List<CompanyEntity>> watchAllCompanies() {
    return _isar.companyEntitys
        .filter()
        .not()
        .syncStatusEqualTo(CompanySyncStatus.deleted)
        .sortByCompanyName()
        .watch(fireImmediately: true);
  }

  /// Get company by local Isar ID
  Future<CompanyEntity?> getCompanyById(Id id) async {
    return await _isar.companyEntitys.get(id);
  }

  /// Get company by server ID
  Future<CompanyEntity?> getCompanyByServerId(String serverId) async {
    return await _isar.companyEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get company by contact number (fast indexed lookup)
  Future<CompanyEntity?> getCompanyByContact(String contact) async {
    return await _isar.companyEntitys
        .filter()
        .contactEqualTo(contact)
        .not()
        .syncStatusEqualTo(CompanySyncStatus.deleted)
        .findFirst();
  }

  /// Search companies by name
  Future<List<CompanyEntity>> searchByName(String query) async {
    if (query.isEmpty) return getAllCompanies();
    
    return await _isar.companyEntitys
        .filter()
        .not()
        .syncStatusEqualTo(CompanySyncStatus.deleted)
        .group((q) => q
            .companyNameContains(query, caseSensitive: false)
            .or()
            .contactContains(query))
        .sortByCompanyName()
        .findAll();
  }

  // ==================== UPDATE ====================

  /// Update an existing company
  /// If syncStatus was SYNCED, changes to UPDATED
  /// If syncStatus was NEW, keeps as NEW (not yet on server)
  Future<CompanyEntity?> updateCompany({
    required Id id,
    String? companyName,
    String? companyCode,
    String? contact,
    String? address,
    bool? isActive,
  }) async {
    final existing = await _isar.companyEntitys.get(id);
    if (existing == null) {
      debugPrint('[CompanyOffline] Company not found: $id');
      return null;
    }

    // Validate uniqueness of company code if changed
    if (companyCode != null && companyCode != existing.companyCode) {
      final codeTaken = await isCompanyCodeTaken(companyCode, excludeId: id);
      if (codeTaken) {
        throw Exception('Company code "$companyCode" already exists');
      }
    }

    // Determine new syncStatus
    CompanySyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case CompanySyncStatus.newRecord:
        newSyncStatus = CompanySyncStatus.newRecord;
        break;
      case CompanySyncStatus.synced:
        newSyncStatus = CompanySyncStatus.updated;
        break;
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
      contact: contact,
      address: address,
      isActive: isActive,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.companyEntitys.put(updated);
    });

    debugPrint('[CompanyOffline] Company updated: ${updated.id}, syncStatus: ${updated.syncStatus}');
    notifyListeners();
    return updated;
  }

  // ==================== DELETE ====================

  /// Soft delete a company (mark for deletion, don't remove from DB)
  /// This allows background sync to delete from server first
  Future<void> deleteCompany(Id id) async {
    final existing = await _isar.companyEntitys.get(id);
    if (existing == null) {
      debugPrint('[CompanyOffline] Company not found for delete: $id');
      return;
    }

    // If it's a NEW record (never synced), we can hard delete
    if (existing.syncStatus == CompanySyncStatus.newRecord) {
      await _isar.writeTxn(() async {
        await _isar.companyEntitys.delete(id);
      });
      debugPrint('[CompanyOffline] Company hard deleted (was never synced): $id');
    } else {
      // Mark for deletion - background sync will delete from server
      final deleted = existing.copyWith(
        syncStatus: CompanySyncStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await _isar.writeTxn(() async {
        await _isar.companyEntitys.put(deleted);
      });
      debugPrint('[CompanyOffline] Company marked for deletion: $id');
    }

    notifyListeners();
  }

  /// Hard delete after successful server deletion
  Future<void> permanentlyDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.companyEntitys.delete(id);
    });
    debugPrint('[CompanyOffline] Company permanently deleted: $id');
    notifyListeners();
  }

  // ==================== SYNC HELPERS ====================

  /// Get all companies that need to be synced to server
  Future<List<CompanyEntity>> getCompaniesNeedingSync() async {
    return await _isar.companyEntitys
        .filter()
        .not()
        .syncStatusEqualTo(CompanySyncStatus.synced)
        .findAll();
  }

  /// Get count of unsynced companies
  Future<int> getUnsyncedCount() async {
    return await _isar.companyEntitys
        .filter()
        .not()
        .syncStatusEqualTo(CompanySyncStatus.synced)
        .count();
  }

  /// Mark a company as synced (after successful server sync)
  Future<void> markAsSynced(Id id, String serverId) async {
    final existing = await _isar.companyEntitys.get(id);
    if (existing == null) return;

    final synced = existing.copyWith(
      serverId: serverId,
      syncStatus: CompanySyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.companyEntitys.put(synced);
    });

    debugPrint('[CompanyOffline] Company marked as synced: $id -> $serverId');
  }

  /// Import companies from server (initial load or refresh)
  /// Only updates if server data is newer
  Future<void> importFromServer(List<Map<String, dynamic>> serverCompanies) async {
    await _isar.writeTxn(() async {
      for (final data in serverCompanies) {
        final serverId = data['id'] as String?;
        if (serverId == null) continue;

        // Check if we already have this company
        final existing = await _isar.companyEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        if (existing == null) {
          // New company from server
          final company = CompanyEntity.fromServer(data);
          await _isar.companyEntitys.put(company);
        } else if (existing.syncStatus == CompanySyncStatus.synced) {
          // Only update if local is synced (no local changes)
          final updated = CompanyEntity.fromServer(data);
          updated.id = existing.id;
          await _isar.companyEntitys.put(updated);
        }
        // If local has changes (NEW, UPDATED, DELETED), don't overwrite
      }
    });

    debugPrint('[CompanyOffline] Imported ${serverCompanies.length} companies from server');
    notifyListeners();
  }

  // ==================== STATISTICS ====================

  /// Get total company count
  Future<int> getTotalCount() async {
    return await _isar.companyEntitys
        .filter()
        .not()
        .syncStatusEqualTo(CompanySyncStatus.deleted)
        .count();
  }

  /// Clear all local companies (use with caution)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.companyEntitys.clear();
    });
    debugPrint('[CompanyOffline] All companies cleared');
    notifyListeners();
  }
}
