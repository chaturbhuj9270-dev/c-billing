// Regression guard: incremental sync cursor logic. Feature: realtime-sync.
import 'package:c_billing/core/services/sync_query_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no cursor => full pull', () {
    expect(SyncQueryHelper.effectiveSince(null), isNull);
  });

  test('cursor older than this session => full pull', () {
    SyncQueryHelper.beginSession('user-a');
    final old = DateTime.now().subtract(const Duration(days: 1));
    expect(SyncQueryHelper.effectiveSince(old), isNull);
  });

  test('cursor from this session is used as is', () {
    SyncQueryHelper.beginSession('user-a');
    final recent = DateTime.now().add(const Duration(seconds: 1));
    expect(SyncQueryHelper.effectiveSince(recent), recent);
  });
}
