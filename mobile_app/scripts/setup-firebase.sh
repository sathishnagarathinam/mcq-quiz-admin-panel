#!/bin/bash

# MCQ Quiz System - Firebase Setup Script
# This script helps you set up Firebase for the MCQ Quiz System

set -e

echo "🔥 MCQ Quiz System - Firebase Setup"
echo "=================================="
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

# Check if Firebase CLI is installed
check_firebase_cli() {
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed"
        echo "Please install it using: npm install -g firebase-tools"
        exit 1
    fi
    print_status "Firebase CLI is installed"
}

# Check if user is logged in to Firebase
check_firebase_login() {
    if ! firebase projects:list &> /dev/null; then
        print_warning "You are not logged in to Firebase"
        echo "Please run: firebase login"
        read -p "Press Enter after logging in..."
    fi
    print_status "Firebase authentication verified"
}

# Create Firebase project
create_firebase_project() {
    echo ""
    echo "📋 Firebase Project Configuration"
    echo "================================"
    
    read -p "Enter your Firebase project ID (e.g., mcq-quiz-system-prod): " PROJECT_ID
    read -p "Enter your project display name (e.g., MCQ Quiz System): " PROJECT_NAME
    
    echo ""
    print_info "Creating Firebase project: $PROJECT_ID"
    
    # Note: Project creation via CLI requires Firebase Blaze plan
    print_warning "Please create the project manually in Firebase Console if not already created"
    print_info "Visit: https://console.firebase.google.com/"
    print_info "Project ID: $PROJECT_ID"
    print_info "Project Name: $PROJECT_NAME"
    
    read -p "Press Enter after creating the project in Firebase Console..."
    
    # Use the project
    firebase use --add $PROJECT_ID
    print_status "Firebase project configured: $PROJECT_ID"
}

# Enable Firebase services
enable_firebase_services() {
    echo ""
    echo "🔧 Enabling Firebase Services"
    echo "============================="
    
    print_info "Please enable the following services in Firebase Console:"
    echo "1. Authentication (Phone Number sign-in)"
    echo "2. Firestore Database"
    echo "3. Storage"
    echo "4. Cloud Functions"
    echo "5. Hosting"
    echo "6. Analytics (optional)"
    echo ""
    
    print_info "Visit: https://console.firebase.google.com/project/$PROJECT_ID"
    read -p "Press Enter after enabling all services..."
    
    print_status "Firebase services enabled"
}

# Configure Authentication
configure_authentication() {
    echo ""
    echo "🔐 Authentication Configuration"
    echo "=============================="
    
    print_info "Configuring Phone Number Authentication:"
    echo "1. Go to Authentication > Sign-in method"
    echo "2. Enable 'Phone' provider"
    echo "3. Add your phone number for testing (optional)"
    echo "4. Configure reCAPTCHA (for web)"
    echo ""
    
    read -p "Press Enter after configuring authentication..."
    print_status "Authentication configured"
}

# Deploy Firestore rules and indexes
deploy_firestore() {
    echo ""
    echo "📊 Deploying Firestore Configuration"
    echo "==================================="
    
    cd firebase
    
    print_info "Deploying Firestore security rules..."
    firebase deploy --only firestore:rules
    print_status "Firestore rules deployed"
    
    print_info "Deploying Firestore indexes..."
    firebase deploy --only firestore:indexes
    print_status "Firestore indexes deployed"
    
    cd ..
}

# Deploy Storage rules
deploy_storage() {
    echo ""
    echo "📁 Deploying Storage Configuration"
    echo "================================="
    
    cd firebase
    
    print_info "Deploying Storage security rules..."
    firebase deploy --only storage
    print_status "Storage rules deployed"
    
    cd ..
}

# Create environment configuration
create_env_config() {
    echo ""
    echo "⚙️ Creating Environment Configuration"
    echo "===================================="
    
    print_info "Getting Firebase configuration..."
    
    # Get project config
    firebase setup:web
    
    print_info "Please copy the Firebase config from the console and update:"
    echo "1. mobile_app/lib/core/config/firebase_options.dart"
    echo "2. web_admin/src/config/firebase.ts"
    echo ""
    
    print_warning "Don't forget to add your config files to .gitignore for security"
    
    read -p "Press Enter after updating configuration files..."
    print_status "Environment configuration created"
}

# Create initial admin user
create_admin_user() {
    echo ""
    echo "👤 Admin User Setup"
    echo "=================="
    
    print_info "To create an admin user:"
    echo "1. Run the mobile app or web admin panel"
    echo "2. Sign up with your phone number"
    echo "3. Go to Firebase Console > Firestore"
    echo "4. Find your user document in 'users' collection"
    echo "5. Change the 'role' field from 'user' to 'master_admin'"
    echo ""
    
    read -p "Press Enter to continue..."
    print_status "Admin user setup instructions provided"
}

# Main setup function
main() {
    echo "Starting Firebase setup for MCQ Quiz System..."
    echo ""
    
    check_firebase_cli
    check_firebase_login
    create_firebase_project
    enable_firebase_services
    configure_authentication
    deploy_firestore
    deploy_storage
    create_env_config
    create_admin_user
    
    echo ""
    echo "🎉 Firebase Setup Complete!"
    echo "=========================="
    print_status "Firebase project is ready for MCQ Quiz System"
    echo ""
    print_info "Next steps:"
    echo "1. Configure mobile app (run setup-mobile.sh)"
    echo "2. Configure web admin panel (run setup-web.sh)"
    echo "3. Add sample data"
    echo "4. Test the system"
    echo ""
    print_warning "Remember to:"
    echo "- Keep your Firebase config files secure"
    echo "- Set up billing if using Cloud Functions"
    echo "- Configure custom domain for hosting (optional)"
    echo ""
}

# Run main function
main
