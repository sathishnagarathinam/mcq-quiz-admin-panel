# 📋 Release Notes - Version 1.7.32+40

**Release Date**: January 15, 2026  
**Build**: 1.7.32+40  
**Platform**: Android 6.0+  
**Size**: 67.8 MB

---

## 🎯 Release Highlights

This release focuses on **critical bug fixes** for notification navigation and free quiz access management, ensuring a seamless user experience.

---

## ✅ What's Fixed

### 🔔 **Notification Navigation (CRITICAL FIX)**
- **Issue**: Tapping quiz notifications didn't navigate to quiz pages
- **Root Cause**: Race condition in notification handling causing pending navigation to be cleared
- **Solution**: 
  - Removed race condition in main app initialization
  - Captured navigation values before async delay
  - Improved router state management
- **Result**: ✅ Notifications now properly navigate to quiz instruction pages

### 🆓 **Free Quiz Access Management (CRITICAL FIX)**
- **Issue**: Admin-granted free access wasn't recognized by the app
- **Root Cause**: Mobile app wasn't checking the `free_quiz_access` collection
- **Solution**: 
  - Added `_checkAdminGrantedFreeAccess()` method
  - Integrated free access check into quiz access status logic
  - Proper expiry validation for admin-granted access
- **Result**: ✅ Users with admin-granted free access can now access paid quizzes

### 🚀 **Performance Improvements**
- Optimized notification delivery pipeline
- Improved app startup time
- Better memory management during navigation
- Reduced latency in quiz access checks

---

## 📱 Technical Details

### **Android Support**
- ✅ Full 16KB page size support
- ✅ Android 15 compatibility
- ✅ Devices from Android 6.0 (API 23) to Android 15 (API 35)

### **Dependencies Updated**
- Firebase Messaging: 15.2.10
- Flutter Local Notifications: 17.0.0
- GoRouter: Latest stable

### **Code Changes**
- `mobile_app/lib/core/services/fcm_service.dart`: Fixed notification navigation
- `mobile_app/lib/main.dart`: Removed race condition
- `mobile_app/lib/core/services/paid_quiz_access_service.dart`: Added free access check
- `mobile_app/pubspec.yaml`: Version bumped to 1.7.32+40

---

## 🧪 Testing Performed

✅ Notification navigation from terminated state  
✅ Notification navigation from background state  
✅ Notification navigation from foreground state  
✅ Free quiz access with admin grants  
✅ Paid quiz access after payment  
✅ Quiz access expiry validation  
✅ Multiple device compatibility  
✅ Payment flow integration  

---

## 📊 Build Information

```
Build Type: Release
Gradle Task: bundleRelease
Output: app-release.aab (67.8 MB)
Signing: Release keystore
Optimization: Tree-shaking enabled
```

---

## 🔄 Migration Notes

**For Users Upgrading from v1.7.31:**
- No data migration required
- All previous quiz attempts preserved
- Payment history maintained
- User preferences retained

**For Admins:**
- Free access grants now work correctly
- Notifications properly navigate to quizzes
- No admin panel changes required

---

## 🐛 Known Issues

None reported in this release.

---

## 📝 Changelog Summary

| Component | Change | Impact |
|-----------|--------|--------|
| FCM Service | Fixed notification navigation race condition | High |
| Quiz Access | Added admin-granted free access check | High |
| App Init | Removed pending navigation race condition | High |
| Performance | Optimized notification handling | Medium |

---

## 🚀 Next Steps

1. **Install**: Download from Google Play Store or use APK
2. **Test**: Verify notification navigation works
3. **Feedback**: Report any issues via in-app feedback
4. **Enjoy**: Start your exam preparation!

---

## 📞 Support

- **Report Issues**: Use in-app feedback
- **Contact Support**: Email through the app
- **Feedback**: Share suggestions for improvements

---

**Thank you for using Dakshin Postal Academy! 🎉**

