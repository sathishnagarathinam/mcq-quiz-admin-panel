# 🔧 Firestore Troubleshooting Guide

## 🚨 **CURRENT ISSUE**
- **Firebase Authentication**: ✅ Working (user created successfully)
- **Firestore Database**: ❌ Not working (no data saved)
- **Error**: Registration fails but user appears in Firebase Auth

## 🔍 **DEBUGGING STEPS**

### **1. Test Firestore Connection**
Use the built-in debug screen to test Firestore:

1. **Navigate to Debug Screen**: 
   - Go to registration screen
   - Click "Debug Firestore Connection" button
   - Or navigate directly to `/debug/firestore`

2. **Run Tests**:
   - Click "Run Firestore Tests"
   - Check results for each test:
     - ✅ Connection Test
     - ✅ Mobile Users Collection Test  
     - ✅ Security Rules Check

### **2. Common Firestore Issues & Solutions**

#### **A. Firestore Not Enabled**
**Symptoms**: Connection test fails
**Solution**:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `mcq-quiz-system`
3. Navigate to **Firestore Database**
4. Click **Create database**
5. Choose **Start in test mode** (for now)
6. Select a location (closest to your users)

#### **B. Security Rules Too Restrictive**
**Symptoms**: Permission denied errors
**Current Rules** (if any):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Temporary Solution** (for testing):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents for testing
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Production Solution**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Mobile users can read/write their own data
    match /mobile_users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admin users (separate collection)
    match /admin_users/{adminId} {
      allow read, write: if request.auth != null && request.auth.uid == adminId;
    }
    
    // Quizzes - mobile users can read, admins can write
    match /quizzes/{quizId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && isAdmin();
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return exists(/databases/$(database)/documents/admin_users/$(request.auth.uid));
    }
  }
}
```

#### **C. Network/Connectivity Issues**
**Symptoms**: Timeout errors, network failures
**Solutions**:
1. Check internet connection
2. Try on different network
3. Check if Firebase services are down
4. Verify Firebase project configuration

#### **D. Firebase Configuration Issues**
**Check these files**:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

**Verify**:
- Project ID matches: `mcq-quiz-system`
- Package name matches: `com.mcqquiz.app`
- SHA fingerprints are correct

### **3. Manual Firestore Test**

#### **Test in Firebase Console**:
1. Go to Firestore Database in Firebase Console
2. Click **Start collection**
3. Collection ID: `test`
4. Document ID: `test_doc`
5. Add field: `message` (string) = `"Hello Firestore"`
6. Save and verify document appears

#### **Test from App**:
Run the debug screen tests and check logs for detailed error messages.

### **4. Debug Logging Analysis**

Look for these debug messages in the console:

#### **Success Pattern**:
```
DEBUG: 🔐 Starting simple user registration for: user@example.com
DEBUG: ✅ Firebase Auth user created: abc123uid
DEBUG: 📝 Preparing to store user data for UID: abc123uid
DEBUG: 📝 Collection: mobile_users
DEBUG: 📝 User data prepared: [uid, email, name, ...]
DEBUG: ✅ Firestore document created successfully
DEBUG: ✅ User data stored in Firestore
```

#### **Failure Patterns**:
```
DEBUG: ❌ Firestore storage failed: [permission-denied]
DEBUG: ❌ Firestore storage failed: [unavailable]
DEBUG: ❌ Firestore storage failed: [deadline-exceeded]
```

### **5. Step-by-Step Resolution**

#### **Step 1: Enable Firestore**
1. Firebase Console → Firestore Database
2. Create database in test mode
3. Choose location

#### **Step 2: Set Temporary Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

#### **Step 3: Test Connection**
1. Run debug screen tests
2. Check all tests pass
3. Try registration again

#### **Step 4: Verify Data**
1. Check Firebase Console → Firestore
2. Look for `mobile_users` collection
3. Verify user document exists

#### **Step 5: Secure Rules** (after testing)
Replace test rules with production rules that require authentication.

### **6. Alternative Solutions**

#### **If Firestore Still Fails**:
1. **Use Realtime Database**: Switch to Firebase Realtime Database
2. **Local Storage**: Store user data locally initially
3. **Retry Logic**: Implement automatic retry for Firestore operations

#### **Temporary Workaround**:
```dart
// In SimpleAuthService, modify registration to continue even if Firestore fails
try {
  await _storeUserData(...);
} catch (e) {
  // Log error but don't fail registration
  print('Firestore failed, user can still login: $e');
}
```

### **7. Monitoring & Verification**

#### **Check Firebase Console**:
- **Authentication**: Users should appear here
- **Firestore**: Documents should appear in `mobile_users` collection
- **Usage**: Monitor read/write operations

#### **App Logs**:
- Enable debug mode
- Check for Firestore error messages
- Monitor registration success/failure rates

### **8. Next Steps**

1. **Run Debug Tests**: Use the debug screen to identify the specific issue
2. **Check Firebase Console**: Verify Firestore is enabled and configured
3. **Update Security Rules**: Set appropriate rules for your use case
4. **Test Registration**: Try registering a new user
5. **Verify Data**: Check if user data appears in Firestore

### **🆘 EMERGENCY CONTACT**

If all else fails:
1. **Firebase Support**: Check Firebase status page
2. **Flutter Firebase Plugin**: Check GitHub issues
3. **Stack Overflow**: Search for similar Firestore issues

The debug screen will help identify the exact issue so we can provide a targeted solution!
