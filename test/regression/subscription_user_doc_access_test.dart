import 'package:c_billing/core/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 6, 1);
  DateTime? expiry(Map<String, dynamic> data, {DateTime? authCreatedAt}) =>
      SubscriptionService.accessExpiryFromUserData(
        data,
        authCreatedAt: authCreatedAt,
        now: start,
      );

  test('a stored paid expiry wins over everything else', () {
    final paid = DateTime(2027, 6, 1);
    expect(
      expiry({
        'subscriptionExpiresAt': paid,
        'subscriptionStatus': 'trial',
        'trialExpiresAt': DateTime(2026, 7, 1),
      }),
      paid,
    );
  });

  test('active with a subscriptionDate gets a full paid year', () {
    expect(
      expiry({'subscriptionStatus': 'active', 'subscriptionDate': start}),
      start.add(SubscriptionService.subscriptionDuration),
    );
  });

  test('active set from the console without a date still gets a year', () {
    expect(
      expiry({'subscriptionStatus': 'active', 'createdAt': start}),
      start.add(SubscriptionService.subscriptionDuration),
    );
    expect(
      expiry({'subscriptionStatus': 'active'}),
      start.add(SubscriptionService.subscriptionDuration),
    );
  });

  test('a trial subscriptionDate is only a 30 day trial, not a paid year', () {
    expect(
      expiry({'subscriptionStatus': 'trial', 'subscriptionDate': start}),
      start.add(SubscriptionService.freeTrialDuration),
    );
  });

  test('trial uses the stored trial expiry, then the trial start', () {
    final trialEnd = DateTime(2026, 6, 20);
    expect(expiry({'trialExpiresAt': trialEnd, 'trialStartedAt': start}), trialEnd);
    expect(
      expiry({'trialStartedAt': start}),
      start.add(SubscriptionService.freeTrialDuration),
    );
    expect(
      expiry({'createdAt': start.toIso8601String()}),
      start.add(SubscriptionService.freeTrialDuration),
    );
  });

  test('falls back to the Auth account age when the doc has no dates', () {
    expect(
      expiry({}, authCreatedAt: start),
      start.add(SubscriptionService.freeTrialDuration),
    );
    expect(expiry({}), isNull);
  });
}
