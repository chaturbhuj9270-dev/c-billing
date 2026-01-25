# Firebase Phone Authentication Setup & Fix

## Current Error
```
operation-not-allowed: This operation is not allowed. This may be because 
the given sign-in provider is disabled for this Firebase project. Enable it 
in the Firebase console, under the sign-in method tab of the Auth section.
```

## Error Fix Summary
Phone Authentication is disabled in Firebase Console. Also fixed the fatal error for iOS: "Unexpectedly found nil while implicitly unwrapping an Optional value" in PhoneAuthProvider.swift:109

## Changes Made to Code

### 1. Enhanced `_sendOtp()` Method
- Added phone number validation (10-digit check for India)
- Improved error handling with specific error codes
- Better logging for debugging
- Proper timeout configuration

### 2. Improved `_showOtpDialog()` Method
- Added null check for `_verificationId`
- Better error message handling for different Firebase error codes
- Improved logging for all verification steps
- Proper exception handling for edge cases

### 3. Key Improvements
- Validates OTP is exactly 6 digits before verification
- Checks if `_verificationId` is not null before using it
- Handles `invalid-verification-code`, `session-expired`, and other error codes
- Added detailed console logging for debugging

## Android Configuration Requirements

### 1. Update build.gradle (app level)
Ensure you have the latest Firebase Auth and Play Integrity versions in `android/app/build.gradle`:

```gradle
dependencies {
    // ... other dependencies
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.android.play:core:1.10.3' // or latest
}
```

### 2. Update AndroidManifest.xml
Ensure `android/app/src/main/AndroidManifest.xml` has internet permission:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 3. Add SMS Permission (if receiving OTP via SMS)
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_SMS" />
```

### 4. SHA-1 Certificate Configuration (MOST IMPORTANT)
As described in Firebase Console Configuration above.

## iOS Configuration Requirements

### 1. Update Podfile (if not already done)
Ensure your iOS platform is set to iOS 11.0 or higher in `ios/Podfile`:

```ruby
platform :ios, '11.0'
```

### 2. GoogleService-Info.plist
- Ensure GoogleService-Info.plist is properly added to Xcode
- The file should be in `ios/Runner/GoogleService-Info.plist`
- Make sure it's added to all targets in Xcode

### 3. Add Phone Number Verification Capability
1. Open `ios/Runner.xcworkspace` (NOT Runner.xcodeproj)
2. Select Runner target
3. Go to Signing & Capabilities
4. Click "+ Capability"
5. Add "Sign in with Apple" (required for iOS phone auth fallback)

### 4. Firebase Console Configuration - CRITICAL STEP

#### Step 1: Enable Phone Authentication
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **c-billing**
3. Go to **Build** → **Authentication**
4. Click on **Sign-in method** tab
5. Click on **Phone**
6. Toggle **Enable** to ON
7. Click **Save**

#### Step 2: Add Android SHA-1 Certificate Fingerprint
This is required for reCAPTCHA verification on Android.

**Get your SHA-1 fingerprint:**
```bash
cd /Users/admin/Documents/dev/Projects/Flutter/c_billing/android
./gradlew signingReport
```

Look for `SHA1` in the output. You'll see something like:
```
SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
```

**Add to Firebase Console:**
1. In Firebase Console → Project Settings (gear icon)
2. Click on **Your apps** → Select your Android app
3. Scroll to **SHA certificate fingerprints**
4. Click **Add fingerprint**
5. Paste the SHA1 value (format: AB:CD:EF:...)
6. Click **Save**

#### Step 3: Add Debug SHA-1 Fingerprint (if different from release)
For development/debug builds, you need the debug keystore SHA-1:
```bash
cd /Users/admin/Documents/dev/Projects/Flutter/c_billing
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy the SHA1 and add it to Firebase Console the same way as above.

#### Step 4: Verify in Firebase Console
Go to **Project Settings** → **Your apps** → Android app
Check that both SHA1 fingerprints are listed under "SHA certificate fingerprints"

### 5. Update Podfile Post Install (Optional but Recommended)
Add this to the end of your `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'FIREBASE_PHONE_AUTH_ENABLED=1',
      ]
    end
  end
end
```

## Testing the Fix - QUICK START

### Step 1: Get SHA-1 Certificate
```bash
cd android
./gradlew signingReport
# Copy the SHA1 value
```

### Step 2: Add to Firebase Console
1. Open Firebase Console
2. Project Settings → Your apps → Android app
3. Add SHA1 fingerprint
4. Wait 2-3 minutes for changes to sync

