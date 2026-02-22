# Build Guide - Version 1.7.33 (Build 41)

## 📋 Prerequisites

- Flutter SDK (>=3.10.0)
- Android SDK (API 36)
- Java Development Kit (JDK 11+)
- Gradle 8.0+
- Git

---

## 🔧 Build Steps

### **Step 1: Clean Previous Build**
```bash
cd /Volumes/work/mcq/mobile_app
flutter clean
```

### **Step 2: Get Dependencies**
```bash
flutter pub get
```

### **Step 3: Build App Bundle (Release)**
```bash
flutter build appbundle --release
```

**Expected Output**:
```
✓ Built build/app/outputs/bundle/release/app-release.aab
```

### **Step 4: Verify Build**
```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

---

## 📦 Build Output

### **Location**
```
mobile_app/build/app/outputs/bundle/release/app-release.aab
```

### **File Details**
- **Format**: Android App Bundle (.aab)
- **Size**: ~50-60 MB (typical)
- **Signature**: Release keystore
- **Version**: 1.7.33+41

---

## ✅ Build Verification

### **Check 1: File Exists**
```bash
test -f build/app/outputs/bundle/release/app-release.aab && echo "✓ Bundle exists"
```

### **Check 2: File Size**
```bash
du -h build/app/outputs/bundle/release/app-release.aab
```

### **Check 3: Build Logs**
```bash
cat build_output.log | grep -i "error\|warning"
```

---

## 🚀 Upload to Google Play

### **Step 1: Open Google Play Console**
1. Go to https://play.google.com/console
2. Select "Dakshin Postal Academy" app
3. Go to "Release" → "Production"

### **Step 2: Create New Release**
1. Click "Create new release"
2. Upload app-release.aab
3. Wait for processing (2-5 minutes)

### **Step 3: Add Release Notes**
```
Version 1.7.33 (Build 41)

🎯 Key Changes:
✅ Fixed email verification loop issue
✅ Added 16KB page size support
✅ Enhanced email verification sync
✅ Improved user experience

📝 What's Fixed:
- Users no longer stuck in verification loop
- Automatic email verification sync during login
- Firestore/Firebase Auth sync working correctly
- Android 15+ compatibility

🔐 Security:
- Email verification enforced
- Firestore rules updated
- Data encrypted

📱 Compatibility:
- Android 6.0+ (API 23+)
- 16KB page size support
- All device sizes supported
```

### **Step 4: Review & Publish**
1. Review all information
2. Check compliance
3. Click "Review release"
4. Click "Publish"

---

## 📊 Build Configuration

### **Version Information**
```yaml
version: 1.7.33+41
```

### **Android Configuration**
```gradle
compileSdk 36
minSdkVersion 23
targetSdk 35
versionCode 41
versionName 1.7.33
```

### **16KB Page Size Support**
```gradle
manifestPlaceholders = [
    supportsPageSize16KB: "true"
]
```

---

## 🔍 Troubleshooting

### **Issue: Build Fails**
```bash
# Clean and retry
flutter clean
flutter pub get
flutter build appbundle --release
```

### **Issue: Keystore Error**
```bash
# Check keystore exists
ls -la android/key.properties
ls -la android/debug.keystore
```

### **Issue: Gradle Error**
```bash
# Update gradle
cd android
./gradlew --version
./gradlew clean
cd ..
flutter build appbundle --release
```

### **Issue: Memory Error**
```bash
# Increase heap size
export GRADLE_OPTS="-Xmx4096m"
flutter build appbundle --release
```

---

## 📝 Build Checklist

- [ ] Flutter SDK updated
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Previous build cleaned (`flutter clean`)
- [ ] No compilation errors
- [ ] No warnings
- [ ] App bundle created
- [ ] File size reasonable (50-60 MB)
- [ ] Version updated (1.7.33+41)
- [ ] Release notes prepared
- [ ] Google Play Console ready

---

## 🎯 Expected Results

### **Successful Build**
```
✓ Built build/app/outputs/bundle/release/app-release.aab
✓ File size: ~55 MB
✓ No errors or warnings
✓ Ready for upload
```

### **Build Time**
- Clean build: 5-10 minutes
- Incremental build: 2-3 minutes

---

## 📱 Testing Before Upload

### **Test 1: Email Verification**
1. Register new user
2. Verify email
3. Login immediately
4. Should work without loop

### **Test 2: 16KB Support**
1. Check AndroidManifest.xml
2. Verify build.gradle config
3. App should work on all devices

### **Test 3: General Features**
1. Login/Logout
2. Take quiz
3. View results
4. Payment flow
5. Profile management

---

## 🔐 Security Checklist

- [ ] Keystore secure
- [ ] Release signing configured
- [ ] No debug symbols in release
- [ ] ProGuard/R8 enabled
- [ ] Sensitive data encrypted
- [ ] Firebase rules updated

---

## 📞 Support

For build issues:
1. Check Flutter version: `flutter --version`
2. Check Android SDK: `flutter doctor`
3. Review build logs
4. Check Gradle version
5. Contact support if needed

---

## 📋 Next Steps

1. ✅ Build app bundle
2. ✅ Verify build
3. ✅ Upload to Google Play
4. ✅ Add release notes
5. ✅ Submit for review
6. ✅ Monitor for issues
7. ✅ Publish when approved

---

**Build Status**: ✅ READY TO BUILD

**Command to Build**:
```bash
cd /Volumes/work/mcq/mobile_app && \
flutter clean && \
flutter pub get && \
flutter build appbundle --release
```

