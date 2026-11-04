/// Play Store / product identity used across the app.
///
/// After changing [androidApplicationId], register the same package in
/// Firebase Console and replace `android/app/google-services.json`.
///
/// Legal + account-deletion pages are hosted on Firebase Hosting
/// (`firebase deploy --only hosting`). Public site: `https://cbilling.web.app`.
class AppStoreConfig {
  AppStoreConfig._();

  static const String appName = 'C-Billing';
  static const String androidApplicationId = 'com.cbilling.app';
  static const String supportEmail = 'support@cbilling.app';
  static const String supportPhone = '9970662978';

  /// Firebase Hosting site (site id `cbilling` — not the project-id URL).
  static const String webSiteBaseUrl = 'https://cbilling.web.app';

  static const String privacyPolicyUrl = '$webSiteBaseUrl/privacy';
  static const String termsOfServiceUrl = '$webSiteBaseUrl/terms';

  /// Paste this URL into Play Console → App content → Account deletion.
  static const String accountDeletionUrl = '$webSiteBaseUrl/delete-account';
}
