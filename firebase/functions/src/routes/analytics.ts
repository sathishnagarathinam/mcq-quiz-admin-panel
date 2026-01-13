import { Router } from 'express';
import * as admin from 'firebase-admin';

const router = Router();

// Get analytics data
router.get('/', async (req, res) => {
  try {
    const { type = 'daily', date } = req.query;
    
    let query: admin.firestore.Query = admin.firestore().collection('analytics');

    if (type) {
      query = query.where('type', '==', type);
    }

    if (date) {
      query = query.where('date', '==', date);
    }
    
    const snapshot = await query
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();
    
    const analytics = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.status(200).json({
      success: true,
      analytics
    });

  } catch (error) {
    console.error('Error fetching analytics:', error);
    res.status(500).json({
      error: 'Failed to fetch analytics',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export const analyticsRoutes = router;
