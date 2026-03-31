import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/customer/offline/entities/customer_entity.dart';

/// Singleton service for managing Isar database instance
/// Handles initialization, instance access, and database cleanup
class IsarService {
  static IsarService? _instance;
  static Isar? _isar;

  IsarService._();

  /// Get the singleton instance
  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  /// Check if Isar is initialized
  bool get isInitialized => _isar != null && _isar!.isOpen;

  /// Get the Isar instance (throws if not initialized)
  Isar get isar {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('Isar not initialized. Call initialize() first.');
    }
    return _isar!;
  }

  /// Initialize Isar database with all collections
  /// Should be called once during app startup (in main.dart)
  Future<void> initialize() async {
    if (_isar != null && _isar!.isOpen) {
      // Already initialized
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [CustomerEntitySchema],
      directory: dir.path,
      name: 'c_billing_db',
      inspector: true, // Enable Isar inspector in debug mode
    );
  }

  /// Close the Isar database
  /// Call this when the app is being disposed
  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }

  /// Clear all data (for testing or logout scenarios)
  Future<void> clearAllData() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.writeTxn(() async {
        await _isar!.clear();
      });
    }
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    if (_isar == null || !_isar!.isOpen) return 0;
    return _isar!.getSize();
  }

  /// Export database path (for debugging)
  Future<String> getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/c_billing_db.isar';
  }
}
