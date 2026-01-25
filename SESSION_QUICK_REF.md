# Session Timeout - Quick Reference

## Overview
2-hour automatic session timeout with session persistence across all app operations.

## How It Works

### User Logs In → Session Starts (2 hours)
```
TimelineStart ──────────────────────────────── 2 Hours Later
           ↓ Session Initialized             ↓
        Login Success                    Auto-Logout
```

### User Activity → Timer Resets
```
Each Action Resets Timer
Dashboard Activity  → Timer: +2 hours
Add Customer        → Timer: +2 hours  
View Customer       → Timer: +2 hours
```

## Key Methods

### In Your Code:
```dart
import '../../../../core/services/session_manager.dart';

final sessionManager = SessionManager();

// Start session (call after login)
sessionManager.initializeSession(user, onExpire);

// Reset timer (called automatically on activity)
sessionManager.resetSession();

// End session (call on logout)
sessionManager.endSession();

// Check if valid
bool isValid = await sessionManager.isSessionValid();

// Get remaining time
Duration? remaining = sessionManager.getRemainingSessionTime();
```

## Console Output

### Session Active:
```
[DEBUG] Session initialized for user: uid123
[DEBUG] Session timeout set for 2 hours
[DEBUG] Session reset for user: uid123
```

### Session Expired:
```
[CRITICAL] Session expired for user: uid123
[CRITICAL] Session timeout triggered
```

## User Experience

### Active User:
- Logs in at 9:00 AM
- Works continuously
- Activity keeps resetting timer
- Never gets logged out
- Session persists until logout

### Idle User:
- Logs in at 9:00 AM
- Stops using app
- After 2 hours of no activity
- Auto-logout occurs
- Must login again

## Configuration

### Default: 2 Hours
```dart
static const Duration SESSION_TIMEOUT = Duration(hours: 2);
```

### To Test (10 seconds):
```dart
static const Duration SESSION_TIMEOUT = Duration(seconds: 10);
```

## Files Involved

1. **SessionManager** - `lib/core/services/session_manager.dart`
2. **Login Page** - `lib/features/authentication/presentation/pages/login.dart`
3. **Dashboard** - `lib/features/dashboard/presentation/pages/dashboard.dart`
4. **Customer Page** - `lib/features/customer/presentation/pages/customer_page.dart`
5. **Signup Page** - `lib/features/authentication/presentation/pages/signup.dart`

## Integration Pattern

### In Login:
```dart
SessionManager().initializeSession(cred.user!, () {
  // Handle expiration
  FirebaseAuth.instance.signOut();
});
Navigator.pushReplacement(MaterialPageRoute(...));
```

### In Dashboard:
```dart
@override
void initState() {
  _sessionManager = SessionManager();
}

@override
Widget build(BuildContext context) {
  _sessionManager.resetSession();
  // Rest of build
}
```

## Testing Checklist

- [ ] Login → Session starts
- [ ] Console shows init message
- [ ] Use app → Timer resets
- [ ] Manual logout → Session ends
- [ ] Wait 2 hours → Auto-logout (or use 10s for testing)
- [ ] After timeout → Redirected to login
- [ ] Signup → Session auto-initialized

## Common Issues

### Session not initializing?
- Check imports: `import '../../../../core/services/session_manager.dart';`
- Verify call after login success

### Session not resetting?
- Ensure `resetSession()` called in page build()
- Check console for reset logs

### Not auto-logging out?
- Wait full 2 hours or reduce timeout for testing
- Check Firestore still allows operations (rules)

## Security Features

✅ Auto-logout after inactivity  
✅ Session tied to user  
✅ No manual timer management  
✅ Transparent to user (if active)  
✅ Secure redirect on timeout  

## Current APK

Ready to install and test:
```
build/app/outputs/flutter-apk/app-release.apk (53.0 MB)
```

## Support

For detailed documentation, see:
- `SESSION_TIMEOUT.md` - Complete guide
- `SESSION_IMPLEMENTATION.md` - Implementation details
