# PhonePe SDK 3.0.0 Migration Plan

## Overview
PhonePe SDK 3.0.0 introduces significant changes that eliminate the need for client-side checksum generation and provide better security through Order Token approach.

## Key Changes in SDK 3.0.0

### 1. Authentication Method
- **Old (2.x)**: Client-side checksum generation using salt key
- **New (3.0.0)**: Server-side Order Token generation via Auth Token API

### 2. Payment Flow
- **Old**: Direct payload + checksum → PhonePe SDK
- **New**: Auth Token → Create Order → Order Token → PhonePe SDK

### 3. API Structure
- **Old**: Single API call with checksum
- **New**: Two-step API process (Auth + Order)

## Migration Steps

### Phase 1: Backend API Setup (Recommended First)

#### 1.1 Auth Token API Implementation
```javascript
// Backend: Get Auth Token
async function getAuthToken() {
  const payload = {
    merchantId: MERCHANT_ID,
    apiEndPoint: "/v3/transaction/initiate"
  };
  
  const response = await axios.post(
    'https://api.phonepe.com/apis/hermes/v3/token/generate',
    payload,
    {
      headers: {
        'Content-Type': 'application/json',
        'X-CLIENT-ID': CLIENT_ID,
        'X-CLIENT-SECRET': CLIENT_SECRET
      }
    }
  );
  
  return response.data.data.token;
}
```

#### 1.2 Create Order API Implementation
```javascript
// Backend: Create Order with Auth Token
async function createOrder(authToken, orderDetails) {
  const payload = {
    merchantId: MERCHANT_ID,
    merchantTransactionId: orderDetails.transactionId,
    merchantUserId: orderDetails.userId,
    amount: orderDetails.amount,
    callbackUrl: CALLBACK_URL,
    paymentInstrument: {
      type: "PAY_PAGE"
    }
  };
  
  const response = await axios.post(
    'https://api.phonepe.com/apis/hermes/v3/transaction/initiate',
    payload,
    {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      }
    }
  );
  
  return response.data.data.orderToken;
}
```

### Phase 2: Mobile App SDK 3.0.0 Integration

#### 2.1 Update Dependencies
```yaml
# pubspec.yaml
dependencies:
  phonepe_payment_sdk: ^3.0.0
```

#### 2.2 New SDK Initialization
```dart
// Initialize SDK 3.0.0
await PhonePePaymentSdk.init(
  environment,     // "SANDBOX" or "PRODUCTION"
  merchantId,      // Your merchant ID
  flowId,          // Unique flow identifier
  enableLogging,   // Boolean for logging
);
```

#### 2.3 New Payment Flow
```dart
// SDK 3.0.0 Payment Flow
class PhonePeSDK3Service {
  static Future<Map<String, dynamic>> processPayment({
    required String userId,
    required String examId,
    required double amount,
  }) async {
    try {
      // Step 1: Get Order Token from backend
      final orderToken = await _getOrderTokenFromBackend(
        userId: userId,
        examId: examId,
        amount: amount,
      );
      
      // Step 2: Create payment request
      final paymentRequest = {
        "orderId": orderToken['orderId'],
        "merchantId": MERCHANT_ID,
        "token": orderToken['token'],
        "paymentMode": {"type": "PAY_PAGE"}
      };
      
      // Step 3: Start transaction with SDK 3.0.0
      final result = await PhonePePaymentSdk.startTransaction(
        jsonEncode(paymentRequest),
        APP_SCHEMA, // For iOS deep linking
      );
      
      return _handlePaymentResult(result);
      
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> _getOrderTokenFromBackend({
    required String userId,
    required String examId,
    required double amount,
  }) async {
    // Call your backend API to get order token
    final response = await http.post(
      Uri.parse('$BACKEND_URL/api/payments/create-order-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'examId': examId,
        'amount': amount,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get order token');
    }
  }
}
```

### Phase 3: Backend Order Token Service

