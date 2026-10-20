import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Opens the local database on the calling isolate. Drift's background-isolate connection never finishes when that isolate is paused (debug start) or dies during a restart. Every s...
QueryExecutor openAppDatabase() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}c_billing_db.sqlite',
    );
    debugPrint('[LocalDatabase] Opening ${file.path}');
    _lockDatabaseFile(file);
    return NativeDatabase(
      file,
      setup: (_) {
        // WAL sidecars appear after the first write.
        _lockDatabaseFile(file);
      },
    );
  });
}

// Other accounts on this computer cannot read the shop file. The signed-in user still can. Replacing SQLite with an encrypted engine would require migrating the live shop file, so...
void _lockDatabaseFile(File file) {
  if (Platform.isWindows) return;
  try {
    final paths = <String>[file.path, '${file.path}-wal', '${file.path}-shm'];
    for (final path in paths) {
      if (File(path).existsSync()) {
        Process.runSync('chmod', ['600', path]);
      }
    }
  } catch (e) {
    debugPrint('[LocalDatabase] Could not restrict database file: $e');
  }
}
