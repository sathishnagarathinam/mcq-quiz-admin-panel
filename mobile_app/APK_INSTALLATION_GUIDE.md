# MCQ Quiz App - APK Installation Guide

## 📱 **APK Files Available**

### **Debug APK** (For Testing)
- **File**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Size**: 109 MB
- **Purpose**: Development and testing
- **Features**: Includes debugging information

### **Release APK** (For Production)
- **File**: `build/app/outputs/flutter-apk/app-release.apk`
- **Size**: 33.2 MB
- **Purpose**: Production deployment
- **Features**: Optimized and compressed

## 🔧 **Installation Methods**

### **Method 1: ADB Installation (Recommended)**
```bash
# Install Debug APK
adb install build/app/outputs/flutter-apk/app-debug.apk

# Install Release APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Force reinstall if app already exists
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### **Method 2: Direct Installation on Device**
1. Copy the APK file to your Android device
2. Enable "Unknown Sources" in device settings
3. Navigate to the APK file using a file manager
4. Tap the APK file to install

### **Method 3: Flutter Install Command**
```bash
# Install and run debug version
flutter install

# Install release version
flutter install --release
```

## ⚙️ **Device Requirements**

### **Minimum Requirements**
- **Android Version**: 5.0 (API Level 21) or higher
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 100MB free space
- **Architecture**: ARM64, ARMv7, or x86_64

### **Supported Architectures**
- ✅ **ARM64-v8a** (64-bit ARM - Most modern devices)
- ✅ **ARMv7** (32-bit ARM - Older devices)
- ✅ **x86_64** (64-bit Intel - Emulators)

## 🛠️ **Troubleshooting**

### **Issue 1: "App not installed" Error**
**Solutions:**
- Enable "Install unknown apps" in Settings
- Clear Google Play Store cache
- Restart device and try again
- Use ADB installation method

### **Issue 2: "Parse Error" or "Invalid APK"**
**Solutions:**
- Download APK again (file may be corrupted)
- Check device architecture compatibility
- Ensure sufficient storage space
- Try installing debug APK instead

### **Issue 3: "Insufficient Storage"**
**Solutions:**
- Free up at least 200MB storage space
- Clear app cache and temporary files
- Move photos/videos to external storage
- Uninstall unused apps

### **Issue 4: App Crashes on Startup**
**Solutions:**
- Restart device
- Clear app data and cache
- Check if device meets minimum requirements
- Try debug APK for more detailed error info

## 🔐 **Security & Permissions**

### **Required Permissions**
- **Internet Access**: For Firebase connectivity
- **Network State**: To check connectivity
- **Storage Access**: For local data storage
- **Camera**: For profile pictures (optional)

### **Security Notes**
- APKs are properly signed for security
- No malicious code or tracking
- All data encrypted in transit
- Firebase security rules implemented

## 📋 **Installation Steps**

### **For Developers/Testers**
1. **Enable Developer Options**
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings > Developer Options
   - Enable "USB Debugging"

2. **Install ADB Tools**
   ```bash
   # On macOS
   brew install android-platform-tools
   
   # On Windows
   # Download Android SDK Platform Tools
   ```

3. **Connect Device and Install**
   ```bash
   adb devices  # Verify device connection
   adb install app-release.apk
   ```

### **For End Users**
1. **Download APK** to your Android device
2. **Enable Unknown Sources**
   - Settings > Security > Unknown Sources (Android 7 and below)
   - Settings > Apps > Special Access > Install Unknown Apps (Android 8+)
3. **Install APK**
   - Open file manager
   - Navigate to Downloads folder
   - Tap the APK file
   - Follow installation prompts

## 🚀 **Post-Installation**

### **First Launch**
1. Open the MCQ Quiz app
2. Grant required permissions
3. Complete onboarding screens
4. Register with phone number
5. Start taking quizzes!

### **Features Available**
- ✅ Phone number authentication
- ✅ Multiple quiz categories
- ✅ Progress tracking
- ✅ Performance analytics
- ✅ Offline quiz support
- ✅ Modern UI with animations

## 📞 **Support**

If you encounter any issues:
1. Check this troubleshooting guide
2. Try the debug APK for more information
3. Contact the development team
4. Report issues on GitHub

## 📊 **APK Information**

| Property | Debug APK | Release APK |
|----------|-----------|-------------|
| Size | 109 MB | 33.2 MB |
| Minified | No | No* |
| Obfuscated | No | No* |
| Signed | Yes | Yes |
| Architecture | Universal | Universal |

*Minification disabled to prevent compatibility issues

## 🔄 **Updates**

To update the app:
1. Download the new APK version
2. Install over the existing app
3. Your data will be preserved
4. No need to uninstall first

---

**Note**: Always download APKs from trusted sources. This APK is built from the official MCQ Quiz app source code.
