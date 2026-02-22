# 🧪 Manual Testing Guide - Device Security & Authentication

## Overview
This guide provides step-by-step instructions for manually testing the device-based authentication and security features implemented in the mobile quiz application.

## Prerequisites
- Two physical devices (Android/iOS) or one physical device + one emulator
- Test user accounts
- Access to Firebase Console for monitoring
- Screen recording tools (for iOS testing)

## Test Environment Setup

### 1. Firebase Console Access
- Open Firebase Console
- Navigate to Firestore Database
- Monitor `mobile_users` collection during tests
- Check `securityEvents` array for logged events

### 2. Test User Accounts
Create test accounts with these credentials:
- **User A**: `testa@example.com` / `password123`
- **User B**: `testb@example.com` / `password123`

## Test Scenarios

### 🔐 Device Binding Tests

#### Test 1: First Login - Device Binding
**Objective**: Verify device is bound on first login

**Steps**:
1. Install app on Device 1
2. Register new user or use User A
3. Login with email/password
4. Check Firebase Console:
   - `isDeviceBound` should be `true`
   - `registeredDeviceId` should contain device ID
   - `deviceInfo` should contain device details
   - `deviceRegisteredAt` should have timestamp
   - `securityEvents` should contain device binding event

**Expected Result**: ✅ Device successfully bound, user can access app

#### Test 2: Subsequent Login - Same Device
**Objective**: Verify login works on registered device

**Steps**:
1. Sign out from Device 1
2. Sign in again with same credentials
3. Check Firebase Console for security event

**Expected Result**: ✅ Login successful, security event logged

#### Test 3: Unauthorized Device Access
**Objective**: Verify access is blocked from different device

**Steps**:
1. Install app on Device 2
2. Try to login with User A credentials (already bound to Device 1)
3. Observe error message
4. Check Firebase Console for security event

**Expected Result**: 
- ❌ Login blocked
- Error: "This account is registered to a different device"
- Security event logged: `unauthorized_device_access`

### 🛡️ Screen Protection Tests

#### Test 4: Screenshot Prevention - Android
**Objective**: Verify screenshots are blocked on Android

**Steps**:
1. Login to app on Android device
2. Navigate to quiz screen (wrapped with `QuizSecureWrapper`)
3. Try to take screenshot using:
   - Power + Volume Down
   - Screenshot gesture
   - Assistant screenshot
4. Check if screenshot was blocked

**Expected Result**: ❌ Screenshot blocked, black screen or error message

#### Test 5: Screenshot Prevention - iOS
**Objective**: Verify screenshots are blocked on iOS

**Steps**:
1. Login to app on iOS device
2. Navigate to quiz screen
3. Try to take screenshot using:
   - Side button + Volume Up
   - AssistiveTouch screenshot
4. Check Photos app for screenshot

**Expected Result**: ❌ Screenshot blocked or shows black screen

#### Test 6: Screen Recording Detection - iOS
**Objective**: Verify screen recording is detected on iOS

**Steps**:
1. Login to app on iOS device
2. Start screen recording from Control Center
3. Navigate to quiz screen
4. Observe app behavior
5. Check Firebase Console for security events

**Expected Result**: 
- ⚠️ Warning dialog appears
- Screen may be blurred/blocked
- Security event logged: `screen_recording_detected`

#### Test 7: Screen Recording Prevention - Android
**Objective**: Verify screen recording is prevented on Android

**Steps**:
1. Login to app on Android device
2. Start screen recording
3. Navigate to quiz screen
4. Check recorded video

**Expected Result**: ❌ Screen recording shows black screen for protected areas

### 📱 UI Component Tests

#### Test 8: Device Status Widget
**Objective**: Verify device status is displayed correctly

**Steps**:
1. Login to app
2. Navigate to profile/settings screen
3. Add `DeviceStatusWidget` to screen
4. Verify displayed information

**Expected Result**: 
- ✅ Shows "Device Security Status"
- ✅ Shows "Device Binding: Enabled"
- ✅ Shows masked Device ID
- ✅ Shows registration date
- ✅ Shows platform (Android/iOS)

#### Test 9: Device Validation Error Dialog
**Objective**: Verify error dialog appears for unauthorized devices

