import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,

  Typography,
  Grid,
  Card,
  CardContent,
  Paper,
  CardActionArea,
  Avatar,
  CircularProgress,

} from '@mui/material';
import {
  Quiz as QuizIcon,
  Category as CategoryIcon,

  Analytics as AnalyticsIcon,
  CloudUpload as UploadIcon,
  Settings as SettingsIcon,
  School as SchoolIcon,
  CheckCircle as CheckCircleIcon,
  Assignment as AssignmentIcon,
  Campaign as CampaignIcon,
  LiveTv as LiveTvIcon,
  PhoneAndroid as MobileIcon,
  AdminPanelSettings as AdminIcon,
  Notifications as NotificationsIcon,
  People as PeopleIcon,
} from '@mui/icons-material';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../../config/firebase';
import { useAuth } from '../../contexts/AuthContext';
import UserManagement from '../../components/admin/UserManagement';

interface ExamStats {
  totalExams: number;
  activeExams: number;
  examsWithQuestions: number;
  totalQuestions: number;
}

const DashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  const [examStats, setExamStats] = useState<ExamStats>({
    totalExams: 0,
    activeExams: 0,
    examsWithQuestions: 0,
    totalQuestions: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchExamStats();
  }, []);

  const fetchExamStats = async () => {
    try {
      setLoading(true);
      const querySnapshot = await getDocs(collection(db, 'exams'));

      let totalExams = 0;
      let activeExams = 0;
      let examsWithQuestions = 0;
      let totalQuestions = 0;

      querySnapshot.forEach((doc) => {
        const data = doc.data();
        totalExams++;

        if (data.isActive) {
          activeExams++;
        }

        const questions = data.questions || [];
        if (questions.length > 0) {
          examsWithQuestions++;
          totalQuestions += questions.length;
        }
      });

      setExamStats({
        totalExams,
        activeExams,
        examsWithQuestions,
        totalQuestions,
      });
    } catch (error) {
      console.error('Error fetching exam stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCardClick = (path: string) => {
    navigate(path);
  };

  // Navigation cards data
  const navigationCards = [
    {
      title: 'Question Management',
      description: 'Create, edit, and manage quiz questions',
      icon: <QuizIcon />,
      path: '/questions',
      color: '#6366F1',
    },
    {
      title: 'Category Management',
      description: 'Organize questions into categories',
      icon: <CategoryIcon />,
      path: '/categories',
      color: '#06B6D4',
    },
    {
      title: 'Mobile User Management',
      description: 'View and manage mobile app users, analytics, and performance',
      icon: <MobileIcon />,
      path: '/mobile-users',
      color: '#10B981',
    },
    {
      title: 'Mobile User Analytics',
      description: 'View mobile user performance, engagement, and quiz statistics',
      icon: <AnalyticsIcon />,
      path: '/analytics',
      color: '#F59E0B',
    },
    {
      title: 'Bulk Upload',
      description: 'Upload questions in bulk from files',
      icon: <UploadIcon />,
      path: '/bulk-upload',
      color: '#EF4444',
    },
    {
      title: 'Settings',
      description: 'Configure application settings',
      icon: <SettingsIcon />,
      path: '/settings',
      color: '#8B5CF6',
    },
    {
      title: 'Banner Management',
      description: 'Create and manage promotional banners for mobile app',
      icon: <CampaignIcon />,
      path: '/banner-management',
      color: '#E91E63',
    },
    {
      title: 'Live Test Management',
      description: 'Schedule and manage live tests for students',
      icon: <LiveTvIcon />,
      path: '/live-test-management',
      color: '#FF5722',
    },
    {
      title: 'Notification Management',
      description: 'Send notifications to mobile users by name, designation, or office',
      icon: <NotificationsIcon />,
      path: '/notifications',
      color: '#FF5722',
    },
  ];

  const testCards = [
    {
      title: 'Firebase Connection Test',
      description: 'Test Firebase services and configuration',
      icon: <SettingsIcon />,
      path: '/test-firebase',
      color: '#ff5722',
    },
    {
      title: 'Integration Test',
      description: 'Test banner and live test management integration',
      icon: <CampaignIcon />,
      path: '/integration-test',
      color: '#9C27B0',
    },
    {
      title: 'Notification Test',
      description: 'Test notification system functionality',
      icon: <NotificationsIcon />,
      path: '/notification-test',
      color: '#4CAF50',
    },
    {
      title: 'Firebase Connection Test',
      description: 'Test Firebase configuration and connectivity',
      icon: <SettingsIcon />,
      path: '/firebase-connection-test',
      color: '#FF9800',
    },
    {
      title: 'Create Test Users',
      description: 'Create test users for notification system testing',
      icon: <PeopleIcon />,
      path: '/create-test-users',
      color: '#2196F3',
    },
    {
      title: 'User Count Diagnostic',
      description: 'Check user counts and diagnose notification targeting',
      icon: <AnalyticsIcon />,
      path: '/user-count-diagnostic',
      color: '#607D8B',
    },
    {
      title: 'FCM Token Manager',
      description: 'Manage FCM tokens for push notifications',
      icon: <NotificationsIcon />,
      path: '/fcm-token-manager',
      color: '#FF5722',
    },
  ];

  // System Admin Cards (only for system admins)
  const systemAdminCards = [
    {
      title: 'Admin User Management',
      description: 'Manage admin users, approve registrations, and assign roles',
      icon: <AdminIcon />,
      path: '/user-management',
      color: '#e91e63',
    },
  ];

  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom>
        Admin Dashboard
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Welcome to the MCQ Quiz Admin Panel. Select a section below to get started.
      </Typography>

      {/* Exam Statistics */}
      <Typography variant="h5" component="h2" gutterBottom sx={{ mt: 2, mb: 3 }}>
        Exam Statistics
      </Typography>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Avatar sx={{ bgcolor: '#6366F1', mr: 2 }}>
                  <AssignmentIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6" component="div">
                    Total Exams
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    All created exams
                  </Typography>
                </Box>
              </Box>
              <Typography variant="h4" component="div" sx={{ fontWeight: 'bold' }}>
                {loading ? <CircularProgress size={24} /> : examStats.totalExams}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Avatar sx={{ bgcolor: '#10B981', mr: 2 }}>
                  <CheckCircleIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6" component="div">
                    Active Exams
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Available to students
                  </Typography>
                </Box>
              </Box>
              <Typography variant="h4" component="div" sx={{ fontWeight: 'bold' }}>
                {loading ? <CircularProgress size={24} /> : examStats.activeExams}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Avatar sx={{ bgcolor: '#06B6D4', mr: 2 }}>
                  <SchoolIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6" component="div">
                    Ready Exams
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    With questions added
                  </Typography>
                </Box>
              </Box>
              <Typography variant="h4" component="div" sx={{ fontWeight: 'bold' }}>
                {loading ? <CircularProgress size={24} /> : examStats.examsWithQuestions}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Avatar sx={{ bgcolor: '#F59E0B', mr: 2 }}>
                  <QuizIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6" component="div">
                    Total Questions
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Across all exams
                  </Typography>
                </Box>
              </Box>
              <Typography variant="h4" component="div" sx={{ fontWeight: 'bold' }}>
                {loading ? <CircularProgress size={24} /> : examStats.totalQuestions}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Navigation Cards */}
      <Typography variant="h5" component="h2" gutterBottom sx={{ mt: 4, mb: 3 }}>
        Quick Access
      </Typography>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        {navigationCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={4} key={index}>
            <Card
              sx={{
                height: '100%',
                transition: 'all 0.3s ease-in-out',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: 4,
                },
              }}
            >
              <CardActionArea
                onClick={() => handleCardClick(card.path)}
                sx={{ height: '100%', p: 3 }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Avatar
                    sx={{
                      bgcolor: card.color,
                      mr: 2,
                      width: 56,
                      height: 56,
                    }}
                  >
                    {card.icon}
                  </Avatar>
                  <Box>
                    <Typography variant="h6" component="h3" gutterBottom>
                      {card.title}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {card.description}
                    </Typography>
                  </Box>
                </Box>
              </CardActionArea>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Debug Info (temporary) */}
      {process.env.NODE_ENV === 'development' && (
        <Box sx={{ mb: 3, p: 2, bgcolor: 'grey.100', borderRadius: 1 }}>
          <Typography variant="caption" display="block">
            Debug Info: User Role = {adminUser?.role || 'undefined'} |
            Is System Admin = {adminUser?.role === 'system_admin' ? 'Yes' : 'No'}
          </Typography>
        </Box>
      )}

      {/* System Admin Tools */}
      {(adminUser?.role === 'system_admin' || process.env.NODE_ENV === 'development') && (
        <>
          <Typography variant="h5" component="h2" gutterBottom sx={{ mt: 4, mb: 3 }}>
            👑 System Administration
          </Typography>

          <Grid container spacing={3} sx={{ mb: 4 }}>
            {systemAdminCards.map((card, index) => (
              <Grid item xs={12} sm={6} md={4} key={index}>
                <Card
                  sx={{
                    height: '100%',
                    transition: 'all 0.3s ease-in-out',
                    border: '2px solid #e91e63',
                    '&:hover': {
                      transform: 'translateY(-4px)',
                      boxShadow: 4,
                      borderColor: '#ad1457',
                    },
                  }}
                >
                  <CardActionArea
                    onClick={() => handleCardClick(card.path)}
                    sx={{ height: '100%', p: 3 }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <Avatar
                        sx={{
                          bgcolor: card.color,
                          mr: 2,
                          width: 56,
                          height: 56,
                        }}
                      >
                        {card.icon}
                      </Avatar>
                      <Box>
                        <Typography variant="h6" component="h3" gutterBottom>
                          {card.title}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {card.description}
                        </Typography>
                      </Box>
                    </Box>
                  </CardActionArea>
                </Card>
              </Grid>
            ))}
          </Grid>
        </>
      )}

      {/* Test Tools */}
      <Typography variant="h5" component="h2" gutterBottom sx={{ mt: 4, mb: 3 }}>
        Development Tools
      </Typography>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        {testCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={4} key={index}>
            <Card
              sx={{
                height: '100%',
                transition: 'all 0.3s ease-in-out',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: 4,
                },
              }}
            >
              <CardActionArea
                onClick={() => handleCardClick(card.path)}
                sx={{ height: '100%', p: 3 }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Avatar
                    sx={{
                      bgcolor: card.color,
                      mr: 2,
                      width: 56,
                      height: 56,
                    }}
                  >
                    {card.icon}
                  </Avatar>
                  <Box>
                    <Typography variant="h6" component="h3" gutterBottom>
                      {card.title}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {card.description}
                    </Typography>
                  </Box>
                </Box>
              </CardActionArea>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* System Admin Section */}
      {adminUser?.role === 'system_admin' && (
        <>
          <Typography variant="h5" component="h2" gutterBottom sx={{ mt: 4, mb: 3 }}>
            🔧 System Administration
          </Typography>

          <Grid container spacing={3} sx={{ mb: 4 }}>
            <Grid item xs={12}>
              <UserManagement />
            </Grid>
          </Grid>
        </>
      )}

      {/* Stats Overview */}
      <Typography variant="h5" component="h2" gutterBottom sx={{ mt: 4, mb: 3 }}>
        Overview
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total Questions
              </Typography>
              <Typography variant="h4">
                1,234
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total Users
              </Typography>
              <Typography variant="h4">
                567
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Categories
              </Typography>
              <Typography variant="h4">
                12
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Quiz Sessions
              </Typography>
              <Typography variant="h4">
                2,345
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Recent Activity
            </Typography>
            <Typography color="textSecondary">
              Dashboard content will be implemented here...
            </Typography>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default DashboardPage;
