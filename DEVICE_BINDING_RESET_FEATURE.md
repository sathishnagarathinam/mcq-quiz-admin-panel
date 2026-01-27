# Device Binding Reset Feature - Web Admin Panel

## Overview
Admins can now reset device binding for mobile users directly from the web admin panel. This allows users who are locked out due to device changes to regain access.

## Problem This Solves
When a user tries to login from a different device, they get the error:
```
"Unauthorized device access attempt - different device"
```

This happens because the app enforces a **strict one-user-per-device policy** for security. If a user:
- Reinstalls the app
- Gets a new device
- Clears app data
- Updates their OS

The device ID changes and they can't login.

## Solution: Reset Device Binding

### How to Use (Admin)

1. **Go to Mobile Users Page** in web admin
2. **Find the user** (search by name, email, or phone)
3. **Click the phone icon** (🔄 Reset Device Binding button) in the Actions column
4. **Confirm the action** in the dialog
5. **User can now login from a different device**

### What Gets Reset
- `registeredDeviceId` → Set to `null`
- `isDeviceBound` → Set to `false`
- `deviceInfo` → Set to `null`
- `deviceRegisteredAt` → Set to `null`

### What Stays Intact
✅ User account and profile  
✅ Quiz attempts and scores  
✅ Payment records  
✅ All user data  

## User Experience After Reset

1. User tries to login from new device
2. Enters phone number and OTP
3. Device validation passes (no device bound yet)
4. New device is registered as primary device
5. User gains full access

## Technical Details

### Code Changes
- **File**: `web_admin/src/pages/mobile-users/MobileUsersPage.tsx`
- **New State Variables**:
  - `resetDeviceDialogOpen`: Controls dialog visibility
  - `userForDeviceReset`: Stores user being reset
  - `isResettingDevice`: Loading state during reset

- **New Functions**:
  - `handleResetDeviceBinding()`: Opens confirmation dialog
  - `confirmResetDeviceBinding()`: Executes the reset

### Firestore Update
```typescript
await updateDoc(doc(db, 'mobile_users', userId), {
  registeredDeviceId: null,
  isDeviceBound: false,
  deviceInfo: null,
  deviceRegisteredAt: null,
  updatedAt: new Date(),
});
```

## Security Considerations

✅ **Admin-only action** - Only admins can reset device binding  
✅ **Confirmation required** - Dialog prevents accidental resets  
✅ **Audit trail** - Action logged with timestamp  
✅ **No data loss** - User data remains completely intact  
✅ **Reversible** - Can be done multiple times if needed  

## Example Scenario

**User 9876543211 Issue:**
1. User registered on Device A
2. User gets new phone (Device B)
3. Tries to login → Gets "different device" error
4. Admin resets device binding
5. User can now login on Device B
6. Device B becomes the new registered device

## Related Features

- **Device Diagnostics**: Run diagnostics to see current device binding status
- **User Analytics**: View user's quiz attempts and performance
- **Delete User**: Permanently remove user account (different from reset)

## Troubleshooting

**Issue**: Reset button doesn't work
- Check admin permissions
- Ensure Firestore rules allow updates to mobile_users collection

**Issue**: User still can't login after reset
- Verify user's phone number is correct
- Check if user has internet connection
- Run device diagnostics to see current status

## Future Enhancements

- [ ] Bulk reset device binding for multiple users
- [ ] Device binding history/audit log
- [ ] Automatic device binding reset after X days of inactivity
- [ ] User self-service device reset via email verification

