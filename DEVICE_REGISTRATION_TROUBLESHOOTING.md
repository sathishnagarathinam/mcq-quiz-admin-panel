# Device Registration Error Troubleshooting Guide

## Issue: "Device registration failed" Error After Login

**Affected User**: Shanmuga priya (ghNnYzCeVaQKlSSMMmhfBCqsqhV2)
- Email: shanopriya@gmail.com
- Phone: 9790465518

## Root Causes

### 1. **Firestore Security Rules Blocking Update**
The `mobile_users` collection has strict device binding validation rules that may reject updates if:
- The `registeredDeviceId` field is missing or invalid
- The device binding validation function fails
- The user lacks write permissions to their own document

**Solution**: Check Firestore rules in `firebase/firestore.rules` (lines 179-186)

### 2. **Network Timeout During Device Binding**
Device binding has an 8-second timeout. If the network is slow:
- Firestore query times out
- Device binding process fails
- User is signed out as a security measure

**Solution**: Ensure stable internet connection, retry login

### 3. **User Document Not Found**
The user might exist in Firebase Auth but not in the `mobile_users` Firestore collection.

**Solution**: Check if user document exists in Firestore

### 4. **Device Already Bound to Another User**
The device might be registered to a different user account (one-user-per-device policy).

**Solution**: Clear device registration or use a different device

## Diagnostic Steps

### Step 1: Check User Document Exists
```
Firebase Console → Firestore → mobile_users collection
Search for user ID: ghNnYzCeVaQKlSSMMmhfBCqsqhV2
```

### Step 2: Verify Required Fields
User document should have:
- `uid`: User ID
- `email`: shanopriya@gmail.com
- `name`: Shanmuga priya
- `phoneNumber`: 9790465518
- `isActive`: true
- `emailVerified`: true (or false if not verified)

### Step 3: Check Device Binding Fields
Look for these fields in the user document:
- `isDeviceBound`: boolean
- `registeredDeviceId`: string (device ID)
- `deviceInfo`: object with device details
- `deviceRegisteredAt`: timestamp

### Step 4: Check Firestore Rules
Verify the security rules allow:
1. User to read/write their own `mobile_users` document
2. Device binding validation passes
3. No permission denied errors in browser console

## Quick Fixes

### Fix 1: Reset Device Binding (Admin Action)
1. Go to Mobile User Management in web admin
2. Find user "Shanmuga priya"
3. Click the delete button to remove all data
4. User can re-register with a fresh device

### Fix 2: Clear Device Registration
In Firestore, update the user document:
```javascript
{
  isDeviceBound: false,
  registeredDeviceId: null,
  deviceInfo: null,
  deviceRegisteredAt: null
}
```

Then user can login again to re-bind device.

### Fix 3: Check Network Connection
- Ensure device has stable WiFi or mobile data
- Try logging in from a different network
- Check if Firestore is accessible from the device

## Prevention

1. **Improve Error Messages**: Show specific error details to users
2. **Increase Timeout**: Consider increasing the 8-second timeout
3. **Retry Logic**: Implement automatic retry with exponential backoff
4. **Offline Support**: Cache device binding status locally
5. **Admin Tools**: Add ability to reset device binding from web admin

## Related Files

- Mobile app device binding: `mobile_app/lib/core/services/device_auth_service.dart`
- Firestore rules: `firebase/firestore.rules` (lines 40-54, 179-186)
- Auth provider: `mobile_app/lib/core/providers/mobile_user_auth_provider.dart`

