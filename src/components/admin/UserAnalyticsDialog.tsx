import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Grid,
  Card,
  CardContent,
  CardHeader,
  Chip,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  CircularProgress,
  Alert,
  Divider,
  Badge,
  Tooltip,
} from '@mui/material';
import {
  Quiz,
  Timer,
  Star,
  LocalFireDepartment,
  Person,
  FiberManualRecord,
  Sync,
} from '@mui/icons-material';
import { collection, query, where, onSnapshot, Unsubscribe } from 'firebase/firestore';
import { db } from '../../config/firebase';

interface UserAnalytics {
  userId: string;
  userName: string;
  userEmail: string;
  statistics: {
    totalQuizzesAttempted: number;
    totalQuizzesCompleted: number;
    totalQuestionsAnswered: number;
    totalCorrectAnswers: number;
    totalTimeSpent: number;
    currentStreak: number;
    longestStreak: number;
    lastQuizDate?: Date;
  };
  performance: {
    bestScore: number;
    averageScore: number;
    worstScore: number;
    bestTime: number;
    averageTime: number;
    categoryScores: Record<string, number>;
    recentScores: Array<{
      score: number;
      date: Date;
      examType: string;
      quizName: string;
      performance: string;
    }>;
  };
  activity: {
    loginCount: number;
    lastLoginDate?: Date;
    sessionsThisWeek: number;
    sessionsThisMonth: number;
    averageSessionDuration: number;
    activityLevel: string;
  };
  progress: {
    currentLevel: string;
    levelProgress: number;
    experiencePoints: number;
    achievements: string[];
    rank: number;
  };
}

interface UserAnalyticsDialogProps {
  open: boolean;
  onClose: () => void;
  userId: string;
  userName: string;
  userEmail: string;
}

