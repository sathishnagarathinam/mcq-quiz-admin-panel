# Firebase App Check Issue - Complete Fix

## 🚨 Current Error
```
Phone verification failed.
Error: An internal error has occurred.
Firebase App Check token is invalid.
Code: unknown
```

## 🔍 What is Firebase App Check?
Firebase App Check is a security feature that protects your Firebase resources from abuse by verifying that requests come from your authentic app.

## ✅ SOLUTION 1: Disable App Check (Recommended for Development)

### Step 1: Disable in Firebase Console
1. **Go to**: https://console.firebase.google.com
2. **Select**: `mcq-quiz-system` project
3. **Navigate**: App Check (left sidebar)
4. **Find your Android app**: `com.mcqquiz.app`
5. **Disable enforcement**:
   - Click on your app
   - Toggle OFF "Enforce App Check token"
   - Click "Save"

### Step 2: Verify Authentication Settings
1. **Go to**: Authentication → Settings
2. **Check**: "Authorized domains" includes your domain
3. **Verify**: Phone authentication is enabled

## ✅ SOLUTION 2: Configure App Check Properly (For Production)

### Step 1: Enable Play Integrity API
1. **In Firebase Console → App Check**
2. **Select your Android app**
3. **Choose provider**: "Play Integrity API"
4. **Click**: "Register"

### Step 2: Add SHA Fingerprints (Required for App Check)
**Ensure these are added in Project Settings → Your apps → Android:**
```
SHA-1:   08:c3:de:0d:17:61:6f:3a:b8:dd:e2:45:12:b1:c1:44:3d:f1:fa:f5
SHA-256: 1b:99:e7:43:e5:b4:b7:aa:b4:2f:2b:e3:d2:d8:60:e8:e1:31:ae:e9:f7:20:4e:6c:d6:8e:36:4d:99:f4:84:e3
```

### Step 3: Download Updated google-services.json
After configuring App Check, download fresh `google-services.json`

## ✅ SOLUTION 3: Add App Check Dependency (Advanced)

### Add to pubspec.yaml:
```yaml
dependencies:
  firebase_app_check: ^0.2.1+7
```

### Configure in main.dart:
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Configure App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // For development
    // androidProvider: AndroidProvider.playIntegrity, // For production
  );
  
  runApp(MyApp());
}
```

## 🧪 IMMEDIATE TESTING SOLUTION

While fixing App Check, use test numbers that bypass Firebase completely:

**Test Phone Numbers (No App Check Required):**
- `+919876543210` → OTP: `123456`
- `+911234567890` → OTP: `654321`
- `+919999999999` → OTP: `111111`

These work without any Firebase validation.

## 🔧 Quick Fix Commands

```bash
# Clean and rebuild
cd mobile_app
flutter clean
flutter pub get
flutter build apk --debug

# Test with debug build
flutter run --debug
```

## 📱 Expected Results

After disabling App Check:
- ✅ No more "App Check token is invalid" errors
- ✅ Test numbers work immediately
- ✅ Real phone numbers work for SMS OTP
- ✅ Authentication flows complete successfully

## 🚨 Important Notes

1. **Development**: Disable App Check for easier testing
2. **Production**: Enable App Check with proper configuration
3. **Security**: App Check protects against abuse but can block legitimate requests if misconfigured
4. **Testing**: Always test with both test numbers and real numbers

## 🔄 Verification Steps

1. **Disable App Check** in Firebase Console
2. **Test with**: `+919876543210` → OTP: `123456`
3. **Verify**: No "App Check token invalid" errors
4. **Test real number** for SMS delivery
5. **Confirm**: Complete authentication flow works

## 📞 Support

If issues persist after disabling App Check:
- Check Firebase Console logs
- Verify SHA fingerprints are correct
- Ensure package name matches exactly
- Try with different test devices/emulators
