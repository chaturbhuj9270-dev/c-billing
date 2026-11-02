/// In-app legal copy for Play Store Data safety / account requirements.
class LegalDocuments {
  LegalDocuments._();

  static const String privacyPolicyTitle = 'Privacy Policy';
  static const String termsTitle = 'Terms of Service';

  static const String privacyPolicyBody = '''
Last updated: 1 November 2026

C-Billing ("we", "our", or "the App") helps businesses create invoices, manage inventory, customers, and related business records.

1. Information we collect
• Account data: name, email, phone, and authentication credentials (via Firebase Authentication).
• Business data you enter: customers, products, purchases, bills, stock, suppliers, reports, and shop details.
• Device data needed for features you use: camera (barcode / invoice scan), storage (export / import files), Bluetooth (receipt printers), and network connectivity.
• Subscription / purchase status for paid access (Google Play Billing on Android).

2. How we use information
• To provide billing, inventory, sync, printing, and reporting features.
• To authenticate users, protect accounts, and enforce subscription access.
• To sync data across devices when you are signed in and online.
• To improve reliability and diagnose crashes (Crashlytics / error logs).

3. Storage and sync
• Data is stored on your device (offline database) and, when signed in, on Firebase (Cloud Firestore / Storage) under your account.
• You control what business records you create. We do not sell your customer or invoice data.

4. Sharing
• We use Google Firebase / Google Play services to operate authentication, database, storage, and subscriptions.
• We do not sell personal data to third-party advertisers.

5. Retention
• Account and business data remain until you delete them or delete your account.
• Local device data is cleared on logout / account deletion from this device.

6. Your choices
• Update profile details in the App.
• Export or delete business records you created (where the feature is available).
• Delete your account from Profile → Delete account in the App, or on the web at the public account-deletion page linked in the App / Play listing. This permanently deletes your Firebase Auth user and associated cloud profile data we control, and clears local app data on this device when you delete from the App.

7. Children's privacy
• The App is intended for business use by adults. It is not directed to children under 13.

8. Contact
• Email: support@cbilling.app
• Phone: 9970662978

If you host a public web version of this policy, keep it consistent with this text and link it in Play Console Data safety.
''';

  static const String termsBody = '''
Last updated: 1 November 2026

By using C-Billing you agree to these Terms of Service.

1. The service
C-Billing provides business billing, inventory, and related tools. Features may change as we improve the product.

2. Accounts
You are responsible for keeping login credentials secure and for activity under your account. Provide accurate business information for invoices and GST-related fields you choose to use.

3. Subscriptions
Paid access on Android is sold through Google Play Billing. Prices, renewals, and cancellations follow Google Play policies and your Play subscription settings. Free trial terms (if offered) are shown in the App and Play listing.

4. Acceptable use
Do not misuse the App, attempt unauthorized access, or use it for unlawful activity. You are responsible for the accuracy of invoices, tax calculations, and records you generate.

5. Data
Your business data belongs to you. Our Privacy Policy explains how we process it. Account deletion removes your Auth account and associated cloud profile data we control; some residual backups may take time to purge from infrastructure. You may delete from the App (Profile → Delete account) or from the public web account-deletion page.

6. Disclaimer
The App is provided "as is". We are not your accountant or tax advisor. Verify GST, invoices, and ledgers before filing or sharing with authorities/customers.

7. Limitation of liability
To the maximum extent permitted by law, we are not liable for indirect or consequential losses arising from use of the App, including lost profits or data, except where liability cannot be limited by law.

8. Contact
support@cbilling.app · 9970662978
''';
}