const UserAnalyticsDialog: React.FC<UserAnalyticsDialogProps> = ({
  open,
  onClose,
  userId,
  userName,
  userEmail,
}) => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [analytics, setAnalytics] = useState<UserAnalytics | null>(null);
  const [isRealTimeConnected, setIsRealTimeConnected] = useState(false);
  const [lastUpdateTime, setLastUpdateTime] = useState<Date | null>(null);
  const unsubscribeRef = useRef<Unsubscribe | null>(null);

  // Calculate analytics from quiz attempts
  const calculateAnalyticsFromAttempts = useCallback((userAttempts: any[]): UserAnalytics => {
    console.log(`📋 Calculating analytics from ${userAttempts.length} quiz attempts for user ${userId}`);

    // Calculate statistics from real data
    const totalQuizzesAttempted = userAttempts.length;
    const completedAttempts = userAttempts.filter((attempt: any) => attempt.isCompleted);
    const totalQuizzesCompleted = completedAttempts.length;

    const totalQuestionsAnswered = completedAttempts.reduce((sum: number, attempt: any) => sum + (attempt.totalQuestions || 0), 0);
    const totalCorrectAnswers = completedAttempts.reduce((sum: number, attempt: any) => sum + (attempt.correctAnswers || 0), 0);
    const totalTimeSpent = completedAttempts.reduce((sum: number, attempt: any) => sum + (attempt.timeTaken || 0), 0);

    // Calculate scores
    const scores = completedAttempts.map((attempt: any) => attempt.scorePercentage || 0);
    const averageScore = scores.length > 0 ? scores.reduce((sum, score) => sum + score, 0) / scores.length : 0;
    const bestScore = scores.length > 0 ? Math.max(...scores) : 0;
    const worstScore = scores.length > 0 ? Math.min(...scores) : 0;

    // Calculate times
    const times = completedAttempts.map((attempt: any) => attempt.timeTaken || 0);
    const averageTime = times.length > 0 ? times.reduce((sum, time) => sum + time, 0) / times.length : 0;
    const bestTime = times.length > 0 ? Math.min(...times.filter(time => time > 0)) : 0;

    // Calculate streaks
    const sortedAttempts = completedAttempts
      .sort((a: any, b: any) => new Date(b.completedAt?.toDate?.() || b.completedAt).getTime() - new Date(a.completedAt?.toDate?.() || a.completedAt).getTime());

    let currentStreak = 0;
    let longestStreak = 0;
    let tempStreak = 0;
    let lastDate: string | null = null;

    for (const attempt of sortedAttempts) {
      const attemptDate = new Date(attempt.completedAt?.toDate?.() || attempt.completedAt);
      const dateString = attemptDate.toDateString();

      if (lastDate === null) {
        lastDate = dateString;
        currentStreak = 1;
        tempStreak = 1;
      } else if (lastDate === dateString) {
        continue;
      } else {
        const daysDiff = Math.floor((new Date(lastDate).getTime() - attemptDate.getTime()) / (1000 * 60 * 60 * 24));
        if (daysDiff === 1) {
          currentStreak++;
          tempStreak++;
          lastDate = dateString;
        } else {
          longestStreak = Math.max(longestStreak, tempStreak);
          tempStreak = 1;
          if (currentStreak === tempStreak - 1) {
            currentStreak = 0;
          }
          lastDate = dateString;
        }
      }
    }
    longestStreak = Math.max(longestStreak, tempStreak);

    // Calculate recent activity
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const oneMonthAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const sessionsThisWeek = completedAttempts.filter((attempt: any) => {
      const attemptDate = new Date(attempt.completedAt?.toDate?.() || attempt.completedAt);
      return attemptDate > oneWeekAgo;
    }).length;

    const sessionsThisMonth = completedAttempts.filter((attempt: any) => {
      const attemptDate = new Date(attempt.completedAt?.toDate?.() || attempt.completedAt);
      return attemptDate > oneMonthAgo;
    }).length;

    // Category performance
    const categoryStats: Record<string, number[]> = {};
    completedAttempts.forEach((attempt: any) => {
      const category = attempt.examCategory || attempt.category || 'Unknown';
      if (!categoryStats[category]) {
        categoryStats[category] = [];
      }
      categoryStats[category].push(attempt.scorePercentage || 0);
    });

    const categoryScores: Record<string, number> = {};
    Object.entries(categoryStats).forEach(([category, scores]) => {
      categoryScores[category] = scores.reduce((sum, score) => sum + score, 0) / scores.length;
    });

    // Recent scores (last 5) with enhanced data - synchronous for real-time updates
    const recentScores = sortedAttempts.slice(0, 5).map((attempt: any) => {
      const score = attempt.scorePercentage || 0;
      const quizName = attempt.examName || attempt.quizName || 'Quiz';
      const examType = attempt.examCategory || attempt.category || 'Quiz';

      // Calculate performance label
      const performance = score >= 90 ? 'Excellent' :
                        score >= 80 ? 'Very Good' :
                        score >= 70 ? 'Good' :
                        score >= 60 ? 'Average' :
                        score >= 50 ? 'Below Average' : 'Needs Improvement';

      return {
        score,
        date: new Date(attempt.completedAt?.toDate?.() || attempt.completedAt || new Date()),
        examType,
        quizName,
        performance
      };
    });

    // Activity level calculation
    let activityLevel: 'Very Active' | 'Active' | 'Moderate' | 'Inactive' = 'Inactive';
    if (sessionsThisWeek >= 5) {
      activityLevel = 'Very Active';
    } else if (sessionsThisWeek >= 3) {
      activityLevel = 'Active';
    } else if (sessionsThisWeek >= 1) {
      activityLevel = 'Moderate';
    }

    // Mock some fields that would require additional data
    const achievements = [];
    if (totalQuizzesCompleted >= 1) achievements.push('First Quiz');
    if (totalQuizzesCompleted >= 10) achievements.push('Quiz Master');
    if (currentStreak >= 7) achievements.push('Streak Master');
    if (bestScore >= 90) achievements.push('High Scorer');

    const realAnalytics: UserAnalytics = {
      userId,
      userName,
      userEmail,
      statistics: {
        totalQuizzesAttempted,
        totalQuizzesCompleted,
        totalQuestionsAnswered,
        totalCorrectAnswers,
        totalTimeSpent,
        currentStreak,
        longestStreak,
        lastQuizDate: sortedAttempts.length > 0 ? new Date(sortedAttempts[0].completedAt?.toDate?.() || sortedAttempts[0].completedAt) : undefined,
      },
      performance: {
        bestScore: Math.round(bestScore * 10) / 10,
        averageScore: Math.round(averageScore * 10) / 10,
        worstScore: Math.round(worstScore * 10) / 10,
        bestTime,
        averageTime: Math.round(averageTime),
        categoryScores,
        recentScores,
      },
      activity: {
        loginCount: 0, // Would need session tracking
        lastLoginDate: sortedAttempts.length > 0 ? new Date(sortedAttempts[0].completedAt?.toDate?.() || sortedAttempts[0].completedAt) : undefined,
        sessionsThisWeek,
        sessionsThisMonth,
        averageSessionDuration: Math.round(averageTime / 60 * 10) / 10, // Convert to minutes
        activityLevel,
      },
      progress: {
        currentLevel: totalQuizzesCompleted >= 50 ? 'Expert' : totalQuizzesCompleted >= 20 ? 'Advanced' : totalQuizzesCompleted >= 5 ? 'Intermediate' : 'Beginner',
        levelProgress: Math.min((totalQuizzesCompleted % 10) * 10, 100),
        experiencePoints: totalQuizzesCompleted * 50 + totalCorrectAnswers * 5,
        achievements,
        rank: 0, // Would need comparison with other users
      },
    };

    console.log('✅ Real user analytics calculated:', {
      userId,
      totalQuizzes: realAnalytics.statistics.totalQuizzesCompleted,
      averageScore: realAnalytics.performance.averageScore,
      activityLevel: realAnalytics.activity.activityLevel
    });

    return realAnalytics;
  }, [userId, userName, userEmail]);

  // Set up real-time listener for user's quiz attempts
  const setupRealtimeListener = useCallback(() => {
    if (!userId) return;

    console.log(`🔍 Setting up real-time analytics listener for user: ${userId}`);
    setLoading(true);
    setError(null);

    // Clean up previous listener
    if (unsubscribeRef.current) {
      unsubscribeRef.current();
    }

    const attemptsRef = collection(db, 'quiz_attempts');
    const userAttemptsQuery = query(attemptsRef, where('userId', '==', userId));

    const unsubscribe = onSnapshot(userAttemptsQuery, (snapshot) => {
      console.log(`📡 Real-time analytics update: ${snapshot.docs.length} attempts for user ${userId}`);
      setIsRealTimeConnected(true);
      setLastUpdateTime(new Date());

      const userAttempts = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      const calculatedAnalytics = calculateAnalyticsFromAttempts(userAttempts);
      setAnalytics(calculatedAnalytics);
      setLoading(false);
    }, (error) => {
      console.error('❌ Real-time analytics listener error:', error);
      setError('Failed to load user analytics: ' + error.message);
      setIsRealTimeConnected(false);
      setLoading(false);
    });

    unsubscribeRef.current = unsubscribe;
    return unsubscribe;
  }, [userId, calculateAnalyticsFromAttempts]);

  useEffect(() => {
    if (open && userId) {
      setupRealtimeListener();
    }

    // Cleanup on close or unmount
    return () => {
      if (unsubscribeRef.current) {
        unsubscribeRef.current();
        unsubscribeRef.current = null;
        console.log('🔌 Unsubscribed from user analytics listener');
      }
    };
  }, [open, userId, setupRealtimeListener]);

  const StatCard: React.FC<{
    title: string;
    value: string | number;
    subtitle?: string;
    icon: React.ReactNode;
    color?: string;
  }> = ({ title, value, subtitle, icon, color = 'primary' }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
          <Box
            sx={{
              p: 1,
              borderRadius: 1,
              backgroundColor: `${color}.light`,
              color: `${color}.contrastText`,
              mr: 2,
            }}
          >
            {icon}
          </Box>
          <Box>
            <Typography variant="h6" component="div" fontWeight="bold">
              {value}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {title}
            </Typography>
            {subtitle && (
              <Typography variant="caption" color="text.secondary">
                {subtitle}
              </Typography>
            )}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );

  const formatTime = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    }
    return `${minutes}m`;
  };

  const formatDuration = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes}m ${secs}s`;
  };

  const getActivityColor = (level: string): string => {
    switch (level) {
      case 'Very Active': return 'success';
      case 'Active': return 'primary';
      case 'Moderate': return 'warning';
      default: return 'error';
    }
  };

  if (loading) {
    return (
      <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
        <DialogContent>
          <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 200 }}>
            <CircularProgress />
          </Box>
        </DialogContent>
      </Dialog>
    );
  }

  if (error || !analytics) {
    return (
      <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
        <DialogTitle>User Analytics</DialogTitle>
        <DialogContent>
          <Alert severity="error">{error || 'No analytics data available'}</Alert>
        </DialogContent>
        <DialogActions>
          <Button onClick={onClose}>Close</Button>
        </DialogActions>
      </Dialog>
    );
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            <Person sx={{ mr: 1 }} />
            Mobile User Analytics - {analytics.userName}
          </Box>
          {/* Real-time status indicator */}
          <Tooltip title={isRealTimeConnected
            ? `Real-time updates active${lastUpdateTime ? ` - Last update: ${lastUpdateTime.toLocaleTimeString()}` : ''}`
            : 'Connecting to real-time updates...'
          }>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <Badge
                overlap="circular"
                badgeContent=""
                variant="dot"
                sx={{
                  '& .MuiBadge-badge': {
                    backgroundColor: isRealTimeConnected ? '#44b700' : '#ff9800',
                    color: isRealTimeConnected ? '#44b700' : '#ff9800',
                    boxShadow: `0 0 0 2px white`,
                    animation: isRealTimeConnected ? 'pulse 2s infinite' : 'none',
                    '@keyframes pulse': {
                      '0%': { transform: 'scale(1)' },
                      '50%': { transform: 'scale(1.2)' },
                      '100%': { transform: 'scale(1)' },
                    },
                  },
                }}
              >
                <Sync sx={{ fontSize: 16, color: isRealTimeConnected ? 'success.main' : 'warning.main' }} />
              </Badge>
              <Typography variant="caption" color={isRealTimeConnected ? 'success.main' : 'warning.main'}>
                {isRealTimeConnected ? 'Live' : 'Connecting...'}
              </Typography>
            </Box>
          </Tooltip>
        </Box>
        <Typography variant="body2" color="text.secondary">
          {analytics.userEmail}
          {lastUpdateTime && (
            <Typography component="span" variant="caption" sx={{ ml: 2 }}>
              • Last updated: {lastUpdateTime.toLocaleTimeString()}
            </Typography>
          )}
        </Typography>
      </DialogTitle>

      <DialogContent>
        <Box sx={{ mt: 2 }}>
          {/* Overview Stats */}
          <Typography variant="h6" gutterBottom>
            📊 Overview Statistics
          </Typography>
          <Grid container spacing={2} sx={{ mb: 3 }}>
            <Grid item xs={6} md={3}>
              <StatCard
                title="Quizzes Completed"
                value={analytics.statistics.totalQuizzesCompleted}
                subtitle={`${analytics.statistics.totalQuizzesAttempted} attempted`}
                icon={<Quiz />}
                color="primary"
              />
            </Grid>
            <Grid item xs={6} md={3}>
              <StatCard
                title="Average Score"
                value={`${analytics.performance.averageScore.toFixed(1)}%`}
                subtitle={`Best: ${analytics.performance.bestScore.toFixed(1)}%`}
                icon={<Star />}
                color="warning"
              />
            </Grid>
            <Grid item xs={6} md={3}>
              <StatCard
                title="Current Streak"
                value={analytics.statistics.currentStreak}
                subtitle={`Longest: ${analytics.statistics.longestStreak}`}
                icon={<LocalFireDepartment />}
                color="error"
              />
            </Grid>
            <Grid item xs={6} md={3}>
              <StatCard
                title="Total Time"
                value={formatTime(analytics.statistics.totalTimeSpent)}
                subtitle={`Avg: ${formatDuration(analytics.performance.averageTime)}`}
                icon={<Timer />}
                color="info"
              />
            </Grid>
          </Grid>

          <Divider sx={{ my: 3 }} />

          {/* Performance & Activity */}
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Card>
                <CardHeader title="🎯 Performance Metrics" />
                <CardContent>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="body2" color="text.secondary">
                      Accuracy Rate
                    </Typography>
                    <Typography variant="h6">
                      {((analytics.statistics.totalCorrectAnswers / analytics.statistics.totalQuestionsAnswered) * 100).toFixed(1)}%
                    </Typography>
                    <LinearProgress
                      variant="determinate"
                      value={(analytics.statistics.totalCorrectAnswers / analytics.statistics.totalQuestionsAnswered) * 100}
                      sx={{ mt: 1 }}
                    />
                  </Box>
                  
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="body2" color="text.secondary">
                      Completion Rate
                    </Typography>
                    <Typography variant="h6">
                      {((analytics.statistics.totalQuizzesCompleted / analytics.statistics.totalQuizzesAttempted) * 100).toFixed(1)}%
                    </Typography>
                    <LinearProgress
                      variant="determinate"
                      value={(analytics.statistics.totalQuizzesCompleted / analytics.statistics.totalQuizzesAttempted) * 100}
                      color="success"
                      sx={{ mt: 1 }}
                    />
                  </Box>

                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    Category Performance
                  </Typography>
                  {Object.entries(analytics.performance.categoryScores).map(([category, score]) => (
                    <Box key={category} sx={{ mb: 1 }}>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Typography variant="caption">{category}</Typography>
                        <Typography variant="caption">{score.toFixed(1)}%</Typography>
                      </Box>
                      <LinearProgress
                        variant="determinate"
                        value={score}
                        sx={{ height: 4 }}
                      />
                    </Box>
                  ))}
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={12} md={6}>
              <Card>
                <CardHeader title="⚡ Activity & Progress" />
                <CardContent>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="body2" color="text.secondary">
                      Activity Level
                    </Typography>
                    <Chip
                      label={analytics.activity.activityLevel}
                      color={getActivityColor(analytics.activity.activityLevel) as any}
                      sx={{ mt: 1 }}
                    />
                  </Box>

                  <Box sx={{ mb: 2 }}>
                    <Typography variant="body2" color="text.secondary">
                      Current Level: {analytics.progress.currentLevel}
                    </Typography>
                    <Typography variant="h6">
                      {analytics.progress.experiencePoints} XP
                    </Typography>
                    <LinearProgress
                      variant="determinate"
                      value={analytics.progress.levelProgress}
                      sx={{ mt: 1 }}
                    />
                    <Typography variant="caption" color="text.secondary">
                      {analytics.progress.levelProgress.toFixed(0)}% to next level
                    </Typography>
                  </Box>

                  <Box sx={{ mb: 2 }}>
                    <Typography variant="body2" color="text.secondary">
                      Global Rank
                    </Typography>
                    <Typography variant="h6">#{analytics.progress.rank}</Typography>
                  </Box>

                  <Box>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Recent Achievements
                    </Typography>
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                      {analytics.progress.achievements.slice(0, 4).map((achievement, index) => (
                        <Chip
                          key={index}
                          label={achievement}
                          size="small"
                          color="primary"
                          variant="outlined"
                        />
                      ))}
                    </Box>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          </Grid>

          <Divider sx={{ my: 3 }} />

          {/* Recent Activity */}
          <Typography variant="h6" gutterBottom>
            📈 Recent Quiz Performance
          </Typography>
          {analytics.performance.recentScores.length === 0 ? (
            <Box sx={{ textAlign: 'center', py: 4 }}>
              <Quiz sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h6" color="text.secondary" gutterBottom>
                No Recent Quiz Activity
              </Typography>
              <Typography variant="body2" color="text.secondary">
                This user hasn't taken any quizzes recently.
              </Typography>
            </Box>
          ) : (
            <TableContainer component={Paper} sx={{ maxHeight: 400 }}>
              <Table size="small" stickyHeader>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ fontWeight: 'bold' }}>Date</TableCell>
                    <TableCell sx={{ fontWeight: 'bold' }}>Quiz Name</TableCell>
                    <TableCell sx={{ fontWeight: 'bold' }}>Exam Type</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 'bold' }}>Score</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 'bold' }}>Performance</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {analytics.performance.recentScores.map((score, index) => (
                    <TableRow
                      key={index}
                      sx={{
                        '&:hover': { backgroundColor: 'action.hover' },
                        '&:nth-of-type(odd)': { backgroundColor: 'action.selected' }
                      }}
                    >
                      <TableCell>
                        <Typography variant="body2" fontWeight="medium">
                          {score.date.toLocaleDateString('en-IN', { timeZone: 'Asia/Kolkata' })}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {score.date.toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata', hour: '2-digit', minute: '2-digit' })}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" fontWeight="medium" sx={{ maxWidth: 200 }}>
                          {score.quizName}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={score.examType}
                          size="small"
                          variant="outlined"
                          color="primary"
                        />
                      </TableCell>
                      <TableCell align="right">
                        <Typography
                          variant="body2"
                          fontWeight="bold"
                          color={score.score >= 80 ? 'success.main' : score.score >= 60 ? 'warning.main' : 'error.main'}
                        >
                          {score.score}%
                        </Typography>
                      </TableCell>
                      <TableCell align="right">
                        <Chip
                          label={score.performance}
                          color={score.score >= 80 ? 'success' : score.score >= 60 ? 'warning' : 'error'}
                          size="small"
                          variant="filled"
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </Box>
      </DialogContent>
      
      <DialogActions>
        <Button onClick={onClose}>Close</Button>
      </DialogActions>
    </Dialog>
  );
};

export default UserAnalyticsDialog;
