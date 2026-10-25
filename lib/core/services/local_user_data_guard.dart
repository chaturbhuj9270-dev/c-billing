import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../access/tenant_context.dart';
import '../../features/billing/data/datasources/bill_cache_datasource.dart';
import '../../features/company/data/datasources/company_cache_datasource.dart';
import '../../features/customer/data/datasources/customer_cache_datasource.dart';
import '../../features/dashboard/data/datasources/dashboard_cache_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/inventory_management/data/datasources/product_cache_datasource.dart';
import '../../features/inventory_management/data/datasources/purchase_cache_datasource.dart';
import '../../features/supplier/data/datasources/supplier_cache_datasource.dart';
import 'local_database.dart';
import 'sync_bootstrap.dart';

// Ensures the offline SQLite DB + prefs caches belong to the signed-in shop
// owner. Clears everything when the account changes so a new login never shows
// the previous user's data.
class LocalUserDataGuard {
  LocalUserDataGuard._();

  static const String _ownerKey = 'local_data_owner_id';

  // Known SharedPreferences keys that store user business data (not app settings).
  static const List<String> _userCacheKeys = [
    'customer_list_cache',
    'supplier_list_cache',
    'bill_list_cache',
    'product_list_cache',
  ];

  // Call after AccessControlService.loadForCurrentUser().
  // Returns true when local data was wiped for a user switch.
  static Future<bool> ensureBoundToCurrentUser() async {
    final ownerId = TenantContext.dataOwnerIdOrNull;
    if (ownerId == null || ownerId.isEmpty) {
      debugPrint('[LocalUserDataGuard] No owner id yet — skip bind');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_ownerKey);

    if (previous == ownerId) {
      debugPrint('[LocalUserDataGuard] Local data already bound to $ownerId');
      return false;
    }

    debugPrint(
      '[LocalUserDataGuard] Owner changed ($previous → $ownerId) — clearing local data',
    );
    await clearAllUserData();
    await prefs.setString(_ownerKey, ownerId);
    debugPrint('[LocalUserDataGuard] Bound local data to $ownerId');
    return true;
  }

  // Wipe SQLite + user-scoped caches. Does not clear language/theme/credentials.
  static Future<void> clearAllUserData() async {
    try {
      if (LocalDatabase.instance.isInitialized) {
        await LocalDatabase.instance.clearAllData();
      }
    } catch (e) {
      debugPrint('[LocalUserDataGuard] SQLite clear failed: $e');
    }

    try {
      await CustomerCacheDataSource().clearCache();
      await SupplierCacheDataSource().clearCache();
      await BillCacheDataSource().clearCache();
      await ProductCacheDataSource().clearCache();
      await CompanyCacheDataSource().clearAll();
      await PurchaseCacheDataSource().clearAll();
      await DashboardCacheDataSource().clearAll();
      DashboardRepository.invalidateCache();
    } catch (e) {
      debugPrint('[LocalUserDataGuard] Cache clear failed: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _userCacheKeys) {
        await prefs.remove(key);
      }
      final dashKeys = prefs
          .getKeys()
          .where((k) => k.startsWith('dashboard_cache_'))
          .toList();
      for (final key in dashKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('[LocalUserDataGuard] Prefs clear failed: $e');
    }

    SyncBootstrap.resetSyncCursors();
  }

  // Call on logout so the next account always triggers a wipe.
  static Future<void> clearBinding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ownerKey);
    } catch (e) {
      debugPrint('[LocalUserDataGuard] clearBinding failed: $e');
    }
  }
}
