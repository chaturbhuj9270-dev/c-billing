# C-Billing — Play Store release checklist

Code blockers for a first production upload are addressed in this repo.
Complete the **manual** steps below before submitting to production.

## What was fixed in code

- Application ID: `com.cbilling.app` (was `com.example.c_billing`)
- Launcher label: **C-Billing**
- Release signing wired via `android/key.properties` (see below)
- Release minify + shrink + ProGuard rules
- Privacy Policy + Terms in-app (Profile + flyout menu)
- **Delete account** on Profile (Play account-deletion requirement)
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

## 3) Host Privacy Policy + Terms on the web

Play Console Data safety needs a **public HTTPS URL**.

1. Publish the same text as in `lib/core/legal/legal_documents.dart`  
2. Update URLs in `lib/core/config/app_store_config.dart`  
3. Paste the privacy URL into Play Console → App content → Privacy policy

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
