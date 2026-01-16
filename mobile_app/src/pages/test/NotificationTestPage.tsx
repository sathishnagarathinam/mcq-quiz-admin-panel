import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  Alert,
  CircularProgress,
  Grid,
  Card,
  CardContent,
  Divider,
} from '@mui/material';
import {
  Send as SendIcon,
  People as PeopleIcon,
  Notifications as NotificationsIcon,
  ArrowBack as ArrowBackIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { NotificationService } from '../../services/notificationService';
import { useAuth } from '../../contexts/AuthContext';

const NotificationTestPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  
  const [loading, setLoading] = useState(false);
  const [testResults, setTestResults] = useState<string[]>([]);
  const [userCount, setUserCount] = useState(0);
  const [designations, setDesignations] = useState<string[]>([]);
  const [offices, setOffices] = useState<string[]>([]);

  useEffect(() => {
    loadTestData();
  }, []);

  const loadTestData = async () => {
    try {
      const [users, designationsList, officesList] = await Promise.all([
        NotificationService.getMobileUsers(),
        NotificationService.getDesignations(),
        NotificationService.getOfficeNames(),
      ]);
      
      setUserCount(users.length);
      setDesignations(designationsList);
      setOffices(officesList);
      
      addTestResult(`✅ Loaded ${users.length} mobile users`);
      addTestResult(`✅ Found ${designationsList.length} designations: ${designationsList.join(', ')}`);
      addTestResult(`✅ Found ${officesList.length} offices: ${officesList.slice(0, 3).join(', ')}${officesList.length > 3 ? '...' : ''}`);
    } catch (error) {
      console.error('Error loading test data:', error);
      addTestResult(`❌ Error loading test data: ${error}`);
    }
  };

  const addTestResult = (message: string) => {
    setTestResults(prev => [...prev, `${new Date().toLocaleTimeString()}: ${message}`]);
  };

  const sendTestNotification = async (targetType: 'all' | 'designation' | 'office') => {
    if (!adminUser) {
      toast.error('Admin user not found');
      return;
    }

    try {
      setLoading(true);
      addTestResult(`🚀 Starting test notification for ${targetType}...`);

      let target;
      let title;
      let body;

      switch (targetType) {
        case 'all':
          target = { type: 'all' as const };
          title = 'Test Notification - All Users';
          body = 'This is a test notification sent to all mobile users from the admin panel.';
          break;
        case 'designation':
          if (designations.length === 0) {
            addTestResult('❌ No designations available for testing');
            return;
          }
          target = { type: 'designation' as const, designation: designations[0] };
          title = `Test Notification - ${designations[0]}`;
          body = `This is a test notification sent to all users with designation: ${designations[0]}.`;
          break;
        case 'office':
          if (offices.length === 0) {
            addTestResult('❌ No offices available for testing');
            return;
          }
          target = { type: 'office' as const, officeName: offices[0] };
          title = `Test Notification - ${offices[0]}`;
          body = `This is a test notification sent to all users in office: ${offices[0]}.`;
          break;
      }

      const content = {
        title,
        body,
        actionType: 'general' as const,
      };

      // Create notification
      const notificationId = await NotificationService.createNotification(
        content,
        target,
        adminUser.uid,
        {
          priority: 'normal',
          category: 'general',
        }
      );

      addTestResult(`✅ Created notification with ID: ${notificationId}`);

      // Send notification
      await NotificationService.sendNotification(notificationId);
      addTestResult(`✅ Notification sent successfully!`);

      toast.success('Test notification sent successfully!');
    } catch (error) {
      console.error('Error sending test notification:', error);
      addTestResult(`❌ Error sending notification: ${error}`);
      toast.error('Failed to send test notification');
    } finally {
      setLoading(false);
    }
  };

  const clearResults = () => {
    setTestResults([]);
  };

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={() => navigate('/dashboard')}
          variant="outlined"
        >
          Back to Dashboard
        </Button>
        <Typography variant="h4" component="h1" sx={{ flexGrow: 1 }}>
          Notification System Test
        </Typography>
      </Box>

      <Grid container spacing={3}>
        {/* Test Controls */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Test Controls
            </Typography>

            {/* Stats */}
            <Grid container spacing={2} sx={{ mb: 3 }}>
              <Grid item xs={12} sm={4}>
                <Card>
                  <CardContent sx={{ textAlign: 'center', py: 2 }}>
                    <PeopleIcon sx={{ fontSize: 30, color: 'primary.main', mb: 1 }} />
                    <Typography variant="h5" color="primary.main">
                      {userCount}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Mobile Users
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} sm={4}>
                <Card>
                  <CardContent sx={{ textAlign: 'center', py: 2 }}>
                    <NotificationsIcon sx={{ fontSize: 30, color: 'success.main', mb: 1 }} />
                    <Typography variant="h5" color="success.main">
                      {designations.length}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Designations
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} sm={4}>
                <Card>
                  <CardContent sx={{ textAlign: 'center', py: 2 }}>
                    <SendIcon sx={{ fontSize: 30, color: 'warning.main', mb: 1 }} />
                    <Typography variant="h5" color="warning.main">
                      {offices.length}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Offices
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>

            <Divider sx={{ my: 2 }} />

            {/* Test Buttons */}
            <Typography variant="subtitle1" gutterBottom>
              Send Test Notifications
            </Typography>
            
            <Grid container spacing={2}>
              <Grid item xs={12} sm={4}>
                <Button
                  fullWidth
                  variant="contained"
                  onClick={() => sendTestNotification('all')}
                  disabled={loading || userCount === 0}
                  startIcon={loading ? <CircularProgressIndicator size={20} /> : <SendIcon />}
                >
                  All Users
                </Button>
              </Grid>
              <Grid item xs={12} sm={4}>
                <Button
                  fullWidth
                  variant="contained"
                  color="secondary"
                  onClick={() => sendTestNotification('designation')}
                  disabled={loading || designations.length === 0}
                  startIcon={loading ? <CircularProgressIndicator size={20} /> : <SendIcon />}
                >
                  By Designation
                </Button>
              </Grid>
              <Grid item xs={12} sm={4}>
                <Button
                  fullWidth
                  variant="contained"
                  color="success"
                  onClick={() => sendTestNotification('office')}
                  disabled={loading || offices.length === 0}
                  startIcon={loading ? <CircularProgressIndicator size={20} /> : <SendIcon />}
                >
                  By Office
                </Button>
              </Grid>
            </Grid>

            <Box sx={{ mt: 2 }}>
              <Button
                variant="outlined"
                onClick={clearResults}
                disabled={testResults.length === 0}
              >
                Clear Results
              </Button>
            </Box>
          </Paper>
        </Grid>

        {/* Test Results */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Test Results
            </Typography>

            {testResults.length === 0 ? (
              <Alert severity="info">
                No test results yet. Run a test to see results here.
              </Alert>
            ) : (
              <Box
                sx={{
                  maxHeight: 400,
                  overflow: 'auto',
                  bgcolor: 'grey.50',
                  p: 2,
                  borderRadius: 1,
                  fontFamily: 'monospace',
                  fontSize: '0.875rem',
                }}
              >
                {testResults.map((result, index) => (
                  <Box key={index} sx={{ mb: 1 }}>
                    {result}
                  </Box>
                ))}
              </Box>
            )}
          </Paper>
        </Grid>
      </Grid>

      {/* Instructions */}
      <Paper sx={{ p: 3, mt: 3 }}>
        <Typography variant="h6" gutterBottom>
          Testing Instructions
        </Typography>
        <Typography variant="body2" paragraph>
          1. <strong>All Users:</strong> Sends a test notification to all active mobile users
        </Typography>
        <Typography variant="body2" paragraph>
          2. <strong>By Designation:</strong> Sends a test notification to users with the first available designation
        </Typography>
        <Typography variant="body2" paragraph>
          3. <strong>By Office:</strong> Sends a test notification to users in the first available office
        </Typography>
        <Typography variant="body2" paragraph>
          4. Check the mobile app's exam section notification icon to see if notifications appear
        </Typography>
        <Typography variant="body2">
          5. Monitor the test results panel for real-time feedback on the notification sending process
        </Typography>
      </Paper>
    </Box>
  );
};

// Helper component for CircularProgress in buttons
const CircularProgressIndicator: React.FC<{ size: number }> = ({ size }) => (
  <CircularProgress size={size} />
);

export default NotificationTestPage;
