# 🔐 Device-Based Authentication & Security Implementation

## Overview

This implementation provides comprehensive device-based authentication and security features for the mobile quiz application, ensuring that users can only access their accounts from registered devices and preventing screenshots/screen recording during sensitive operations.

## Features Implemented

### 1. Device-Based Authentication
- **Device Binding**: Users' accounts are bound to their device on first login
- **Device Validation**: Subsequent logins validate the device before allowing access
- **Unauthorized Device Blocking**: Prevents access from unregistered devices
- **Security Event Logging**: Tracks all device-related security events

### 2. Screen Security Protection
- **Screenshot Prevention**: Blocks screenshots on Android and iOS
- **Screen Recording Detection**: Detects and prevents screen recording (iOS)
- **Secure Screen Wrapper**: Reusable widget for protecting sensitive screens
- **Real-time Monitoring**: Continuous monitoring during quiz sessions

### 3. Enhanced User Experience
- **Device Status Display**: Shows device registration status to users
- **Security Alerts**: User-friendly error messages for security violations
- **Seamless Integration**: Works with existing authentication flow

## Implementation Details

### Core Services

#### 1. DeviceAuthService (`lib/core/services/device_auth_service.dart`)
```dart
// Key methods:
- getDeviceId(): Get unique device identifier
- getDeviceInfo(): Get comprehensive device information
- bindDeviceToUser(): Bind device to user account
- validateDeviceForUser(): Validate device for login
- hasRegisteredDevice(): Check if user has registered device
```

#### 2. Enhanced SecurityService (`lib/core/services/security_service.dart`)
```dart
// New security methods:
- enableScreenProtection(): Enable comprehensive protection
- disableScreenProtection(): Disable protection
- preventScreenRecording(): Prevent screen recording
- isScreenRecordingActive(): Check recording status
- startScreenRecordingMonitoring(): Monitor recording status
```

### Data Model Updates

#### Enhanced MobileUser Model
```dart
class MobileUser {
  // Existing fields...
  
  // New device security fields:
  final String? registeredDeviceId;
  final Map<String, dynamic>? deviceInfo;
  final DateTime? deviceRegisteredAt;
  final bool isDeviceBound;
  final List<Map<String, dynamic>>? securityEvents;
}
```

### Native Platform Implementation

#### Android (`android/app/src/main/kotlin/com/mcqquiz/app/MainActivity.kt`)
- Screenshot prevention using `FLAG_SECURE`
- Screen recording prevention (same as screenshot prevention)
- Method channels for Flutter communication

#### iOS (`ios/Runner/AppDelegate.swift`)
- Screenshot prevention using secure views
- Screen recording detection using `UIScreen.isCaptured`
- Real-time monitoring with notifications
- Method channels for Flutter communication

### UI Components

#### 1. SecureScreenWrapper (`lib/core/widgets/secure_screen_wrapper.dart`)
```dart
// Usage examples:
SecureScreenWrapper(child: QuizScreen())
QuizSecureWrapper(child: QuizContent())
ResultsSecureWrapper(child: ResultsContent())
```

#### 2. Device Status Widget (`lib/features/auth/widgets/device_status_widget.dart`)
- Shows device registration status
- Displays device information (masked for security)
- Security status indicators

## Authentication Flow

### First Login (Device Binding)
1. User enters email/password
2. Firebase authentication succeeds
3. Device validation checks if device is bound
4. If not bound, device is automatically registered
5. Device ID and info stored in Firestore
6. User gains access

### Subsequent Logins (Device Validation)
1. User enters email/password
2. Firebase authentication succeeds
3. Device validation compares current device with registered device
4. If devices match: Access granted
5. If devices don't match: Access denied with error message

### Unauthorized Device Access
1. User tries to login from different device
2. Device validation fails
3. User is signed out automatically
4. Error message: "This account is registered to a different device"
5. Security event logged in Firestore

## Security Features

