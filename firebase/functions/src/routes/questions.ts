import { Router } from 'express';
import * as admin from 'firebase-admin';

const router = Router();

// Get questions with pagination
router.get('/', async (req, res) => {
  try {
    const { limit = 10, offset = 0, category, difficulty } = req.query;
    
    let query: admin.firestore.Query = admin.firestore().collection('questions');

    if (category) {
      query = query.where('category', '==', category);
    }

    if (difficulty) {
      query = query.where('difficulty', '==', difficulty);
    }
    
    const snapshot = await query
      .orderBy('createdAt', 'desc')
      .limit(Number(limit))
      .offset(Number(offset))
      .get();
    
    const questions = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.status(200).json({
      success: true,
      questions,
      total: snapshot.size
    });

  } catch (error) {
    console.error('Error fetching questions:', error);
    res.status(500).json({
      error: 'Failed to fetch questions',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Create new question
router.post('/', async (req, res) => {
  try {
    const questionData = {
      ...req.body,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await admin.firestore().collection('questions').add(questionData);
    
    res.status(201).json({
      success: true,
      id: docRef.id
    });

  } catch (error) {
    console.error('Error creating question:', error);
    res.status(500).json({
      error: 'Failed to create question',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export { router as questionRoutes };
