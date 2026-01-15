import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,

  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Button,
  TextField,
  InputAdornment,
  IconButton,
  Tooltip,
  Avatar,
  LinearProgress,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  Badge,

} from '@mui/material';
import {
  Search,
  Refresh,
  Analytics,
  PhoneAndroid,
  TrendingUp,
  Quiz,
  Star,
  Schedule,
  Person,
  FiberManualRecord,
  ArrowBack,
  CurrencyRupee,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { collection, query, onSnapshot, orderBy, where, Unsubscribe } from 'firebase/firestore';
import { db } from '../../config/firebase';
import UserAnalyticsDialog from '../../components/admin/UserAnalyticsDialog';

interface QuizAttempt {
  id: string;
  userId: string;
  examId?: string;
  examCategory?: string;
  category?: string;
  totalQuestions: number;
  correctAnswers: number;
  scorePercentage: number;
  timeTaken: number;
  isCompleted: boolean;
  attemptedAt?: Date;
  completedAt?: Date;
}

interface MobileUser {
  id: string;
  name: string;
  email: string;
  phone?: string;
  designation: string;
  officeName: string;
  registeredAt: Date;
  lastLoginAt?: Date;
  isActive: boolean;
  totalQuizzes: number;
  averageScore: number;
  currentStreak: number;
  activityLevel: 'Very Active' | 'Active' | 'Moderate' | 'Inactive';
  userType?: string;
  emailVerified?: boolean;
  profileComplete?: boolean;
  totalPaidAmount?: number; // Sum of all paid quiz amounts
  paidQuizCount?: number; // Number of paid quizzes purchased
  recentActivity?: {
    lastQuizDate?: Date;
    lastQuizScore?: number;
    sessionsThisWeek: number;
  };
}

interface MobileUserStats {
  totalUsers: number;
  activeUsers: number;
  newUsersThisMonth: number;
  averageQuizzesPerUser: number;
  averageScore: number;
  topPerformers: MobileUser[];
  totalRevenue: number; // Total amount from paid quizzes
  totalPaidUsers: number; // Number of users who paid for quizzes
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`mobile-users-tabpanel-${index}`}
      aria-labelledby={`mobile-users-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const MobileUsersPage: React.FC = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState<MobileUser[]>([]);
  const [stats, setStats] = useState<MobileUserStats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [tabValue, setTabValue] = useState(0);
  const [selectedUser, setSelectedUser] = useState<MobileUser | null>(null);
  const [analyticsDialogOpen, setAnalyticsDialogOpen] = useState(false);
  const [filterDesignation, setFilterDesignation] = useState('');
  const [isRealTimeConnected, setIsRealTimeConnected] = useState(false);
  const [lastUpdateTime, setLastUpdateTime] = useState<Date | null>(null);
  const [recentActivities, setRecentActivities] = useState<QuizAttempt[]>([]);

  // Store quiz attempts for real-time user stats calculation
  const quizAttemptsRef = useRef<Map<string, QuizAttempt[]>>(new Map());
  // Store raw user data for combining with quiz attempts
  const rawUsersRef = useRef<Map<string, any>>(new Map());
  // Store paid orders for calculating total paid amount per user
  const paidOrdersRef = useRef<Map<string, { amount: number; count: number }>>(new Map());

  // Calculate user stats from quiz attempts
  const calculateUserStats = useCallback((userId: string, userData: any): {
    totalQuizzes: number;
    averageScore: number;
    currentStreak: number;
    activityLevel: 'Very Active' | 'Active' | 'Moderate' | 'Inactive';
    recentActivity?: MobileUser['recentActivity'];
  } => {
    const userAttempts = quizAttemptsRef.current.get(userId) || [];
    const completedAttempts = userAttempts.filter(a => a.isCompleted);

    // Use quiz attempts data if available, otherwise fallback to user document data
    const totalQuizzes = completedAttempts.length || userData.quizzesTaken || userData.stats?.totalQuizzes || 0;

    // Calculate average score from quiz attempts
    const averageScore = completedAttempts.length > 0
      ? completedAttempts.reduce((sum, a) => sum + (a.scorePercentage || 0), 0) / completedAttempts.length
      : userData.averageScore || userData.stats?.averageScore || 0;

    // Calculate streak
    const sortedAttempts = [...completedAttempts].sort((a, b) => {
      const dateA = a.completedAt || a.attemptedAt || new Date(0);
      const dateB = b.completedAt || b.attemptedAt || new Date(0);
      return dateB.getTime() - dateA.getTime();
    });

    let currentStreak = 0;
    let lastDateStr: string | null = null;

    for (const attempt of sortedAttempts) {
      const attemptDate = attempt.completedAt || attempt.attemptedAt;
      if (!attemptDate) continue;
      const dateStr = attemptDate.toDateString();

      if (!lastDateStr) {
        lastDateStr = dateStr;
        currentStreak = 1;
      } else if (dateStr === lastDateStr) {
        continue;
      } else {
        const lastDate = new Date(lastDateStr);
        const daysDiff = Math.floor((lastDate.getTime() - attemptDate.getTime()) / (1000 * 60 * 60 * 24));
        if (daysDiff === 1) {
          currentStreak++;
          lastDateStr = dateStr;
        } else {
          break;
        }
      }
    }

    // If no quiz attempts, use user document streak
    if (currentStreak === 0) {
      currentStreak = userData.stats?.currentStreak || 0;
    }

    // Calculate activity level based on last login and recent activity
    const lastLoginDate = userData.lastLoginAt?.toDate?.() || userData.lastLoginAt || userData.updatedAt?.toDate?.();
    const daysSinceLastLogin = lastLoginDate
      ? Math.floor((new Date().getTime() - new Date(lastLoginDate).getTime()) / (1000 * 60 * 60 * 24))
      : 999;

    // Calculate sessions this week
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const sessionsThisWeek = completedAttempts.filter(a => {
      const date = a.completedAt || a.attemptedAt;
      return date && date > oneWeekAgo;
    }).length;

    let activityLevel: 'Very Active' | 'Active' | 'Moderate' | 'Inactive' = 'Inactive';
    if (daysSinceLastLogin <= 1 && sessionsThisWeek >= 5) {
      activityLevel = 'Very Active';
    } else if (daysSinceLastLogin <= 3 && sessionsThisWeek >= 3) {
      activityLevel = 'Active';
    } else if (daysSinceLastLogin <= 7 && sessionsThisWeek >= 1) {
      activityLevel = 'Moderate';
    }

    // Get recent activity info
    const lastQuiz = sortedAttempts[0];
    const recentActivity: MobileUser['recentActivity'] = {
      lastQuizDate: lastQuiz?.completedAt || lastQuiz?.attemptedAt,
      lastQuizScore: lastQuiz?.scorePercentage,
      sessionsThisWeek,
    };

    return {
      totalQuizzes,
      averageScore: Math.round(averageScore * 10) / 10,
      currentStreak,
      activityLevel,
      recentActivity,
    };
  }, []);

  // Build users array from raw data and quiz attempts
  const buildUsersWithStats = useCallback(() => {
    const realUsers: MobileUser[] = [];

    rawUsersRef.current.forEach((userData, odocId) => {
      const userStats = calculateUserStats(odocId, userData);
      const lastLoginDate = userData.lastLoginAt?.toDate?.() || userData.lastLoginAt || userData.updatedAt?.toDate?.();

      // Get paid order data for this user
      const userPaymentData = paidOrdersRef.current.get(odocId) || { amount: 0, count: 0 };

      const user: MobileUser = {
        id: odocId,
        name: userData.name || 'Unknown User',
        email: userData.email || 'No email',
        phone: userData.phoneNumber || userData.phone || 'Not provided',
        designation: userData.designation || 'Not specified',
        officeName: userData.officeName || 'Not specified',
        registeredAt: userData.createdAt?.toDate?.() || new Date(),
        lastLoginAt: lastLoginDate ? new Date(lastLoginDate) : undefined,
        isActive: userData.isActive !== false,
        ...userStats,
        userType: userData.userType || 'mobile_user',
        emailVerified: userData.emailVerified || false,
        profileComplete: userData.profileComplete || false,
        totalPaidAmount: userPaymentData.amount,
        paidQuizCount: userPaymentData.count,
      };

      realUsers.push(user);
    });

    // Sort by last login (most recent first)
    realUsers.sort((a, b) => {
      const dateA = a.lastLoginAt?.getTime() || 0;
      const dateB = b.lastLoginAt?.getTime() || 0;
      return dateB - dateA;
    });

    setUsers(realUsers);
    setLastUpdateTime(new Date());

    // Update stats
    const currentMonth = new Date();
    const firstDayOfMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1);
    const newUsersThisMonth = realUsers.filter(u => u.registeredAt >= firstDayOfMonth).length;
    const totalQuizzes = realUsers.reduce((sum, u) => sum + u.totalQuizzes, 0);
    const averageQuizzesPerUser = realUsers.length > 0 ? totalQuizzes / realUsers.length : 0;
    const topPerformers = realUsers
      .filter(u => u.totalQuizzes > 0)
      .sort((a, b) => b.averageScore - a.averageScore)
      .slice(0, 5);

    // Calculate total revenue from paid orders
    let totalRevenue = 0;
    let totalPaidUsers = 0;
    paidOrdersRef.current.forEach((data) => {
      totalRevenue += data.amount;
      totalPaidUsers++;
    });

    const newStats = {
      totalUsers: realUsers.length,
      activeUsers: realUsers.filter(u => u.activityLevel !== 'Inactive').length,
      newUsersThisMonth,
      averageQuizzesPerUser: Math.round(averageQuizzesPerUser * 10) / 10,
      averageScore: realUsers.length > 0
        ? Math.round((realUsers.reduce((sum, u) => sum + u.averageScore, 0) / realUsers.length) * 10) / 10
        : 0,
      topPerformers,
      totalRevenue,
      totalPaidUsers
    };
    setStats(newStats);

    console.log(`✅ Built ${realUsers.length} users with real-time stats`);
  }, [calculateUserStats]);

  const setupRealtimeListeners = useCallback((): Unsubscribe[] => {
    console.log('🔍 Setting up comprehensive real-time listeners...');
    const unsubscribes: Unsubscribe[] = [];

    // 1. Real-time listener for mobile_users collection
    const mobileUsersRef = collection(db, 'mobile_users');
    const usersQuery = query(mobileUsersRef, orderBy('createdAt', 'desc'));

    const usersUnsubscribe = onSnapshot(usersQuery, (snapshot) => {
      console.log(`📡 Real-time users update: ${snapshot.docs.length} mobile users`);
      setIsRealTimeConnected(true);

      // Update raw users ref
      rawUsersRef.current.clear();
      snapshot.docs.forEach((doc) => {
        rawUsersRef.current.set(doc.id, doc.data());
      });

      // Rebuild users with current quiz attempts
      buildUsersWithStats();
      setLoading(false);
    }, (error) => {
      console.error('❌ Users listener error:', error);
      setError('Failed to load mobile users: ' + error.message);
      setIsRealTimeConnected(false);
      setLoading(false);
    });
    unsubscribes.push(usersUnsubscribe);

    // 2. Real-time listener for quiz_attempts collection
    const attemptsRef = collection(db, 'quiz_attempts');
    const attemptsQuery = query(attemptsRef, orderBy('attemptedAt', 'desc'));

    const attemptsUnsubscribe = onSnapshot(attemptsQuery, (snapshot) => {
      console.log(`📡 Real-time quiz attempts update: ${snapshot.docs.length} attempts`);

      // Group attempts by user
      quizAttemptsRef.current.clear();
      const recentList: QuizAttempt[] = [];

      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        const attempt: QuizAttempt = {
          id: doc.id,
          userId: data.userId || '',
          examId: data.examId,
          examCategory: data.examCategory,
          category: data.category,
          totalQuestions: data.totalQuestions || 0,
          correctAnswers: data.correctAnswers || 0,
          scorePercentage: data.scorePercentage || 0,
          timeTaken: data.timeTaken || 0,
          isCompleted: data.isCompleted || false,
          attemptedAt: data.attemptedAt?.toDate?.() || (data.attemptedAt ? new Date(data.attemptedAt) : undefined),
          completedAt: data.completedAt?.toDate?.() || (data.completedAt ? new Date(data.completedAt) : undefined),
        };

        // Add to user's attempts
        const userId = attempt.userId;
        if (userId) {
          if (!quizAttemptsRef.current.has(userId)) {
            quizAttemptsRef.current.set(userId, []);
          }
          quizAttemptsRef.current.get(userId)!.push(attempt);
        }

        // Track recent activities (last 10)
        if (recentList.length < 10) {
          recentList.push(attempt);
        }
      });

      setRecentActivities(recentList);

      // Rebuild users with updated quiz attempts
      if (rawUsersRef.current.size > 0) {
        buildUsersWithStats();
      }
    }, (error) => {
      console.error('❌ Quiz attempts listener error:', error);
    });
    unsubscribes.push(attemptsUnsubscribe);

    // 3. Real-time listener for paid orders (status = 'paid')
    const ordersRef = collection(db, 'orders');
    const paidOrdersQuery = query(ordersRef, where('status', '==', 'paid'));

    const ordersUnsubscribe = onSnapshot(paidOrdersQuery, (snapshot) => {
      console.log(`📡 Real-time paid orders update: ${snapshot.docs.length} paid orders`);

      // Group paid orders by user and sum amounts
      paidOrdersRef.current.clear();

      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        const userId = data.userId;
        const amount = data.amount || 0; // amount in rupees

        if (userId) {
          const existing = paidOrdersRef.current.get(userId) || { amount: 0, count: 0 };
          paidOrdersRef.current.set(userId, {
            amount: existing.amount + amount,
            count: existing.count + 1
          });
        }
      });

      console.log(`💰 Calculated paid amounts for ${paidOrdersRef.current.size} users`);

      // Rebuild users with updated payment data
      if (rawUsersRef.current.size > 0) {
        buildUsersWithStats();
      }
    }, (error) => {
      console.error('❌ Orders listener error:', error);
    });
    unsubscribes.push(ordersUnsubscribe);

    console.log('✅ All real-time listeners set up');
    return unsubscribes;
  }, [buildUsersWithStats]);

  useEffect(() => {
    // Set up real-time listeners for both mobile_users and quiz_attempts
    const unsubscribes = setupRealtimeListeners();

    // Cleanup function to unsubscribe when component unmounts
    return () => {
      unsubscribes.forEach((unsubscribe) => {
        unsubscribe();
      });
      console.log('🔌 Unsubscribed from all real-time listeners');
    };
  }, [setupRealtimeListeners]);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleViewAnalytics = (user: MobileUser) => {
    setSelectedUser(user);
    setAnalyticsDialogOpen(true);
  };

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.officeName.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesDesignation = !filterDesignation || user.designation === filterDesignation;
    return matchesSearch && matchesDesignation;
  });

  const getActivityColor = (level: string) => {
    switch (level) {
      case 'Very Active': return 'success';
      case 'Active': return 'primary';
      case 'Moderate': return 'warning';
      default: return 'error';
    }
  };

  const StatCard: React.FC<{
    title: string;
    value: string | number;
    subtitle?: string;
    icon: React.ReactNode;
    color?: string;
  }> = ({ title, value, subtitle, icon, color = 'primary' }) => (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
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
            <Typography variant="h4" component="div" fontWeight="bold">
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

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Button
            variant="outlined"
            startIcon={<ArrowBack />}
            onClick={() => navigate('/dashboard')}
            sx={{ minWidth: 'auto' }}
          >
            Back to Dashboard
          </Button>
          <Typography variant="h4" component="h1">
            📱 Mobile User Management
          </Typography>
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
                <FiberManualRecord sx={{ fontSize: 12, color: isRealTimeConnected ? 'success.main' : 'warning.main' }} />
              </Badge>
              <Typography variant="caption" color={isRealTimeConnected ? 'success.main' : 'warning.main'}>
                {isRealTimeConnected ? 'Live' : 'Connecting...'}
              </Typography>
            </Box>
          </Tooltip>
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          {lastUpdateTime && (
            <Typography variant="caption" color="text.secondary">
              Last updated: {lastUpdateTime.toLocaleTimeString()}
            </Typography>
          )}
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={() => {
              console.log('🔄 Manual refresh triggered');
              // The real-time listener automatically handles updates
              // This button provides visual feedback to the user
              buildUsersWithStats();
            }}
          >
            Refresh
          </Button>
        </Box>
      </Box>

      {/* Statistics Cards */}
      {stats && (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={2.4}>
            <StatCard
              title="Total Users"
              value={stats.totalUsers}
              icon={<Person />}
              color="primary"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <StatCard
              title="Active Users"
              value={stats.activeUsers}
              subtitle={`${((stats.activeUsers / stats.totalUsers) * 100).toFixed(1)}% active`}
              icon={<TrendingUp />}
              color="success"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <StatCard
              title="New This Month"
              value={stats.newUsersThisMonth}
              icon={<PhoneAndroid />}
              color="info"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <StatCard
              title="Avg Quizzes"
              value={stats.averageQuizzesPerUser}
              subtitle="per user"
              icon={<Quiz />}
              color="warning"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <StatCard
              title="Avg Score"
              value={`${stats.averageScore}%`}
              icon={<Star />}
              color="secondary"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <StatCard
              title="Total Revenue"
              value={`₹${stats.totalRevenue.toLocaleString('en-IN')}`}
              subtitle={`${stats.totalPaidUsers} paying users`}
              icon={<CurrencyRupee />}
              color="success"
            />
          </Grid>
        </Grid>
      )}

      {/* Tabs */}
      <Paper sx={{ width: '100%' }}>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={tabValue} onChange={handleTabChange}>
            <Tab label="All Users" />
            <Tab label="Top Performers" />
            <Tab label="Recent Activity" />
          </Tabs>
        </Box>

        <TabPanel value={tabValue} index={0}>
          {/* Search and Filters */}
          <Box sx={{ mb: 3 }}>
            <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', mb: 2 }}>
              <TextField
                placeholder="Search users..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Search />
                    </InputAdornment>
                  ),
                }}
                sx={{ flexGrow: 1 }}
              />
              <TextField
                select
                label="Designation"
                value={filterDesignation}
                onChange={(e) => setFilterDesignation(e.target.value)}
                SelectProps={{ native: true }}
                sx={{ minWidth: 150 }}
              >
                <option value="">All</option>
                <option value="GDS">GDS</option>
                <option value="MTS">MTS</option>
                <option value="Postman">Postman</option>
                <option value="PA">PA</option>
                <option value="Inspector">Inspector</option>
                <option value="Not specified">Not specified</option>
              </TextField>
            </Box>

            {/* Results Summary */}
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Typography variant="body2" color="text.secondary">
                Showing {filteredUsers.length} of {users.length} mobile users
                {searchTerm && ` matching "${searchTerm}"`}
                {filterDesignation && ` with designation "${filterDesignation}"`}
              </Typography>
              {(searchTerm || filterDesignation) && (
                <Button
                  size="small"
                  onClick={() => {
                    setSearchTerm('');
                    setFilterDesignation('');
                  }}
                >
                  Clear Filters
                </Button>
              )}
            </Box>
          </Box>

          {/* Users Table */}
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 300 }}>
              <CircularProgress />
              <Typography variant="body2" sx={{ ml: 2 }}>
                Loading mobile users...
              </Typography>
            </Box>
          ) : filteredUsers.length === 0 ? (
            <Box sx={{ textAlign: 'center', py: 8 }}>
              <PhoneAndroid sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h6" color="text.secondary" gutterBottom>
                No Mobile Users Found
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {users.length === 0
                  ? 'No mobile users have registered yet.'
                  : 'No users match your search criteria.'}
              </Typography>
            </Box>
          ) : (
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>User</TableCell>
                    <TableCell>Designation</TableCell>
                    <TableCell>Office</TableCell>
                    <TableCell>Activity</TableCell>
                    <TableCell>Quizzes</TableCell>
                    <TableCell>Avg Score</TableCell>
                    <TableCell>Streak</TableCell>
                    <TableCell>Paid Amount</TableCell>
                    <TableCell>Last Login</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredUsers.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <Avatar sx={{ mr: 2, bgcolor: 'primary.main' }}>
                            {user.name.charAt(0).toUpperCase()}
                          </Avatar>
                          <Box>
                            <Typography variant="body2" fontWeight="medium">
                              {user.name}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {user.email}
                            </Typography>
                            {user.phone && (
                              <Typography variant="caption" color="text.secondary" display="block">
                                {user.phone}
                              </Typography>
                            )}
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={user.designation}
                          size="small"
                          variant={user.designation === 'Not specified' ? 'outlined' : 'filled'}
                        />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {user.officeName}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={user.activityLevel}
                          color={getActivityColor(user.activityLevel) as any}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" fontWeight="medium">
                          {user.totalQuizzes}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" fontWeight="medium">
                          {user.averageScore > 0 ? `${user.averageScore}%` : 'N/A'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          {user.currentStreak > 0 ? (
                            <Chip
                              label={`${user.currentStreak} days`}
                              color="warning"
                              size="small"
                              icon={<Schedule />}
                            />
                          ) : (
                            <Typography variant="caption" color="text.secondary">
                              No streak
                            </Typography>
                          )}
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Tooltip title={user.paidQuizCount
                          ? `${user.paidQuizCount} quiz${user.paidQuizCount > 1 ? 'es' : ''} purchased`
                          : 'No paid quizzes'
                        }>
                          <Box>
                            {user.totalPaidAmount && user.totalPaidAmount > 0 ? (
                              <Chip
                                label={`₹${user.totalPaidAmount.toFixed(0)}`}
                                color="success"
                                size="small"
                                variant="outlined"
                              />
                            ) : (
                              <Typography variant="caption" color="text.secondary">
                                ₹0
                              </Typography>
                            )}
                          </Box>
                        </Tooltip>
                      </TableCell>
                      <TableCell>
                        <Tooltip title={user.lastLoginAt
                          ? new Date(user.lastLoginAt).toLocaleString('en-IN', {
                              timeZone: 'Asia/Kolkata',
                              dateStyle: 'full',
                              timeStyle: 'medium'
                            })
                          : 'Never logged in'
                        }>
                          <Typography variant="body2">
                            {user.lastLoginAt
                              ? new Date(user.lastLoginAt).toLocaleString('en-IN', {
                                  timeZone: 'Asia/Kolkata',
                                  day: '2-digit',
                                  month: '2-digit',
                                  year: 'numeric',
                                  hour: '2-digit',
                                  minute: '2-digit'
                                })
                              : 'Never'}
                          </Typography>
                        </Tooltip>
                      </TableCell>
                      <TableCell>
                        <Tooltip title="View Mobile User Analytics">
                          <IconButton
                            size="small"
                            onClick={() => handleViewAnalytics(user)}
                          >
                            <Analytics />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <Typography variant="h6" gutterBottom>
            🏆 Top Performers
          </Typography>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 200 }}>
              <CircularProgress />
            </Box>
          ) : stats?.topPerformers.length === 0 ? (
            <Box sx={{ textAlign: 'center', py: 8 }}>
              <Star sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h6" color="text.secondary" gutterBottom>
                No Top Performers Yet
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Top performers will appear here once mobile users start taking quizzes.
              </Typography>
            </Box>
          ) : (
            <Grid container spacing={3}>
              {stats?.topPerformers.map((user, index) => (
                <Grid item xs={12} md={4} key={user.id}>
                  <Card>
                    <CardContent>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                        <Avatar sx={{
                          mr: 2,
                          bgcolor: index === 0 ? '#FFD700' : index === 1 ? '#C0C0C0' : '#CD7F32',
                          color: 'white',
                          fontWeight: 'bold'
                        }}>
                          {index + 1}
                        </Avatar>
                        <Box>
                          <Typography variant="h6">{user.name}</Typography>
                          <Typography variant="body2" color="text.secondary">
                            {user.designation} - {user.officeName}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {user.email}
                          </Typography>
                        </Box>
                      </Box>
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="body2" color="text.secondary">
                          Average Score
                        </Typography>
                        <Typography variant="h4" color="primary.main">
                          {user.averageScore}%
                        </Typography>
                        <LinearProgress
                          variant="determinate"
                          value={user.averageScore}
                          sx={{ mt: 1 }}
                        />
                      </Box>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                        <Typography variant="body2">
                          Quizzes: {user.totalQuizzes}
                        </Typography>
                        <Typography variant="body2">
                          Streak: {user.currentStreak} days
                        </Typography>
                      </Box>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Chip
                          label={user.activityLevel}
                          color={getActivityColor(user.activityLevel) as any}
                          size="small"
                        />
                        <Button
                          size="small"
                          startIcon={<Analytics />}
                          onClick={() => handleViewAnalytics(user)}
                        >
                          View Details
                        </Button>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          )}
        </TabPanel>

        <TabPanel value={tabValue} index={2}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Typography variant="h6">
              📊 Recent Quiz Activity (Real-time)
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <FiberManualRecord sx={{ fontSize: 12, color: isRealTimeConnected ? 'success.main' : 'warning.main' }} />
              <Typography variant="caption" color={isRealTimeConnected ? 'success.main' : 'warning.main'}>
                {isRealTimeConnected ? 'Live updates active' : 'Connecting...'}
              </Typography>
            </Box>
          </Box>

          {recentActivities.length === 0 ? (
            <Alert severity="info" sx={{ mb: 3 }}>
              No recent quiz activity found. Activities will appear here in real-time when users take quizzes.
            </Alert>
          ) : (
            <TableContainer component={Paper}>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>User</TableCell>
                    <TableCell>Quiz Category</TableCell>
                    <TableCell align="center">Score</TableCell>
                    <TableCell align="center">Questions</TableCell>
                    <TableCell align="center">Time Taken</TableCell>
                    <TableCell>Completed At</TableCell>
                    <TableCell>Status</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {recentActivities.map((activity) => {
                    const user = users.find(u => u.id === activity.userId);
                    return (
                      <TableRow key={activity.id} hover>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Avatar sx={{ width: 32, height: 32, mr: 1, bgcolor: 'primary.main', fontSize: '0.875rem' }}>
                              {user?.name?.charAt(0).toUpperCase() || 'U'}
                            </Avatar>
                            <Box>
                              <Typography variant="body2" fontWeight="medium">
                                {user?.name || 'Unknown User'}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {user?.email || activity.userId}
                              </Typography>
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={activity.examCategory || activity.category || 'General'}
                            size="small"
                            variant="outlined"
                          />
                        </TableCell>
                        <TableCell align="center">
                          <Typography
                            variant="body2"
                            fontWeight="bold"
                            color={activity.scorePercentage >= 80 ? 'success.main' : activity.scorePercentage >= 60 ? 'warning.main' : 'error.main'}
                          >
                            {activity.scorePercentage.toFixed(1)}%
                          </Typography>
                        </TableCell>
                        <TableCell align="center">
                          <Typography variant="body2">
                            {activity.correctAnswers}/{activity.totalQuestions}
                          </Typography>
                        </TableCell>
                        <TableCell align="center">
                          <Typography variant="body2">
                            {Math.floor(activity.timeTaken / 60)}m {activity.timeTaken % 60}s
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {activity.completedAt
                              ? activity.completedAt.toLocaleDateString() + ' ' + activity.completedAt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                              : activity.attemptedAt
                                ? activity.attemptedAt.toLocaleDateString() + ' ' + activity.attemptedAt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                                : 'N/A'
                            }
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={activity.isCompleted ? 'Completed' : 'In Progress'}
                            size="small"
                            color={activity.isCompleted ? 'success' : 'warning'}
                          />
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </TableContainer>
          )}

          {/* Real-time Stats Summary */}
          <Card sx={{ mt: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                🔄 Real-time Connection Status
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={6} md={3}>
                  <Typography variant="body2" color="text.secondary">Connection Status</Typography>
                  <Chip
                    label={isRealTimeConnected ? 'Connected' : 'Disconnected'}
                    color={isRealTimeConnected ? 'success' : 'error'}
                    size="small"
                  />
                </Grid>
                <Grid item xs={6} md={3}>
                  <Typography variant="body2" color="text.secondary">Total Users Loaded</Typography>
                  <Typography variant="h6">{users.length}</Typography>
                </Grid>
                <Grid item xs={6} md={3}>
                  <Typography variant="body2" color="text.secondary">Quiz Attempts Tracked</Typography>
                  <Typography variant="h6">{recentActivities.length}</Typography>
                </Grid>
                <Grid item xs={6} md={3}>
                  <Typography variant="body2" color="text.secondary">Last Update</Typography>
                  <Typography variant="body2">
                    {lastUpdateTime ? lastUpdateTime.toLocaleTimeString() : 'Never'}
                  </Typography>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </TabPanel>
      </Paper>

      {/* Analytics Dialog */}
      {selectedUser && (
        <UserAnalyticsDialog
          open={analyticsDialogOpen}
          onClose={() => {
            setAnalyticsDialogOpen(false);
            setSelectedUser(null);
          }}
          userId={selectedUser.id}
          userName={selectedUser.name}
          userEmail={selectedUser.email}
        />
      )}
    </Box>
  );
};

export default MobileUsersPage;
