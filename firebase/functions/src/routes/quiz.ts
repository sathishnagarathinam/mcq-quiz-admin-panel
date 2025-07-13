import { Router } from 'express';
import * as admin from 'firebase-admin';

const router = Router();

// Get quiz results
router.get('/results', async (req, res) => {
  try {
    const { userId, limit = 10 } = req.query;
    
    let query: admin.firestore.Query = admin.firestore().collection('quiz_results');

    if (userId) {
      query = query.where('userId', '==', userId);
    }
    
    const snapshot = await query
      .orderBy('completedAt', 'desc')
      .limit(Number(limit))
      .get();
    
    const results = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.status(200).json({
      success: true,
      results
    });

  } catch (error) {
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
    const resultData = {
      ...req.body,
      completedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await admin.firestore().collection('quiz_results').add(resultData);
    
    res.status(201).json({
      success: true,
      id: docRef.id
    });

  } catch (error) {
    console.error('Error submitting quiz result:', error);
    res.status(500).json({
      error: 'Failed to submit quiz result',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export { router as quizRoutes };
