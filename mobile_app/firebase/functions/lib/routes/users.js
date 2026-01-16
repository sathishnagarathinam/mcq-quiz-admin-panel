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
exports.userRoutes = void 0;
const express_1 = require("express");
const admin = __importStar(require("firebase-admin"));
const router = (0, express_1.Router)();
// Get users with pagination
router.get('/', async (req, res) => {
    try {
        const { limit = 10, offset = 0, role } = req.query;
        let query = admin.firestore().collection('users');
        if (role) {
            query = query.where('role', '==', role);
        }
        const snapshot = await query
            .orderBy('createdAt', 'desc')
            .limit(Number(limit))
            .offset(Number(offset))
            .get();
        const users = snapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
        res.status(200).json({
            success: true,
            users,
            total: snapshot.size
        });
    }
    catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({
            error: 'Failed to fetch users',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Update user
router.put('/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const updateData = Object.assign(Object.assign({}, req.body), { updatedAt: admin.firestore.FieldValue.serverTimestamp() });
        await admin.firestore().collection('users').doc(userId).update(updateData);
        res.status(200).json({
            success: true,
            message: 'User updated successfully'
        });
    }
    catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({
            error: 'Failed to update user',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
exports.userRoutes = router;
//# sourceMappingURL=users.js.map