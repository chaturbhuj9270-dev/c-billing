/// Google Play / App Store product configuration for C-Billing yearly plan.
///
/// Create a matching **subscription** in Play Console:
/// Monetize → Products → Subscriptions → product ID must match [yearlyProductId].
class SubscriptionProducts {
  SubscriptionProducts._();

  /// Play Console / App Store Connect subscription product ID
  static const String yearlyProductId = 'cbilling_yearly';

  /// Android applicationId (must match Play Console package name)
  static const String androidPackageName = 'com.example.c_billing';

  /// Display price fallback when store product is not loaded yet
  static const String fallbackPriceLabel = '₹3,999';
}
