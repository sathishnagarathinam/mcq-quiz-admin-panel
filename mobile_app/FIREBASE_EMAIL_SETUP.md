# Firebase Email Verification Setup Guide

## 🔧 **Firebase Console Configuration**

### **Step 1: Configure Email Action URLs**

1. **Go to Firebase Console**: https://console.firebase.google.com
2. **Select your project**
3. **Navigate to Authentication > Templates**
4. **Configure Email Action URLs**:

#### **Email Verification Template**
- **Action URL**: `https://your-project-id.firebaseapp.com/__/auth/action`
- **From Name**: MCQ Quiz System
- **From Email**: noreply@your-project-id.firebaseapp.com
- **Reply-to Email**: support@yourdomain.com (optional)

#### **Password Reset Template**
- **Action URL**: `https://your-project-id.firebaseapp.com/__/auth/action`
- **From Name**: MCQ Quiz System
- **From Email**: noreply@your-project-id.firebaseapp.com

### **Step 2: Configure Authorized Domains**

1. **Go to Authentication > Settings**
2. **Scroll to Authorized Domains**
3. **Add your domains**:
   - `your-project-id.firebaseapp.com` (default)
   - `your-custom-domain.com` (if you have one)
   - `localhost` (for development only)

### **Step 3: Enable Email/Password Authentication**

1. **Go to Authentication > Sign-in method**
2. **Enable Email/Password**
3. **Configure settings**:
   - ✅ Enable Email/Password
   - ✅ Enable Email link (passwordless sign-in) - Optional
   - ✅ Enable One account per email address

## 📱 **Mobile App Configuration**

### **Update Firebase Config**

Update your `firebase_options.dart` file with the correct project configuration:

```dart
// File: lib/firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-android-api-key',
    appId: 'your-android-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    authDomain: 'your-project-id.firebaseapp.com', // Important for email links
  );
}
```

### **Update Email Auth Service**

The email auth service has been updated with proper domain configuration:

```dart
// Configured in: lib/core/services/email_auth_service.dart
final actionCodeSettings = ActionCodeSettings(
  url: 'https://your-project-id.firebaseapp.com/__/auth/action',
  handleCodeInApp: true,
  iOSBundleId: 'com.mcqquiz.app',
  androidPackageName: 'com.mcqquiz.app',
  androidInstallApp: true,
  androidMinimumVersion: '21',
);
```

## 🔐 **Email Verification Flow**

### **1. Registration Process**
```
User Registration → Email Verification Sent → Verification Screen → Email Verified → Login Allowed
```

### **2. Login Process**
```
Login Attempt → Check Email Verified → If Not Verified: Block Login → Show Verification Screen
```

### **3. Email Verification Screen Features**
- ✅ **Check Verification Status**: Refresh user data to check if email is verified
- ✅ **Resend Verification Email**: Send new verification email
- ✅ **Proper Error Handling**: Handle network and Firebase errors
- ✅ **User-Friendly UI**: Clear instructions and feedback

## 📧 **Email Templates Customization**

### **Email Verification Template**
```html
<!-- Customize in Firebase Console > Authentication > Templates -->
<h2>Verify your email for MCQ Quiz System</h2>
<p>Hello,</p>
<p>Thank you for registering with MCQ Quiz System. Please click the link below to verify your email address:</p>
<a href="%LINK%">Verify Email Address</a>
<p>If you didn't create an account, you can safely ignore this email.</p>
<p>Best regards,<br>MCQ Quiz System Team</p>
```

### **Password Reset Template**
```html
<h2>Reset your password for MCQ Quiz System</h2>
<p>Hello,</p>
<p>We received a request to reset your password. Click the link below to create a new password:</p>
<a href="%LINK%">Reset Password</a>
<p>If you didn't request this, you can safely ignore this email.</p>
<p>Best regards,<br>MCQ Quiz System Team</p>
```

## 🛠️ **Troubleshooting**

### **Issue: Email links go to localhost**
**Solution**: 
1. Update `authDomain` in Firebase config
2. Configure proper Action URL in Firebase Console
3. Add your domain to Authorized Domains

### **Issue: Email verification not working**
**Solution**:
1. Check spam folder
2. Verify email template is enabled
3. Check Firebase Console logs
4. Ensure proper ActionCodeSettings configuration

### **Issue: "Invalid action code" error**
**Solution**:
1. Email link may have expired (1 hour default)
2. Link may have been used already
3. Resend verification email

### **Issue: App not handling email links**
**Solution**:
1. Configure deep linking in Android manifest
2. Add URL schemes for iOS
3. Test with proper domain configuration

## 📋 **Testing Checklist**

### **Email Verification Testing**
- [ ] Registration sends verification email
- [ ] Email contains proper verification link
- [ ] Link opens in browser (not localhost)
- [ ] Verification updates user status
- [ ] Login blocked until verified
- [ ] Resend verification works
- [ ] Verification screen shows proper status

### **Password Reset Testing**
- [ ] Password reset email sent
- [ ] Reset link works properly
- [ ] New password can be set
- [ ] Login works with new password

## 🔗 **Important URLs**

- **Firebase Console**: https://console.firebase.google.com
- **Authentication Templates**: https://console.firebase.google.com/project/YOUR_PROJECT/authentication/emails
- **Authorized Domains**: https://console.firebase.google.com/project/YOUR_PROJECT/authentication/settings
- **Firebase Documentation**: https://firebase.google.com/docs/auth/web/email-link-auth

## 📞 **Support**

If you encounter issues:
1. Check Firebase Console logs
2. Verify all configuration steps
3. Test with different email providers
4. Contact Firebase support if needed

---

**Note**: Replace `your-project-id` with your actual Firebase project ID throughout this configuration.
