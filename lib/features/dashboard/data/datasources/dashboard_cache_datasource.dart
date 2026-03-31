import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';

/// Local cache datasource for dashboard data
/// Uses SharedPreferences for persistent storage and in-memory cache for speed
class DashboardCacheDataSource {
  static const String _cachePrefix = 'dashboard_cache_';
  static const Duration _defaultCacheDuration = Duration(minutes: 30);

  SharedPreferences? _prefs;
  
  /// In-memory cache for instant access
  final Map<String, DashboardSummary> _memoryCache = {};

  /// Initialize the datasource
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadAllCachesToMemory();
  }

  /// Load all dashboard caches from disk to memory
  Future<void> _loadAllCachesToMemory() async {
    if (_prefs == null) return;
    
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final key in keys) {
      try {
        final jsonStr = _prefs!.getString(key);
        if (jsonStr != null) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final summary = DashboardSummary.fromJson(json);
          final cacheKey = key.replaceFirst(_cachePrefix, '');
          _memoryCache[cacheKey] = summary;
        }
      } catch (e) {
        // Ignore corrupted cache entries
        await _prefs!.remove(key);
      }
    }
  }

  /// Get cached data from memory (instant, synchronous)
  DashboardSummary? getCachedSync(DashboardParams params) {
    return _memoryCache[params.cacheKey];
  }

  /// Get cached data (async, from memory or disk)
  Future<DashboardSummary?> getCached(DashboardParams params) async {
    // First check memory cache
    final memoryCached = _memoryCache[params.cacheKey];
    if (memoryCached != null) {
      return memoryCached;
    }

    // Fallback to disk cache
    await _ensureInitialized();
    final jsonStr = _prefs!.getString('$_cachePrefix${params.cacheKey}');
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final summary = DashboardSummary.fromJson(json);
      
      // Store in memory for next access
      _memoryCache[params.cacheKey] = summary;
      return summary;
    } catch (e) {
      // Clear corrupted cache
      await _prefs!.remove('$_cachePrefix${params.cacheKey}');
      return null;
    }
  }

  /// Save data to cache (both memory and disk)
  Future<void> saveToCache(DashboardParams params, DashboardSummary summary) async {
    // Immediately update memory cache
    _memoryCache[params.cacheKey] = summary;

    // Async save to disk
    await _ensureInitialized();
    final jsonStr = jsonEncode(summary.toJson());
    await _prefs!.setString('$_cachePrefix${params.cacheKey}', jsonStr);
  }

  /// Check if cache is valid (exists and not expired)
  bool isCacheValid(DashboardParams params, {Duration? maxAge}) {
    final cached = _memoryCache[params.cacheKey];
    if (cached == null) return false;
    
    final age = maxAge ?? _defaultCacheDuration;
    return !cached.isStale(threshold: age);
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    _memoryCache.clear();
    
    await _ensureInitialized();
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  /// Clear specific cache entry
  Future<void> clearCache(DashboardParams params) async {
    _memoryCache.remove(params.cacheKey);
    
    await _ensureInitialized();
    await _prefs!.remove('$_cachePrefix${params.cacheKey}');
  }

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Preload default dashboard cache on app start
  Future<void> preloadDefaultCache() async {
    await init();
    // Load thisMonth filter by default as it's the most common
    final defaultParams = const DashboardParams(filter: DashboardFilter.thisMonth);
    await getCached(defaultParams);
  }
}
