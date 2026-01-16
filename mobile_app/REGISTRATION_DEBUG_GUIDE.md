# Registration Debug Guide

This guide helps debug registration issues with the real-time Firebase OTP implementation.

## Common Issues and Solutions

### 1. OTP Not Being Sent

**Symptoms:**
- No OTP received on phone
- Error messages about billing or quota

**Possible Causes:**
- Firebase SMS billing not enabled
- Invalid phone number format
- Firebase quota exceeded
- Test mode enabled

**Solutions:**
1. **Check Firebase Console:**
   - Go to Firebase Console → Authentication → Sign-in method
   - Ensure Phone authentication is enabled
   - Check if SMS billing is enabled in Firebase Console → Usage and billing

2. **Check Phone Number Format:**
   - Ensure phone number includes country code (e.g., +919876543210)
   - Use valid phone numbers for testing

3. **Enable Test Mode (for development):**
   ```dart
   // In auth_provider_minimal.dart, line 127
   static const bool _useTestMode = true; // For development
   ```

4. **Use Firebase Test Phone Numbers:**
   - Add test phone numbers in Firebase Console
   - Use these for development testing

### 2. Registration Data Not Saved to Firebase

**Symptoms:**
- OTP verification succeeds but user data not in Firestore
- Error messages about Firestore operations

**Debug Steps:**
1. **Check Debug Logs:**
   - Look for "DEBUG: Creating Firestore document..." messages
   - Check for any Firestore errors in logs

2. **Verify Firestore Rules:**
   - Ensure Firestore security rules allow writes
   - Check if authentication is required for writes

3. **Check Network Connection:**
   - Ensure device has internet connectivity
   - Check if Firestore is accessible

### 3. OTP Verification Fails

**Symptoms:**
- "Invalid OTP" or "Session expired" errors
- OTP verification always fails

**Debug Steps:**
1. **Check Verification ID Storage:**
   - Look for "DEBUG: Registration OTP sent successfully" messages
   - Verify verification ID is being stored properly

2. **Check OTP Input:**
   - Ensure OTP is exactly 6 digits
   - Check for any input formatting issues

3. **Check Session Timeout:**
   - OTP expires after 60 seconds by default
   - Request new OTP if expired

## Debug Mode Setup

### Enable Debug Logging

1. **In main.dart:**
   ```dart
   // Uncomment this line to run tests
   if (kDebugMode) await FirebaseRealtimeAuthTest.runAllTests();
   ```

2. **Check Console Output:**
   - Look for DEBUG messages in console
   - Follow the registration flow step by step

### Test Mode vs Production Mode

**Test Mode (for development):**
```dart
static const bool _useTestMode = true;
```
- Uses mock Firebase service
- No real SMS sent
- Good for UI testing

**Production Mode (for real testing):**
```dart
static const bool _useTestMode = false;
```
- Uses real Firebase Auth
- Sends actual SMS
- Requires Firebase billing

## Step-by-Step Debug Process

### 1. Registration Form Submission
- Check if form validation passes
- Verify all required fields are filled
- Look for "DEBUG: Using Firebase Real-time Auth for registration" message

### 2. OTP Sending
- Look for "DEBUG: Registration OTP sent successfully" message
- Check for any error messages in onVerificationFailed callback
- Verify phone number format

### 3. OTP Verification
- Look for "DEBUG: Starting registration completion..." message
- Check "DEBUG: User signed in successfully" message
- Verify "DEBUG: Firestore document created successfully" message

### 4. Data Storage
- Check "DEBUG: Registration data stored locally" message
- Verify "DEBUG: User signed out after registration" message

## Firebase Console Checks

### 1. Authentication Tab
- Check if user appears in Authentication → Users
- Verify phone number is correctly stored

### 2. Firestore Tab
- Check if user document exists in 'users' collection
- Verify all fields are populated correctly

### 3. Usage Tab
- Check SMS usage and billing status
- Monitor quota usage

## Common Error Messages

### "Firebase SMS billing is not enabled"
- Enable billing in Firebase Console
- Or use test phone numbers for development

### "The phone number format is invalid"
- Ensure phone number includes country code
- Use format: +[country_code][phone_number]

### "Too many requests"
- Wait before sending another OTP
- Check rate limiting settings

### "Session expired"
- Request new OTP
- Check if verification is attempted within timeout period

## Testing Checklist

- [ ] Firebase project configured correctly
- [ ] Phone authentication enabled in Firebase Console
- [ ] SMS billing enabled (for production) or test numbers configured
- [ ] Test mode setting matches environment (dev/prod)
- [ ] Phone number format is correct (+country_code + number)
- [ ] Firestore security rules allow writes
- [ ] Network connectivity available
- [ ] Debug logging enabled
- [ ] Console output monitored during testing

## Quick Fix Commands

### Reset Registration State
```dart
// Clear stored data
await FirebaseRealtimeAuthService.clearStoredData();
```

### Test Firebase Connection
```dart
// Run Firebase tests
await FirebaseRealtimeAuthTest.runAllTests();
```

### Check Firestore Rules
```javascript
// Allow authenticated writes
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Support

If issues persist:
1. Check Firebase Console for detailed error logs
2. Monitor device logs for crash reports
3. Verify Firebase project configuration
4. Test with different phone numbers
5. Try both test mode and production mode
