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
Object.defineProperty(exports, "__esModule", { value: true });
exports.RazorpayService = void 0;
// eslint-disable-next-line @typescript-eslint/no-var-requires
const Razorpay = require('razorpay');
const crypto = __importStar(require("crypto"));
class RazorpayService {
    constructor(config) {
        this.keyId = config.keyId;
        this.keySecret = config.keySecret;
        this.razorpay = new Razorpay({
            key_id: config.keyId,
            key_secret: config.keySecret,
        });
        console.log('✅ Razorpay service initialized');
        console.log('🔑 Key ID:', this.keyId.substring(0, 12) + '...');
    }
    /**
     * Create a Razorpay order
     */
    async createOrder(request) {
        try {
            console.log('📦 Creating Razorpay order...');
            console.log('   Merchant Order ID:', request.merchantOrderId);
            console.log('   Amount (paise):', request.amount);
            const orderOptions = {
                amount: request.amount,
                currency: request.currency || 'INR',
                receipt: request.merchantOrderId,
                notes: {
                    merchantOrderId: request.merchantOrderId,
                    userId: request.userId,
                    examId: request.examId,
                    userEmail: request.userEmail || '',
                    userPhone: request.userPhone || '',
                },
            };
            const order = await this.razorpay.orders.create(orderOptions);
            console.log('✅ Razorpay order created successfully');
            console.log('   Order ID:', order.id);
            console.log('   Status:', order.status);
            return {
                success: true,
                data: {
                    orderId: order.id,
                    merchantOrderId: request.merchantOrderId,
                    amount: order.amount,
                    currency: order.currency,
                    keyId: this.keyId,
                },
            };
        }
        catch (error) {
            console.error('❌ Error creating Razorpay order:', error);
            console.error('   Error message:', error.message);
            console.error('   Error code:', error.code);
            console.error('   Error details:', error.description || error.details || 'No details');
            console.error('   Full error:', JSON.stringify(error, null, 2));
            // Provide more specific error messages
            let errorMessage = 'Failed to create order';
            if (error.code === 'INVALID_CREDENTIALS') {
                errorMessage = 'Invalid Razorpay credentials. Please check your API keys.';
            }
            else if (error.code === 'NETWORK_ERROR') {
                errorMessage = 'Network error connecting to Razorpay. Please try again.';
            }
            else if (error.message) {
                errorMessage = error.message;
            }
            return {
                success: false,
                message: errorMessage,
            };
        }
    }
    /**
     * Verify payment signature
     */
    verifyPaymentSignature(request) {
        var _a;
        try {
            console.log('🔐 Verifying Razorpay payment signature...');
            console.log('   Payment ID:', request.paymentId);
            console.log('   Order ID:', request.orderId);
            console.log('   Received Signature:', ((_a = request.signature) === null || _a === void 0 ? void 0 : _a.substring(0, 20)) + '...');
            // Generate expected signature
            const body = request.orderId + '|' + request.paymentId;
            console.log('   Body for signature:', body);
            const expectedSignature = crypto
                .createHmac('sha256', this.keySecret)
                .update(body)
                .digest('hex');
            console.log('   Expected Signature:', expectedSignature.substring(0, 20) + '...');
            const isValid = expectedSignature === request.signature;
            if (isValid) {
                console.log('✅ Payment signature verified successfully');
            }
            else {
                console.error('❌ Payment signature verification failed');
                console.error('   Expected:', expectedSignature);
                console.error('   Received:', request.signature);
            }
            return {
                success: true,
                verified: isValid,
                message: isValid ? 'Signature verified' : 'Invalid signature',
            };
        }
        catch (error) {
            console.error('❌ Error verifying signature:', error);
            return {
                success: false,
                verified: false,
                message: error.message || 'Verification failed',
            };
        }
    }
    /**
     * Verify Razorpay webhook signature
     */
    verifyWebhookSignature(body, signature, webhookSecret) {
        try {
            const expectedSignature = crypto
                .createHmac('sha256', webhookSecret)
                .update(body)
                .digest('hex');
            return expectedSignature === signature;
        }
        catch (error) {
            console.error('❌ Error verifying webhook signature:', error);
            return false;
        }
    }
    /**
     * Fetch payment details from Razorpay
     */
    async fetchPayment(paymentId) {
        try {
            const payment = await this.razorpay.payments.fetch(paymentId);
            return { success: true, data: payment };
        }
        catch (error) {
            console.error('❌ Error fetching payment:', error);
            return { success: false, message: error.message };
        }
    }
}
exports.RazorpayService = RazorpayService;
//# sourceMappingURL=razorpay.service.js.map