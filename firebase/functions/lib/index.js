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
exports.updateAnalytics = exports.generateDailyChallenge = exports.onFeedbackResponse = exports.onQuestionCreate = exports.onQuizComplete = exports.onUserCreate = exports.api = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const compression_1 = __importDefault(require("compression"));
// Import routes
const auth_1 = require("./routes/auth");
const questions_1 = require("./routes/questions");
const quiz_1 = require("./routes/quiz");
const analytics_1 = require("./routes/analytics");
const users_1 = require("./routes/users");
const notifications_1 = require("./routes/notifications");
const fcm_cleanup_1 = require("./routes/fcm-cleanup");
const payments_1 = require("./routes/payments");
// Initialize Firebase Admin
admin.initializeApp();
// Initialize Express app
const app = (0, express_1.default)();
// Middleware
app.use((0, helmet_1.default)());
app.use((0, compression_1.default)());
app.use((0, cors_1.default)({ origin: true }));
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ extended: true }));
// Use routes
app.use('/auth', auth_1.authRoutes);
app.use('/questions', questions_1.questionRoutes);
app.use('/quiz', quiz_1.quizRoutes);
app.use('/analytics', analytics_1.analyticsRoutes);
app.use('/users', users_1.userRoutes);
app.use('/notifications', notifications_1.notificationRoutes);
app.use('/fcm-cleanup', fcm_cleanup_1.fcmCleanupRoutes);
app.use('/payments', payments_1.paymentRoutes);
// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});
// Error handling middleware
app.use((error, req, res, next) => {
    console.error('API Error:', error);
    res.status(error.status || 500).json({
        error: {
            message: error.message || 'Internal server error',
            code: error.code || 'INTERNAL_ERROR'
        }
    });
});
// Export the Express app as a Firebase Function
exports.api = functions.https.onRequest(app);
// Firestore Triggers
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
    try {
        const userDoc = {
            uid: user.uid,
            email: user.email || null,
            phoneNumber: user.phoneNumber || null,
            displayName: user.displayName || null,
            role: 'user',
            isActive: true,
            stats: {
                totalQuizzes: 0,
                totalScore: 0,
                averageScore: 0,
                currentStreak: 0,
                longestStreak: 0,
                totalTimeSpent: 0
            },
            preferences: {
                darkMode: false,
                notifications: true,
                language: 'en'
            },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        await admin.firestore().collection('users').doc(user.uid).set(userDoc);
        console.log(`User profile created for ${user.uid}`);
    }
    catch (error) {
        console.error('Error creating user profile:', error);
    }
});
exports.onQuizComplete = functions.firestore
    .document('quiz_results/{resultId}')
    .onCreate(async (snapshot, context) => {
    try {
        const result = snapshot.data();
        const userId = result.userId;
        // Update user stats
        const userRef = admin.firestore().collection('users').doc(userId);
        const userDoc = await userRef.get();
        if (userDoc.exists) {
            const userData = userDoc.data();
            const currentStats = userData.stats || {};
            const newStats = {
                totalQuizzes: (currentStats.totalQuizzes || 0) + 1,
                totalScore: (currentStats.totalScore || 0) + result.score,
                averageScore: ((currentStats.totalScore || 0) + result.score) / ((currentStats.totalQuizzes || 0) + 1),
                totalTimeSpent: (currentStats.totalTimeSpent || 0) + result.timeSpent
            };
            await userRef.update({
                stats: newStats,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            // Update leaderboard
            await updateLeaderboard(userId, result);
            // Check for achievements
            await checkAchievements(userId, newStats, result);
        }
    }
    catch (error) {
        console.error('Error processing quiz completion:', error);
    }
});
exports.onQuestionCreate = functions.firestore
    .document('questions/{questionId}')
    .onCreate(async (snapshot, context) => {
    try {
        const question = snapshot.data();
        // Update category question count
        if (question.category) {
            const categoryRef = admin.firestore().collection('categories').doc(question.category);
            await categoryRef.update({
                questionCount: admin.firestore.FieldValue.increment(1),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    }
    catch (error) {
        console.error('Error updating category count:', error);
    }
});
// Trigger when feedback is updated with admin response
exports.onFeedbackResponse = functions.firestore
    .document('feedback/{feedbackId}')
    .onUpdate(async (change, context) => {
    try {
        const beforeData = change.before.data();
        const afterData = change.after.data();
        // Check if admin response was added
        const wasResponded = !beforeData.adminResponse && afterData.adminResponse;
        const statusChanged = beforeData.status !== 'responded' && afterData.status === 'responded';
        if (wasResponded && statusChanged) {
            console.log(`Admin responded to feedback ${context.params.feedbackId}`);
            // Create notification for the user
            await createFeedbackResponseNotification(afterData, context.params.feedbackId);
        }
    }
    catch (error) {
        console.error('Error processing feedback response:', error);
    }
});
// Scheduled Functions
exports.generateDailyChallenge = functions.pubsub
    .schedule('0 6 * * *') // Every day at 6 AM
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
    try {
        const today = new Date().toISOString().split('T')[0];
        // Check if challenge already exists for today
        const existingChallenge = await admin.firestore()
            .collection('daily_challenges')
            .where('date', '==', today)
            .get();
        if (!existingChallenge.empty) {
            console.log('Daily challenge already exists for today');
            return;
        }
        // Get random questions from different categories
        const categories = ['general_knowledge', 'po_guide', 'volumes'];
        const selectedQuestions = [];
        for (const category of categories) {
            const questionsSnapshot = await admin.firestore()
                .collection('questions')
                .where('category', '==', category)
                .where('isActive', '==', true)
                .limit(2)
                .get();
            questionsSnapshot.docs.forEach(doc => {
                selectedQuestions.push(doc.id);
            });
        }
        if (selectedQuestions.length >= 5) {
            const challenge = {
                id: `challenge_${today}`,
                date: today,
                title: `Daily Challenge - ${new Date().toLocaleDateString('en-US', { weekday: 'long' })}`,
                description: 'Test your knowledge with today\'s mixed challenge',
                questionIds: selectedQuestions.slice(0, 5),
                category: 'mixed',
                difficulty: 'medium',
                timeLimit: 300,
                isActive: true,
                participants: 0,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours from now
            };
            await admin.firestore()
                .collection('daily_challenges')
                .doc(challenge.id)
                .set(challenge);
            console.log('Daily challenge created successfully');
            // Send push notification to all users
            await sendDailyChallengeNotification();
        }
    }
    catch (error) {
        console.error('Error generating daily challenge:', error);
    }
});
exports.updateAnalytics = functions.pubsub
    .schedule('0 1 * * *') // Every day at 1 AM
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
    try {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const dateStr = yesterday.toISOString().split('T')[0];
        // Calculate daily analytics
        const analytics = await calculateDailyAnalytics(dateStr);
        await admin.firestore()
            .collection('analytics')
            .doc(`daily_${dateStr}`)
            .set(Object.assign(Object.assign({}, analytics), { type: 'daily', date: dateStr, createdAt: admin.firestore.FieldValue.serverTimestamp() }));
        console.log('Daily analytics updated successfully');
    }
    catch (error) {
        console.error('Error updating analytics:', error);
    }
});
// Helper Functions
async function updateLeaderboard(userId, result) {
    const leaderboardRef = admin.firestore().collection('leaderboard').doc(userId);
    const leaderboardDoc = await leaderboardRef.get();
    if (leaderboardDoc.exists) {
        const data = leaderboardDoc.data();
        await leaderboardRef.update({
            totalScore: data.totalScore + result.score,
            totalQuizzes: data.totalQuizzes + 1,
            averageScore: (data.totalScore + result.score) / (data.totalQuizzes + 1),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
    }
    else {
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        const userData = userDoc.data();
        await leaderboardRef.set({
            userId,
            userName: userData.displayName || 'Anonymous',
            profileImageUrl: userData.profileImageUrl || null,
            totalScore: result.score,
            totalQuizzes: 1,
            averageScore: result.score,
            category: result.category,
            examPattern: result.examPattern,
            badges: [],
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            period: 'all_time'
        });
    }
}
async function checkAchievements(userId, stats, result) {
    const achievements = [];
    // Check for various achievements
    if (result.percentage === 100) {
        achievements.push('perfectionist');
    }
    if (result.averageTimePerQuestion < 30) {
        achievements.push('speed_demon');
    }
    if (stats.totalQuizzes >= 50) {
        achievements.push('knowledge_seeker');
    }
    // Update user achievements if any new ones
    if (achievements.length > 0) {
        const userRef = admin.firestore().collection('users').doc(userId);
        await userRef.update({
            [`achievements.${Date.now()}`]: achievements,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }
}
async function sendDailyChallengeNotification() {
    // Implementation for sending push notifications
    // This would use Firebase Cloud Messaging
    console.log('Sending daily challenge notifications...');
}
async function calculateDailyAnalytics(date) {
    const startOfDay = new Date(date + 'T00:00:00.000Z');
    const endOfDay = new Date(date + 'T23:59:59.999Z');
    // Get quiz results for the day
    const resultsSnapshot = await admin.firestore()
        .collection('quiz_results')
        .where('completedAt', '>=', startOfDay)
        .where('completedAt', '<=', endOfDay)
        .get();
    const results = resultsSnapshot.docs.map(doc => doc.data());
    return {
        totalQuizzes: results.length,
        averageScore: results.reduce((sum, r) => sum + r.score, 0) / results.length || 0,
        totalUsers: new Set(results.map(r => r.userId)).size,
        categoryStats: calculateCategoryStats(results),
        popularQuestions: calculatePopularQuestions(results)
    };
}
function calculateCategoryStats(results) {
    const categoryMap = new Map();
    results.forEach(result => {
        const category = result.category;
        if (!categoryMap.has(category)) {
            categoryMap.set(category, { attempts: 0, totalScore: 0 });
        }
        const stats = categoryMap.get(category);
        stats.attempts += 1;
        stats.totalScore += result.score;
    });
    return Array.from(categoryMap.entries()).map(([category, stats]) => ({
        category,
        attempts: stats.attempts,
        averageScore: stats.totalScore / stats.attempts
    }));
}
function calculatePopularQuestions(results) {
    const questionMap = new Map();
    results.forEach(result => {
        var _a;
        (_a = result.questionAnalysis) === null || _a === void 0 ? void 0 : _a.forEach((qa) => {
            if (!questionMap.has(qa.questionId)) {
                questionMap.set(qa.questionId, { attempts: 0, correctAttempts: 0 });
            }
            const stats = questionMap.get(qa.questionId);
            stats.attempts += 1;
            if (qa.isCorrect) {
                stats.correctAttempts += 1;
            }
        });
    });
    return Array.from(questionMap.entries()).map(([questionId, stats]) => ({
        questionId,
        attempts: stats.attempts,
        correctRate: stats.correctAttempts / stats.attempts
    }));
}
async function createFeedbackResponseNotification(feedbackData, feedbackId) {
    var _a;
    try {
        console.log(`Creating notification for feedback response: ${feedbackId}`);
        // Get user's FCM token
        const userDoc = await admin.firestore().collection('users').doc(feedbackData.userId).get();
        if (!userDoc.exists) {
            console.log(`User ${feedbackData.userId} not found`);
            return;
        }
        const userData = userDoc.data();
        // Create notification content
        const notificationData = {
            title: 'Admin Response to Your Feedback',
            body: `We've responded to your feedback about "${feedbackData.examName}". Check it out!`,
            imageUrl: null,
            actionUrl: `/feedback/${feedbackId}`,
            actionType: 'navigate',
            target: {
                type: 'specific_users',
                userIds: [feedbackData.userId]
            },
            status: 'sent',
            sentCount: 1,
            totalTargets: 1,
            createdBy: 'system',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            priority: 'normal',
            category: 'feedback_response',
            metadata: {
                feedbackId: feedbackId,
                examId: feedbackData.examId,
                examName: feedbackData.examName,
                adminResponse: ((_a = feedbackData.adminResponse) === null || _a === void 0 ? void 0 : _a.substring(0, 100)) + '...'
            }
        };
        // Save notification to Firestore
        const notificationRef = await admin.firestore()
            .collection('notifications')
            .add(notificationData);
        // Create notification recipient record
        const recipientData = {
            notificationId: notificationRef.id,
            userId: feedbackData.userId,
            status: 'sent',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
                feedbackId: feedbackId,
                examName: feedbackData.examName
            }
        };
        await admin.firestore()
            .collection('notification_recipients')
            .add(recipientData);
        // Send FCM notification if user has token
        if (userData.fcmToken) {
            const message = {
                token: userData.fcmToken,
                notification: {
                    title: notificationData.title,
                    body: notificationData.body,
                },
                data: {
                    type: 'feedback_response',
                    feedbackId: feedbackId,
                    examId: feedbackData.examId,
                    actionUrl: notificationData.actionUrl
                },
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
                            alert: {
                                title: notificationData.title,
                                body: notificationData.body
                            },
                            badge: 1,
                            sound: 'default',
                        },
                    },
                },
            };
            try {
                const response = await admin.messaging().send(message);
                console.log(`FCM notification sent successfully: ${response}`);
                // Update recipient status to delivered
                await admin.firestore()
                    .collection('notification_recipients')
                    .where('notificationId', '==', notificationRef.id)
                    .where('userId', '==', feedbackData.userId)
                    .get()
                    .then(snapshot => {
                    if (!snapshot.empty) {
                        snapshot.docs[0].ref.update({
                            status: 'delivered',
                            deliveredAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                    }
                });
            }
            catch (fcmError) {
                console.error('Error sending FCM notification:', fcmError);
                // Keep the notification record even if FCM fails
            }
        }
        else {
            console.log(`User ${feedbackData.userId} has no FCM token`);
        }
        console.log(`Feedback response notification created successfully for user ${feedbackData.userId}`);
    }
    catch (error) {
        console.error('Error creating feedback response notification:', error);
    }
}
//# sourceMappingURL=index.js.map