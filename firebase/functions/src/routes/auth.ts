import { Router } from 'express';
import * as admin from 'firebase-admin';

const router = Router();

// Verify ID token
router.post('/verify-token', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        error: 'ID token is required'
      });
    }

    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    return res.status(200).json({
      success: true,
      uid: decodedToken.uid,
      email: decodedToken.email
    });

  } catch (error) {
    console.error('Error verifying token:', error);
    return res.status(401).json({
      error: 'Invalid token',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Create custom token
router.post('/create-custom-token', async (req, res) => {
  try {
    const { uid, claims } = req.body;

    if (!uid) {
      return res.status(400).json({
        error: 'UID is required'
      });
    }

    const customToken = await admin.auth().createCustomToken(uid, claims);
    
    return res.status(200).json({
      success: true,
      customToken
    });

  } catch (error) {
    console.error('Error creating custom token:', error);
    return res.status(500).json({
      error: 'Failed to create custom token',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export const authRoutes = router;
