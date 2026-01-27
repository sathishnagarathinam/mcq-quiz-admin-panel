# 🔧 Delete User - Troubleshooting Guide

## 🐛 Common Errors and Solutions

### Error 1: "Cloud Functions URL is not configured"

**Cause**: `REACT_APP_FUNCTIONS_URL` environment variable is missing

**Solution**:
```bash
# Check .env file
cat web_admin/.env

# Should contain:
REACT_APP_FUNCTIONS_URL=https://us-central1-mcq-quiz-system.cloudfunctions.net/api

# If missing, add it:
echo "REACT_APP_FUNCTIONS_URL=https://us-central1-mcq-quiz-system.cloudfunctions.net/api" >> web_admin/.env

# Restart dev server
npm run dev
```

---

### Error 2: "Server error (404): Not Found"

**Cause**: Cloud Function is not deployed

**Solution**:
```bash
# Deploy Cloud Functions
cd web_admin/firebase/functions
npm run deploy

# Verify deployment
firebase functions:list

# Should show: api (HTTPS)
```

---

### Error 3: "Server error (500): Internal Server Error"

**Cause**: Cloud Function has an error

**Solution**:
1. Check Firebase Console logs:
   - Go to Firebase Console
   - Functions → api → Logs
   - Look for error messages

2. Common issues:
   - Missing Firebase Admin SDK initialization
   - Firestore permissions issue
   - Invalid user ID format

---

### Error 4: "Unexpected token '<'"

**Cause**: API returning HTML instead of JSON (now fixed)

**Solution**:
1. Check browser console (F12)
2. Look for detailed error message
3. Follow solutions for Error 2 or 3

---

## ✅ Verification Checklist

### Step 1: Check Environment
- [ ] `REACT_APP_FUNCTIONS_URL` is set
- [ ] URL is correct format
- [ ] No typos in URL

### Step 2: Check Cloud Function
- [ ] Cloud Function is deployed
- [ ] Function name is "api"
- [ ] Function is HTTPS type
- [ ] Function is in us-central1 region

### Step 3: Check Firestore
- [ ] User exists in `users` collection
- [ ] User exists in `mobile_users` collection
- [ ] Firestore permissions allow deletion

### Step 4: Test Deletion
- [ ] Click delete button
- [ ] Confirm in dialog
- [ ] Check console for logs
- [ ] Verify success message

---

## 🧪 Manual Testing

### Test with curl
```bash
# Get your Cloud Function URL
FUNCTIONS_URL="https://us-central1-mcq-quiz-system.cloudfunctions.net/api"
USER_ID="test-user-id"

# Test DELETE endpoint
curl -X DELETE \
  "${FUNCTIONS_URL}/users/${USER_ID}" \
  -H "Content-Type: application/json"

# Expected response:
# {"success": true, "message": "User and all related data deleted successfully", ...}
```

### Test with Postman
1. Create new DELETE request
2. URL: `https://us-central1-mcq-quiz-system.cloudfunctions.net/api/users/{userId}`
3. Headers: `Content-Type: application/json`
4. Send request
5. Check response

---

## 📊 Expected Responses

### Success (200)
```json
{
  "success": true,
  "message": "User and all related data deleted successfully",
  "deletedData": {
    "user": true,
    "quizAttempts": 5,
    "paidOrders": 2,
    "deviceRegistrations": 1,
    "notifications": 10,
    "feedback": 3,
    "sessions": 8
  }
}
```

### Error (400)
```json
{
  "error": "User ID is required"
}
```

### Error (500)
```json
{
  "error": "Failed to delete user",
  "details": "Error message here"
}
```

---

## 🔍 Debug Logging

### Enable Detailed Logs
1. Open DevTools (F12)
2. Go to Console tab
3. Look for logs starting with:
   - `🗑️` - Deletion started
   - `📡` - API call made
   - `📊` - Response received
   - `✅` - Deletion completed

### Example Log Output
```
🗑️ Starting deletion process for user: abc123
📡 Calling delete endpoint: https://us-central1-mcq-quiz-system.cloudfunctions.net/api/users/abc123
📊 Response status: 200, Content-Type: application/json
✅ User deletion completed for: abc123
```

---

## 🚀 Quick Fix Steps

1. **Check environment variable**
   ```bash
   echo $REACT_APP_FUNCTIONS_URL
   ```

2. **Verify Cloud Function**
   - Open Firebase Console
   - Go to Functions
   - Check if "api" function exists

3. **Redeploy if needed**
   ```bash
   cd web_admin/firebase/functions
   npm run deploy
   ```

4. **Clear cache and reload**
   - Ctrl+Shift+Delete (clear cache)
   - Reload page
   - Try delete again

5. **Check console logs**
   - F12 → Console
   - Look for error details

---

## 📞 Still Not Working?

1. Check Firebase Console logs
2. Verify user exists in Firestore
3. Check Firestore permissions
4. Verify Cloud Function code
5. Test with curl/Postman first

---

**Status**: ✅ FIXED  
**Testing**: REQUIRED  

