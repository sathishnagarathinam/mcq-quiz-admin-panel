# Payment API Reference

## Base URL
```
https://us-central1-mcq-quiz-system.cloudfunctions.net/api
```

## Endpoints

### 1. Create Payment Order

**Endpoint:** `POST /payments/create-order`

**Description:** Creates a Razorpay order for quiz payment

**Request Body:**
```json
{
  "userId": "user_id_string",
  "examId": "exam_id_string",
  "amount": 99.99,
  "userEmail": "user@example.com",
  "userPhone": "9876543210",
  "discountPercentage": 10,
  "couponCode": "SAVE10",
  "bannerRoutedFrom": "banner_id"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "orderId": "order_1234567890",
    "merchantOrderId": "ORDER_1705084800000_user_id",
    "amount": 9999,
    "currency": "INR",
    "keyId": "rzp_live_xxxxx",
    "receipt": "ORDER_1705084800000_user_id"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "error": "Missing required fields: userId, examId, amount"
}
```

**Response (Error - 500):**
```json
{
  "success": false,
  "error": "Failed to create payment order",
  "details": "Error message details"
}
```

**Notes:**
- Amount is sent in **rupees** (e.g., 99.99)
- Backend converts to **paise** (multiplies by 100)
- Response amount is in **paise** (integer)
- All fields except discountPercentage, couponCode, bannerRoutedFrom are required

---

### 2. Verify Payment

**Endpoint:** `POST /payments/verify`

**Description:** Verifies payment signature and grants quiz access

**Request Body:**
```json
{
  "paymentId": "pay_1234567890",
  "orderId": "order_1234567890",
  "signature": "signature_hash_from_razorpay",
  "merchantOrderId": "ORDER_1705084800000_user_id"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "verified": true,
  "message": "Payment verified successfully"
}
```

**Response (Invalid Signature - 400):**
```json
{
  "success": false,
  "verified": false,
  "message": "Invalid payment signature"
}
```

**Response (Error - 500):**
```json
{
  "success": false,
  "verified": false,
  "error": "Failed to verify payment",
  "details": "Error message details"
}
```

**Notes:**
- Signature is verified using HMAC-SHA256
- On success, creates paid_quiz_access record
- Access is granted for 30 days from payment date
- Order status is updated to 'paid' in Firestore

---

## Firestore Collections

### orders
Stores all payment orders

**Document ID:** `merchantOrderId`

**Fields:**
- `userId`: string
- `examId`: string
- `amount`: number (in rupees)
- `amountInPaise`: number (in paise)
- `currency`: string ("INR")
- `razorpayOrderId`: string
- `merchantOrderId`: string
- `status`: string ("pending" or "paid")
- `discountPercentage`: number
- `couponCode`: string
- `bannerRoutedFrom`: string
- `userEmail`: string
- `userPhone`: string
- `razorpayPaymentId`: string (added after verification)
- `createdAt`: timestamp
- `updatedAt`: timestamp
- `verifiedAt`: timestamp (added after verification)

### paid_quiz_access
Stores user access records for paid quizzes

**Fields:**
- `userId`: string
- `examId`: string
- `examName`: string
- `paymentId`: string
- `orderId`: string
- `merchantOrderId`: string
- `accessStartDate`: date
- `accessEndDate`: date (30 days from start)
- `status`: string ("active")
- `createdAt`: timestamp

---

## Error Codes

| Code | Message | Cause |
|------|---------|-------|
| 400 | Missing required fields | userId, examId, or amount not provided |
| 400 | Invalid payment signature | Signature verification failed |
| 500 | Failed to create payment order | Razorpay API error or Firestore error |
| 500 | Failed to verify payment | Firestore update error |

---

## Integration Example (Dart/Flutter)

```dart
// Create order
final response = await http.post(
  Uri.parse('$baseUrl/payments/create-order'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'userId': userId,
    'examId': examId,
    'amount': 99.99,
    'userEmail': userEmail,
    'userPhone': userPhone,
  }),
);

final orderData = RazorpayOrderData.fromJson(jsonDecode(response.body)['data']);

// Open Razorpay checkout
final options = {
  'key': orderData.keyId,
  'amount': orderData.amount, // Amount in paise (integer)
  'order_id': orderData.orderId,
  // ... other options
};

_razorpay.open(options);

// Verify payment
final verifyResponse = await http.post(
  Uri.parse('$baseUrl/payments/verify'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'paymentId': paymentId,
    'orderId': orderId,
    'signature': signature,
    'merchantOrderId': merchantOrderId,
  }),
);
```

---

## Environment Variables

Set these in Firebase Functions:
```
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
```

---

## Testing

Use Razorpay test credentials:
- Test Card: 4111 1111 1111 1111
- Expiry: Any future date
- CVV: Any 3 digits

