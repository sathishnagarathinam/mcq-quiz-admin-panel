# Real-time Firebase OTP Implementation

This document describes the implementation of real-time Firebase OTP authentication for user registration and login in the MCQ Quiz mobile application.

## Overview

The real-time OTP implementation uses Firebase Auth SDK directly to provide immediate feedback during the OTP verification process, replacing the previous REST API approach with native Firebase Auth methods.

## Key Features

- **Real-time callbacks**: Immediate feedback for OTP sent, verification failed, and verification completed events
- **Enhanced error handling**: Specific error messages for different failure scenarios
- **Auto-verification support**: Automatic verification on Android devices when possible
- **Resend functionality**: Built-in OTP resend capability with proper token management
- **Secure data storage**: Temporary registration data stored securely using SharedPreferences
- **Separation of concerns**: Registration and login flows are properly separated

## Architecture

### Core Components

1. **FirebaseRealtimeAuthService** (`lib/core/services/firebase_realtime_auth_service.dart`)
   - Main service handling Firebase Auth operations
   - Provides real-time callbacks for OTP events
   - Manages verification IDs and resend tokens
   - Handles both registration and login flows

2. **AuthProvider** (`lib/core/providers/auth_provider_minimal.dart`)
   - State management for authentication
   - Integrates with the real-time auth service
   - Provides methods for registration and login OTP flows

3. **Registration OTP Screen** (`lib/features/auth/screens/registration_otp_screen.dart`)
   - UI for OTP verification during registration
   - Enhanced with better error handling and user feedback
   - Supports OTP resend functionality

## Implementation Details

### Registration Flow

1. **Send Registration OTP**
   ```dart
   await FirebaseRealtimeAuthService.sendRegistrationOTP(
     phoneNumber: phoneNumber,
     name: name,
     email: email,
     officeName: officeName,
     designation: designation,
     onCodeSent: (message) => // Handle success,
     onVerificationFailed: (error) => // Handle error,
     onVerificationCompleted: () => // Handle auto-verification,
     onRegistrationSuccess: (user) => // Handle completion,
   );
   ```

2. **Verify Registration OTP**
   ```dart
   final user = await FirebaseRealtimeAuthService.verifyRegistrationOTP(otp);
   ```

3. **Resend Registration OTP**
   ```dart
   await FirebaseRealtimeAuthService.resendRegistrationOTP();
   ```

### Login Flow

1. **Send Login OTP**
   ```dart
   await FirebaseRealtimeAuthService.sendLoginOTP(
     phoneNumber: phoneNumber,
     onCodeSent: (message) => // Handle success,
     onVerificationFailed: (error) => // Handle error,
     onVerificationCompleted: () => // Handle auto-verification,
   );
   ```

2. **Verify Login OTP**
   ```dart
   final user = await FirebaseRealtimeAuthService.verifyLoginOTP(otp);
   ```

### Error Handling

The implementation provides specific error messages for common scenarios:

- **billing-not-enabled**: Firebase SMS billing not enabled
- **invalid-phone-number**: Invalid phone number format
- **too-many-requests**: Rate limiting exceeded
- **quota-exceeded**: SMS quota exceeded
- **invalid-verification-code**: Invalid OTP entered
- **session-expired**: OTP session expired

### Data Storage

Temporary registration data is stored securely using the following keys:
- `temp_registration_data`: User registration information
- `firebase_registration_verification_id`: Verification ID for registration
- `resend_token`: Token for OTP resend functionality

## Security Considerations

1. **Data Isolation**: Registration and login verification IDs are stored separately
2. **Automatic Cleanup**: Temporary data is cleared after successful verification
3. **Session Management**: Proper handling of verification sessions and timeouts
4. **User Separation**: Registration completes but user is not automatically logged in

## Testing

### Manual Testing

1. **Registration Flow**:
   - Fill registration form with valid data
   - Submit form and verify OTP is sent
   - Enter received OTP and verify registration completes
   - Confirm user is redirected to login screen

2. **Login Flow**:
   - Enter registered phone number
   - Verify OTP is sent
   - Enter received OTP and verify login succeeds
   - Confirm user is redirected to home screen

3. **Error Scenarios**:
   - Test with invalid phone numbers
   - Test with incorrect OTP codes
   - Test OTP expiration
   - Test resend functionality

### Automated Testing

A test utility is provided in `lib/core/services/firebase_realtime_auth_test.dart`:

```dart
// Run all tests
await FirebaseRealtimeAuthTest.runAllTests();

// Test specific functionality
await FirebaseRealtimeAuthTest.testRegistrationOTP();
await FirebaseRealtimeAuthTest.testLoginOTP();
await FirebaseRealtimeAuthTest.testResendOTP();
```

## Configuration

### Firebase Setup

Ensure Firebase is properly configured:

1. **Firebase Console**: Enable Phone Authentication
2. **Billing**: Enable SMS billing for production use
3. **Test Numbers**: Configure test phone numbers for development

### App Configuration

The implementation uses the existing Firebase configuration in:
- `lib/core/config/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## Migration from REST API

The implementation maintains backward compatibility while providing enhanced functionality:

1. **Test Mode**: Existing test mode functionality is preserved
2. **State Management**: Auth provider state structure remains unchanged
3. **Navigation**: Existing navigation flows are maintained
4. **Error Handling**: Enhanced error messages while maintaining existing error structure

## Best Practices

1. **Always check mounted state** before updating UI after async operations
2. **Use proper error handling** for all Firebase Auth operations
3. **Clear sensitive data** after successful operations
4. **Provide user feedback** for all OTP operations
5. **Handle auto-verification** gracefully on Android devices

## Troubleshooting

### Common Issues

1. **OTP not received**: Check Firebase billing and phone number format
2. **Verification failed**: Ensure proper error handling and user feedback
3. **Session expired**: Implement proper timeout handling and resend functionality
4. **Auto-verification issues**: Test on different Android devices and versions

### Debug Mode

Enable debug logging by uncommenting the test runner in `main.dart`:

```dart
if (kDebugMode) await FirebaseRealtimeAuthTest.runAllTests();
```

## Future Enhancements

1. **Analytics**: Add Firebase Analytics for OTP success/failure rates
2. **Retry Logic**: Implement automatic retry for failed OTP sends
3. **Rate Limiting**: Add client-side rate limiting for OTP requests
4. **Biometric Auth**: Integrate biometric authentication as alternative
5. **Multi-factor Auth**: Support for additional authentication factors
