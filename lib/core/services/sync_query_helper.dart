import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Shared helper for incremental ("changed since") pulls from Firestore.
///
/// Why this exists: documents in the same collection store `updatedAt` as a
/// Firestore Timestamp (FieldValue.serverTimestamp) when written by the app's
/// API services, but as an ISO-8601 string when written by other code paths
/// (repositories, billing service, web). Firestore range filters only match
/// values of the SAME type, so a single `where('updatedAt', > isoString)`
/// silently misses every Timestamp document — other devices' edits were never
/// pulled after the first sync of a session. We therefore query both types and
/// merge, with an overlap window to tolerate device clock skew.
class SyncQueryHelper {
  SyncQueryHelper._();

  /// Re-read this much history on every incremental pull (clock skew safety).
  /// Importers ignore records that are not newer than the local copy.
  static const Duration overlap = Duration(minutes: 5);

  static String? _sessionUid;
  static DateTime _sessionStart = DateTime.fromMillisecondsSinceEpoch(0);

  /// Call when a user session starts (login / app start with a signed-in user).
  /// Any `lastSyncTime` captured before this moment belonged to a previous
  /// session/account and must not be used as an incremental cursor.
  static void beginSession(String? uid) {
    if (uid == null) return;
    if (_sessionUid == uid) return;
    _sessionUid = uid;
    _sessionStart = DateTime.now();
  }

  /// Returns null (=> full pull) when [since] predates the current session.
  static DateTime? effectiveSince(DateTime? since) {
    if (since == null) return null;
    if (since.isBefore(_sessionStart)) return null;
    return since;
  }

  /// Fetch documents changed after [since]. With no cursor, fetches everything
  /// (no orderBy, so documents lacking [field] are not dropped).
  static Future<List<Map<String, dynamic>>> fetchChanged(
    Query<Map<String, dynamic>> base, {
    DateTime? since,
    String field = 'updatedAt',
  }) async {
    final cursor = effectiveSince(since);
    if (cursor == null) {
      final snapshot = await base.get();
      return _toMaps(snapshot.docs);
    }

    final from = cursor.subtract(overlap);
    final results = await Future.wait([
      base.where(field, isGreaterThan: Timestamp.fromDate(from)).get(),
      base
          .where(field, isGreaterThan: from.toLocal().toIso8601String())
          .get(),
    ]);

    final merged = <String, Map<String, dynamic>>{};
    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        merged[doc.id] = data;
      }
    }
    if (kDebugMode && merged.isNotEmpty) {
      debugPrint(
        '[SyncQuery] ${merged.length} changed docs since $from (field=$field)',
      );
    }
    return merged.values.toList();
  }

  static List<Map<String, dynamic>> _toMaps(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
