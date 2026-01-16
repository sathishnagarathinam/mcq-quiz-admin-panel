# Firebase Phone Authentication Android Setup

## 🚨 Current Error
```
Phone Authentication requires additional configuration steps. 
Follow the steps for your platform.
```

## ✅ COMPLETE ANDROID CONFIGURATION

### Step 1: Enable Required APIs in Google Cloud Console

1. **Go to**: https://console.cloud.google.com
2. **Select project**: `mcq-quiz-system`
3. **Navigate**: APIs & Services → Library
4. **Enable these APIs**:
   - ✅ **Android Device Verification API**
   - ✅ **SafetyNet API** (if available)
   - ✅ **Play Integrity API**

### Step 2: Configure Firebase App Check

**I've already added App Check configuration to your project:**
- ✅ Added `firebase_app_check` dependency
- ✅ Configured debug provider in `main.dart`
- ✅ Added proper initialization

### Step 3: Firebase Console Configuration

1. **Go to**: https://console.firebase.google.com
2. **Select**: `mcq-quiz-system` project
3. **App Check → Apps → Android app**:
   - Select your app: `com.mcqquiz.app`
   - Choose provider: **Debug** (for development)
   - For production: **Play Integrity API**

### Step 4: Add SHA Fingerprints (Critical)

**Ensure these are added in Project Settings → Your apps → Android:**
```
SHA-1:   08:c3:de:0d:17:61:6f:3a:b8:dd:e2:45:12:b1:c1:44:3d:f1:fa:f5
SHA-256: 1b:99:e7:43:e5:b4:b7:aa:b4:2f:2b:e3:d2:d8:60:e8:e1:31:ae:e9:f7:20:4e:6c:d6:8e:36:4d:99:f4:84:e3
```

### Step 5: Authentication Settings

1. **Authentication → Sign-in method**:
   - ✅ Enable **Phone** authentication
   - ✅ Add authorized domains if needed

2. **Authentication → Settings → Phone numbers for testing**:
   - Add: `+919876543210` → `123456`
   - Add: `+911234567890` → `654321`
   - Add: `+919999999999` → `111111`

### Step 6: Download Updated Configuration

1. **After all configurations**
2. **Download new google-services.json**
3. **Replace** in `mobile_app/android/app/`

## 🔧 BUILD AND TEST

### Install Dependencies:
```bash
cd mobile_app
flutter pub get
```

### Clean and Rebuild:
```bash
flutter clean
flutter build apk --debug
flutter run
```

## 🧪 TESTING STEPS

### Test 1: App Check Configuration
- App should start without App Check errors
- Check debug logs for "Firebase App Check configured successfully"

### Test 2: Test Phone Numbers
- Use: `+919876543210` → OTP: `123456`
- Should work without SMS delivery
- Verifies Firebase configuration is correct

### Test 3: Real Phone Numbers
- Try with your actual phone number
- Should receive SMS OTP
- Verifies complete SMS delivery pipeline

## 📱 EXPECTED BEHAVIOR

After complete configuration:
- ✅ No "additional configuration" errors
- ✅ App Check tokens generated successfully
- ✅ Test numbers work immediately
- ✅ Real numbers receive SMS OTP
- ✅ Complete authentication flow works

## 🔍 DEBUGGING

### Check Debug Logs:
```
DEBUG: Firebase initialized successfully
DEBUG: Firebase App Check configured successfully
DEBUG: OTP sent successfully
```

### Common Issues:
1. **APIs not enabled** → Enable in Google Cloud Console
2. **SHA fingerprints missing** → Add to Firebase Console
3. **App Check not configured** → Already fixed in your code
4. **Billing not enabled** → Check Firebase Console billing

## 🚨 TROUBLESHOOTING

### If Still Not Working:

1. **Verify Google Cloud APIs**:
   - Android Device Verification API: **ENABLED**
   - Play Integrity API: **ENABLED**

2. **Check Firebase Console**:
   - App Check: **Configured**
   - Authentication: **Phone enabled**
   - SHA fingerprints: **Added**

3. **Test with Debug Build**:
   ```bash
   flutter run --debug
   ```

4. **Check Logs**:
   - Look for App Check initialization messages
   - Verify no API errors in console

## 📞 SUPPORT

If issues persist:
- Check Firebase Console → Authentication → Users for activity
- Verify Google Cloud Console → APIs for quota usage
- Contact Firebase Support with project ID: `mcq-quiz-system`

The configuration has been added to your project. Run `flutter pub get` and rebuild to test!