**Steps**:
1. Trigger unauthorized device access (Test 3)
2. Observe error dialog
3. Test dialog buttons

**Expected Result**: 
- ✅ Security alert dialog appears
- ✅ Clear error message
- ✅ "Sign Out" button works

### 🔄 Edge Case Tests

#### Test 10: Network Connectivity Issues
**Objective**: Test behavior during network issues

**Steps**:
1. Start login process
2. Disable network during device validation
3. Re-enable network
4. Complete login

**Expected Result**: ✅ Graceful error handling, retry mechanism works

#### Test 11: Firestore Permission Errors
**Objective**: Test behavior with Firestore errors

**Steps**:
1. Temporarily modify Firestore rules to deny access
2. Attempt login
3. Restore rules

**Expected Result**: ✅ Appropriate error messages, no app crashes

#### Test 12: Device Info Retrieval Failure
**Objective**: Test fallback when device info fails

**Steps**:
1. This requires code modification to simulate failure
2. Mock device info plugin to throw error
3. Attempt device binding

**Expected Result**: ✅ Fallback device ID generation works

### 🔒 Security Event Monitoring

#### Test 13: Security Events Logging
**Objective**: Verify all security events are logged

**Steps**:
1. Perform various actions:
   - Device binding
   - Successful login
   - Unauthorized access attempt
   - Screen recording detection
2. Check Firebase Console `securityEvents` array

**Expected Events**:
```json
[
  {
    "type": "device_bound",
    "timestamp": "...",
    "deviceId": "...",
    "details": "Device successfully bound to account"
  },
  {
    "type": "device_validation_success",
    "timestamp": "...",
    "deviceId": "...",
    "details": "Device validation successful"
  },
  {
    "type": "unauthorized_device_access",
    "timestamp": "...",
    "attemptedDeviceId": "...",
    "registeredDeviceId": "...",
    "details": "Unauthorized device access attempt"
  },
  {
    "type": "screen_recording_detected",
    "timestamp": "...",
    "deviceId": "...",
    "details": "Security breach detected"
  }
]
```

## Performance Tests

#### Test 14: Login Performance
**Objective**: Verify device validation doesn't significantly impact login time

**Steps**:
1. Time login process before implementation
2. Time login process after implementation
3. Compare times

**Expected Result**: ✅ Minimal performance impact (< 2 seconds additional)

#### Test 15: App Startup Performance
**Objective**: Verify security initialization doesn't slow startup

**Steps**:
1. Time app startup
2. Monitor for any delays

**Expected Result**: ✅ No significant startup delay

## Regression Tests

#### Test 16: Existing Functionality
**Objective**: Verify existing features still work

**Steps**:
1. Test quiz functionality
2. Test results display
3. Test profile management
4. Test other core features

**Expected Result**: ✅ All existing functionality works normally

## Test Data Cleanup

After testing, clean up test data:
1. Delete test user documents from Firestore
2. Clear any test security events
3. Reset device bindings if needed

## Troubleshooting Common Issues

### Issue: Device binding fails
**Solution**: Check Firestore rules, network connectivity, device info permissions

### Issue: Screenshots not blocked on Android
**Solution**: Verify FLAG_SECURE is properly set, check Android version compatibility

### Issue: Screen recording not detected on iOS
**Solution**: Verify iOS version (requires iOS 11+), check notification setup

### Issue: Security events not logged
**Solution**: Check Firebase authentication, Firestore permissions, network connectivity

## Test Results Template

Use this template to document test results:

```
Test: [Test Name]
Date: [Date]
Device: [Device Model/OS Version]
Result: [PASS/FAIL]
Notes: [Any observations]
Issues: [Any issues found]
```

## Automated Test Execution

Run automated tests alongside manual testing:

```bash
# Unit tests
flutter test test/core/services/device_auth_service_test.dart
flutter test test/core/services/security_service_test.dart

# Integration tests
flutter test integration_test/auth_flow_integration_test.dart
```

## Security Validation Checklist

- [ ] Device binding works on first login
- [ ] Unauthorized devices are blocked
- [ ] Screenshots are prevented
- [ ] Screen recording is detected (iOS)
- [ ] Security events are logged
- [ ] Error messages are user-friendly
- [ ] Performance is acceptable
- [ ] Existing functionality is preserved
