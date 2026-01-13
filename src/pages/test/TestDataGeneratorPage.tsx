import React, { useState } from 'react';
import { Box, Typography, Paper, Button, Alert, CircularProgress } from '@mui/material';
import { db } from '../../config/firebase';
import { collection, addDoc, doc, setDoc, serverTimestamp } from 'firebase/firestore';

const TestDataGeneratorPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<string>('');
  const [error, setError] = useState<string>('');

  const generateTestData = async () => {
    setLoading(true);
    setError('');
    setResult('');

    try {
      console.log('🔧 Generating test data...');
      
      // Create a test user
      const testUserId = 'test-user-' + Date.now();
      const testUserData = {
        name: 'Test User',
        email: 'testuser@example.com',
        phoneNumber: '+91 9876543210',
        designation: 'MTS',
        officeName: 'Test Office',
        userType: 'mobile_user',
        role: 'user',
        emailVerified: true,
        profileComplete: true,
        isActive: true,
        quizzesTaken: 3,
        averageScore: 85.5,
        stats: {
          totalQuizzes: 3,
          totalScore: 256,
          averageScore: 85.5,
          currentStreak: 2,
          longestStreak: 3,
          totalTimeSpent: 1800,
        },
        preferences: {
          notifications: true,
          darkMode: false,
          language: 'en',
        },
        createdAt: serverTimestamp(),
        lastLoginAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };

      // Create user document
      await setDoc(doc(db, 'mobile_users', testUserId), testUserData);
      console.log('✅ Test user created:', testUserId);

      // Create quiz attempts
      const quizAttempts = [
        {
          userId: testUserId,
          examId: 'exam-1',
          examName: 'General Knowledge Quiz',
          examType: 'General Knowledge',
          score: 85,
          totalQuestions: 100,
          correctAnswers: 85,
          scorePercentage: 85.0,
          timeSpent: 600,
          isCompleted: true,
          status: 'completed',
          attemptedAt: serverTimestamp(),
          completedAt: serverTimestamp(),
          answers: {},
        },
        {
          userId: testUserId,
          examId: 'exam-2',
          examName: 'Postal Rules Quiz',
          examType: 'Postal Rules',
          score: 90,
          totalQuestions: 100,
          correctAnswers: 90,
          scorePercentage: 90.0,
          timeSpent: 720,
          isCompleted: true,
          status: 'completed',
          attemptedAt: serverTimestamp(),
          completedAt: serverTimestamp(),
          answers: {},
        },
        {
          userId: testUserId,
          examId: 'exam-3',
          examName: 'Current Affairs Quiz',
          examType: 'Current Affairs',
          score: 81,
          totalQuestions: 100,
          correctAnswers: 81,
          scorePercentage: 81.0,
          timeSpent: 480,
          isCompleted: true,
          status: 'completed',
          attemptedAt: serverTimestamp(),
          completedAt: serverTimestamp(),
          answers: {},
        },
      ];

      for (const attempt of quizAttempts) {
        await addDoc(collection(db, 'quiz_attempts'), attempt);
      }
      console.log('✅ Quiz attempts created');

      // Create user analytics
      const userAnalytics = {
        statistics: {
          totalQuizzesAttempted: 3,
          totalQuizzesCompleted: 3,
          totalQuestionsAnswered: 300,
          totalCorrectAnswers: 256,
          totalTimeSpent: 1800,
          currentStreak: 2,
          longestStreak: 3,
          lastQuizDate: serverTimestamp(),
        },
        performance: {
          bestScore: 90.0,
          averageScore: 85.5,
          worstScore: 81.0,
          bestTime: 480,
          averageTime: 600.0,
          categoryScores: {
            'General Knowledge': 85.0,
            'Postal Rules': 90.0,
            'Current Affairs': 81.0,
          },
          categoryAttempts: {
            'General Knowledge': 1,
            'Postal Rules': 1,
            'Current Affairs': 1,
          },
          recentScores: [
            {
              score: 81.0,
              date: serverTimestamp(),
              examType: 'Current Affairs',
              timeSpent: 480,
            },
            {
              score: 90.0,
              date: serverTimestamp(),
              examType: 'Postal Rules',
              timeSpent: 720,
            },
            {
              score: 85.0,
              date: serverTimestamp(),
              examType: 'General Knowledge',
              timeSpent: 600,
            },
          ],
        },
        activity: {
          loginCount: 5,
          lastLoginDate: serverTimestamp(),
          sessionsThisWeek: 3,
          sessionsThisMonth: 8,
          dailyActivity: {
            '2024-01-15': 1,
            '2024-01-16': 2,
            '2024-01-17': 1,
          },
          recentExamTypes: ['Current Affairs', 'Postal Rules', 'General Knowledge'],
          averageSessionDuration: 25.5,
        },
        progress: {
          currentLevel: 'Intermediate',
          levelProgress: 65.0,
          experiencePoints: 850,
          achievements: ['First Quiz', 'Score 80+', 'Three in a Row'],
          badges: {
            'quiz_master': true,
            'consistent_performer': true,
            'fast_learner': false,
          },
          rank: 15,
          improvementRate: 12.5,
        },
        lastUpdated: serverTimestamp(),
      };

      await setDoc(doc(db, 'user_analytics', testUserId), userAnalytics);
      console.log('✅ User analytics created');

      setResult(`✅ Test data generated successfully!
      
Test User ID: ${testUserId}
- Created user with 3 completed quizzes
- Average score: 85.5%
- Current streak: 2
- Quiz attempts: 3
- User analytics: Complete profile

You can now check the Mobile User Management page to see the test data.`);

    } catch (error: any) {
      console.error('❌ Error generating test data:', error);
      setError(error.message || 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        🧪 Test Data Generator
      </Typography>
      
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          Generate Test Mobile User Data
        </Typography>
        <Typography variant="body2" sx={{ mb: 2 }}>
          This will create a test user with quiz attempts and analytics data to verify 
          that the mobile user management system is working correctly.
        </Typography>
        
        <Button 
          variant="contained" 
          onClick={generateTestData}
          disabled={loading}
          sx={{ mb: 2 }}
        >
          {loading ? <CircularProgress size={20} sx={{ mr: 1 }} /> : null}
          Generate Test Data
        </Button>
        
        {error && (
          <Alert severity="error" sx={{ mt: 2 }}>
            {error}
          </Alert>
        )}
        
        {result && (
          <Alert severity="success" sx={{ mt: 2 }}>
            <Typography variant="body2" component="pre" sx={{ whiteSpace: 'pre-wrap' }}>
              {result}
            </Typography>
          </Alert>
        )}
      </Paper>
    </Box>
  );
};

export default TestDataGeneratorPage;
