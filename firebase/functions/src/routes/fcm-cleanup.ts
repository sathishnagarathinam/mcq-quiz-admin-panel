import { Router } from 'express';
import * as admin from 'firebase-admin';

const router = Router();

// Validate and report on FCM tokens
router.get('/validate-tokens', async (req, res) => {
  try {
    console.log('🔍 [FCM-CLEANUP] Starting FCM token validation...');

    const usersRef = admin.firestore().collection('mobile_users');
    const snapshot = await usersRef.get();

    let validTokens = 0;
    let invalidTestTokens = 0;
    let nullTokens = 0;
    const invalidTokenUsers: any[] = [];
    const validTokenUsers: any[] = [];

    for (const doc of snapshot.docs) {
      const userData = doc.data();
      const token = userData.fcmToken;
      const userName = userData.name || 'Unknown';

      if (!token) {
        nullTokens++;
      } else if (typeof token === 'string' && token.startsWith('test_fcm_token_')) {
        invalidTestTokens++;
        invalidTokenUsers.push({
          userId: doc.id,
          userName,
          token: token.substring(0, 30) + '...',
          type: 'test_token'
        });
      } else if (typeof token === 'string' && token.length > 100) {
        validTokens++;
        validTokenUsers.push({
          userId: doc.id,
          userName,
          token: token.substring(0, 30) + '...',
          type: 'real_token'
        });
      } else {
        invalidTestTokens++;
        invalidTokenUsers.push({
          userId: doc.id,
          userName,
          token: token.substring(0, 30) + '...',
          type: 'invalid_format'
        });
      }
    }

    console.log(`✅ [FCM-CLEANUP] Validation complete:`, {
      totalUsers: snapshot.docs.length,
      validTokens,
      invalidTestTokens,
      nullTokens
    });

    return res.status(200).json({
      success: true,
      summary: {
        totalUsers: snapshot.docs.length,
        validTokens,
        invalidTestTokens,
        nullTokens,
        validPercentage: ((validTokens / snapshot.docs.length) * 100).toFixed(1) + '%'
      },
      invalidTokenUsers: invalidTokenUsers.slice(0, 10),
      validTokenUsers: validTokenUsers.slice(0, 10),
      message: `Found ${validTokens} valid tokens and ${invalidTestTokens} invalid test tokens`
    });
  } catch (error) {
    console.error('❌ [FCM-CLEANUP] Error validating tokens:', error);
    return res.status(500).json({
      error: 'Failed to validate tokens',
      details: error instanceof Error ? error.message : String(error)
    });
  }
});

// Delete invalid test tokens
router.post('/cleanup-invalid-tokens', async (req, res) => {
  try {
    console.log('🧹 [FCM-CLEANUP] Starting cleanup of invalid test tokens...');

    const usersRef = admin.firestore().collection('mobile_users');
    const snapshot = await usersRef.get();

    let deletedCount = 0;
    const deletedUsers: any[] = [];

    for (const doc of snapshot.docs) {
      const userData = doc.data();
      const token = userData.fcmToken;

      if (token && typeof token === 'string' && token.startsWith('test_fcm_token_')) {
        await doc.ref.update({
          fcmToken: null,
          lastTokenUpdate: null,
          tokenCleanedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        deletedCount++;
        deletedUsers.push({
          userId: doc.id,
          userName: userData.name || 'Unknown',
          deletedToken: token.substring(0, 30) + '...'
        });

        console.log(`✅ [FCM-CLEANUP] Deleted invalid token for user: ${userData.name}`);
      }
    }

    console.log(`✅ [FCM-CLEANUP] Cleanup complete. Deleted ${deletedCount} invalid tokens`);

    return res.status(200).json({
      success: true,
      deletedCount,
      deletedUsers: deletedUsers.slice(0, 10),
      message: `Successfully deleted ${deletedCount} invalid test tokens. Users need to log in to generate real tokens.`
    });
  } catch (error) {
    console.error('❌ [FCM-CLEANUP] Error cleaning up tokens:', error);
    return res.status(500).json({
      error: 'Failed to cleanup tokens',
      details: error instanceof Error ? error.message : String(error)
    });
  }
});

export const fcmCleanupRoutes = router;

