import { Router } from 'express';
import * as admin from 'firebase-admin';
import axios from 'axios';
import crypto from 'crypto';

const router = Router();

// Get Razorpay credentials from environment
const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID || '';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || '';

// Create Razorpay order
router.post('/create-order', async (req, res): Promise<void> => {
  try {
    const { userId, examId, amount, userEmail, userPhone, discountPercentage, couponCode, bannerRoutedFrom } = req.body;

    console.log('📝 Create Order Request:', {
      userId,
      examId,
      amount,
      userEmail,
      userPhone,
      discountPercentage,
      couponCode,
      bannerRoutedFrom
    });

    // Validate required fields
    if (!userId || !examId || !amount) {
      console.error('❌ Missing required fields');
      res.status(400).json({
        success: false,
        error: 'Missing required fields: userId, examId, amount'
      });
      return;
    }

    // Check if Razorpay credentials are set
    if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
      console.error('❌ Razorpay credentials not configured');
      console.error('   RAZORPAY_KEY_ID:', RAZORPAY_KEY_ID ? '✓ Set' : '✗ Missing');
      console.error('   RAZORPAY_KEY_SECRET:', RAZORPAY_KEY_SECRET ? '✓ Set' : '✗ Missing');
      res.status(500).json({
        success: false,
        error: 'Payment service not configured. Please contact support.',
        details: 'Razorpay credentials are missing'
      });
      return;
    }

    // Convert amount to paise (multiply by 100)
    const amountInPaise = Math.round(amount * 100);

    console.log('💰 Amount conversion:', {
      original: amount,
      inPaise: amountInPaise
    });

    // Create merchant order ID (must be <= 40 chars for Razorpay receipt)
    // Using timestamp + random suffix to ensure uniqueness
    const timestamp = Date.now().toString().slice(-8); // Last 8 digits of timestamp
    const randomSuffix = Math.random().toString(36).substring(2, 8); // 6 random chars
    const merchantOrderId = `ORD_${timestamp}_${randomSuffix}`;

    console.log('🔄 Creating Razorpay order with ID:', merchantOrderId);
    console.log('   Receipt length:', merchantOrderId.length, 'chars (max: 40)');

    // Create Razorpay order via API
    let razorpayResponse;
    try {
      razorpayResponse = await axios.post(
        'https://api.razorpay.com/v1/orders',
        {
          amount: amountInPaise,
          currency: 'INR',
          receipt: merchantOrderId,
          notes: {
            userId,
            examId,
            discountPercentage: discountPercentage || 0,
            couponCode: couponCode || '',
            bannerRoutedFrom: bannerRoutedFrom || ''
          }
        },
        {
          auth: {
            username: RAZORPAY_KEY_ID,
            password: RAZORPAY_KEY_SECRET
          },
          timeout: 10000
        }
      );
      console.log('✅ Razorpay API response:', razorpayResponse.data);
    } catch (axiosError: any) {
      console.error('❌ Razorpay API Error:');
      console.error('   Status:', axiosError.response?.status);
      console.error('   Status Text:', axiosError.response?.statusText);
      console.error('   Data:', axiosError.response?.data);
      console.error('   Message:', axiosError.message);

      // Return detailed error to client
      res.status(500).json({
        success: false,
        error: 'Failed to create payment order with Razorpay',
        details: axiosError.response?.data?.description || axiosError.message,
        razorpayError: axiosError.response?.data
      });
      return;
    }

    const razorpayOrder = razorpayResponse.data;

    // Store order in Firestore
    const orderData = {
      userId,
      examId,
      amount,
      amountInPaise,
      currency: 'INR',
      razorpayOrderId: razorpayOrder.id,
      merchantOrderId,
      status: 'pending',
      discountPercentage: discountPercentage || 0,
      couponCode: couponCode || '',
      bannerRoutedFrom: bannerRoutedFrom || '',
      userEmail,
      userPhone,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    console.log('💾 Storing order in Firestore:', merchantOrderId);
    await admin.firestore().collection('orders').doc(merchantOrderId).set(orderData);
    console.log('✅ Order stored successfully');

    // Return order data to client
    res.status(200).json({
      success: true,
      data: {
        orderId: razorpayOrder.id,
        merchantOrderId,
        amount: amountInPaise,
        currency: 'INR',
        keyId: RAZORPAY_KEY_ID,
        receipt: merchantOrderId
      }
    });
  } catch (error) {
    console.error('❌ Unexpected error creating order:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create payment order',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Verify payment
router.post('/verify', async (req, res): Promise<void> => {
  try {
    const { paymentId, orderId, signature, merchantOrderId } = req.body;

    // Verify signature
    const body = orderId + '|' + paymentId;
    const expectedSignature = crypto
      .createHmac('sha256', RAZORPAY_KEY_SECRET)
      .update(body)
      .digest('hex');

    const isSignatureValid = expectedSignature === signature;

    if (!isSignatureValid) {
      res.status(400).json({
        success: false,
        verified: false,
        message: 'Invalid payment signature'
      });
      return;
    }

    // Update order status in Firestore
    await admin.firestore().collection('orders').doc(merchantOrderId).update({
      status: 'paid',
      razorpayPaymentId: paymentId,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Create access record for paid quiz
    const orderDoc = await admin.firestore().collection('orders').doc(merchantOrderId).get();
    const orderData = orderDoc.data();

    if (orderData) {
      const accessRecord = {
        userId: orderData.userId,
        examId: orderData.examId,
        examName: orderData.examName || '',
        paymentId,
        orderId,
        merchantOrderId,
        accessStartDate: admin.firestore.FieldValue.serverTimestamp(),
        accessEndDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
        status: 'active',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Create in global collection for analytics
      await admin.firestore().collection('paid_quiz_access').add(accessRecord);

      // IMPORTANT: Also create in user's subcollection for quick access checks
      // This is where the mobile app looks for access records
      console.log(`📝 Creating access record for user: ${orderData.userId}, exam: ${orderData.examId}`);
      await admin.firestore()
        .collection('users')
        .doc(orderData.userId)
        .collection('exam_access')
        .doc(orderData.examId)
        .set(accessRecord);

      console.log(`✅ Access record created in user subcollection`);
    }

    res.status(200).json({
      success: true,
      verified: true,
      message: 'Payment verified successfully'
    });
  } catch (error) {
    console.error('Error verifying payment:', error);
    res.status(500).json({
      success: false,
      verified: false,
      error: 'Failed to verify payment',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export const paymentRoutes = router;

