import React, { useState, useEffect, useCallback } from 'react';
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

  ArrowBack,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { collection, getDocs, query, where, onSnapshot, orderBy } from 'firebase/firestore';
import { db } from '../../config/firebase';
import UserAnalyticsDialog from '../../components/admin/UserAnalyticsDialog';

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
}

interface MobileUserStats {
  totalUsers: number;
  activeUsers: number;
  newUsersThisMonth: number;
  averageQuizzesPerUser: number;
  averageScore: number;
  topPerformers: MobileUser[];
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
  const [debugInfo, setDebugInfo] = useState<{
    collectionsChecked: string[];
    documentsFound: number;
    sampleDocument: any;
    errors: string[];
  }>({
    collectionsChecked: [],
    documentsFound: 0,
    sampleDocument: null,
    errors: []
  });



  const debugFirestoreCollections = async () => {
    const possibleCollections = ['users', 'mobile_users', 'app_users', 'registered_users', 'user_profiles'];
    const debugResults = {
      collectionsChecked: [] as string[],
      documentsFound: 0,
      sampleDocument: null as any,
      errors: [] as string[]
    };

    for (const collectionName of possibleCollections) {
      try {
        console.log(`🔍 Checking collection: ${collectionName}`);
        const collectionRef = collection(db, collectionName);
        const snapshot = await getDocs(collectionRef);

        debugResults.collectionsChecked.push(collectionName);

        if (snapshot.docs.length > 0) {
          console.log(`✅ Found ${snapshot.docs.length} documents in ${collectionName}`);
          debugResults.documentsFound = snapshot.docs.length;
          debugResults.sampleDocument = {
            id: snapshot.docs[0].id,
            data: snapshot.docs[0].data(),
            collection: collectionName
          };

          // If we found users, use this collection
          return { collectionName, snapshot };
        } else {
          console.log(`📭 Collection ${collectionName} is empty`);
        }
      } catch (error) {
        console.log(`❌ Error accessing collection ${collectionName}:`, error);
        debugResults.errors.push(`${collectionName}: ${error}`);
      }
    }

    setDebugInfo(debugResults);
    return null;
  };

