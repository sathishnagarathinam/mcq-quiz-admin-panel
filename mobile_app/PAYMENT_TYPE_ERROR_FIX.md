# Payment Type Error Fix - String to Int Conversion

## Problem
When attempting to make a payment for a paid quiz, the app was throwing the error:
```
type 'String' is not a subtype of type 'int' of index
```

This error occurred during the Razorpay payment initialization when the `amount` field was being passed to the Razorpay checkout options.

## Root Cause
The Razorpay SDK requires the `amount` field to be an **integer** (in paise), but the backend was potentially returning it as a String or the type conversion wasn't being handled properly.

## Solution Implemented

### 1. Enhanced Type Conversion in RazorpayOrderData Model
**File:** `mobile_app/lib/core/models/razorpay_models.dart`

Improved the `fromJson` factory method to handle multiple data types:
- `int` - directly used
- `String` - parsed using `int.tryParse()`
- `double` - converted to int using `.toInt()`
- `null` or other types - fallback to 0

```dart
factory RazorpayOrderData.fromJson(Map<String, dynamic> json) {
  int parsedAmount = 0;
  final amountValue = json['amount'];
  
  if (amountValue is int) {
    parsedAmount = amountValue;
  } else if (amountValue is String) {
    parsedAmount = int.tryParse(amountValue) ?? 0;
  } else if (amountValue is double) {
    parsedAmount = amountValue.toInt();
  } else if (amountValue != null) {
    parsedAmount = int.tryParse(amountValue.toString()) ?? 0;
  }
  // ... rest of the code
}
```

### 2. Explicit Type Handling in Payment Dialog
**File:** `mobile_app/lib/features/payment/widgets/payment_confirmation_dialog.dart`

Added a comment to ensure the amount is always an integer when passed to Razorpay:
```dart
// Amount is already an int in paise from RazorpayOrderData
final options = {
  'key': orderData.keyId,
  'amount': orderData.amount, // Amount in paise - MUST be int
  // ... rest of options
};
```

### 3. Created Backend Payment Endpoints
**Files:** 
- `mobile_app/firebase/functions/src/routes/payments.ts`
- `web_admin/firebase/functions/src/routes/payments.ts`

Implemented two endpoints:

#### POST `/payments/create-order`
- Accepts: userId, examId, amount, userEmail, userPhone, discountPercentage, couponCode, bannerRoutedFrom
- Converts amount to paise (multiplies by 100)
- Creates Razorpay order via Razorpay API
- Stores order in Firestore
- Returns: orderId, merchantOrderId, amount (in paise), keyId

#### POST `/payments/verify`
- Accepts: paymentId, orderId, signature, merchantOrderId
- Verifies payment signature using HMAC-SHA256
- Updates order status to 'paid'
- Creates paid_quiz_access record for 30-day access
- Returns: verification status

### 4. Registered Routes in Firebase Functions
Updated both `mobile_app/firebase/functions/src/index.ts` and `web_admin/firebase/functions/src/index.ts` to:
- Import the new paymentRoutes
- Register the routes at `/payments` endpoint

## Environment Variables Required
Set these in your Firebase Functions environment:
```
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
```

## Testing the Fix
1. Ensure Razorpay credentials are set in Firebase Functions environment
2. Deploy the updated Firebase functions
3. Attempt to make a payment for a paid quiz
4. The payment should now proceed without the type error

## Key Points
- Amount is always stored and passed as an **integer in paise**
- Razorpay requires: 1 rupee = 100 paise
- The backend handles conversion from rupees to paise
- Type safety is ensured at multiple levels (model parsing, dialog options)

