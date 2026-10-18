import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the local database on the calling isolate.
///
/// Drift's background-isolate connection never finishes when that isolate is
/// paused (debug start) or dies during a restart. Every screen then waits on
/// the first query and stays on its loading state, even though the sqlite
/// file already has the records.
QueryExecutor openAppDatabase() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}c_billing_db.sqlite',
    );
    debugPrint('[LocalDatabase] Opening ${file.path}');
    return NativeDatabase(file);
  });
}
