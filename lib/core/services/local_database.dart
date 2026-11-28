import '../database/app_database.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  AppDatabase? _db;

  bool get isInitialized => _db != null;

  AppDatabase get db {
    final database = _db;
    if (database == null) {
      throw StateError(
        'Local database is not initialized. Call initialize() first.',
      );
    }
    return database;
  }

  Future<void> initialize() async {
    _db ??= AppDatabase();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> clearAllData() async {
    await _db?.clearAll();
  }

  Future<int> getDatabaseSize() async {
    final database = _db;
    if (database == null) return 0;
    final row = await database
        .customSelect(
          'SELECT page_count * page_size AS size FROM pragma_page_count(), pragma_page_size()',
        )
        .getSingle();
    return row.read<int>('size');
  }
}
