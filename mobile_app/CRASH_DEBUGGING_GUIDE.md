# App Crash Debugging Guide - Google Play Store Installation

## 🚨 Issue: App crashes after installing from Google Play Store

This guide will help you identify and fix the crash issue systematically.

## 🔍 Step 1: Check Google Play Console Crash Reports

### Access Crash Reports:
1. **Go to Google Play Console**
2. **Navigate to**: Your App → Quality → Android vitals → Crashes & ANRs
3. **Look for**: Recent crash reports with stack traces
4. **Check**: Crash rate, affected devices, Android versions

### What to Look For:
- **Stack traces**: Exact error location in code
- **Crash frequency**: How often it happens
- **Device patterns**: Specific devices/Android versions affected
- **User actions**: What triggers the crash

## 🔍 Step 2: Compare Release vs Debug Builds

### Test Local Release Build:
```bash
cd mobile_app

# Install the same release APK locally
adb install build/app/outputs/flutter-apk/app-release.apk

# Monitor logs while testing
adb logcat | grep -E "(flutter|mcq|crash|error)"
```

### Check if crash happens locally:
- **If YES**: Issue is in release build configuration
- **If NO**: Issue might be Play Store specific (signing, optimization, etc.)

## 🔍 Step 3: Enable Crash Reporting in App

### Add Firebase Crashlytics (Recommended):

1. **Add dependency** in `pubspec.yaml`:
```yaml
dependencies:
  firebase_crashlytics: ^3.4.9
```

2. **Initialize in main.dart**:
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set up Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(MyApp());
}
```

## 🔍 Step 4: Common Play Store Crash Causes

### 1. ProGuard/R8 Obfuscation Issues
**Problem**: Code obfuscation breaks reflection or dynamic calls

**Check**: `android/app/build.gradle`
```gradle
buildTypes {
    release {
        // Check if these are causing issues
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

**Fix**: Add ProGuard rules in `android/app/proguard-rules.pro`:
```
# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep PhonePe SDK classes
-keep class com.phonepe.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class androidx.** { *; }

# Keep your app classes
-keep class com.mcqquiz1.app.** { *; }
```

### 2. Missing Permissions or Configurations
**Check**: `android/app/src/main/AndroidManifest.xml`

**Common Issues**:
- Missing internet permission
- Incorrect activity configurations
- Missing provider declarations

### 3. Firebase Configuration Issues
**Check**: `android/app/google-services.json`

**Verify**:
- Correct package name (`com.mcqquiz1.app`)
- Valid SHA-1 fingerprints
- Enabled services match your usage

### 4. Native Dependencies Issues
**Common Culprits**:
- PhonePe SDK
- Firebase plugins
- Local authentication
- File system access

## 🔍 Step 5: Debug Specific Scenarios

### Test App Launch Flow:
1. **Fresh Install**: Uninstall completely, then install from Play Store
2. **First Launch**: Check if crash happens on first open
3. **Permissions**: Test when app requests permissions
4. **Authentication**: Test login/registration flows
5. **Payment**: Test PhonePe integration

### Check Device Logs:
```bash
# Connect device and run:
adb logcat -c  # Clear logs
adb logcat | grep -E "(AndroidRuntime|flutter|FATAL|mcq)"
```

## 🔍 Step 6: Immediate Debugging Steps

### 1. Check App Signing:
```bash
# Verify APK signature
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

### 2. Test on Different Devices:
- **Different Android versions** (API 23-35)
- **Different manufacturers** (Samsung, Google, OnePlus, etc.)
- **Different RAM/storage** configurations

### 3. Check Network Dependencies:
- **Firebase connection**
- **API endpoints**
- **PhonePe SDK initialization**

## 🛠️ Step 7: Quick Fixes to Try

### 1. Disable Obfuscation Temporarily:
In `android/app/build.gradle`:
```gradle
buildTypes {
    release {
        minifyEnabled false  // Temporarily disable
        shrinkResources false  // Temporarily disable
        signingConfig signingConfigs.release
    }
}
```

### 2. Add Exception Handling:
In `main.dart`:
```dart
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(MyApp());
  } catch (e, stackTrace) {
    print('App initialization error: $e');
    print('Stack trace: $stackTrace');
    // Log to external service or show error dialog
  }
}
```

### 3. Check Splash Screen:
Ensure splash screen configuration is correct in `android/app/src/main/res/values/styles.xml`

## 📊 Step 8: Collect Crash Data

### Enable Debug Logging:
Add this to your app's initialization:
```dart
if (kDebugMode) {
  print('App starting in debug mode');
} else {
  // Production logging
  FirebaseCrashlytics.instance.log('App starting in release mode');
}
```

### Test Specific Features:
1. **Authentication flow**
2. **Database connections**
3. **Payment integration**
4. **File access**
5. **Permissions requests**

## 🚀 Step 9: Create Debug Build for Play Store

### Build with Debug Info:
```bash
flutter build appbundle --release --dart-define=FLUTTER_WEB_USE_SKIA=true --verbose
```

### Upload to Internal Testing:
1. **Google Play Console** → **Testing** → **Internal testing**
2. **Upload debug-enabled build**
3. **Test with internal testers**
4. **Collect detailed crash reports**

## 📞 Immediate Action Plan

1. **Check Google Play Console** for crash reports (most important)
2. **Test release APK locally** with `adb logcat`
3. **Disable obfuscation** temporarily and rebuild
4. **Add Firebase Crashlytics** for better crash reporting
5. **Test on multiple devices** and Android versions

## 🔧 Emergency Fix Process

If you need to fix immediately:

1. **Identify the crash** from Play Console
2. **Fix the specific issue**
3. **Build version 1.5.1+6**
4. **Test thoroughly locally**
5. **Upload as emergency update**

Would you like me to help you implement any of these debugging steps or check specific parts of your code that might be causing the crash?
