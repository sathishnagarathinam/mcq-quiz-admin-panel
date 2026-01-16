# Authentication Feature

This directory contains the authentication feature for the MCQ Quiz mobile app, implementing Firebase phone number authentication with a modern, student-friendly UI.

## Features

### 🔐 Phone Number Authentication
- Firebase phone authentication with OTP verification
- Country code picker with support for multiple countries
- Real-time phone number validation
- Automatic OTP detection (when supported by device)

### 🎨 Modern UI Design
- Clean, rounded card-based design
- Gradient backgrounds with animated elements
- Smooth animations and transitions
- Loading states with haptic feedback
- Error handling with user-friendly messages

### 📱 Student-Friendly Interface
- Large, easy-to-tap buttons
- Clear visual feedback
- Animated background elements
- Lottie animations (with fallback icons)
- Accessibility considerations

## File Structure

```
auth/
├── screens/
│   ├── phone_login_screen.dart      # Phone number input screen
│   └── otp_verification_screen.dart # OTP verification screen
├── widgets/
│   ├── animated_background.dart     # Animated background components
│   └── phone_input_field.dart      # Reusable phone input widget
├── auth_exports.dart               # Feature exports
└── README.md                       # This file
```

## Screen Details

### Phone Login Screen (`phone_login_screen.dart`)
- **Purpose**: Collect user's phone number for authentication
- **Features**:
  - Country code picker with flag emojis
  - Phone number validation (10 digits)
  - Animated header with Lottie animation
  - Error handling and loading states
  - Terms of service and privacy policy links

### OTP Verification Screen (`otp_verification_screen.dart`)
- **Purpose**: Verify the OTP sent to user's phone
- **Features**:
  - 6-digit PIN input with custom styling
  - Auto-focus and completion detection
  - Resend OTP functionality with countdown timer
  - Animated phone icon with pulse effect
  - Help section with troubleshooting tips

## Widget Components

### Animated Background (`animated_background.dart`)
- Provides animated background elements
- Floating particles and geometric shapes
- Gradient backgrounds
- Customizable colors and animation duration

### Phone Input Field (`phone_input_field.dart`)
- Reusable phone number input component
- Integrated country code picker
- Phone number formatting
- Validation and error states
- Animated focus effects

## Usage

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_exports.dart';

// Navigate to phone login
context.goNamed('phone-login');

// Navigate to OTP verification with data
context.goNamed('otp-verification', extra: {
  'phoneNumber': '+919876543210',
  'countryCode': '+91',
  'countryFlag': '🇮🇳',
});
```

### Custom Phone Input

```dart
PhoneInputField(
  controller: phoneController,
  label: 'Phone Number',
  hint: 'Enter your phone number',
  onChanged: (value) => print('Phone: $value'),
  onCountryChanged: (country) => print('Country: ${country.name}'),
)
```

### Animated Background

```dart
AnimatedBackground(
  duration: Duration(seconds: 8),
  colors: [
    Colors.blue.withOpacity(0.1),
    Colors.purple.withOpacity(0.05),
  ],
  child: YourContent(),
)
```

## Authentication Flow

1. **Phone Login Screen**
   - User enters phone number
   - Country code is automatically detected (defaults to India)
   - Validation ensures 10-digit phone number
   - Firebase sends OTP to the provided number

2. **OTP Verification Screen**
   - User enters 6-digit OTP
   - Auto-completion when OTP is detected
   - Resend functionality with 60-second countdown
   - Success leads to home screen

3. **Error Handling**
   - Network errors are handled gracefully
   - Invalid OTP shows clear error messages
   - Retry mechanisms for failed operations

## Customization

### Theme Integration
The authentication screens use the app's theme system:
- `AppTheme.primaryColor` for main elements
- `AppTheme.errorColor` for error states
- `AppTheme.surfaceColor` for card backgrounds
- Google Fonts (Poppins) for typography

### Animation Customization
```dart
// Customize animation duration
AnimatedBackground(
  duration: Duration(seconds: 10),
  child: content,
)

// Custom pulse animation
PulsingWidget(
  duration: Duration(milliseconds: 2000),
  minScale: 0.9,
  maxScale: 1.1,
  child: widget,
)
```

## Dependencies

- `firebase_auth`: Firebase authentication
- `country_code_picker`: Country selection
- `pinput`: OTP input field
- `lottie`: Animations (with fallback)
- `google_fonts`: Typography
- `flutter_riverpod`: State management

## Assets Required

- `assets/animations/phone_login.json` - Lottie animation for login screen
- Country flag emojis are handled programmatically

## Testing

The authentication system includes test mode support:
- Mock OTP verification for development
- Simulated network delays
- Error state testing

## Accessibility

- Semantic labels for screen readers
- High contrast colors
- Large touch targets (minimum 44px)
- Clear error messages
- Keyboard navigation support

## Future Enhancements

- [ ] Biometric authentication integration
- [ ] Social login options (Google, Apple)
- [ ] Multi-language support
- [ ] Dark mode optimizations
- [ ] Tablet layout adaptations
