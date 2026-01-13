# MCQ Quiz System - Setup Guide

This guide will help you set up the complete MCQ Quiz System for Post Office departmental exam preparation.

## Prerequisites

Before you begin, ensure you have the following installed:

### For Mobile App (Flutter)
- Flutter SDK (3.10.0 or later)
- Dart SDK (3.0.0 or later)
- Android Studio with Android SDK
- Xcode (for iOS development, macOS only)
- VS Code or Android Studio IDE

### For Web Admin Panel (React)
- Node.js (16.0 or later)
- npm or yarn package manager
- VS Code or any preferred code editor

### For Backend (Firebase)
- Firebase CLI
- Google Cloud account
- Firebase project

## Step 1: Firebase Setup

### 1.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `mcq-quiz-system`
4. Enable Google Analytics (optional)
5. Create project

### 1.2 Enable Firebase Services
1. **Authentication**
   - Go to Authentication > Sign-in method
   - Enable Phone authentication
   - Configure phone number sign-in

2. **Firestore Database**
   - Go to Firestore Database
   - Create database in production mode
   - Choose your preferred location

3. **Storage**
   - Go to Storage
   - Get started with default rules

4. **Cloud Functions** (Optional)
   - Go to Functions
   - Get started and follow setup

### 1.3 Configure Firebase CLI
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project directory
cd /path/to/MCQ
firebase init

# Select the following services:
# - Firestore
# - Functions
# - Hosting
# - Storage
```

### 1.4 Deploy Firebase Configuration
```bash
cd firebase
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

## Step 2: Mobile App Setup (Flutter)

### 2.1 Install Flutter Dependencies
```bash
cd mobile_app
flutter pub get
```

### 2.2 Configure Firebase for Flutter

#### Android Configuration
1. Download `google-services.json` from Firebase Console
2. Place it in `mobile_app/android/app/`
3. Update `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

4. Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-analytics'
}
```

#### iOS Configuration
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `mobile_app/ios/Runner/` in Xcode
3. Update `ios/Runner/Info.plist` with required permissions

### 2.3 Generate Firebase Options
```bash
cd mobile_app
flutter packages pub run build_runner build
```

### 2.4 Run the Mobile App
```bash
# For Android
flutter run

# For iOS (macOS only)
flutter run -d ios
```

## Step 3: Web Admin Panel Setup (React)

### 3.1 Install Dependencies
```bash
cd web_admin
npm install
```

### 3.2 Configure Firebase for Web
1. Go to Firebase Console > Project Settings
2. Add a web app
3. Copy the Firebase configuration
4. Create `web_admin/src/config/firebase.ts`:

```typescript
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  // Your Firebase config
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
```

### 3.3 Environment Variables
Create `web_admin/.env`:
```env
REACT_APP_FIREBASE_API_KEY=your_api_key
REACT_APP_FIREBASE_AUTH_DOMAIN=your_auth_domain
REACT_APP_FIREBASE_PROJECT_ID=your_project_id
REACT_APP_FIREBASE_STORAGE_BUCKET=your_storage_bucket
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
REACT_APP_FIREBASE_APP_ID=your_app_id
```

### 3.4 Run the Web Admin Panel
```bash
npm start
```

## Step 4: Initial Data Setup

### 4.1 Create Admin User
1. Run the mobile app or web admin
2. Sign up with your phone number
3. Go to Firebase Console > Firestore
4. Find your user document
5. Update the `role` field to `master_admin`

### 4.2 Add Initial Categories
Use the web admin panel to add categories:
- Volumes
- PO Guide
- General Knowledge
- Previous Year Papers

### 4.3 Add Sample Questions
1. Go to Questions section in web admin
2. Add sample questions for each category
3. Or use the bulk upload feature with CSV/Excel

## Step 5: Testing

### 5.1 Test Mobile App
1. Complete onboarding flow
2. Login with phone number
3. Take a sample quiz
4. Check results and analytics

### 5.2 Test Web Admin Panel
1. Login as admin
2. Create questions and categories
3. View analytics dashboard
4. Test bulk upload functionality

## Step 6: Deployment

### 6.1 Deploy Web Admin Panel
```bash
cd web_admin
npm run build
firebase deploy --only hosting
```

### 6.2 Build Mobile App for Production

#### Android
```bash
cd mobile_app
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS
```bash
cd mobile_app
flutter build ios --release
```

## Step 7: Security Configuration

### 7.1 Update Firestore Rules
Review and update the security rules in `firebase/firestore.rules` based on your requirements.

### 7.2 Configure Storage Rules
Update `firebase/storage.rules` for proper file upload security.

### 7.3 Set up Authentication Rules
Configure phone authentication settings and rate limiting.

## Troubleshooting

### Common Issues

1. **Firebase Configuration Error**
   - Ensure all Firebase services are enabled
   - Check API keys and configuration files
   - Verify project ID matches

2. **Flutter Build Issues**
   - Run `flutter clean && flutter pub get`
   - Check Flutter and Dart SDK versions
   - Verify Android/iOS setup

3. **React Build Issues**
   - Delete `node_modules` and run `npm install`
   - Check Node.js version compatibility
   - Verify environment variables

4. **Permission Issues**
   - Check Firestore security rules
   - Verify user roles and permissions
   - Test with different user types

### Getting Help

- Check the [Firebase Documentation](https://firebase.google.com/docs)
- Review [Flutter Documentation](https://flutter.dev/docs)
- Visit [React Documentation](https://reactjs.org/docs)
- Create issues in the project repository

## Next Steps

1. Customize the UI to match your branding
2. Add more question categories and types
3. Implement advanced analytics
4. Set up push notifications
5. Add offline support
6. Implement advanced security features
7. Set up automated testing
8. Configure CI/CD pipeline

## Support

For technical support or questions:
- Email: support@mcqquiz.com
- Documentation: [Project Wiki]
- Issues: [GitHub Issues]
