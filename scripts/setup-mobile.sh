#!/bin/bash

# MCQ Quiz System - Mobile App Setup Script
# This script helps you set up the Flutter mobile app

set -e

echo "📱 MCQ Quiz System - Mobile App Setup"
echo "====================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed"
        echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    print_status "Flutter is installed"
    
    # Check Flutter doctor
    print_info "Running Flutter doctor..."
    flutter doctor
}

# Check Flutter version
check_flutter_version() {
    FLUTTER_VERSION=$(flutter --version | head -n 1 | cut -d ' ' -f 2)
    print_info "Flutter version: $FLUTTER_VERSION"
    
    # Check if version is 3.10.0 or higher
    if [[ $(echo "$FLUTTER_VERSION 3.10.0" | tr " " "\n" | sort -V | head -n 1) != "3.10.0" ]]; then
        print_warning "Flutter version should be 3.10.0 or higher for best compatibility"
    else
        print_status "Flutter version is compatible"
    fi
}

# Install Flutter dependencies
install_dependencies() {
    echo ""
    echo "📦 Installing Flutter Dependencies"
    echo "================================="
    
    cd mobile_app
    
    print_info "Getting Flutter packages..."
    flutter pub get
    print_status "Flutter dependencies installed"
    
    cd ..
}

# Configure Firebase for Flutter
configure_firebase_flutter() {
    echo ""
    echo "🔥 Configuring Firebase for Flutter"
    echo "==================================="
    
    # Check if FlutterFire CLI is installed
    if ! command -v flutterfire &> /dev/null; then
        print_info "Installing FlutterFire CLI..."
        dart pub global activate flutterfire_cli
        print_status "FlutterFire CLI installed"
    else
        print_status "FlutterFire CLI is already installed"
    fi
    
    cd mobile_app
    
    print_info "Configuring Firebase for Flutter..."
    print_warning "Please select your Firebase project when prompted"
    
    # Configure Firebase
    flutterfire configure
    
    print_status "Firebase configured for Flutter"
    cd ..
}

# Setup Android configuration
setup_android() {
    echo ""
    echo "🤖 Android Configuration"
    echo "======================="
    
    cd mobile_app
    
    # Check if google-services.json exists
    if [ ! -f "android/app/google-services.json" ]; then
        print_warning "google-services.json not found"
        print_info "Please download google-services.json from Firebase Console:"
        echo "1. Go to Firebase Console > Project Settings"
        echo "2. Select your Android app"
        echo "3. Download google-services.json"
        echo "4. Place it in mobile_app/android/app/"
        read -p "Press Enter after adding google-services.json..."
    else
        print_status "google-services.json found"
    fi
    
    # Update Android build.gradle files
    print_info "Updating Android configuration..."
    
    # Check if google-services plugin is added
    if ! grep -q "google-services" android/app/build.gradle; then
        print_info "Adding Google Services plugin to Android configuration..."
        
        # Add to android/build.gradle
        if ! grep -q "google-services" android/build.gradle; then
            echo "    classpath 'com.google.gms:google-services:4.3.15'" >> android/build.gradle.tmp
            sed '/dependencies {/r android/build.gradle.tmp' android/build.gradle > android/build.gradle.new
            mv android/build.gradle.new android/build.gradle
            rm android/build.gradle.tmp
        fi
        
        # Add to android/app/build.gradle
        echo "apply plugin: 'com.google.gms.google-services'" >> android/app/build.gradle
        
        print_status "Google Services plugin added"
    else
        print_status "Google Services plugin already configured"
    fi
    
    cd ..
}

# Setup iOS configuration
setup_ios() {
    echo ""
    echo "🍎 iOS Configuration"
    echo "==================="
    
    cd mobile_app
    
    # Check if GoogleService-Info.plist exists
    if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
        print_warning "GoogleService-Info.plist not found"
        print_info "Please download GoogleService-Info.plist from Firebase Console:"
        echo "1. Go to Firebase Console > Project Settings"
        echo "2. Select your iOS app"
        echo "3. Download GoogleService-Info.plist"
        echo "4. Add it to ios/Runner/ in Xcode"
        read -p "Press Enter after adding GoogleService-Info.plist..."
    else
        print_status "GoogleService-Info.plist found"
    fi
    
    # Check if CocoaPods is installed (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v pod &> /dev/null; then
            print_warning "CocoaPods is not installed"
            print_info "Installing CocoaPods..."
            sudo gem install cocoapods
            print_status "CocoaPods installed"
        else
            print_status "CocoaPods is installed"
        fi
        
        # Install iOS dependencies
        print_info "Installing iOS dependencies..."
        cd ios
        pod install
        cd ..
        print_status "iOS dependencies installed"
    else
        print_info "Skipping iOS setup (not on macOS)"
    fi
    
    cd ..
}

# Generate code
generate_code() {
    echo ""
    echo "🔧 Generating Code"
    echo "=================="
    
    cd mobile_app
    
    print_info "Running code generation..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    print_status "Code generation completed"
    
    cd ..
}

# Test the app
test_app() {
    echo ""
    echo "🧪 Testing the App"
    echo "=================="
    
    cd mobile_app
    
    print_info "Running Flutter tests..."
    flutter test
    print_status "Tests completed"
    
    print_info "Analyzing code..."
    flutter analyze
    print_status "Code analysis completed"
    
    cd ..
}

# Run the app
run_app() {
    echo ""
    echo "🚀 Running the App"
    echo "=================="
    
    cd mobile_app
    
    print_info "Available devices:"
    flutter devices
    
    echo ""
    read -p "Do you want to run the app now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Starting the app..."
        flutter run
    else
        print_info "You can run the app later using: flutter run"
    fi
    
    cd ..
}

# Create development environment file
create_dev_env() {
    echo ""
    echo "⚙️ Creating Development Environment"
    echo "=================================="
    
    cd mobile_app
    
    # Create .env file for development
    cat > .env << EOF
# Development Environment Configuration
ENVIRONMENT=development
DEBUG_MODE=true
ENABLE_LOGGING=true
API_BASE_URL=http://localhost:5001
FIREBASE_EMULATOR=true
EOF
    
    print_status "Development environment file created"
    cd ..
}

# Main setup function
main() {
    echo "Starting mobile app setup for MCQ Quiz System..."
    echo ""
    
    check_flutter
    check_flutter_version
    install_dependencies
    configure_firebase_flutter
    setup_android
    setup_ios
    create_dev_env
    generate_code
    test_app
    
    echo ""
    echo "🎉 Mobile App Setup Complete!"
    echo "============================="
    print_status "Flutter mobile app is ready for development"
    echo ""
    print_info "Next steps:"
    echo "1. Update Firebase configuration in firebase_options.dart"
    echo "2. Test the app on a device or emulator"
    echo "3. Configure app icons and splash screens"
    echo "4. Set up code signing for release builds"
    echo ""
    print_warning "Remember to:"
    echo "- Keep your Firebase config files secure"
    echo "- Test on both Android and iOS devices"
    echo "- Set up proper app permissions"
    echo "- Configure release signing for production"
    echo ""
    
    run_app
}

# Run main function
main
