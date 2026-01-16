#!/bin/bash

# Screenshot Protection Test Script
# This script helps test the screenshot protection functionality

echo "🛡️ Screenshot Protection Test Script"
echo "===================================="
echo ""

# Check if device is connected
echo "📱 Checking for connected Android devices..."
DEVICE_COUNT=$(adb devices | grep -v "List of devices" | grep -c "device")

if [ $DEVICE_COUNT -eq 0 ]; then
    echo "❌ No Android devices found. Please connect a device and enable USB debugging."
    exit 1
fi

echo "✅ Found $DEVICE_COUNT Android device(s)"
echo ""

# Build and install the app
echo "🔨 Building APK..."
flutter build apk --debug --target-platform android-arm64

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Please check the error messages above."
    exit 1
fi

echo "✅ APK built successfully"
echo ""

# Install the app
echo "📲 Installing app on device..."
adb install -r build/app/outputs/flutter-apk/app-debug.apk

if [ $? -ne 0 ]; then
    echo "❌ Installation failed. Trying to uninstall first..."
    adb uninstall com.mcqquiz1.app
    echo "🔄 Retrying installation..."
    adb install build/app/outputs/flutter-apk/app-debug.apk
    
    if [ $? -ne 0 ]; then
        echo "❌ Installation failed again. Please check device storage and permissions."
        exit 1
    fi
fi

echo "✅ App installed successfully"
echo ""

# Launch the app
echo "🚀 Launching app..."
adb shell am start -n com.mcqquiz1.app/.MainActivity

echo "✅ App launched"
echo ""

echo "🧪 TESTING INSTRUCTIONS:"
echo "========================"
echo ""
echo "1. 📱 Look at your Android device - the MCQ Quiz app should be open"
echo "2. 🔴 In DEBUG MODE: Look for a red security button (🛡️) on the home screen"
echo "3. 👆 Tap the red security button to enable screenshot protection"
echo "4. ✅ You should see a green snackbar message confirming protection is enabled"
echo "5. 📸 Try taking a screenshot using Power + Volume Down buttons"
echo "6. 🚫 The screenshot should be BLOCKED or show a black screen"
echo "7. 📱 Check your device's photo gallery - no screenshot should be saved"
echo ""
echo "🔍 WHAT TO EXPECT:"
echo "=================="
echo "• Screenshot attempt should fail silently"
echo "• Some devices may show 'Screenshot blocked' message"
echo "• Gallery should not contain any screenshots of the app"
echo "• App content should appear black in recent apps view"
echo ""
echo "✅ If screenshots are blocked, the protection is working correctly!"
echo "❌ If screenshots are saved normally, there may be an issue with the implementation"
echo ""
echo "📝 ADDITIONAL TESTS:"
echo "==================="
echo "• Try screen recording - it should also be blocked"
echo "• Switch to recent apps view - app content should appear black"
echo "• Try third-party screenshot apps - they should also be blocked"
echo ""
echo "🐛 TROUBLESHOOTING:"
echo "=================="
echo "• If protection doesn't work, check device logs: adb logcat | grep -i security"
echo "• Ensure you're testing on a real device (not emulator)"
echo "• Some custom Android ROMs may bypass FLAG_SECURE"
echo ""
