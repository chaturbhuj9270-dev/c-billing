import 'package:c_billing/core/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a still-running confirmed window keeps a paying user in when offline',
    () async {
      final future = DateTime.now().add(const Duration(days: 100));
      SharedPreferences.setMockInitialValues({
        'subscription_last_expiry_u1': future.millisecondsSinceEpoch,
      });
      expect(await SubscriptionService.lastKnownWindowOpen('u1'), isTrue);
    },
  );

  test('an ended window does not unlock the app offline', () async {
    final past = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'subscription_last_expiry_u1': past.millisecondsSinceEpoch,
    });
    expect(await SubscriptionService.lastKnownWindowOpen('u1'), isFalse);
  });

  test('a device that never confirmed a window stays locked offline', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SubscriptionService.lastKnownWindowOpen('u1'), isFalse);
  });

  test('the cached window belongs to one user only', () async {
    final future = DateTime.now().add(const Duration(days: 100));
    SharedPreferences.setMockInitialValues({
      'subscription_last_expiry_u1': future.millisecondsSinceEpoch,
    });
    expect(await SubscriptionService.lastKnownWindowOpen('u2'), isFalse);
  });
}
