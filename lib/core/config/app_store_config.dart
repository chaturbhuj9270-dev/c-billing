/// Play Store / product identity used across the app.
///
/// After changing [androidApplicationId], register the same package in
/// Firebase Console and replace `android/app/google-services.json`.
class AppStoreConfig {
  AppStoreConfig._();

  static const String appName = 'C-Billing';
  static const String androidApplicationId = 'com.cbilling.app';
  static const String supportEmail = 'support@cbilling.app';
  static const String supportPhone = '9970662978';

  /// Host this HTML publicly, then set the real URL before Play submission.
  /// Until then, in-app Privacy / Terms screens satisfy the in-app requirement.
  static const String privacyPolicyUrl =
      'https://cbilling.app/privacy'; // TODO: publish and verify URL
  static const String termsOfServiceUrl =
      'https://cbilling.app/terms'; // TODO: publish and verify URL
}
