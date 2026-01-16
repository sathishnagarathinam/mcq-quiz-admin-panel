import React, { useEffect, useState } from 'react';
import { Box, Typography, Paper, Alert, CircularProgress, Accordion, AccordionSummary, AccordionDetails, Button } from '@mui/material';
import { ExpandMore, Refresh } from '@mui/icons-material';
import { db } from '../../config/firebase';
import { collection, getDocs, query, where, orderBy, limit } from 'firebase/firestore';

interface UserQuizMapping {
  userId: string;
  userName: string;
  userEmail: string;
  quizAttempts: any[];
  userAnalytics: any;
  userDocument: any;
  hasStatistics: boolean;
  issuesFound: string[];
}

const UserQuizMappingTestPage: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [mappings, setMappings] = useState<UserQuizMapping[]>([]);
  const [error, setError] = useState<string>('');
  const [summary, setSummary] = useState<any>(null);

  const analyzeUserQuizMappings = async () => {
    setLoading(true);
    setError('');
    
    try {
      console.log('🔍 Analyzing user-quiz mappings...');
      
      const userMappings: UserQuizMapping[] = [];
      let totalUsers = 0;
      let usersWithQuizzes = 0;
      let usersWithAnalytics = 0;
      let usersWithStats = 0;

      // Get all mobile users
      const usersRef = collection(db, 'mobile_users');
      const usersSnapshot = await getDocs(usersRef);
      totalUsers = usersSnapshot.size;

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const userId = userDoc.id;
        const issues: string[] = [];

        console.log(`📱 Analyzing user: ${userId} (${userData.name})`);

        // Get quiz attempts for this user
        let quizAttempts: any[] = [];
        try {
          const attemptsRef = collection(db, 'quiz_attempts');
          const attemptsQuery = query(attemptsRef, where('userId', '==', userId));
          const attemptsSnapshot = await getDocs(attemptsQuery);
          quizAttempts = attemptsSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
          }));
          
          if (quizAttempts.length > 0) {
            usersWithQuizzes++;
          }
        } catch (e) {
          issues.push(`Failed to fetch quiz attempts: ${e}`);
        }

        // Get user analytics
        let userAnalytics: any = null;
        try {
          const analyticsRef = collection(db, 'user_analytics');
          const analyticsQuery = query(analyticsRef, where('__name__', '==', userId));
          const analyticsSnapshot = await getDocs(analyticsQuery);
          
          if (analyticsSnapshot.docs.length > 0) {
            userAnalytics = analyticsSnapshot.docs[0].data();
            usersWithAnalytics++;
          }
        } catch (e) {
          issues.push(`Failed to fetch user analytics: ${e}`);
        }

        // Check if user document has statistics
        const hasDocumentStats = !!(userData.quizzesTaken || userData.averageScore || userData.stats);
        if (hasDocumentStats) {
          usersWithStats++;
        }

        // Identify issues
        if (quizAttempts.length > 0 && !userAnalytics) {
          issues.push('Has quiz attempts but no user analytics');
        }
        
        if (quizAttempts.length > 0 && !hasDocumentStats) {
          issues.push('Has quiz attempts but no statistics in user document');
        }
        
        if (userAnalytics && !hasDocumentStats) {
          issues.push('Has user analytics but statistics not synced to user document');
        }

        const mapping: UserQuizMapping = {
          userId,
          userName: userData.name || 'Unknown',
          userEmail: userData.email || 'No email',
          quizAttempts,
          userAnalytics,
          userDocument: {
            quizzesTaken: userData.quizzesTaken,
            averageScore: userData.averageScore,
            stats: userData.stats,
          },
          hasStatistics: hasDocumentStats,
          issuesFound: issues,
        };

        userMappings.push(mapping);
      }

      setMappings(userMappings);
      setSummary({
        totalUsers,
        usersWithQuizzes,
        usersWithAnalytics,
        usersWithStats,
        usersWithIssues: userMappings.filter(m => m.issuesFound.length > 0).length,
      });

      console.log('✅ Analysis complete:', {
        totalUsers,
        usersWithQuizzes,
        usersWithAnalytics,
        usersWithStats,
      });

    } catch (error: any) {
      console.error('❌ Analysis failed:', error);
      setError(error.message || 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    analyzeUserQuizMappings();
  }, []);

  if (loading) {
    return (
      <Box sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
        <CircularProgress size={20} />
        <Typography>Analyzing user-quiz mappings...</Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">Error: {error}</Alert>
        <Button onClick={analyzeUserQuizMappings} sx={{ mt: 2 }}>
          Retry Analysis
        </Button>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4">
          🔍 User-Quiz Mapping Analysis
        </Typography>
        <Button 
          variant="outlined" 
          startIcon={<Refresh />}
          onClick={analyzeUserQuizMappings}
        >
          Refresh Analysis
        </Button>
      </Box>
      
      {/* Summary */}
      {summary && (
        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h6" gutterBottom>📊 Summary</Typography>
          <Typography variant="body2">
            <strong>Total Users:</strong> {summary.totalUsers}<br/>
            <strong>Users with Quiz Attempts:</strong> {summary.usersWithQuizzes}<br/>
            <strong>Users with Analytics:</strong> {summary.usersWithAnalytics}<br/>
            <strong>Users with Statistics in Document:</strong> {summary.usersWithStats}<br/>
            <strong>Users with Issues:</strong> {summary.usersWithIssues}
          </Typography>
        </Paper>
      )}

      {/* Issues Found */}
      {mappings.filter(m => m.issuesFound.length > 0).length > 0 && (
        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h6" gutterBottom color="error">⚠️ Issues Found</Typography>
          {mappings.filter(m => m.issuesFound.length > 0).map((mapping, index) => (
            <Box key={mapping.userId} sx={{ mb: 2 }}>
              <Typography variant="subtitle2" fontWeight="bold">
                {mapping.userName} ({mapping.userEmail})
              </Typography>
              <Typography variant="body2" color="error">
                • {mapping.issuesFound.join(' • ')}
              </Typography>
            </Box>
          ))}
        </Paper>
      )}

      {/* Detailed Mappings */}
      <Typography variant="h6" gutterBottom>👥 User Details</Typography>
      {mappings.map((mapping, index) => (
        <Accordion key={mapping.userId}>
          <AccordionSummary expandIcon={<ExpandMore />}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Typography variant="subtitle1">
                {mapping.userName} ({mapping.userEmail})
              </Typography>
              {mapping.issuesFound.length > 0 && (
                <Typography variant="caption" color="error" sx={{ fontWeight: 'bold' }}>
                  {mapping.issuesFound.length} issue(s)
                </Typography>
              )}
              {mapping.hasStatistics && (
                <Typography variant="caption" color="success.main" sx={{ fontWeight: 'bold' }}>
                  ✅ Has Stats
                </Typography>
              )}
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Typography variant="body2" component="pre" sx={{ fontSize: '0.8rem', overflow: 'auto' }}>
              {JSON.stringify({
                userId: mapping.userId,
                quizAttempts: mapping.quizAttempts.length,
                quizAttemptsDetails: mapping.quizAttempts.map(a => ({
                  id: a.id,
                  examName: a.examName,
                  score: a.score,
                  isCompleted: a.isCompleted,
                  completedAt: a.completedAt,
                })),
                userAnalytics: mapping.userAnalytics ? 'Present' : 'Missing',
                userDocument: mapping.userDocument,
                issues: mapping.issuesFound,
              }, null, 2)}
            </Typography>
          </AccordionDetails>
        </Accordion>
      ))}
    </Box>
  );
};

export default UserQuizMappingTestPage;
