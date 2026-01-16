# Firebase Authentication Configuration Fix

## 🚨 Current Error
```
Phone verification failed: This app is not authorized to use Firebase Authentication. 
Please verify that the correct package name, SHA-1, and SHA-256 are configured in the Firebase Console. 
L Invalid app info in play _integrity_token J
```

## 🔍 Root Cause Analysis
This error occurs because:
1. **SHA-1/SHA-256 fingerprints** don't match between your app and Firebase Console
2. **App integrity verification** is failing
3. **Debug vs Release keystore** mismatch

## ✅ Step-by-Step Solution

### Step 1: Get Your App's SHA Fingerprints

Since Java isn't available on your system, use these methods:

#### Method A: Using Android Studio (Recommended)
1. Open project in Android Studio
2. Open **Gradle** panel (right side)
3. Navigate: `android` → `Tasks` → `android` → `signingReport`
4. Double-click `signingReport`
5. Copy SHA-1 and SHA-256 from output

#### Method B: Install Java and Use Keytool
```bash
# Install Java first, then:
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
```

#### Method C: Flutter Build Output
```bash
cd mobile_app
flutter build apk --debug --verbose
# Look for SHA fingerprints in build output
```

### Step 2: Update Firebase Console

1. **Go to**: https://console.firebase.google.com
2. **Select project**: `mcq-quiz-system`
3. **Project Settings** → **Your apps** tab
4. **Find Android app**: `com.mcqquiz.app`
5. **Add SHA fingerprints**:
   - Click "Add fingerprint"
   - Add SHA-1: `[YOUR_SHA1_HERE]`
   - Add SHA-256: `[YOUR_SHA256_HERE]`
   - **IMPORTANT**: Firebase accepts both UPPERCASE and lowercase
   - **Convert if needed**: If your SHA-1 is in CAPS, convert to lowercase
   - Save changes

### Step 3: Download New google-services.json

1. After adding fingerprints in Firebase Console
2. **Download** updated `google-services.json`
3. **Replace** file in `mobile_app/android/app/google-services.json`

### Step 4: Verify Configuration

Current configuration (✅ Correct):
- **Package Name**: `com.mcqquiz.app`
- **Application ID**: `com.mcqquiz.app`
- **Firebase Project**: `mcq-quiz-system`

### Step 5: Clean and Rebuild

```bash
cd mobile_app
flutter clean
flutter pub get
flutter build apk --debug
```

## 🧪 Immediate Testing Solution

While fixing Firebase config, use test phone numbers that bypass SMS:

### Test Phone Numbers Available:
- `+919876543210` → OTP: `123456`
- `+911234567890` → OTP: `654321`
- `+919999999999` → OTP: `111111`

These work without Firebase SMS and don't require SHA fingerprints.

## 🔧 Alternative Solutions

### Option 1: Disable App Check (Temporary)
In Firebase Console:
1. Go to **App Check**
2. **Disable** for development
3. Re-enable after fixing SHA fingerprints

### Option 2: Use Firebase Emulator
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start auth emulator
firebase emulators:start --only auth
```

### Option 3: Update to Use REST API
The app can fallback to Firebase REST API for authentication which doesn't require SHA fingerprints.

## 📱 SHA Fingerprint Format Issue - SOLUTION

### **Problem**: Case Sensitivity
- **Your project SHA-1**: `08:C3:DE:0D:17:61:6F:3A:B8:DD:E2:45:12:B1:C1:44:3D:F1:FA:F5` (UPPERCASE)
- **Firebase expects**: `08:c3:de:0d:17:61:6f:3a:b8:dd:e2:45:12:b1:c1:44:3d:f1:fa:f5` (lowercase)

### **Solution**: Convert to Lowercase
```bash
# Your current SHA-1 (UPPERCASE):
08:C3:DE:0D:17:61:6F:3A:B8:DD:E2:45:12:B1:C1:44:3D:F1:FA:F5

# Convert to lowercase for Firebase:
08:c3:de:0d:17:61:6f:3a:b8:dd:e2:45:12:b1:c1:44:3d:f1:fa:f5
```

### **Steps to Fix**:
1. **Copy your UPPERCASE SHA-1**
2. **Convert to lowercase** (use online converter or manual)
3. **Add lowercase version** to Firebase Console
4. **Save and download** new google-services.json

## 🚀 Advanced Troubleshooting (If Still No OTP)

### **Check Firebase Console Logs:**
1. Go to Firebase Console → Authentication → Users
2. Check if authentication attempts are being logged
3. Look for error messages in the logs

### **Verify Billing and Quotas:**
1. Firebase Console → Usage and billing
2. Check SMS quota usage
3. Ensure billing account is active
4. Verify no spending limits are blocking SMS

### **Test Different Scenarios:**
1. **Different phone numbers** (various carriers)
2. **Different devices** (Android/iOS)
3. **Different networks** (WiFi vs mobile data)
4. **Different times** (avoid peak hours)

### **Carrier-Specific Issues:**
- **Jio**: Sometimes blocks automated SMS
- **Airtel**: May delay international SMS
- **Vi/Vodafone**: Check spam filtering
- **BSNL**: Often has delivery delays

### **Alternative Testing:**
1. **Use test number**: `+919876543210` → OTP: `123456`
2. **Try international numbers**: `+15555551234`
3. **Test with emulator** vs real device
4. **Use different Firebase project** for testing

## 🔧 Emergency Solutions

### **If Nothing Works:**
1. **Use Firebase Auth Emulator** for development
2. **Implement email-based verification** as backup
3. **Use third-party SMS service** (Twilio, etc.)
4. **Contact Firebase Support** with project details

## 📞 Support Contacts

If issues persist:
1. **Firebase Support**: https://firebase.google.com/support
2. **Check Firebase Status**: https://status.firebase.google.com
3. **Flutter Firebase Docs**: https://firebase.flutter.dev

## 🔄 Verification Checklist

- [ ] SHA-1 fingerprint added to Firebase Console
- [ ] SHA-256 fingerprint added to Firebase Console  
- [ ] New google-services.json downloaded and replaced
- [ ] App cleaned and rebuilt
- [ ] Test phone number works (+919876543210)
- [ ] Real phone number SMS works
- [ ] No more "app not authorized" errors

## 📝 Notes

- **Debug vs Release**: Different keystores = different SHA fingerprints
- **Multiple Variants**: Add fingerprints for all build variants
- **Team Development**: Each developer needs their debug SHA fingerprints added
- **CI/CD**: Add CI keystore fingerprints for automated builds
