"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PhonePeService = void 0;
const axios_1 = __importDefault(require("axios"));
class PhonePeService {
    constructor(config) {
        this.cachedToken = null;
        this.config = config;
    }
    /**
     * Get OAuth Access Token for Standard Checkout v2
     * Endpoint: POST https://api.phonepe.com/apis/identity-manager/v1/oauth/token
     */
    async getAuthToken() {
        var _a, _b, _c, _d, _e;
        // Return cached token if still valid (with 60 second buffer)
        if (this.cachedToken && Date.now() < this.cachedToken.expiresAt - 60000) {
            console.log('🔑 Using cached auth token');
            return this.cachedToken.token;
        }
        try {
            // Use the identity-manager endpoint for OAuth token
            const authTokenUrl = `${this.config.authUrl}/v1/oauth/token`;
            console.log('🔐 Fetching new OAuth token from PhonePe...');
            console.log('📍 Auth URL:', authTokenUrl);
            const response = await axios_1.default.post(authTokenUrl, new URLSearchParams({
                client_id: this.config.clientId,
                client_version: this.config.clientVersion,
                client_secret: this.config.clientSecret,
                grant_type: 'client_credentials',
            }).toString(), {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
            });
            const tokenData = response.data;
            console.log('✅ OAuth token response received');
            // PhonePe returns access_token at root level (snake_case format)
            // Response format: { access_token, expires_in, token_type: "O-Bearer", ... }
            const accessToken = tokenData.access_token || ((_a = tokenData.data) === null || _a === void 0 ? void 0 : _a.accessToken);
            const expiresIn = tokenData.expires_in || ((_b = tokenData.data) === null || _b === void 0 ? void 0 : _b.expiresIn) || 1800; // default 30 min
            if (accessToken) {
                // Cache the token
                this.cachedToken = {
                    token: accessToken,
                    expiresAt: Date.now() + (expiresIn * 1000),
                };
                console.log('✅ Token cached, expires in', expiresIn, 'seconds');
                return accessToken;
            }
            throw new Error('No access token in response');
        }
        catch (error) {
            console.error('❌ Error fetching auth token:', ((_c = error.response) === null || _c === void 0 ? void 0 : _c.data) || error.message);
            throw new Error(`Failed to get PhonePe auth token: ${((_e = (_d = error.response) === null || _d === void 0 ? void 0 : _d.data) === null || _e === void 0 ? void 0 : _e.message) || error.message}`);
        }
    }
    /**
     * Create Order Token for Standard Checkout v2 (Mobile SDK)
     * Endpoint: POST https://api.phonepe.com/apis/pg/checkout/v2/sdk/order
     */
    async createPaymentOrder(paymentRequest) {
        var _a, _b, _c;
        try {
            // First get the auth token
            const authToken = await this.getAuthToken();
            // Payload per PhonePe Standard Checkout v2 SDK specification
            // Note: message field in paymentFlow is NOT required
            const payload = {
                merchantOrderId: paymentRequest.merchantOrderId,
                amount: paymentRequest.amount,
                expireAfter: 1200, // 20 minutes
                metaInfo: {
                    udf1: paymentRequest.userId || 'user',
                    udf2: paymentRequest.merchantOrderId,
                },
                paymentFlow: {
                    type: 'PG_CHECKOUT',
                },
            };
            // Use /checkout/v2/sdk/order for mobile SDK integration
            const orderUrl = `${this.config.apiUrl}/checkout/v2/sdk/order`;
            console.log('🚀 Creating order with PhonePe Standard Checkout v2 SDK...');
            console.log('📍 API URL:', orderUrl);
            console.log('🔐 Client ID:', this.config.clientId);
            console.log('📦 Payload:', JSON.stringify(payload));
            const response = await axios_1.default.post(orderUrl, payload, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `O-Bearer ${authToken}`,
                },
            });
            console.log('✅ Order created:', response.data);
            // Normalize PhonePe SDK response to match our expected format
            // SDK endpoint returns: { orderId, state, expireAt, token }
            // We normalize to: { success, data: { orderId, state, expireAt, token } }
            const rawData = response.data;
            const normalizedResponse = {
                success: true,
                code: 'SUCCESS',
                message: 'Order created successfully',
                data: {
                    orderId: rawData.orderId,
                    state: rawData.state,
                    expireAt: rawData.expireAt,
                    token: rawData.token,
                },
            };
            return normalizedResponse;
        }
        catch (error) {
            const status = (_a = error.response) === null || _a === void 0 ? void 0 : _a.status;
            const data = (_b = error.response) === null || _b === void 0 ? void 0 : _b.data;
            console.error('❌ Error creating order:', data || error.message);
            console.error('🔍 Error details:', status, (_c = error.response) === null || _c === void 0 ? void 0 : _c.statusText);
            const backendMessage = (data && (data.message || data.error || data.code)) ||
                error.message ||
                'Unknown error from PhonePe';
            throw new Error(`PhonePe createOrder failed (status ${status !== null && status !== void 0 ? status : 'N/A'}): ${backendMessage}`);
        }
    }
    /**
     * Verify payment status using Standard Checkout v2 Status API
     * Endpoint: GET /checkout/v2/order/{merchantOrderId}/status
     */
    async verifyPaymentStatus(merchantOrderId) {
        var _a;
        try {
            const authToken = await this.getAuthToken();
            console.log('🔍 Verifying payment status for:', merchantOrderId);
            const response = await axios_1.default.get(`${this.config.apiUrl}/checkout/v2/order/${merchantOrderId}/status`, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `O-Bearer ${authToken}`,
                },
            });
            console.log('✅ Payment status verified:', response.data);
            return response.data;
        }
        catch (error) {
            console.error('❌ Error verifying payment status:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
            throw new Error(`Failed to verify payment status: ${error.message}`);
        }
    }
    /**
     * Verify webhook signature from PhonePe Standard Checkout v2
     * Uses username (client_id) and password (client_secret) from Authorization header
     */
    verifyWebhookSignature(authHeader) {
        try {
            if (!authHeader || !authHeader.startsWith('Basic ')) {
                console.error('❌ Invalid auth header format');
                return false;
            }
            const base64Credentials = authHeader.substring(6);
            const credentials = Buffer.from(base64Credentials, 'base64').toString('utf-8');
            const [username, password] = credentials.split(':');
            const isValid = username === this.config.clientId && password === this.config.clientSecret;
            console.log('🔐 Webhook signature verification:', isValid ? 'VALID' : 'INVALID');
            return isValid;
        }
        catch (error) {
            console.error('❌ Error verifying webhook signature:', error);
            return false;
        }
    }
}
exports.PhonePeService = PhonePeService;
//# sourceMappingURL=phonepe.service.js.map