import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Alert,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Chip,
  Container,
  Grid,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import WarningIcon from '@mui/icons-material/Warning';
import { db, auth, storage, functions } from '../../config/firebase';
import { collection, addDoc, getDocs, deleteDoc } from 'firebase/firestore';

interface TestResult {
  name: string;
  status: 'pass' | 'fail' | 'warn';
  message: string;
}

const FirebaseTestPage: React.FC = () => {
  const [testResults, setTestResults] = useState<TestResult[]>([]);
  const [isRunning, setIsRunning] = useState(false);

  const addTestResult = (name: string, status: 'pass' | 'fail' | 'warn', message: string) => {
    setTestResults(prev => [...prev, { name, status, message }]);
  };

  const runFirebaseTests = async () => {
    setIsRunning(true);
    setTestResults([]);

    // Test 1: Firebase Configuration
    try {
      const config = {
        apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
        projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
        authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
      };

      if (config.apiKey && config.projectId && config.authDomain) {
        addTestResult('Firebase Configuration', 'pass', 'All required config values present');
      } else {
        addTestResult('Firebase Configuration', 'fail', 'Missing required config values');
      }

      if (config.projectId === 'mcq-quiz-system') {
        addTestResult('Project ID', 'pass', 'mcq-quiz-system');
      } else {
        addTestResult('Project ID', 'warn', `Found: ${config.projectId}`);
      }
    } catch (error) {
      addTestResult('Firebase Configuration', 'fail', 'Configuration error');
    }

    // Test 1.5: Network Connectivity
    try {
      const response = await fetch('https://firebase.googleapis.com/v1/projects/mcq-quiz-system', {
        method: 'GET',
      });

      if (response.status === 200 || response.status === 403) {
        addTestResult('Firebase Network', 'pass', 'Can reach Firebase servers');
      } else {
        addTestResult('Firebase Network', 'warn', `HTTP ${response.status}`);
      }
    } catch (error: any) {
      addTestResult('Firebase Network', 'fail', `Network error: ${error.message}`);
    }

    // Test 2: Firestore Connection
    try {
      const testCollection = collection(db, 'test-connection');
      const testDoc = await addDoc(testCollection, {
        message: 'Firebase connection test',
        timestamp: new Date(),
      });
      
      addTestResult('Firestore Write', 'pass', 'Successfully wrote test document');
      
      // Read the document back
      const snapshot = await getDocs(testCollection);
      if (!snapshot.empty) {
        addTestResult('Firestore Read', 'pass', `Found ${snapshot.size} document(s)`);
      } else {
        addTestResult('Firestore Read', 'warn', 'No documents found');
      }
      
      // Clean up test document
      await deleteDoc(testDoc);
      addTestResult('Firestore Delete', 'pass', 'Test document cleaned up');
      
    } catch (error: any) {
      addTestResult('Firestore Connection', 'fail', error.message || 'Connection failed');
    }

    // Test 3: Authentication Service
    try {
      if (auth.currentUser) {
        addTestResult('Auth Service', 'pass', `User: ${auth.currentUser.email}`);
      } else {
        addTestResult('Auth Service', 'pass', 'Service available (no user signed in)');
      }

      // Test auth configuration
      try {
        // This will test if auth is properly configured
        await auth.authStateReady;
        addTestResult('Auth Configuration', 'pass', 'Authentication service initialized');
      } catch (authError: any) {
        addTestResult('Auth Configuration', 'fail', `Auth config error: ${authError.message}`);
      }
    } catch (error: any) {
      addTestResult('Auth Service', 'fail', error.message || 'Auth service error');
    }

    // Test 4: Storage Service
    try {
      // Just check if storage is initialized
      if (storage) {
        addTestResult('Storage Service', 'pass', 'Service initialized');
      } else {
        addTestResult('Storage Service', 'fail', 'Service not available');
      }
    } catch (error: any) {
      addTestResult('Storage Service', 'fail', error.message || 'Storage service error');
    }

    // Test 5: Functions Service
    try {
      if (functions) {
        addTestResult('Functions Service', 'pass', 'Service initialized');
      } else {
        addTestResult('Functions Service', 'warn', 'Service not available');
      }
    } catch (error: any) {
      addTestResult('Functions Service', 'warn', error.message || 'Functions service error');
    }

    setIsRunning(false);
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pass':
        return <CheckCircleIcon color="success" />;
      case 'fail':
        return <ErrorIcon color="error" />;
      case 'warn':
        return <WarningIcon color="warning" />;
      default:
        return null;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pass':
        return 'success';
      case 'fail':
        return 'error';
      case 'warn':
        return 'warning';
      default:
        return 'default';
    }
  };

  const summary = testResults.reduce(
    (acc, result) => {
      acc[result.status]++;
      return acc;
    },
    { pass: 0, fail: 0, warn: 0 }
  );

  return (
    <Container maxWidth="lg">
      <Box sx={{ py: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          🔥 Firebase Connection Test
        </Typography>
        
        <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
          This page tests the Firebase connection and services for the MCQ Quiz System.
        </Typography>

        <Grid container spacing={3}>
          <Grid item xs={12} md={8}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                  <Typography variant="h6">Test Results</Typography>
                  <Button
                    variant="contained"
                    onClick={runFirebaseTests}
                    disabled={isRunning}
                  >
                    {isRunning ? 'Running Tests...' : 'Run Firebase Tests'}
                  </Button>
                </Box>

                {testResults.length > 0 && (
                  <List>
                    {testResults.map((result, index) => (
                      <ListItem key={index}>
                        <ListItemIcon>
                          {getStatusIcon(result.status)}
                        </ListItemIcon>
                        <ListItemText
                          primary={result.name}
                          secondary={result.message}
                        />
                        <Chip
                          label={result.status.toUpperCase()}
                          color={getStatusColor(result.status) as any}
                          size="small"
                        />
                      </ListItem>
                    ))}
                  </List>
                )}

                {testResults.length === 0 && !isRunning && (
                  <Alert severity="info">
                    Click "Run Firebase Tests" to test the Firebase connection.
                  </Alert>
                )}
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Test Summary
                </Typography>
                
                {testResults.length > 0 ? (
                  <Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography>Passed:</Typography>
                      <Chip label={summary.pass} color="success" size="small" />
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography>Warnings:</Typography>
                      <Chip label={summary.warn} color="warning" size="small" />
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                      <Typography>Failed:</Typography>
                      <Chip label={summary.fail} color="error" size="small" />
                    </Box>

                    {summary.fail === 0 && summary.warn === 0 && (
                      <Alert severity="success">
                        🎉 All tests passed! Firebase is working perfectly.
                      </Alert>
                    )}
                    
                    {summary.fail === 0 && summary.warn > 0 && (
                      <Alert severity="warning">
                        ⚠️ Tests passed with warnings. Check the details above.
                      </Alert>
                    )}
                    
                    {summary.fail > 0 && (
                      <Alert severity="error">
                        ❌ Some tests failed. Please check your Firebase configuration.
                      </Alert>
                    )}
                  </Box>
                ) : (
                  <Typography color="text.secondary">
                    No tests run yet.
                  </Typography>
                )}
              </CardContent>
            </Card>

            <Card sx={{ mt: 2 }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Configuration Info
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Project ID:</strong> {process.env.REACT_APP_FIREBASE_PROJECT_ID || 'Not set'}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Auth Domain:</strong> {process.env.REACT_APP_FIREBASE_AUTH_DOMAIN || 'Not set'}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Environment:</strong> {process.env.REACT_APP_ENVIRONMENT || 'development'}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Box>
    </Container>
  );
};

export default FirebaseTestPage;
