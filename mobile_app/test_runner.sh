#!/bin/bash

# Device Security & Authentication Test Runner
# This script runs all tests for the device-based authentication and security features

echo "🧪 Running Device Security & Authentication Tests"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the Flutter project root directory"
    exit 1
fi

print_status "Starting test execution..."

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Generate mocks if needed
print_status "Generating mocks..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run unit tests
echo ""
print_status "Running Unit Tests..."
echo "========================"

# Device Authentication Service Tests
print_status "Testing DeviceAuthService..."
flutter test test/core/services/device_auth_service_test.dart --reporter=expanded
if [ $? -eq 0 ]; then
    print_success "DeviceAuthService tests passed"
else
    print_error "DeviceAuthService tests failed"
    exit 1
fi

# Security Service Tests
print_status "Testing SecurityService..."
flutter test test/core/services/security_service_test.dart --reporter=expanded
if [ $? -eq 0 ]; then
    print_success "SecurityService tests passed"
else
    print_error "SecurityService tests failed"
    exit 1
fi

# Scenario Tests
echo ""
print_status "Running Scenario Tests..."
echo "=========================="

# Device Binding Tests
print_status "Testing device binding scenarios..."
flutter test test/scenarios/device_binding_test.dart --reporter=expanded
if [ $? -eq 0 ]; then
    print_success "Device binding tests passed"
else
    print_error "Device binding tests failed"
    exit 1
fi

# Unauthorized Device Tests
print_status "Testing unauthorized device scenarios..."
flutter test test/scenarios/unauthorized_device_test.dart --reporter=expanded
if [ $? -eq 0 ]; then
    print_success "Unauthorized device tests passed"
else
    print_error "Unauthorized device tests failed"
    exit 1
fi

# Screen Protection Tests
print_status "Testing screen protection scenarios..."
flutter test test/scenarios/screen_protection_test.dart --reporter=expanded
if [ $? -eq 0 ]; then
    print_success "Screen protection tests passed"
else
    print_error "Screen protection tests failed"
    exit 1
fi

# Integration Tests
echo ""
print_status "Running Integration Tests..."
echo "============================="

print_status "Testing authentication flow integration..."
flutter test test/integration/auth_flow_integration_test.dart --reporter=expanded
if [ $? -eq 0 ]; then
    print_success "Integration tests passed"
else
    print_error "Integration tests failed"
    exit 1
fi

# Run all tests together for coverage
echo ""
print_status "Running All Tests for Coverage..."
echo "=================================="

flutter test --coverage --reporter=expanded
if [ $? -eq 0 ]; then
    print_success "All tests passed with coverage"
else
    print_error "Some tests failed"
    exit 1
fi

# Generate coverage report if lcov is available
if command -v lcov &> /dev/null; then
    print_status "Generating coverage report..."
    genhtml coverage/lcov.info -o coverage/html
    print_success "Coverage report generated in coverage/html/"
else
    print_warning "lcov not found. Install lcov to generate HTML coverage reports."
fi

echo ""
print_success "🎉 All tests completed successfully!"
echo ""
print_status "Test Summary:"
echo "✅ DeviceAuthService unit tests"
echo "✅ SecurityService unit tests"
echo "✅ Device binding scenario tests"
echo "✅ Unauthorized device scenario tests"
echo "✅ Screen protection scenario tests"
echo "✅ Authentication flow integration tests"
echo ""
print_status "Next Steps:"
echo "1. Review the manual testing guide: MANUAL_TESTING_GUIDE.md"
echo "2. Test on physical devices for platform-specific features"
echo "3. Verify Firebase Firestore rules are deployed"
echo "4. Test with real user accounts and multiple devices"
echo ""
print_status "For manual testing, refer to:"
echo "📖 MANUAL_TESTING_GUIDE.md"
echo "📖 DEVICE_SECURITY_IMPLEMENTATION.md"
