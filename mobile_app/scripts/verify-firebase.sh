#!/bin/bash

# Firebase Verification Script for MCQ Quiz System
# This script verifies that Firebase is properly configured

echo "🔍 Firebase Configuration Verification"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verification results
ERRORS=0
WARNINGS=0

# Function to print results
print_check() {
    if [ "$2" = "pass" ]; then
        echo -e "${GREEN}✅ $1${NC}"
    elif [ "$2" = "warn" ]; then
        echo -e "${YELLOW}⚠️  $1${NC}"
        ((WARNINGS++))
    else
        echo -e "${RED}❌ $1${NC}"
        ((ERRORS++))
    fi
}

echo -e "${BLUE}📋 Checking configuration files...${NC}"

# Check Android configuration
if [ -f "mobile_app/android/app/google-services.json" ]; then
    # Verify it's not a template
    if grep -q "YOUR_PROJECT_NUMBER" "mobile_app/android/app/google-services.json"; then
        print_check "Android google-services.json (contains template values)" "fail"
    else
        print_check "Android google-services.json" "pass"
    fi
else
    print_check "Android google-services.json (missing)" "fail"
fi

# Check iOS configuration
if [ -f "mobile_app/ios/Runner/GoogleService-Info.plist" ]; then
    # Verify it's not a template
    if grep -q "YOUR_IOS_CLIENT_ID" "mobile_app/ios/Runner/GoogleService-Info.plist"; then
        print_check "iOS GoogleService-Info.plist (contains template values)" "fail"
    else
        print_check "iOS GoogleService-Info.plist" "pass"
    fi
else
    print_check "iOS GoogleService-Info.plist (missing)" "fail"
fi

# Check Web configuration
if [ -f "web_admin/.env.local" ]; then
    # Verify it's not using template values
    if grep -q "your-web-api-key-here" "web_admin/.env.local"; then
        print_check "Web .env.local (contains template values)" "fail"
    else
        print_check "Web .env.local" "pass"
    fi
else
    print_check "Web .env.local (missing)" "fail"
fi

echo ""
echo -e "${BLUE}🔧 Checking Firebase CLI...${NC}"

# Check Firebase CLI
if command -v firebase &> /dev/null; then
    print_check "Firebase CLI installed" "pass"
    
    # Check if logged in
    if firebase projects:list &> /dev/null; then
        print_check "Firebase CLI logged in" "pass"
        
        # Check project access
        if firebase projects:list | grep -q "mcq-quiz-system"; then
            print_check "Project 'mcq-quiz-system' accessible" "pass"
        else
            print_check "Project 'mcq-quiz-system' not found" "fail"
        fi
    else
        print_check "Firebase CLI not logged in" "fail"
    fi
else
    print_check "Firebase CLI not installed" "fail"
fi

echo ""
echo -e "${BLUE}📱 Checking mobile app dependencies...${NC}"

# Check Flutter dependencies
if [ -f "mobile_app/pubspec.yaml" ]; then
    if grep -q "firebase_core" "mobile_app/pubspec.yaml"; then
        print_check "Firebase Core dependency" "pass"
    else
        print_check "Firebase Core dependency (missing)" "warn"
    fi
    
    if grep -q "firebase_auth" "mobile_app/pubspec.yaml"; then
        print_check "Firebase Auth dependency" "pass"
    else
        print_check "Firebase Auth dependency (missing)" "warn"
    fi
    
    if grep -q "cloud_firestore" "mobile_app/pubspec.yaml"; then
        print_check "Cloud Firestore dependency" "pass"
    else
        print_check "Cloud Firestore dependency (missing)" "warn"
    fi
else
    print_check "Mobile app pubspec.yaml (missing)" "fail"
fi

echo ""
echo -e "${BLUE}🌐 Checking web admin dependencies...${NC}"

# Check Web dependencies
if [ -f "web_admin/package.json" ]; then
    if grep -q "firebase" "web_admin/package.json"; then
        print_check "Firebase Web SDK" "pass"
    else
        print_check "Firebase Web SDK (missing)" "warn"
    fi
else
    print_check "Web admin package.json (missing)" "fail"
fi

echo ""
echo "======================================"

# Summary
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! Firebase is properly configured.${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Configuration complete with $WARNINGS warnings.${NC}"
else
    echo -e "${RED}❌ Found $ERRORS errors and $WARNINGS warnings.${NC}"
    echo -e "${BLUE}📖 Please see FIREBASE_SETUP_GUIDE.md for setup instructions.${NC}"
fi

echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo "1. Test mobile app: cd mobile_app && flutter run"
echo "2. Test web admin: cd web_admin && npm start"
echo "3. Start Firebase emulators: cd firebase && firebase emulators:start"