### Screen Protection
```dart
// Automatic protection for quiz screens
QuizSecureWrapper(
  child: QuizContent(),
  onSecurityBreach: () {
    // Handle security violation
  },
)

// Manual control
await SecurityService.enableScreenProtection();
await SecurityService.disableScreenProtection();
```

### Screen Recording Detection (iOS)
- Real-time detection using `UIScreen.capturedDidChangeNotification`
- Automatic warnings when recording detected
- Optional screen blurring during recording
- Security event logging

## Firestore Security Rules

Enhanced rules support device-based authentication:
```javascript
// Mobile users collection with device validation
match /mobile_users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  allow update: if request.auth != null && 
    request.auth.uid == userId &&
    validateDeviceBinding(request.resource.data, resource.data);
}

function validateDeviceBinding(newData, existingData) {
  return !existingData.keys().hasAll(['isDeviceBound']) ||
         !existingData.isDeviceBound ||
         (existingData.isDeviceBound && 
          newData.registeredDeviceId == existingData.registeredDeviceId);
}
```

## Usage Examples

### 1. Protecting Quiz Screens
```dart
class QuizScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return QuizSecureWrapper(
      child: Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: QuizContent(),
      ),
      onSecurityBreach: () {
        // Handle security violation
        Navigator.of(context).pushReplacementNamed('/home');
      },
    );
  }
}
```

### 2. Protecting Results Screens
```dart
class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResultsSecureWrapper(
      child: Scaffold(
        appBar: AppBar(title: Text('Results')),
        body: ResultsContent(),
      ),
    );
  }
}
```

### 3. Showing Device Status
```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Other profile content...
          DeviceStatusWidget(),
        ],
      ),
    );
  }
}
```

### 4. Handling Device Validation Errors
```dart
// In login screen
final success = await ref.read(mobileUserAuthProvider.notifier).signInUser(
  email: email,
  password: password,
);

if (!success) {
  final authState = ref.read(mobileUserAuthProvider);
  if (authState.error?.contains('registered to a different device') == true) {
    DeviceValidationErrorDialog.show(
      context,
      message: authState.error!,
      onSignOut: () {
        // Handle sign out
      },
    );
  }
}
```

## Security Considerations

### Device ID Generation
- **Android**: Uses Android ID with fallback to device fingerprint hash
- **iOS**: Uses identifierForVendor with fallback to device info hash
- **Persistence**: Device IDs are cached for performance
- **Privacy**: Device info is stored securely in Firestore

### Screen Protection
- **Android**: Uses `FLAG_SECURE` to prevent screenshots and recording
- **iOS**: Uses secure views and recording detection
- **Limitations**: iOS doesn't allow preventing screen recording, only detection

### Security Events
All security-related events are logged:
- Device binding
- Device validation success/failure
- Unauthorized access attempts
- Screen recording detection
- Security breaches

## Testing

### Device Binding Testing
1. Register new user on Device A
2. Verify device is bound in Firestore
3. Try to login from Device B
4. Verify access is denied
5. Check security events are logged

### Screen Protection Testing
1. Enable screen protection
2. Try to take screenshot (should fail on Android)
3. Try screen recording (should be detected on iOS)
4. Verify warnings are shown
5. Check security events are logged

## Deployment Notes

### Android Permissions
No additional permissions required for screenshot prevention.

### iOS Capabilities
No additional capabilities required for screen recording detection.

### Firestore Indexes
Consider adding indexes for device-related queries:
```javascript
// Index for device binding queries
mobile_users: {
  registeredDeviceId: 'asc',
  isDeviceBound: 'asc'
}
```

## Future Enhancements

1. **Device Management**: Allow users to unbind/rebind devices
2. **Multiple Device Support**: Support for multiple registered devices
3. **Biometric Integration**: Additional biometric authentication
4. **Advanced Monitoring**: More sophisticated security monitoring
5. **Remote Wipe**: Ability to remotely clear app data on security breach