  const setupRealtimeListener = useCallback(() => {
    console.log('🔍 Setting up real-time listener for mobile users...');

    // Set up real-time listener for mobile_users collection
    const mobileUsersRef = collection(db, 'mobile_users');
    const q = query(mobileUsersRef, orderBy('createdAt', 'desc'));

    const unsubscribe = onSnapshot(q, (snapshot) => {
      console.log(`📡 Real-time update: ${snapshot.docs.length} mobile users found`);

      const realUsers: MobileUser[] = [];

      snapshot.docs.forEach((userDoc) => {
        const userData = userDoc.data();
        console.log(`👤 Processing user ${userDoc.id}:`, {
          name: userData.name,
          email: userData.email,
          userType: userData.userType,
          isActive: userData.isActive
        });

        // Extract statistics from user document (updated by mobile app)
        const totalQuizzes = userData.quizzesTaken || userData.stats?.totalQuizzes || 0;
        const averageScore = userData.averageScore || userData.stats?.averageScore || 0;
        const currentStreak = userData.stats?.currentStreak || 0;

        console.log(`📊 User ${userDoc.id} stats from document:`, {
          quizzesTaken: userData.quizzesTaken,
          averageScore: userData.averageScore,
          statsObject: userData.stats,
          calculatedTotalQuizzes: totalQuizzes,
          calculatedAverageScore: averageScore,
          calculatedCurrentStreak: currentStreak
        });

        // Calculate activity level
        const lastLoginDate = userData.lastLoginAt?.toDate() || userData.updatedAt?.toDate();
        const daysSinceLastLogin = lastLoginDate
          ? Math.floor((new Date().getTime() - lastLoginDate.getTime()) / (1000 * 60 * 60 * 24))
          : 999;

        let activityLevel: 'Very Active' | 'Active' | 'Moderate' | 'Inactive' = 'Inactive';
        if (daysSinceLastLogin <= 1 && totalQuizzes >= 5) {
          activityLevel = 'Very Active';
        } else if (daysSinceLastLogin <= 3 && totalQuizzes >= 3) {
          activityLevel = 'Active';
        } else if (daysSinceLastLogin <= 7 && totalQuizzes >= 1) {
          activityLevel = 'Moderate';
        }

        // Create user object with consistent data structure
        const user: MobileUser = {
          id: userDoc.id,
          name: userData.name || 'Unknown User',
          email: userData.email || 'No email',
          phone: userData.phoneNumber || userData.phone || 'Not provided',
          designation: userData.designation || 'Not specified',
          officeName: userData.officeName || 'Not specified',
          registeredAt: userData.createdAt?.toDate() || new Date(),
          lastLoginAt: lastLoginDate,
          isActive: userData.isActive !== false,
          totalQuizzes,
          averageScore: Math.round(averageScore * 10) / 10,
          currentStreak,
          activityLevel,
          userType: userData.userType || 'mobile_user',
          emailVerified: userData.emailVerified || false,
          profileComplete: userData.profileComplete || false,
        };

        realUsers.push(user);
      });

      console.log(`✅ Processed ${realUsers.length} mobile users`);
      setUsers(realUsers);
      setLoading(false);

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

      const stats = {
        totalUsers: realUsers.length,
        activeUsers: realUsers.filter(u => u.isActive).length,
        newUsersThisMonth,
        averageQuizzesPerUser: Math.round(averageQuizzesPerUser * 10) / 10,
        averageScore: realUsers.length > 0
          ? Math.round((realUsers.reduce((sum, u) => sum + u.averageScore, 0) / realUsers.length) * 10) / 10
          : 0,
        topPerformers
      };
      setStats(stats);
    }, (error) => {
      console.error('❌ Real-time listener error:', error);
      setError('Failed to load mobile users: ' + error.message);
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const loadMobileUsers = useCallback(async () => {
    try {
      setLoading(true);
      console.log('🔍 Starting comprehensive Firestore debugging...');

      // First, try to find which collection has user data
      const foundCollection = await debugFirestoreCollections();

      if (!foundCollection) {
        console.log('❌ No user collections found with data');
        throw new Error('No user collections found with data');
      }

      const { collectionName, snapshot } = foundCollection;
      console.log(`✅ Using collection: ${collectionName} with ${snapshot.docs.length} documents`);

      const realUsers: MobileUser[] = [];

      for (const userDoc of snapshot.docs) {
        const userData = userDoc.data();
        console.log(`👤 Processing user ${userDoc.id}:`, {
          name: userData.name || userData.displayName || userData.fullName,
          email: userData.email,
          phone: userData.phone || userData.phoneNumber,
          hasCreatedAt: !!userData.createdAt,
          hasDesignation: !!userData.designation,
          allFields: Object.keys(userData)
        });

        // Fetch user analytics for each user (for future use)
        try {
          const analyticsRef = collection(db, 'user_analytics');
          const analyticsQuery = query(analyticsRef, where('userId', '==', userDoc.id));
          const analyticsSnapshot = await getDocs(analyticsQuery);

          if (!analyticsSnapshot.empty) {
            // Analytics data available for future features
            console.log('Analytics found for user:', userDoc.id);
          }
        } catch (analyticsError) {
          console.log('No analytics found for user:', userDoc.id);
        }

        // Fetch quiz attempts for this user
        let quizAttempts: any[] = [];
        try {
          const attemptsRef = collection(db, 'quiz_attempts');
          const attemptsQuery = query(attemptsRef, where('userId', '==', userDoc.id));
          const attemptsSnapshot = await getDocs(attemptsQuery);
          quizAttempts = attemptsSnapshot.docs.map(doc => doc.data());
        } catch (attemptsError) {
          console.log('No quiz attempts found for user:', userDoc.id);
        }

        // Calculate statistics from quiz attempts
        const totalQuizzes = quizAttempts.length;
        const completedQuizzes = quizAttempts.filter(attempt => attempt.isCompleted);
        const averageScore = completedQuizzes.length > 0
          ? completedQuizzes.reduce((sum, attempt) => sum + (attempt.scorePercentage || 0), 0) / completedQuizzes.length
          : 0;

        // Calculate current streak
        const sortedAttempts = quizAttempts
          .filter(attempt => attempt.isCompleted)
          .sort((a, b) => new Date(b.completedAt?.toDate?.() || b.completedAt).getTime() - new Date(a.completedAt?.toDate?.() || a.completedAt).getTime());

        let currentStreak = 0;
        let lastDate = null;

        for (const attempt of sortedAttempts) {
          const attemptDate = new Date(attempt.completedAt?.toDate?.() || attempt.completedAt);
          const dateString = attemptDate.toDateString();

          if (lastDate === null) {
            lastDate = dateString;
            currentStreak = 1;
          } else if (lastDate === dateString) {
            // Same day, continue
            continue;
          } else {
            const daysDiff = Math.floor((new Date(lastDate).getTime() - attemptDate.getTime()) / (1000 * 60 * 60 * 24));
            if (daysDiff === 1) {
              currentStreak++;
              lastDate = dateString;
            } else {
              break;
            }
          }
        }

        // Determine activity level
        const lastLoginDate = userData.lastLoginAt?.toDate?.() || userData.lastLoginAt;
        const daysSinceLastLogin = lastLoginDate
          ? Math.floor((new Date().getTime() - new Date(lastLoginDate).getTime()) / (1000 * 60 * 60 * 24))
          : 999;

        let activityLevel: 'Very Active' | 'Active' | 'Moderate' | 'Inactive' = 'Inactive';
        if (daysSinceLastLogin <= 1 && totalQuizzes >= 5) {
          activityLevel = 'Very Active';
        } else if (daysSinceLastLogin <= 3 && totalQuizzes >= 3) {
          activityLevel = 'Active';
        } else if (daysSinceLastLogin <= 7 && totalQuizzes >= 1) {
          activityLevel = 'Moderate';
        }

        // Extract user data with flexible field names
        const extractedName = userData.name || userData.displayName || userData.fullName || userData.userName || 'Unknown User';
        const extractedEmail = userData.email || userData.emailAddress || 'No email';
        const extractedPhone = userData.phone || userData.phoneNumber || userData.mobile || '';
        const extractedDesignation = userData.designation || userData.role || userData.jobTitle || 'Not specified';
        const extractedOffice = userData.officeName || userData.office || userData.workplace || userData.location || 'Not specified';
        const extractedCreatedAt = userData.createdAt?.toDate?.() || userData.createdAt || userData.registeredAt?.toDate?.() || userData.registeredAt || new Date();

        const mobileUser: MobileUser = {
          id: userDoc.id,
          name: extractedName,
          email: extractedEmail,
          phone: extractedPhone,
          designation: extractedDesignation,
          officeName: extractedOffice,
          registeredAt: extractedCreatedAt,
          lastLoginAt: lastLoginDate,
          isActive: daysSinceLastLogin <= 7,
          totalQuizzes,
          averageScore: Math.round(averageScore * 10) / 10,
          currentStreak,
          activityLevel,
        };

        realUsers.push(mobileUser);
      }

      // Calculate real statistics
      const currentMonth = new Date().getMonth();
      const currentYear = new Date().getFullYear();

      const realStats: MobileUserStats = {
        totalUsers: realUsers.length,
        activeUsers: realUsers.filter(u => u.isActive).length,
        newUsersThisMonth: realUsers.filter(u => {
          const regDate = new Date(u.registeredAt);
          return regDate.getMonth() === currentMonth && regDate.getFullYear() === currentYear;
        }).length,
        averageQuizzesPerUser: realUsers.length > 0
          ? Math.round(realUsers.reduce((sum, u) => sum + u.totalQuizzes, 0) / realUsers.length)
          : 0,
        averageScore: realUsers.length > 0
          ? Math.round(realUsers.reduce((sum, u) => sum + u.averageScore, 0) / realUsers.length * 10) / 10
          : 0,
        topPerformers: realUsers
          .filter(u => u.totalQuizzes > 0) // Only users who have taken quizzes
          .sort((a, b) => b.averageScore - a.averageScore)
          .slice(0, 3),
      };

      // If no real users found, show some sample data for demonstration
      if (realUsers.length === 0) {
        console.log('⚠️ No users found in Firestore, showing sample data for demonstration');
        const sampleUsers: MobileUser[] = [
          {
            id: 'sample-1',
            name: 'Sample User 1',
            email: 'sample1@example.com',
            phone: '+91 9876543210',
            designation: 'GDS',
            officeName: 'Sample GPO',
            registeredAt: new Date('2024-01-15'),
            lastLoginAt: new Date('2024-01-20'),
            isActive: true,
            totalQuizzes: 5,
            averageScore: 78.5,
            currentStreak: 3,
            activityLevel: 'Active',
          },
          {
            id: 'sample-2',
            name: 'Sample User 2',
            email: 'sample2@example.com',
            phone: '+91 9876543211',
            designation: 'MTS',
            officeName: 'Sample Central',
            registeredAt: new Date('2024-01-10'),
            lastLoginAt: new Date('2024-01-19'),
            isActive: true,
            totalQuizzes: 8,
            averageScore: 82.3,
            currentStreak: 5,
            activityLevel: 'Very Active',
          }
        ];

        const sampleStats: MobileUserStats = {
          totalUsers: sampleUsers.length,
          activeUsers: sampleUsers.filter(u => u.isActive).length,
          newUsersThisMonth: 1,
          averageQuizzesPerUser: 6,
          averageScore: 80.4,
          topPerformers: sampleUsers.sort((a, b) => b.averageScore - a.averageScore),
        };

        setUsers(sampleUsers);
        setStats(sampleStats);
      } else {
        setUsers(realUsers);
        setStats(realStats);
      }

      console.log(`✅ Loaded ${realUsers.length} real users + ${realUsers.length === 0 ? 2 : 0} sample users`);
    } catch (error) {
      console.error('❌ Error loading mobile users:', error);

      // Show sample data on error for demonstration
      const fallbackUsers: MobileUser[] = [
        {
          id: 'fallback-1',
          name: 'Demo User (Firestore Error)',
          email: 'demo@example.com',
          phone: '+91 9999999999',
          designation: 'GDS',
          officeName: 'Demo Office',
          registeredAt: new Date(),
          lastLoginAt: new Date(),
          isActive: true,
          totalQuizzes: 3,
          averageScore: 75.0,
          currentStreak: 1,
          activityLevel: 'Active',
        }
      ];

      setUsers(fallbackUsers);
      setStats({
        totalUsers: 1,
        activeUsers: 1,
        newUsersThisMonth: 1,
        averageQuizzesPerUser: 3,
        averageScore: 75.0,
        topPerformers: fallbackUsers,
      });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    // Set up real-time listener
    const unsubscribe = setupRealtimeListener();

    // Cleanup function to unsubscribe when component unmounts
    return () => {
      if (unsubscribe) {
        unsubscribe();
        console.log('🔌 Unsubscribed from real-time listener');
      }
    };
  }, [setupRealtimeListener]);

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
        </Box>
        <Button
          variant="outlined"
          startIcon={<Refresh />}
          onClick={() => {
            console.log('🔄 Manual refresh triggered');
            // The real-time listener will automatically update the data
            // But we can also trigger a manual refresh if needed
            setLoading(true);
            setTimeout(() => setLoading(false), 1000);
          }}
        >
          Refresh
        </Button>
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
                        <Typography variant="body2">
                          {user.lastLoginAt
                            ? new Date(user.lastLoginAt).toLocaleDateString()
                            : 'Never'}
                        </Typography>
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
          <Typography variant="h6" gutterBottom>
            📊 Recent Activity & Debug Info
          </Typography>
          <Alert severity="info" sx={{ mb: 3 }}>
            Recent activity tracking will be implemented with real-time data from the mobile app.
          </Alert>

          {/* Debug Information */}
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                🔧 Debug Information
              </Typography>
              <Typography variant="body2" paragraph>
                <strong>Total Users Found:</strong> {users.length}
              </Typography>
              <Typography variant="body2" paragraph>
                <strong>Data Source:</strong> {users.length > 0 && users[0].id.startsWith('sample') ? 'Sample Data (No Firestore Users)' :
                                                users.length > 0 && users[0].id.startsWith('fallback') ? 'Fallback Data (Firestore Error)' :
                                                users.length > 0 ? 'Real Firestore Data' : 'No Data'}
              </Typography>

              {/* Debug Information */}
              {debugInfo.collectionsChecked.length > 0 && (
                <>
                  <Typography variant="body2" paragraph>
                    <strong>Collections Checked:</strong> {debugInfo.collectionsChecked.join(', ')}
                  </Typography>
                  <Typography variant="body2" paragraph>
                    <strong>Documents Found:</strong> {debugInfo.documentsFound}
                  </Typography>
                  {debugInfo.sampleDocument && (
                    <>
                      <Typography variant="body2" paragraph>
                        <strong>Sample Document from {debugInfo.sampleDocument.collection}:</strong>
                      </Typography>
                      <Box component="pre" sx={{
                        backgroundColor: 'grey.100',
                        p: 2,
                        borderRadius: 1,
                        fontSize: '0.75rem',
                        overflow: 'auto',
                        maxHeight: 200
                      }}>
                        {JSON.stringify(debugInfo.sampleDocument.data, null, 2)}
                      </Box>
                    </>
                  )}
                  {debugInfo.errors.length > 0 && (
                    <>
                      <Typography variant="body2" paragraph>
                        <strong>Errors:</strong>
                      </Typography>
                      <ul>
                        {debugInfo.errors.map((error, index) => (
                          <li key={index}><Typography variant="caption">{error}</Typography></li>
                        ))}
                      </ul>
                    </>
                  )}
                </>
              )}
              <Typography variant="body2" paragraph>
                <strong>Expected Firestore Collections:</strong>
              </Typography>
              <ul>
                <li><code>users</code> - Mobile app user profiles</li>
                <li><code>user_analytics</code> - User performance analytics</li>
                <li><code>quiz_attempts</code> - Individual quiz attempt records</li>
              </ul>
              <Typography variant="body2" paragraph>
                <strong>Expected User Document Fields:</strong>
              </Typography>
              <ul>
                <li><code>name</code> or <code>displayName</code> - User's name</li>
                <li><code>email</code> - User's email address</li>
                <li><code>phone</code> or <code>phoneNumber</code> - Phone number</li>
                <li><code>designation</code> - Job role (GDS, MTS, etc.)</li>
                <li><code>officeName</code> - Workplace</li>
                <li><code>createdAt</code> - Registration timestamp</li>
                <li><code>lastLoginAt</code> - Last login timestamp</li>
              </ul>
              <Alert severity="warning" sx={{ mt: 2 }}>
                If you're seeing sample/fallback data, it means either:
                <br />• No users exist in the Firestore 'users' collection
                <br />• There was an error connecting to Firestore
                <br />• The user documents don't have the expected field structure
                <br /><br />
                Check the browser console for detailed error messages.
              </Alert>
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