#### 3.1 Complete Backend Implementation
```javascript
// Complete SDK 3.0.0 backend service
class PhonePeSDK3Service {
  constructor() {
    this.clientId = process.env.PHONEPE_CLIENT_ID;
    this.clientSecret = process.env.PHONEPE_CLIENT_SECRET;
    this.merchantId = process.env.PHONEPE_MERCHANT_ID;
    this.baseUrl = process.env.PHONEPE_BASE_URL;
  }
  
  async getAuthToken() {
    const payload = {
      merchantId: this.merchantId,
      apiEndPoint: "/v3/transaction/initiate"
    };
    
    const response = await axios.post(
      `${this.baseUrl}/v3/token/generate`,
      payload,
      {
        headers: {
          'Content-Type': 'application/json',
          'X-CLIENT-ID': this.clientId,
          'X-CLIENT-SECRET': this.clientSecret
        }
      }
    );
    
    return response.data.data.token;
  }
  
  async createOrderToken(orderDetails) {
    const authToken = await this.getAuthToken();
    
    const payload = {
      merchantId: this.merchantId,
      merchantTransactionId: orderDetails.transactionId,
      merchantUserId: orderDetails.userId,
      amount: orderDetails.amount * 100, // Convert to paise
      callbackUrl: process.env.CALLBACK_URL,
      paymentInstrument: {
        type: "PAY_PAGE"
      }
    };
    
    const response = await axios.post(
      `${this.baseUrl}/v3/transaction/initiate`,
      payload,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        }
      }
    );
    
    return {
      orderId: orderDetails.transactionId,
      token: response.data.data.orderToken,
      expiresAt: response.data.data.expiresAt
    };
  }
}

// API Endpoints
app.post('/api/payments/create-order-token', async (req, res) => {
  try {
    const { userId, examId, amount } = req.body;
    const transactionId = `MT_${Date.now()}_${userId}`;
    
    const phonePeService = new PhonePeSDK3Service();
    const orderToken = await phonePeService.createOrderToken({
      transactionId,
      userId,
      amount
    });
    
    // Store order in database
    await storeOrder({
      transactionId,
      userId,
      examId,
      amount,
      orderToken: orderToken.token,
      status: 'PENDING'
    });
    
    res.json({
      success: true,
      orderId: transactionId,
      token: orderToken.token,
      expiresAt: orderToken.expiresAt
    });
    
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
```

## Migration Timeline

### Week 1: Backend Setup
- [ ] Set up Auth Token API
- [ ] Implement Create Order API
- [ ] Test with PhonePe sandbox
- [ ] Set up webhook handlers

### Week 2: Mobile App Integration
- [ ] Update to SDK 3.0.0
- [ ] Implement new payment flow
- [ ] Update UI for new flow
- [ ] Test integration

### Week 3: Testing & Validation
- [ ] End-to-end testing
- [ ] Error handling validation
- [ ] Performance testing
- [ ] Security audit

### Week 4: Deployment
- [ ] Production backend deployment
- [ ] Mobile app release
- [ ] Monitor payment flows
- [ ] Rollback plan if needed

## Benefits of SDK 3.0.0

1. **Enhanced Security**: No client-side secrets
2. **Better Error Handling**: Clearer error messages
3. **Improved Performance**: Optimized API calls
4. **Future-Proof**: Latest PhonePe features
5. **Simplified Maintenance**: No checksum management

## Rollback Plan

If issues arise during migration:

1. **Immediate**: Revert to SDK 2.0.3
2. **Backend**: Keep both APIs running
3. **Mobile**: Feature flag for SDK version
4. **Gradual**: Percentage-based rollout

## Testing Strategy

### 1. Unit Tests
- Auth Token generation
- Order Token creation
- Payment flow validation

### 2. Integration Tests
- End-to-end payment flow
- Webhook handling
- Error scenarios

### 3. Load Tests
- High-volume payment processing
- Concurrent user scenarios
- API rate limiting

## Configuration

### Environment Variables
```bash
# SDK 3.0.0 Configuration
PHONEPE_CLIENT_ID=your_client_id
PHONEPE_CLIENT_SECRET=your_client_secret
PHONEPE_MERCHANT_ID=your_merchant_id
PHONEPE_BASE_URL=https://api.phonepe.com/apis/hermes
PHONEPE_ENVIRONMENT=SANDBOX # or PRODUCTION
```

### Mobile App Configuration
```dart
// SDK 3.0.0 Configuration
class PhonePeConfig {
  static const String merchantId = 'YOUR_MERCHANT_ID';
  static const String flowId = 'MCQ_QUIZ_APP';
  static const String environment = 'SANDBOX';
  static const String appSchema = 'com.mcqquiz.app';
  static const bool enableLogging = true;
}
```

## Next Steps

1. **Choose Migration Approach**: Backend-first or SDK-first
2. **Set Up Development Environment**: SDK 3.0.0 sandbox
3. **Implement Backend APIs**: Auth Token and Order creation
4. **Update Mobile App**: New SDK integration
5. **Test Thoroughly**: All payment scenarios
6. **Deploy Gradually**: Phased rollout
7. **Monitor Closely**: Payment success rates
