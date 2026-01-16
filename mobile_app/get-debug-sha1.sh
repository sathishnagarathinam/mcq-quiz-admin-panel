#!/bin/bash

# Simple script to get debug SHA-1 certificate
echo "🔐 Getting Debug SHA-1 Certificate"
echo "=================================="

# Check if we're on macOS and use the system Java
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - try different Java locations
    JAVA_LOCATIONS=(
        "/usr/bin/java"
        "/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java"
        "/Library/Java/JavaVirtualMachines/*/Contents/Home/bin/java"
        "$JAVA_HOME/bin/java"
    )
    
    KEYTOOL_LOCATIONS=(
        "/usr/bin/keytool"
        "/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/keytool"
        "/Library/Java/JavaVirtualMachines/*/Contents/Home/bin/keytool"
        "$JAVA_HOME/bin/keytool"
    )
    
    # Find working keytool
    KEYTOOL=""
    for location in "${KEYTOOL_LOCATIONS[@]}"; do
        if [[ -f $location ]] || command -v keytool &> /dev/null; then
            KEYTOOL="keytool"
            break
        fi
    done
    
    if [[ -z "$KEYTOOL" ]]; then
        echo "❌ keytool not found. Trying alternative method..."
        
        # Alternative: Use Gradle to get SHA-1
        echo ""
        echo "📱 Using Gradle to get SHA-1:"
        echo "=============================="
        
        cd android
        ./gradlew signingReport 2>/dev/null | grep -A 2 -B 2 "SHA1" || {
            echo "⚠️  Gradle method failed. Manual steps needed:"
            echo ""
            echo "1. Install Java JDK from: https://adoptium.net/"
            echo "2. Or use Android Studio to get SHA-1:"
            echo "   - Open Android Studio"
            echo "   - Go to Gradle panel (right side)"
            echo "   - Navigate to: app → Tasks → android → signingReport"
            echo "   - Double-click signingReport"
            echo "   - Copy the SHA1 value from the output"
            echo ""
            echo "3. Add the SHA-1 to Firebase Console:"
            echo "   - Go to: https://console.firebase.google.com/project/mcq-quiz-system/settings/general"
            echo "   - Scroll to 'Your apps' section"
            echo "   - Click on your Android app"
            echo "   - Add the SHA-1 certificate fingerprint"
        }
        cd ..
        exit 1
    fi
fi

# Default debug keystore location
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

# Check if debug keystore exists
if [[ ! -f "$DEBUG_KEYSTORE" ]]; then
    echo "⚠️  Debug keystore not found at: $DEBUG_KEYSTORE"
    echo ""
    echo "Creating debug keystore..."
    mkdir -p "$HOME/.android"
    keytool -genkey -v -keystore "$DEBUG_KEYSTORE" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
fi

echo "✅ Debug keystore found: $DEBUG_KEYSTORE"
echo ""

echo "🔑 Debug SHA-1 Certificate:"
echo "=========================="
keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep SHA1 | head -1 | sed 's/.*SHA1: //'

echo ""
echo "📋 Next Steps:"
echo "=============="
echo "1. Copy the SHA-1 certificate above"
echo "2. Go to Firebase Console: https://console.firebase.google.com/project/mcq-quiz-system/settings/general"
echo "3. Scroll to 'Your apps' section"
echo "4. Click on your Android app (com.mcqquiz.app)"
echo "5. Click 'Add fingerprint' and paste the SHA-1"
echo "6. Save the changes"
echo ""
echo "🎯 Package Name: com.mcqquiz.app"
echo "🎯 App ID: 1:109048215498:android:c0ac280012cca252b08133"