### Step 3: Enable Phone Auth in Console
1. Authentication → Sign-in method
2. Enable **Phone**
3. Save

### Step 4: Test the App
```bash
flutter clean
flutter pub get
flutter run
```

### Step 5: Use Test Phone Numbers (Optional)
For development without incurring SMS costs:
1. Authentication → Sign-in method → Phone
2. Scroll to "Test phone numbers"
3. Add number: +919876543210
4. Firebase will show OTP in console

When you enter this test number, the OTP will be displayed in Firebase Console.

## Troubleshooting

### Error: "operation-not-allowed"
**Cause**: Phone authentication is disabled in Firebase Console
**Solution**: 
1. Go to Firebase Console → Authentication → Sign-in method
2. Click on "Phone" and toggle Enable
3. Click Save
4. Wait 2-3 minutes for propagation

### Error: "INVALID_CERT_HASH" or "There was an error while trying to get your package certificate hash"
**Cause**: Android SHA-1 certificate not added to Firebase Console
**Solution**:
1. Get SHA-1: `cd android && ./gradlew signingReport`
2. Go to Firebase Console → Project Settings → Your apps → Android
3. Add SHA1 fingerprint under "SHA certificate fingerprints"
4. Save and wait 2-3 minutes

### Error: "reCAPTCHA token with error"
**Cause**: SHA-1 certificate hash mismatch or not registered
**Solution**: Same as above - ensure SHA-1 is correctly added to Firebase

### Error: "Unexpectedly found nil while implicitly unwrapping an Optional" (iOS)
**Cause**: GoogleService-Info.plist not configured or Verification ID is nil
**Solution**: 
- Verify GoogleService-Info.plist exists in Runner target
- Check Firebase project setup
- Use test phone numbers from Firebase Console
- Run: `cd ios && pod repo update && pod install --repo-update && cd ..`

### Error: "missing-client-identifier"
**Cause**: iOS device/simulator doesn't support phone authentication
**Solution**: 
- Use a physical device for testing
- Or use Firebase Emulator Suite
- Or add test phone numbers in Firebase Console

### Error: "too-many-requests"
**Cause**: Too many OTP requests from same number
**Solution**: 
- Wait a few minutes before retrying
- Use different test numbers
- Use Firebase test phone numbers for development

### Error: "invalid-phone-number"
**Cause**: Phone number format is incorrect
**Solution**: 
- Ensure number starts with country code (+91 for India)
- Must be 10 digits after country code
- Use format: +91XXXXXXXXXX

### Error: "session-expired"
**Cause**: OTP verification session timed out (> 120 seconds)
**Solution**: 
- Click "Resend OTP" button
- Request new OTP

### Common Issue: "Failed with INVALID_CERT_HASH 400"
This specific error means:
1. **SHA-1 not added to Firebase**: Most common cause
2. **Wrong SHA-1 was added**: Make sure it matches exactly
3. **Using debug keystore SHA-1**: Add both debug and release SHA-1 values

**Fix Steps**:
```bash
# Get debug SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

# Get release SHA-1
cd android && ./gradlew signingReport
```

Add both SHA1 values to Firebase Console.

## Dart Code Updated
- Phone number validation added (regex for Indian numbers)
- Better null safety checks
- Improved error messages
- Detailed logging for debugging

## Additional Notes
- The app now validates phone numbers before sending OTP
- Session expires after 120 seconds (configurable)
- Resend token is properly managed for retry scenarios
- All Firebase error codes are properly handled

## Next Steps if Issues Persist
1. Check Firebase Console logs
2. Verify GoogleService-Info.plist credentials
3. Ensure iOS Deployment Target is 11.0+
4. Clean build: `flutter clean && flutter pub get`
5. Rebuild iOS: `cd ios && rm -rf Pods Podfile.lock && pod install --repo-update && cd ..`
6. Rebuild Android: `cd android && ./gradlew clean && cd ..`

## Quick Action Checklist

- [ ] Enable Phone Auth in Firebase Console → Authentication → Sign-in method → Phone (Toggle ON)
- [ ] Get SHA-1: `cd android && ./gradlew signingReport`
- [ ] Add SHA-1 to Firebase Console → Project Settings → Your apps → Android → SHA certificate fingerprints
- [ ] Wait 2-3 minutes for Firebase to propagate changes
- [ ] Run: `flutter clean && flutter pub get`
- [ ] Run: `flutter run`
- [ ] Test with phone number format: +91XXXXXXXXXX (10 digits)
- [ ] (Optional) Add test phone number in Firebase Console for development testing
