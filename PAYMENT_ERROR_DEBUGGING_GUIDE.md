# Payment Error Debugging Guide

## Error: "Failed to create payment order"

### Root Causes & Solutions

#### 1. **Missing Razorpay Credentials** ⚠️ MOST COMMON
**Symptom:** Error message includes "Razorpay credentials not configured"

**Solution:**
```bash
# Set environment variables in Firebase Functions
firebase functions:config:set razorpay.key_id="your_key_id" razorpay.key_secret="your_key_secret" --project mcq-quiz-system
```

Or via Firebase Console:
1. Go to Firebase Console → Project Settings → Functions
2. Set environment variables:
   - `RAZORPAY_KEY_ID` = your Razorpay Key ID
   - `RAZORPAY_KEY_SECRET` = your Razorpay Key Secret

#### 2. **Invalid Razorpay Credentials**
**Symptom:** Razorpay API returns 401 Unauthorized

**Solution:**
- Verify credentials are correct in Razorpay Dashboard
- Check if using test vs production credentials
- Ensure credentials haven't expired

#### 3. **Invalid Amount Format**
**Symptom:** Razorpay API returns 400 Bad Request with "amount" error

**Solution:**
- Amount must be in paise (smallest currency unit)
- Backend automatically converts: amount_rupees × 100 = amount_paise
- Minimum amount: 1 paise (0.01 rupees)
- Maximum amount: 50,000,000 paise (500,000 rupees)

#### 4. **Network/Timeout Issues**
**Symptom:** Request times out or connection refused

**Solution:**
- Check internet connectivity
- Verify Razorpay API is accessible
- Increase timeout if needed (currently 10 seconds)

#### 5. **Firestore Permission Issues**
**Symptom:** Order created but not stored in Firestore

**Solution:**
- Verify Firestore rules allow writing to 'orders' collection
- Check Firebase project has Firestore enabled
- Ensure service account has proper permissions

### How to Debug

#### Step 1: Check Firebase Logs
```bash
firebase functions:log --project mcq-quiz-system
```

Look for:
- ✅ "Create Order Request" - Request received
- ✅ "Amount conversion" - Amount converted to paise
- ✅ "Razorpay API response" - Order created successfully
- ❌ "Razorpay credentials not configured" - Missing credentials
- ❌ "Razorpay API Error" - API returned error

#### Step 2: Check Mobile App Logs
In Flutter, check the developer console for:
```
🔵 Creating Razorpay order...
   User: user_id, Exam: exam_id, Amount: 99.99
❌ Dio error creating order: Failed to create payment order
   Response: {...error details...}
```

#### Step 3: Verify Request Data
Check that the mobile app is sending:
- `userId` - User ID (string, required)
- `examId` - Exam ID (string, required)
- `amount` - Amount in rupees (number, required)
- `userEmail` - User email (string, required)
- `userPhone` - User phone (string, required)

#### Step 4: Test Razorpay Credentials
```bash
# Test with curl
curl -X POST https://api.razorpay.com/v1/orders \
  -H "Content-Type: application/json" \
  -u "YOUR_KEY_ID:YOUR_KEY_SECRET" \
  -d '{
    "amount": 9999,
    "currency": "INR",
    "receipt": "test_receipt"
  }'
```

### Enhanced Error Logging

The updated payment endpoint now logs:
1. **Request Details** - What data was received
2. **Credential Status** - Whether credentials are configured
3. **Amount Conversion** - Original and converted amounts
4. **Razorpay Response** - Full API response or error
5. **Firestore Operations** - Order storage status

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Razorpay credentials not configured" | Missing env vars | Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET |
| "Invalid authentication" | Wrong credentials | Verify credentials in Razorpay Dashboard |
| "Invalid amount" | Amount format issue | Ensure amount is in rupees (e.g., 99.99) |
| "Invalid currency" | Wrong currency code | Use "INR" only |
| "Invalid receipt" | Duplicate receipt | Receipt must be unique |
| "Timeout" | Network issue | Check connectivity, increase timeout |

### Testing Checklist

- [ ] Razorpay credentials are set in Firebase Functions
- [ ] Credentials are correct (test or production)
- [ ] Amount is in rupees (not paise)
- [ ] User ID and Exam ID are valid
- [ ] User email and phone are provided
- [ ] Firestore has write permissions
- [ ] Firebase Functions are deployed
- [ ] Mobile app is using correct API endpoint

### Next Steps if Error Persists

1. Check Firebase Console logs for exact error
2. Verify Razorpay account status (not suspended)
3. Contact Razorpay support with error details
4. Check Firebase project quotas and limits
5. Verify Firestore database is active

---

**Updated:** January 13, 2026  
**Status:** Enhanced logging deployed

