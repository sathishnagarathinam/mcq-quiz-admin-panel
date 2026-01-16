# Google Play Store App Crash Diagnosis & Fix

## 🚨 CRITICAL ISSUE FOUND: Package Name Mismatch

### The Problem
Your app is crashing because of a **package name mismatch** between your app and Firebase configuration:

- **App Package Name**: `com.mcqquiz1.app` (in `build.gradle`)
- **Firebase Config**: `com.mcqquiz.app` (in `google-services.json`)

This causes Firebase initialization to fail, leading to app crashes.

## 🔧 IMMEDIATE FIX OPTIONS

### Option 1: Update Firebase Configuration (Recommended)
1. **Go to Firebase Console**: https://console.firebase.google.com
2. **Select your project**: mcq-quiz-system
3. **Add new Android app** with package name: `com.mcqquiz1.app`
4. **Download new `google-services.json`**
5. **Replace** the current file in `android/app/google-services.json`

### Option 2: Update App Package Name
1. **Change package name** in `android/app/build.gradle`:
   ```gradle
   applicationId "com.mcqquiz.app"  // Remove the "1"
   ```
2. **Rebuild** the app bundle

## 📊 How to Diagnose App Crashes

### 1. Google Play Console Crash Reports
1. **Go to**: Google Play Console → Your App → Quality → Crashes & ANRs
2. **Check**: Recent crashes and stack traces
3. **Look for**: Firebase initialization errors

### 2. Firebase Crashlytics (If Enabled)
1. **Go to**: Firebase Console → Crashlytics
2. **Check**: Real-time crash reports
3. **Filter by**: Version 1.5.0

### 3. Local Testing with Release Build
```bash
# Install release APK locally and check logs
adb install app-release.apk
adb logcat | grep -E "(FATAL|ERROR|Firebase|MCQ)"
```

### 4. Android Studio Logcat
```bash
# Filter for your app
adb logcat | grep "com.mcqquiz1.app"
```

## 🔍 Common Crash Causes & Solutions

### 1. Firebase Configuration Issues
**Symptoms**: App crashes on startup
**Causes**:
- Package name mismatch ✅ **FOUND**
- Missing google-services.json
- Invalid Firebase project configuration

**Fix**: Update Firebase configuration as described above

### 2. ProGuard/R8 Obfuscation Issues
**Symptoms**: App works in debug but crashes in release
**Check**: `android/app/proguard-rules.pro`
**Fix**: Add keep rules for Firebase and other libraries

### 3. Missing Permissions
**Symptoms**: App crashes when accessing features
**Check**: `android/app/src/main/AndroidManifest.xml`
**Current permissions**: ✅ Properly configured

### 4. Native Library Issues
**Symptoms**: UnsatisfiedLinkError crashes
**Causes**: Missing native libraries for different architectures
**Check**: ABI splits configuration

### 5. Memory Issues
**Symptoms**: OutOfMemoryError
**Causes**: Large app size, memory leaks
**Fix**: Enable multidex (already enabled ✅)

## 🛠️ Step-by-Step Crash Investigation

### Step 1: Check Google Play Console
1. **Login** to Google Play Console
2. **Navigate** to: App → Quality → Crashes & ANRs
3. **Look for** crash reports for version 1.5.0
4. **Copy** the stack trace

### Step 2: Analyze Stack Trace
Look for these patterns:
```
Firebase initialization failed
java.lang.RuntimeException: Default FirebaseApp is not initialized
com.google.firebase.FirebaseException
```

### Step 3: Test Locally
```bash
# Install and test release build
cd mobile_app
flutter install --release

# Monitor logs
adb logcat | grep -E "(FATAL|ERROR|Firebase)"
```

### Step 4: Check Firebase Project
1. **Verify** package name in Firebase Console
2. **Check** SHA-1 fingerprints match
3. **Ensure** all required services are enabled

## 🔧 Quick Fix Implementation

### Update Firebase Configuration
1. **Download** new `google-services.json` with correct package name
2. **Replace** current file:
   ```bash
   cp new-google-services.json android/app/google-services.json
   ```
3. **Rebuild** app bundle:
   ```bash
   flutter clean
   flutter build appbundle --release
   ```

### Alternative: Fix Package Name
1. **Update** `android/app/build.gradle`:
   ```gradle
   defaultConfig {
       applicationId "com.mcqquiz.app"  // Remove "1"
   ```
2. **Update** deep link scheme in `AndroidManifest.xml`:
   ```xml
   <data android:scheme="mcqquizapp" android:host="payment" />
   ```
3. **Rebuild** and test

## 📱 Testing Checklist

After implementing the fix:
- [ ] App launches without crashing
- [ ] Firebase authentication works
- [ ] User registration/login works
- [ ] Payment integration works
- [ ] All main features accessible
- [ ] No crashes in Google Play Console

## 🚀 Deployment Steps

1. **Fix** the package name mismatch
2. **Test** locally with release build
3. **Build** new app bundle (version 1.5.1)
4. **Upload** to Google Play Console
5. **Monitor** crash reports

## 📞 Emergency Contacts

If crashes persist:
1. **Check** Firebase Console for service status
2. **Review** recent Firebase SDK updates
3. **Test** with minimal Firebase configuration
4. **Consider** rollback to previous working version

---

**Priority**: 🔴 CRITICAL - Fix immediately before users download
**Impact**: App completely unusable for new installs
**Solution**: Update Firebase configuration with correct package name
