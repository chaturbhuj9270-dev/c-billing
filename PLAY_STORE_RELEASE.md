# C-Billing — Play Store release checklist

Code blockers for a first production upload are addressed in this repo.
Complete the **manual** steps below before submitting to production.

## What was fixed in code

- Application ID: `com.cbilling.app` (was `com.example.c_billing`)
- Launcher label: **C-Billing**
- Release signing wired via `android/key.properties` (see below)
- Release minify + shrink + ProGuard rules
- Privacy Policy + Terms in-app (Profile + flyout menu) + Firebase Hosting pages
- **Delete account** on Profile (all platforms) + public web page `/delete-account`
- Cloud Functions: `deleteMyAccount`, `requestAccountDeletionOtp`, `confirmAccountDeletionWithOtp`
- Android subscriptions already use **Google Play Billing** (`PaymentScreen`)
- Storage permissions scoped with `maxSdkVersion`
- Bluetooth CONNECT/SCAN declared for printers
- Firebase Crashlytics hooked for release crashes
- `allowBackup="false"`

## 1) Create upload keystore (once)

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
cp key.properties.example key.properties
# Edit key.properties with your passwords and:
# storeFile=upload-keystore.jks
```

Keep `upload-keystore.jks` and passwords offline / in a password manager. Never commit them.

## 2) Re-register Android app in Firebase

Package change requires a new Android app entry:

1. Firebase Console → project `c-billing-4744a` → Add Android app  
2. Package name: `com.cbilling.app`  
3. Download new `google-services.json` → replace `android/app/google-services.json`  
4. Enable Crashlytics in Firebase  
5. (Optional) SHA-1 of upload key for Auth / App Check

Until this is done, Firebase Auth / Crashlytics may fail against the old app registration.

## 3) Deploy Privacy, Terms, and account-deletion web pages

Play requires:
- A **public privacy policy URL**
- An **external account-deletion URL** (in addition to in-app Profile → Delete account)

Static pages live in `hosting/public/` and are configured in `firebase.json`.

```bash
# From repo root
cd functions && npm install && cd ..
firebase deploy --only functions:deleteMyAccount,functions:requestAccountDeletionOtp,functions:confirmAccountDeletionWithOtp,hosting
# Or simply:
firebase deploy --only functions,hosting
```

After deploy, verify:

- Privacy: https://c-billing-4744a.web.app/privacy  
- Terms: https://c-billing-4744a.web.app/terms  
- Delete account: https://c-billing-4744a.web.app/delete-account  

These URLs are already set in `lib/core/config/app_store_config.dart`.

### Play Console fields

1. App content → **Privacy policy** → paste `AppStoreConfig.privacyPolicyUrl`
2. App content → **Data safety / Account deletion** → paste `AppStoreConfig.accountDeletionUrl`
3. Declare in-app path: **Profile → Delete account**
4. Optional: add a custom domain in Firebase Hosting and update `webSiteBaseUrl`

### Email OTP on the web page

`requestAccountDeletionOtp` sends mail via the Firestore `mail` collection (Trigger Email extension) and optional SMTP params already used by login OTP. Ensure one of those delivery paths works before relying on the email-code tab.

### Auth authorized domains

Firebase Console → Authentication → Settings → Authorized domains should include:

- `c-billing-4744a.web.app`
- `c-billing-4744a.firebaseapp.com`
- any custom domain you attach

## 4) Play Console setup

- Create app with package `com.cbilling.app`
- Enable Play App Signing
- Create subscription product matching `SubscriptionProducts` / `cbilling_yearly`
- License testers for closed testing
- Data safety form (Auth, personal info, financial/business records, photos/camera, device IDs as applicable)
- Account deletion: declare in-app path **Profile → Delete account**
- Content rating questionnaire
- Store listing: title **C-Billing**, screenshots, feature graphic, short/full description
- Target audience / financial features declarations as prompted

## 5) Build AAB

```bash
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload to **Internal testing** first, then Closed testing, then staged Production (10% → 100%).

## 6) Smoke test before production

- [ ] Sign up / login / logout  
- [ ] Delete account (test account)  
- [ ] Privacy / Terms open  
- [ ] Create bill, collect payment, stock change, purchase add  
- [ ] Play subscription purchase (license tester)  
- [ ] Offline create → online sync  
- [ ] Crashlytics test crash appears in Firebase (optional)

## Notes

- Cashfree client code remains for non-Play channels; Android pay wall uses Play Billing only.
- If minify breaks a plugin, adjust `android/app/proguard-rules.pro`.
