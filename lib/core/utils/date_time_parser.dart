import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Parses Firestore [Timestamp], [DateTime], or ISO-8601 [String] values.
DateTime? parseFlexibleDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Same as [parseFlexibleDateTime], falling back to [DateTime.now] when null.
DateTime parseFlexibleDateTimeOrNow(dynamic value) =>
    parseFlexibleDateTime(value) ?? DateTime.now();
