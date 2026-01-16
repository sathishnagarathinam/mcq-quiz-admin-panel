import React, { useState } from 'react';
import { Box, Typography, Paper, Button, Alert, CircularProgress, LinearProgress } from '@mui/material';
import { Refresh, PlayArrow } from '@mui/icons-material';
import { db } from '../../config/firebase';
import { collection, getDocs, query, where, doc, updateDoc, serverTimestamp } from 'firebase/firestore';

const AnalyticsRefreshPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [result, setResult] = useState<string>('');
  const [error, setError] = useState<string>('');

  const refreshUserAnalytics = async () => {
    setLoading(true);
    setError('');
    setResult('');
    setProgress(0);

    try {
      console.log('🔄 Starting analytics refresh...');
      
      // Get all mobile users
      const usersRef = collection(db, 'mobile_users');
      const usersSnapshot = await getDocs(usersRef);
      const totalUsers = usersSnapshot.size;
      
      console.log(`📱 Found ${totalUsers} mobile users`);
      
      let processedUsers = 0;
      let updatedUsers = 0;
      let usersWithIssues = 0;
      const issues: string[] = [];

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        
        try {
          console.log(`📊 Processing user: ${userId} (${userData.name})`);
          
          // Get quiz attempts for this user
          const attemptsRef = collection(db, 'quiz_attempts');
          const attemptsQuery = query(attemptsRef, where('userId', '==', userId));
          const attemptsSnapshot = await getDocs(attemptsQuery);
          const quizAttempts = attemptsSnapshot.docs.map(doc => doc.data());
          
          // Calculate statistics from quiz attempts
          const totalQuizzes = quizAttempts.length;
          const completedQuizzes = quizAttempts.filter(attempt => attempt.isCompleted);
          
          let averageScore = 0;
          let totalCorrectAnswers = 0;
          let totalQuestionsAnswered = 0;
          let totalTimeSpent = 0;
          
          if (completedQuizzes.length > 0) {
            // Calculate average score
            const totalScore = completedQuizzes.reduce((sum, attempt) => {
              const score = attempt.scorePercentage || attempt.score || 0;
              return sum + score;
            }, 0);
            averageScore = totalScore / completedQuizzes.length;
            
            // Calculate total correct answers and questions
            totalCorrectAnswers = completedQuizzes.reduce((sum, attempt) => {
              return sum + (attempt.correctAnswers || attempt.score || 0);
            }, 0);
            
            totalQuestionsAnswered = completedQuizzes.reduce((sum, attempt) => {
              return sum + (attempt.totalQuestions || 0);
            }, 0);
            
            // Calculate total time spent
            totalTimeSpent = completedQuizzes.reduce((sum, attempt) => {
              return sum + (attempt.timeSpent || 0);
            }, 0);
          }

          // Calculate current streak (consecutive completed quizzes)
          let currentStreak = 0;
          const sortedAttempts = completedQuizzes
            .sort((a, b) => {
              const dateA = a.completedAt?.toDate?.() || a.completedAt || new Date(0);
              const dateB = b.completedAt?.toDate?.() || b.completedAt || new Date(0);
              return new Date(dateB).getTime() - new Date(dateA).getTime();
            });

          for (const attempt of sortedAttempts) {
            if (attempt.isCompleted) {
              currentStreak++;
            } else {
              break;
            }
          }

          // Update user document with calculated statistics
          const userRef = doc(db, 'mobile_users', userId);
          await updateDoc(userRef, {
            quizzesTaken: totalQuizzes,
            totalScore: totalCorrectAnswers,
            averageScore: Math.round(averageScore * 10) / 10,
            stats: {
              totalQuizzes,
              totalScore: totalCorrectAnswers,
              averageScore: Math.round(averageScore * 10) / 10,
              currentStreak,
              longestStreak: currentStreak, // For now, set to current streak
              totalTimeSpent,
              totalQuestionsAnswered,
              totalCorrectAnswers,
            },
            lastLoginAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
          });

          console.log(`✅ Updated user ${userId}: ${totalQuizzes} quizzes, ${averageScore.toFixed(1)}% avg`);
          updatedUsers++;

        } catch (userError) {
          console.error(`❌ Error processing user ${userId}:`, userError);
          issues.push(`User ${userData.name || userId}: ${userError}`);
          usersWithIssues++;
        }

        processedUsers++;
        setProgress((processedUsers / totalUsers) * 100);
      }

      const resultMessage = `✅ Analytics refresh completed!

📊 Summary:
- Total users processed: ${processedUsers}
- Users updated successfully: ${updatedUsers}
- Users with issues: ${usersWithIssues}

${issues.length > 0 ? `\n⚠️ Issues encountered:\n${issues.join('\n')}` : ''}

All user statistics have been recalculated from their quiz attempts and updated in their user documents. The admin panel should now show correct statistics.`;

      setResult(resultMessage);
      console.log('✅ Analytics refresh completed successfully');

    } catch (error: any) {
      console.error('❌ Analytics refresh failed:', error);
      setError(error.message || 'Unknown error');
    } finally {
      setLoading(false);
      setProgress(100);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        🔄 Analytics Refresh Tool
      </Typography>
      
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          Refresh User Statistics
        </Typography>
        <Typography variant="body2" sx={{ mb: 2 }}>
          This tool will recalculate all user statistics from their quiz attempts and update 
          their user documents. This fixes the issue where users show 0 quizzes, N/A scores, 
          and missing streak data in the admin panel.
        </Typography>
        
        <Typography variant="body2" sx={{ mb: 3, color: 'text.secondary' }}>
          <strong>What this does:</strong><br/>
          • Fetches all quiz attempts for each user<br/>
          • Calculates total quizzes, average score, current streak<br/>
          • Updates user documents with correct statistics<br/>
          • Ensures admin panel shows real-time data
        </Typography>
        
        <Button 
          variant="contained" 
          onClick={refreshUserAnalytics}
          disabled={loading}
          startIcon={loading ? <CircularProgress size={20} /> : <PlayArrow />}
          sx={{ mb: 2 }}
        >
          {loading ? 'Refreshing Analytics...' : 'Start Analytics Refresh'}
        </Button>
        
        {loading && (
          <Box sx={{ mt: 2 }}>
            <Typography variant="body2" sx={{ mb: 1 }}>
              Progress: {Math.round(progress)}%
            </Typography>
            <LinearProgress variant="determinate" value={progress} />
          </Box>
        )}
        
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
      
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          ⚠️ Important Notes
        </Typography>
        <Typography variant="body2">
          • This operation may take a few minutes for large numbers of users<br/>
          • It's safe to run multiple times - it will recalculate from source data<br/>
          • After running this, check the Mobile User Management page to verify statistics<br/>
          • If issues persist, check the User-Quiz Mapping page for detailed diagnostics
        </Typography>
      </Paper>
    </Box>
  );
};

export default AnalyticsRefreshPage;
