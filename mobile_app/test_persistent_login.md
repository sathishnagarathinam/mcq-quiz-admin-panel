# Persistent Login Testing Guide

## Overview
This guide helps you test the persistent login functionality that has been implemented in the MCQ Quiz mobile app.

## What Was Implemented

### 1. Splash Screen
- **File**: `lib/features/auth/screens/splash_screen.dart`
- **Purpose**: Checks authentication state on app startup
- **Behavior**: 
  - Shows for 2 seconds minimum for better UX
  - Checks if user is already authenticated
  - Redirects to home if authenticated, login if not

### 2. Authentication Guards
- **File**: `lib/core/router/app_router.dart`
- **Purpose**: Protects routes based on authentication state
- **Behavior**:
  - Redirects authenticated users away from auth pages to home
  - Redirects unauthenticated users away from protected pages to login
  - Initial route is now `/splash` instead of `/auth/email-login`

### 3. Updated Logout Flow
- **File**: `lib/features/profile/screens/profile_screen.dart`
- **Purpose**: Ensures proper navigation after logout
- **Behavior**: Navigates to splash screen after logout, which then redirects to login

## Testing Steps

### Test 1: Fresh Install (No Previous Login)
1. **Start the app** (fresh install or after clearing app data)
2. **Expected behavior**:
   - App shows splash screen for ~2 seconds
   - Automatically navigates to email login screen
   - No manual navigation required

### Test 2: Login and Verify Session Persistence
1. **Login with valid credentials**:
   - Use the email login screen
   - Enter valid email and password
   - Tap "Sign In"
2. **Expected behavior**:
   - Successful login navigates to home screen
   - User can access all app features

### Test 3: App Restart (Key Test)
1. **Close the app completely** (not just minimize):
   - Use recent apps and swipe away the app
   - Or use device settings to force stop the app
2. **Restart the app**
3. **Expected behavior**:
   - App shows splash screen for ~2 seconds
   - **Automatically navigates to home screen** (not login)
   - User remains logged in without re-entering credentials

### Test 4: Logout Functionality
1. **From home screen, navigate to profile**
2. **Tap "Sign Out" button**
3. **Expected behavior**:
   - Shows success message
   - Navigates to splash screen
   - Splash screen redirects to login screen
   - User must login again to access app

### Test 5: Authentication Guards
1. **While logged out, try to access protected routes**:
   - Try navigating directly to `/home`, `/profile`, `/quiz`, etc.
2. **Expected behavior**:
   - Automatically redirected to login screen
   - Cannot access protected content without authentication

1. **While logged in, try to access auth routes**:
   - Try navigating to `/auth/email-login` or `/auth/email-register`
2. **Expected behavior**:
   - Automatically redirected to home screen
   - Cannot access login/register pages when already authenticated

## Technical Details

### Authentication State Management
- Uses Supabase authentication with automatic session persistence
- `MobileUserAuthNotifier` checks auth state on app startup
- Listens to auth state changes for real-time updates

### Router Configuration
- Initial location: `/splash`
- Redirect logic based on authentication state
- Protected routes require authentication
- Auth routes redirect when already authenticated

### Session Persistence
- Supabase handles session persistence automatically
- No manual token management required
- Sessions persist across app restarts until explicit logout

## Troubleshooting

### If persistent login doesn't work:
1. Check if Supabase is properly initialized
2. Verify authentication provider is correctly checking auth state
3. Ensure router guards are properly configured
4. Check for any errors in the console logs

### Common Issues:
- **App always goes to login**: Check if auth state checking is working
- **App always goes to home**: Check if logout is properly clearing auth state
- **Navigation loops**: Check router redirect logic for infinite redirects

## Success Criteria
✅ Fresh install shows login screen
✅ Successful login navigates to home
✅ App restart keeps user logged in (goes to home)
✅ Logout properly clears session and shows login
✅ Authentication guards work correctly
