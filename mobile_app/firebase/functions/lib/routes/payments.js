"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.paymentRoutes = void 0;
const express_1 = require("express");
const admin = __importStar(require("firebase-admin"));
const axios_1 = __importDefault(require("axios"));
const crypto_1 = __importDefault(require("crypto"));
const router = (0, express_1.Router)();
// Get Razorpay credentials from environment
const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID || '';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || '';
// Create Razorpay order
router.post('/create-order', async (req, res) => {
    var _a, _b, _c, _d, _e, _f;
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
            razorpayResponse = await axios_1.default.post('https://api.razorpay.com/v1/orders', {
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
            }, {
                auth: {
                    username: RAZORPAY_KEY_ID,
                    password: RAZORPAY_KEY_SECRET
                },
                timeout: 10000
            });
            console.log('✅ Razorpay API response:', razorpayResponse.data);
        }
        catch (axiosError) {
            console.error('❌ Razorpay API Error:');
            console.error('   Status:', (_a = axiosError.response) === null || _a === void 0 ? void 0 : _a.status);
            console.error('   Status Text:', (_b = axiosError.response) === null || _b === void 0 ? void 0 : _b.statusText);
            console.error('   Data:', (_c = axiosError.response) === null || _c === void 0 ? void 0 : _c.data);
            console.error('   Message:', axiosError.message);
            // Return detailed error to client
            res.status(500).json({
                success: false,
                error: 'Failed to create payment order with Razorpay',
                details: ((_e = (_d = axiosError.response) === null || _d === void 0 ? void 0 : _d.data) === null || _e === void 0 ? void 0 : _e.description) || axiosError.message,
                razorpayError: (_f = axiosError.response) === null || _f === void 0 ? void 0 : _f.data
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
    }
    catch (error) {
        console.error('❌ Unexpected error creating order:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create payment order',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Verify payment
router.post('/verify', async (req, res) => {
    try {
        const { paymentId, orderId, signature, merchantOrderId } = req.body;
        // Verify signature
        const body = orderId + '|' + paymentId;
        const expectedSignature = crypto_1.default
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
                accessStartDate: new Date(),
                accessEndDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
                status: 'active',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            };
            await admin.firestore().collection('paid_quiz_access').add(accessRecord);
        }
        res.status(200).json({
            success: true,
            verified: true,
            message: 'Payment verified successfully'
        });
    }
    catch (error) {
        console.error('Error verifying payment:', error);
        res.status(500).json({
            success: false,
            verified: false,
            error: 'Failed to verify payment',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
exports.paymentRoutes = router;
//# sourceMappingURL=payments.js.map