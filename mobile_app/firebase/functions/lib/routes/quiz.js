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
exports.quizRoutes = void 0;
const express_1 = require("express");
const admin = __importStar(require("firebase-admin"));
const router = (0, express_1.Router)();
// Get quiz results
router.get('/results', async (req, res) => {
    try {
        const { userId, limit = 10 } = req.query;
        let query = admin.firestore().collection('quiz_results');
        if (userId) {
            query = query.where('userId', '==', userId);
        }
        const snapshot = await query
            .orderBy('completedAt', 'desc')
            .limit(Number(limit))
            .get();
        const results = snapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
        res.status(200).json({
            success: true,
            results
        });
    }
    catch (error) {
        console.error('Error fetching quiz results:', error);
        res.status(500).json({
            error: 'Failed to fetch quiz results',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Submit quiz result
router.post('/submit', async (req, res) => {
    try {
        const resultData = Object.assign(Object.assign({}, req.body), { completedAt: admin.firestore.FieldValue.serverTimestamp() });
        const docRef = await admin.firestore().collection('quiz_results').add(resultData);
        res.status(201).json({
            success: true,
            id: docRef.id
        });
    }
    catch (error) {
        console.error('Error submitting quiz result:', error);
        res.status(500).json({
            error: 'Failed to submit quiz result',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
exports.quizRoutes = router;
//# sourceMappingURL=quiz.js.map