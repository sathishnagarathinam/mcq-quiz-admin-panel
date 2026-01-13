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
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
} from '@mui/material';
import {
  CheckCircle as CheckIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  ArrowBack as ArrowBackIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { collection, getDocs, addDoc, deleteDoc, doc } from 'firebase/firestore';
import { db } from '../../config/firebase';
import { useAuth } from '../../contexts/AuthContext';

interface TestResult {
  name: string;
  status: 'success' | 'error' | 'warning';
  message: string;
  details?: string;
}

const FirebaseConnectionTestPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  
  const [loading, setLoading] = useState(false);
  const [testResults, setTestResults] = useState<TestResult[]>([]);

  useEffect(() => {
    runTests();
  }, []);

  const runTests = async () => {
    setLoading(true);
    setTestResults([]);
    
    const results: TestResult[] = [];

    // Test 1: Firebase Configuration
    try {
      const config = {
        apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
        authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
        projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
        storageBucket: process.env.REACT_APP_FIREBASE_STORAGE_BUCKET,
        messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID,
        appId: process.env.REACT_APP_FIREBASE_APP_ID,
      };

      const missingKeys = Object.entries(config).filter(([key, value]) => !value).map(([key]) => key);
      
      if (missingKeys.length === 0) {
        results.push({
          name: 'Firebase Configuration',
          status: 'success',
          message: 'All Firebase environment variables are set',
        });
      } else {
        results.push({
          name: 'Firebase Configuration',
          status: 'error',
          message: 'Missing Firebase environment variables',
          details: `Missing: ${missingKeys.join(', ')}`,
        });
      }
    } catch (error) {
      results.push({
        name: 'Firebase Configuration',
        status: 'error',
        message: 'Error checking Firebase configuration',
        details: String(error),
      });
    }

    // Test 2: Firestore Connection
    try {
      const testCollection = collection(db, 'test_connection');
      await getDocs(testCollection);
      results.push({
        name: 'Firestore Connection',
        status: 'success',
        message: 'Successfully connected to Firestore',
      });
    } catch (error) {
      results.push({
        name: 'Firestore Connection',
        status: 'error',
        message: 'Failed to connect to Firestore',
        details: String(error),
      });
    }

    // Test 3: Mobile Users Collection Access
    try {
      const mobileUsersRef = collection(db, 'mobile_users');
      const snapshot = await getDocs(mobileUsersRef);
      results.push({
        name: 'Mobile Users Collection',
        status: 'success',
        message: `Found ${snapshot.docs.length} mobile users in collection`,
        details: snapshot.docs.length === 0 ? 'No mobile users found - this might be why targeting fails' : undefined,
      });
    } catch (error) {
      results.push({
        name: 'Mobile Users Collection',
        status: 'error',
        message: 'Failed to access mobile_users collection',
        details: String(error),
      });
    }

    // Test 4: Notifications Collection Access
    try {
      const notificationsRef = collection(db, 'notifications');
      const snapshot = await getDocs(notificationsRef);
      results.push({
        name: 'Notifications Collection',
        status: 'success',
        message: `Found ${snapshot.docs.length} notifications in collection`,
      });
    } catch (error) {
      results.push({
        name: 'Notifications Collection',
        status: 'error',
        message: 'Failed to access notifications collection',
        details: String(error),
      });
    }

    // Test 5: Write Permission Test
    try {
      const testDoc = {
        test: true,
        timestamp: new Date(),
        createdBy: adminUser?.uid || 'test-user',
      };
      
      const docRef = await addDoc(collection(db, 'test_write'), testDoc);
      await deleteDoc(doc(db, 'test_write', docRef.id));
      
      results.push({
        name: 'Write Permissions',
        status: 'success',
        message: 'Successfully created and deleted test document',
      });
    } catch (error) {
      results.push({
        name: 'Write Permissions',
        status: 'error',
        message: 'Failed to write to Firestore',
        details: String(error),
      });
    }

    // Test 6: Admin User Check
    if (adminUser) {
      results.push({
        name: 'Admin User',
        status: 'success',
        message: `Logged in as: ${adminUser.name} (${adminUser.email})`,
      });
    } else {
      results.push({
        name: 'Admin User',
        status: 'error',
        message: 'No admin user found - this will cause notification sending to fail',
      });
    }

    setTestResults(results);
    setLoading(false);
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success':
        return <CheckIcon sx={{ color: 'success.main' }} />;
      case 'error':
        return <ErrorIcon sx={{ color: 'error.main' }} />;
      case 'warning':
        return <WarningIcon sx={{ color: 'warning.main' }} />;
      default:
        return <CheckIcon />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'success':
        return 'success.main';
      case 'error':
        return 'error.main';
      case 'warning':
        return 'warning.main';
      default:
        return 'text.primary';
    }
  };

  const hasErrors = testResults.some(result => result.status === 'error');
  const hasWarnings = testResults.some(result => result.status === 'warning');

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
          Firebase Connection Test
        </Typography>
        <Button
          startIcon={<RefreshIcon />}
          onClick={runTests}
          variant="contained"
          disabled={loading}
        >
          Run Tests Again
        </Button>
      </Box>

      {/* Overall Status */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <CheckIcon sx={{ fontSize: 40, color: 'success.main', mb: 1 }} />
              <Typography variant="h4" color="success.main">
                {testResults.filter(r => r.status === 'success').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Tests Passed
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <ErrorIcon sx={{ fontSize: 40, color: 'error.main', mb: 1 }} />
              <Typography variant="h4" color="error.main">
                {testResults.filter(r => r.status === 'error').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Tests Failed
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <WarningIcon sx={{ fontSize: 40, color: 'warning.main', mb: 1 }} />
              <Typography variant="h4" color="warning.main">
                {testResults.filter(r => r.status === 'warning').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Warnings
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Status Alert */}
      {hasErrors && (
        <Alert severity="error" sx={{ mb: 3 }}>
          <strong>Critical Issues Found:</strong> Your notification system will not work properly until these errors are resolved.
        </Alert>
      )}
      {hasWarnings && !hasErrors && (
        <Alert severity="warning" sx={{ mb: 3 }}>
          <strong>Warnings Found:</strong> Your notification system may have issues.
        </Alert>
      )}
      {!hasErrors && !hasWarnings && testResults.length > 0 && (
        <Alert severity="success" sx={{ mb: 3 }}>
          <strong>All Tests Passed:</strong> Your Firebase configuration looks good!
        </Alert>
      )}

      {/* Test Results */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Test Results
        </Typography>

        {loading ? (
          <Box display="flex" justifyContent="center" alignItems="center" minHeight="200px">
            <CircularProgress />
          </Box>
        ) : (
          <List>
            {testResults.map((result, index) => (
              <React.Fragment key={index}>
                <ListItem>
                  <ListItemIcon>
                    {getStatusIcon(result.status)}
                  </ListItemIcon>
                  <ListItemText
                    primary={
                      <Typography variant="subtitle1" color={getStatusColor(result.status)}>
                        {result.name}
                      </Typography>
                    }
                    secondary={
                      <Box>
                        <Typography variant="body2" color="text.secondary">
                          {result.message}
                        </Typography>
                        {result.details && (
                          <Typography variant="body2" color="error.main" sx={{ mt: 0.5 }}>
                            Details: {result.details}
                          </Typography>
                        )}
                      </Box>
                    }
                  />
                </ListItem>
                {index < testResults.length - 1 && <Divider />}
              </React.Fragment>
            ))}
          </List>
        )}
      </Paper>

      {/* Instructions */}
      <Paper sx={{ p: 3, mt: 3 }}>
        <Typography variant="h6" gutterBottom>
          Troubleshooting Guide
        </Typography>
        <Typography variant="body2" paragraph>
          <strong>If you see errors:</strong>
        </Typography>
        <Typography variant="body2" paragraph>
          1. <strong>Missing Environment Variables:</strong> Create a `.env.local` file in the web_admin folder with your Firebase config
        </Typography>
        <Typography variant="body2" paragraph>
          2. <strong>Firestore Connection Failed:</strong> Check your Firebase project settings and ensure Firestore is enabled
        </Typography>
        <Typography variant="body2" paragraph>
          3. <strong>No Users Found:</strong> Register some users in your mobile app or create test users manually
        </Typography>
        <Typography variant="body2" paragraph>
          4. <strong>Write Permissions Failed:</strong> Check your Firestore security rules
        </Typography>
        <Typography variant="body2">
          5. <strong>No Admin User:</strong> Make sure you're logged in to the admin panel
        </Typography>
      </Paper>
    </Box>
  );
};

export default FirebaseConnectionTestPage;
