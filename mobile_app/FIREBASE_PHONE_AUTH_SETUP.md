# Firebase Phone Authentication Setup Guide

## Current Issue
Getting error: `[BILLING_NOT_ENABLED]` when trying to verify phone numbers.

## Step-by-Step Fix

### 1. Enable Phone Authentication Provider

1. **Open Firebase Console:**
   - Go to: https://console.firebase.google.com/project/mcq-quiz-system/authentication/providers

2. **Enable Phone Provider:**
   - Look for "Phone" in the providers list
   - Click on "Phone"
   - Toggle "Enable" to ON
   - Click "Save"

### 2. Add Test Phone Numbers

1. **Go to Authentication Settings:**
   - Navigate to: https://console.firebase.google.com/project/mcq-quiz-system/authentication/settings

2. **Find "Phone numbers for testing" section:**
   - If you don't see this section, Phone Authentication might not be enabled
   - Try refreshing the page after enabling Phone provider

3. **Add these test numbers:**
   ```
   Phone Number: +919876543210
   Verification Code: 123456
   
   Phone Number: +911234567890
   Verification Code: 654321
   
   Phone Number: +919999999999
   Verification Code: 111111
   ```

### 3. Alternative: Enable Billing (Production Solution)

If you want to use real phone numbers:

1. **Go to Project Settings:**
   - https://console.firebase.google.com/project/mcq-quiz-system/settings/general

2. **Click "Usage and billing" tab**

3. **Upgrade to Blaze Plan:**
   - Click "Modify plan"
   - Select "Blaze (Pay as you go)"
   - Add billing account
   - Set spending limits

### 4. Test the Registration

After adding test phone numbers:

1. **Use test phone number in app:**
   - Phone: `+919876543210`
   - Complete registration form
   - When OTP screen appears, enter: `123456`

2. **Registration should complete successfully**

## Troubleshooting

### If "Phone numbers for testing" is not visible:

1. **Check if Phone Authentication is enabled:**
   - Go to Authentication → Sign-in providers
   - Ensure "Phone" is enabled

2. **Clear browser cache and refresh**

3. **Try incognito/private browsing mode**

4. **Check Firebase project permissions:**
   - Ensure you have Editor/Owner role

### If still having issues:

1. **Use temporary test mode in code:**
   - We can modify the auth service to bypass Firebase temporarily
   - This allows UI testing without Firebase billing

2. **Check Firebase project configuration:**
   - Verify correct project ID in firebase_options.dart
   - Ensure app is connected to correct Firebase project

## Quick Links

- **Firebase Console:** https://console.firebase.google.com/project/mcq-quiz-system
- **Authentication Providers:** https://console.firebase.google.com/project/mcq-quiz-system/authentication/providers
- **Authentication Settings:** https://console.firebase.google.com/project/mcq-quiz-system/authentication/settings
- **Project Settings:** https://console.firebase.google.com/project/mcq-quiz-system/settings/general

## Next Steps

1. Enable Phone Authentication provider
2. Add test phone numbers
3. Test registration with +919876543210 and OTP 123456
4. Verify user creation in Firebase Console
5. For production: Enable billing or continue with test numbers

Let me know which step you're stuck on and I'll provide more specific help!
