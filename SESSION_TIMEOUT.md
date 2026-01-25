# Session Timeout Implementation (2 Hours)

## Overview
Implemented a 2-hour session timeout for user login with automatic logout and session continuity across all app operations.

## Features

### 1. **SessionManager Service** (`lib/core/services/session_manager.dart`)
- Singleton pattern for global session management
- 2-hour (120 minutes) auto-logout timer
- Session reset on every user activity
- Callback notification on session expiration

**Key Methods:**
- `initializeSession(User, callback)` - Start session with expiration handler
- `resetSession()` - Reset timer on user activity
- `endSession()` - Manual logout
- `isSessionValid()` - Check if session is active
- `getRemainingSessionTime()` - Get remaining session duration

### 2. **Login Page Integration** (`lib/features/authentication/presentation/pages/login.dart`)
- Session initialized immediately after successful login
- 2-hour timer starts automatically
- On expiration: automatic logout + "Session expired" message
- User redirected to login page

**Code Flow:**
```dart
FirebaseAuth.instance.signInWithEmailAndPassword(...).then((cred) {
  // Initialize session with 2-hour timeout
  SessionManager().initializeSession(cred.user!, () {
    // Called when 2 hours expire
    FirebaseAuth.instance.signOut();
    showSnackBar('Session expired. Please login again.');
  });
  // Navigate to dashboard
  Navigator.pushReplacement(MaterialPageRoute(builder: (_) => DashboardPage()));
});
```

### 3. **Dashboard Integration** (`lib/features/dashboard/presentation/pages/dashboard.dart`)
- Session timer reset on every user interaction
- Timer reset happens in `build()` and on page navigation
- Logout properly ends session via `SessionManager.endSession()`

**Session Reset Trigger:**
```dart
@override
Widget build(BuildContext context) {
  _sessionManager.resetSession(); // Reset timer on every rebuild
  // ... rest of build
}
```

### 4. **Customer Page Integration** (`lib/features/customer/presentation/pages/customer_page.dart`)
- Session timer reset on page load and user interactions
- CRUD operations maintain active session
- Session management via `SessionManager` singleton

### 5. **Signup Page Integration** (`lib/features/authentication/presentation/pages/signup.dart`)
- New users get session initialized after account setup
- Same 2-hour timeout applies to new accounts

## Session Timeout Flow

```
1. User Logs In
   ↓
2. SessionManager.initializeSession() called
   ↓
3. 2-hour timer starts
   ↓
4. User interacts with app
   ↓
5. SessionManager.resetSession() called (timer resets)
   ↓
6. If no activity for 2 hours → Session expires
   ↓
7. Automatic logout + redirect to login page
```

## Key Features

### ✅ **Activity-Based Timer Reset**
- Every user action resets the 2-hour timer
- No logout if user remains active
- Seamless experience during work

### ✅ **Persistent User Session**
- `SessionManager` singleton maintains user context
- User data available across all pages
- No re-authentication needed within 2 hours

### ✅ **Automatic Cleanup**
- Session ends on logout
- Session ends on timer expiration
- Timer canceled on app exit

### ✅ **User-Friendly Notifications**
- SnackBar message on session expiration
- Redirect to login page
- Console logging for debugging

## Console Logs

### Debug Logs:
```
[DEBUG] Session initialized for user: uid123
[DEBUG] Session reset for user: uid123
[DEBUG] Attempting login with: email@example.com
[DEBUG] Session timeout set for 2 hours
```

### Critical Logs:
```
[CRITICAL] Session expired for user: uid123
[CRITICAL] Session timeout triggered
```

## Implementation Details

### Timer Management
- Implemented with Dart's `Timer` class
- 2-hour duration = `Duration(hours: 2)` = 7,200 seconds
- Timer automatically canceled on session end
- New timer created on each reset

### User Validation
- Session validity checked via Firebase `currentUser.reload()`
- Handles Firebase auth state changes
- Prevents stale user sessions

### Singleton Pattern
- Only one `SessionManager` instance app-wide
- Ensures consistent session state
- Easy access: `SessionManager()`

## Usage in Other Pages

To use session management in any page:

```dart
import '../../../../core/services/session_manager.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late SessionManager _sessionManager;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();
  }

  @override
  Widget build(BuildContext context) {
    _sessionManager.resetSession(); // Reset timer on interaction
    // ... rest of build
  }
}
```

## Testing Session Timeout

To test locally (change timer duration temporarily):

```dart
// In session_manager.dart, change:
static const Duration SESSION_TIMEOUT = Duration(seconds: 10); // For testing

// Then login and wait 10 seconds to see session expire
```

## Security Considerations

✅ **What's Protected:**
- User session auto-expires after inactivity
- Automatic logout on timeout
- Session tied to specific user

⚠️ **What's Not Protected:**
- Firebase rules still needed for database access
- App-level authentication still required
- Local storage not auto-cleared (add if needed)

## Firebase Integration

Session manager works with Firebase Auth:
- `FirebaseAuth.instance.currentUser` - Get active user
- `currentUser.reload()` - Validate user still authenticated
- `FirebaseAuth.instance.signOut()` - Logout on expiration

## Future Enhancements

Possible improvements:
- [ ] Save session expiration time to local storage
- [ ] Show countdown timer in UI (e.g., "10 minutes remaining")
- [ ] Add "Extend Session" button on warning dialog
- [ ] Different timeouts for different user roles (admin/user)
- [ ] Session warning dialog before timeout
- [ ] Activity tracking analytics
- [ ] Biometric re-authentication on timeout

## Files Modified

1. ✅ `lib/core/services/session_manager.dart` - NEW
2. ✅ `lib/features/authentication/presentation/pages/login.dart`
3. ✅ `lib/features/dashboard/presentation/pages/dashboard.dart`
4. ✅ `lib/features/customer/presentation/pages/customer_page.dart`
5. ✅ `lib/features/authentication/presentation/pages/signup.dart`

## Testing Checklist

- [ ] Login and verify session starts
- [ ] Check console for `[DEBUG] Session initialized...`
- [ ] Perform activity and verify timer resets
- [ ] Wait 2 hours (or use shorter timeout for testing)
- [ ] Verify automatic logout on timeout
- [ ] Check SnackBar message appears
- [ ] Verify user redirected to login page
- [ ] Test manual logout ends session properly
- [ ] Test signup page initializes session
- [ ] Test customer page maintains session
