import React, { useEffect, useState } from 'react';
import { Box, Typography, Paper, Alert, CircularProgress, Accordion, AccordionSummary, AccordionDetails } from '@mui/material';
import { ExpandMore } from '@mui/icons-material';
import { db } from '../../config/firebase';
import { collection, getDocs, query, limit } from 'firebase/firestore';

const DataStructureTestPage: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<any>(null);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    const checkDataStructure = async () => {
      try {
        console.log('🔍 Checking data structure...');
        
        const result: any = {
          mobileUsers: [],
          quizAttempts: [],
          userAnalytics: [],
          summary: {
            totalMobileUsers: 0,
            totalQuizAttempts: 0,
            totalUserAnalytics: 0,
            usersWithStats: 0,
            usersWithQuizzes: 0,
          }
        };

        // Check mobile_users collection
        try {
          const mobileUsersRef = collection(db, 'mobile_users');
          const mobileUsersQuery = query(mobileUsersRef, limit(5));
          const mobileUsersSnapshot = await getDocs(mobileUsersQuery);
          
          result.summary.totalMobileUsers = mobileUsersSnapshot.size;
          
          mobileUsersSnapshot.docs.forEach(doc => {
            const userData = doc.data();
            result.mobileUsers.push({
              id: doc.id,
              name: userData.name,
              email: userData.email,
              quizzesTaken: userData.quizzesTaken,
              averageScore: userData.averageScore,
              stats: userData.stats,
              hasStats: !!(userData.stats || userData.quizzesTaken),
              hasQuizzes: (userData.quizzesTaken || 0) > 0,
            });
            
            if (userData.stats || userData.quizzesTaken) {
              result.summary.usersWithStats++;
            }
            if ((userData.quizzesTaken || 0) > 0) {
              result.summary.usersWithQuizzes++;
            }
          });
        } catch (e) {
          console.error('Error fetching mobile users:', e);
        }

        // Check quiz_attempts collection
        try {
          const quizAttemptsRef = collection(db, 'quiz_attempts');
          const quizAttemptsQuery = query(quizAttemptsRef, limit(5));
          const quizAttemptsSnapshot = await getDocs(quizAttemptsQuery);
          
          result.summary.totalQuizAttempts = quizAttemptsSnapshot.size;
          
          quizAttemptsSnapshot.docs.forEach(doc => {
            const attemptData = doc.data();
            result.quizAttempts.push({
              id: doc.id,
              userId: attemptData.userId,
              examName: attemptData.examName,
              score: attemptData.score,
              totalQuestions: attemptData.totalQuestions,
              isCompleted: attemptData.isCompleted,
              scorePercentage: attemptData.scorePercentage,
              completedAt: attemptData.completedAt,
            });
          });
        } catch (e) {
          console.error('Error fetching quiz attempts:', e);
        }

        // Check user_analytics collection
        try {
          const userAnalyticsRef = collection(db, 'user_analytics');
          const userAnalyticsQuery = query(userAnalyticsRef, limit(5));
          const userAnalyticsSnapshot = await getDocs(userAnalyticsQuery);
          
          result.summary.totalUserAnalytics = userAnalyticsSnapshot.size;
          
          userAnalyticsSnapshot.docs.forEach(doc => {
            const analyticsData = doc.data();
            result.userAnalytics.push({
              userId: doc.id,
              statistics: analyticsData.statistics,
              performance: analyticsData.performance,
              lastUpdated: analyticsData.lastUpdated,
            });
          });
        } catch (e) {
          console.error('Error fetching user analytics:', e);
        }

        setData(result);
        console.log('✅ Data structure check complete:', result);
        
      } catch (error: any) {
        console.error('❌ Data structure check failed:', error);
        setError(error.message || 'Unknown error');
      } finally {
        setLoading(false);
      }
    };

    checkDataStructure();
  }, []);

  if (loading) {
    return (
      <Box sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
        <CircularProgress size={20} />
        <Typography>Checking data structure...</Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">Error: {error}</Alert>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        🔍 Data Structure Analysis
      </Typography>
      
      {/* Summary */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>📊 Summary</Typography>
        <Typography variant="body2">
          <strong>Mobile Users:</strong> {data.summary.totalMobileUsers} total, {data.summary.usersWithStats} with stats, {data.summary.usersWithQuizzes} with quizzes<br/>
          <strong>Quiz Attempts:</strong> {data.summary.totalQuizAttempts}<br/>
          <strong>User Analytics:</strong> {data.summary.totalUserAnalytics}
        </Typography>
      </Paper>

      {/* Mobile Users */}
      <Accordion>
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Typography variant="h6">📱 Mobile Users (Sample)</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body2" component="pre" sx={{ fontSize: '0.8rem', overflow: 'auto' }}>
            {JSON.stringify(data.mobileUsers, null, 2)}
          </Typography>
        </AccordionDetails>
      </Accordion>

      {/* Quiz Attempts */}
      <Accordion>
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Typography variant="h6">🎯 Quiz Attempts (Sample)</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body2" component="pre" sx={{ fontSize: '0.8rem', overflow: 'auto' }}>
            {JSON.stringify(data.quizAttempts, null, 2)}
          </Typography>
        </AccordionDetails>
      </Accordion>

      {/* User Analytics */}
      <Accordion>
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Typography variant="h6">📈 User Analytics (Sample)</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body2" component="pre" sx={{ fontSize: '0.8rem', overflow: 'auto' }}>
            {JSON.stringify(data.userAnalytics, null, 2)}
          </Typography>
        </AccordionDetails>
      </Accordion>
    </Box>
  );
};

export default DataStructureTestPage;
