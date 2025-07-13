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
exports.notificationRoutes = void 0;
const express_1 = require("express");
const admin = __importStar(require("firebase-admin"));
const router = (0, express_1.Router)();
exports.notificationRoutes = router;
// Send FCM notification
router.post('/send-fcm', async (req, res) => {
    try {
        const { message } = req.body;
        if (!message || !message.token) {
            return res.status(400).json({
                error: 'Invalid message format or missing token'
            });
        }
        // Send the message using Firebase Admin SDK
        const response = await admin.messaging().send(message);
        console.log('Successfully sent FCM message:', response);
        return res.status(200).json({
            success: true,
            messageId: response
        });
    }
    catch (error) {
        console.error('Error sending FCM message:', error);
        // Handle specific FCM errors
        if (error instanceof Error) {
            if (error.message.includes('registration-token-not-registered')) {
                return res.status(400).json({
                    error: 'Invalid or expired FCM token',
                    code: 'INVALID_TOKEN'
                });
            }
            if (error.message.includes('invalid-argument')) {
                return res.status(400).json({
                    error: 'Invalid message format',
                    code: 'INVALID_MESSAGE'
                });
            }
        }
        return res.status(500).json({
            error: 'Failed to send FCM message',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Send bulk FCM notifications
router.post('/send-bulk-fcm', async (req, res) => {
    try {
        const { messages } = req.body;
        if (!messages || !Array.isArray(messages) || messages.length === 0) {
            return res.status(400).json({
                error: 'Invalid messages format or empty array'
            });
        }
        // Send messages in batches of 500 (FCM limit)
        const batchSize = 500;
        const results = [];
        for (let i = 0; i < messages.length; i += batchSize) {
            const batch = messages.slice(i, i + batchSize);
            try {
                const batchResponse = await admin.messaging().sendAll(batch);
                results.push(batchResponse);
                console.log(`Batch ${Math.floor(i / batchSize) + 1} sent:`, {
                    successCount: batchResponse.successCount,
                    failureCount: batchResponse.failureCount
                });
            }
            catch (batchError) {
                console.error(`Error sending batch ${Math.floor(i / batchSize) + 1}:`, batchError);
                results.push({
                    successCount: 0,
                    failureCount: batch.length,
                    responses: batch.map(() => ({ success: false, error: batchError }))
                });
            }
        }
        // Aggregate results
        const totalSuccess = results.reduce((sum, result) => sum + result.successCount, 0);
        const totalFailure = results.reduce((sum, result) => sum + result.failureCount, 0);
        return res.status(200).json({
            success: true,
            totalMessages: messages.length,
            successCount: totalSuccess,
            failureCount: totalFailure,
            results: results
        });
    }
    catch (error) {
        console.error('Error sending bulk FCM messages:', error);
        return res.status(500).json({
            error: 'Failed to send bulk FCM messages',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Send notification to topic
router.post('/send-to-topic', async (req, res) => {
    try {
        const { topic, notification, data } = req.body;
        if (!topic || !notification) {
            return res.status(400).json({
                error: 'Topic and notification are required'
            });
        }
        const message = {
            notification,
            data: data || {},
            topic: topic,
            android: {
                notification: {
                    icon: 'ic_notification',
                    color: '#1976D2',
                    sound: 'default',
                    channelId: 'mcq_notifications',
                },
                priority: 'high',
            },
            apns: {
                payload: {
                    aps: {
                        alert: notification,
                        badge: 1,
                        sound: 'default',
                    },
                },
            },
        };
        const response = await admin.messaging().send(message);
        console.log('Successfully sent topic message:', response);
        return res.status(200).json({
            success: true,
            messageId: response
        });
    }
    catch (error) {
        console.error('Error sending topic message:', error);
        return res.status(500).json({
            error: 'Failed to send topic message',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Subscribe user to topic
router.post('/subscribe-to-topic', async (req, res) => {
    try {
        const { tokens, topic } = req.body;
        if (!tokens || !topic) {
            return res.status(400).json({
                error: 'Tokens and topic are required'
            });
        }
        const tokensArray = Array.isArray(tokens) ? tokens : [tokens];
        const response = await admin.messaging().subscribeToTopic(tokensArray, topic);
        console.log('Successfully subscribed to topic:', response);
        return res.status(200).json({
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
            errors: response.errors
        });
    }
    catch (error) {
        console.error('Error subscribing to topic:', error);
        return res.status(500).json({
            error: 'Failed to subscribe to topic',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Unsubscribe user from topic
router.post('/unsubscribe-from-topic', async (req, res) => {
    try {
        const { tokens, topic } = req.body;
        if (!tokens || !topic) {
            return res.status(400).json({
                error: 'Tokens and topic are required'
            });
        }
        const tokensArray = Array.isArray(tokens) ? tokens : [tokens];
        const response = await admin.messaging().unsubscribeFromTopic(tokensArray, topic);
        console.log('Successfully unsubscribed from topic:', response);
        return res.status(200).json({
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
            errors: response.errors
        });
    }
    catch (error) {
        console.error('Error unsubscribing from topic:', error);
        return res.status(500).json({
            error: 'Failed to unsubscribe from topic',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
//# sourceMappingURL=notifications.js.map