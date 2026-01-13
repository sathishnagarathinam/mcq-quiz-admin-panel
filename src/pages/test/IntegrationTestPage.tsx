import React, { useState } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  Typography,
  Alert,
  CircularProgress,
  Grid,
  Divider,
} from '@mui/material';
import {
  PlayArrow as PlayIcon,
  CheckCircle as CheckIcon,
  Error as ErrorIcon,
  Campaign as CampaignIcon,
  LiveTv as LiveTvIcon,
} from '@mui/icons-material';
import { addAllSampleData, addSampleBanners, addSampleLiveTests } from '../../utils/sampleData';
import { collection, addDoc, getDocs } from 'firebase/firestore';
import { db } from '../../config/firebase';

const IntegrationTestPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState<{
    banners?: boolean;
    liveTests?: boolean;
    all?: boolean;
    firebaseTest?: boolean;
  }>({});
  const [error, setError] = useState<string | null>(null);

  const handleTestFirebaseConnection = async () => {
    setLoading(true);
    setError(null);

    try {
      console.log('🔥 Testing Firebase connection...');
      console.log('🔥 Database instance:', db);

      // Test 1: Try to read from banners collection
      console.log('🔥 Test 1: Reading banners collection...');
      const bannersSnapshot = await getDocs(collection(db, 'banners'));
      console.log('✅ Banners collection read successful. Count:', bannersSnapshot.docs.length);

      // Test 2: Try to write a test document
      console.log('🔥 Test 2: Writing test document...');
      const testDoc = {
        test: true,
        timestamp: new Date(),
        message: 'Firebase connection test'
      };

      const docRef = await addDoc(collection(db, 'test_connection'), testDoc);
      console.log('✅ Test document created with ID:', docRef.id);

      setResults(prev => ({ ...prev, firebaseTest: true }));
      setError(null);

    } catch (err) {
      console.error('❌ Firebase connection test failed:', err);
      setError('Firebase connection failed: ' + (err as Error).message);
      setResults(prev => ({ ...prev, firebaseTest: false }));
    } finally {
      setLoading(false);
    }
  };

  const handleAddSampleBanners = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const result = await addSampleBanners();
      setResults(prev => ({ ...prev, banners: result }));
      
      if (result) {
        setError(null);
      } else {
        setError('Failed to add sample banners');
      }
    } catch (err) {
      setError('Error adding sample banners: ' + (err as Error).message);
      setResults(prev => ({ ...prev, banners: false }));
    } finally {
      setLoading(false);
    }
  };

  const handleAddSampleLiveTests = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const result = await addSampleLiveTests();
      setResults(prev => ({ ...prev, liveTests: result }));
      
      if (result) {
        setError(null);
      } else {
        setError('Failed to add sample live tests');
      }
    } catch (err) {
      setError('Error adding sample live tests: ' + (err as Error).message);
      setResults(prev => ({ ...prev, liveTests: false }));
    } finally {
      setLoading(false);
    }
  };

  const handleAddAllSampleData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const result = await addAllSampleData();
      setResults(prev => ({ ...prev, all: result }));
      
      if (result) {
        setError(null);
      } else {
        setError('Failed to add all sample data');
      }
    } catch (err) {
      setError('Error adding sample data: ' + (err as Error).message);
      setResults(prev => ({ ...prev, all: false }));
    } finally {
      setLoading(false);
    }
  };

  const getResultIcon = (result?: boolean) => {
    if (result === undefined) return null;
    return result ? (
      <CheckIcon color="success" />
    ) : (
      <ErrorIcon color="error" />
    );
  };

  const getResultColor = (result?: boolean): 'primary' | 'success' | 'error' => {
    if (result === undefined) return 'primary';
    return result ? 'success' : 'error';
  };

  return (
    <Box p={3}>
      <Typography variant="h4" component="h1" gutterBottom>
        Integration Test - Banner & Live Test Management
      </Typography>
      
      <Typography variant="body1" color="textSecondary" paragraph>
        Use this page to test the integration between the web admin and mobile app.
        Add sample data to Firebase and verify it appears in both the admin interface and mobile app.
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Banner Testing */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <CampaignIcon sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">
                  Banner Management Test
                </Typography>
                {getResultIcon(results.banners)}
              </Box>
              
              <Typography variant="body2" color="textSecondary" paragraph>
                Add sample promotional banners to test the banner management system.
                These will appear in the mobile app's home screen.
              </Typography>

              <Box mb={2}>
                <Typography variant="subtitle2" gutterBottom>
                  Sample Banners Include:
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  • Special Offer (30% discount)
                  • Limited Time (Free premium)
                  • Weekend Sale (50% off)
                </Typography>
              </Box>

              <Button
                variant="contained"
                startIcon={loading ? <CircularProgress size={20} /> : <PlayIcon />}
                onClick={handleAddSampleBanners}
                disabled={loading}
                color={getResultColor(results.banners)}
                fullWidth
              >
                Add Sample Banners
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Live Test Testing */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <LiveTvIcon sx={{ mr: 1, color: 'error.main' }} />
                <Typography variant="h6">
                  Live Test Management Test
                </Typography>
                {getResultIcon(results.liveTests)}
              </Box>
              
              <Typography variant="body2" color="textSecondary" paragraph>
                Add sample live tests to test the live test management system.
                These will appear in the mobile app's live test section.
              </Typography>

              <Box mb={2}>
                <Typography variant="subtitle2" gutterBottom>
                  Sample Live Tests Include:
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  • IBPS RRB Officer Prelims
                  • SBI PO Mains Mock Test
                  • IBPS Clerk Prelims Speed Test
                </Typography>
              </Box>

              <Button
                variant="contained"
                startIcon={loading ? <CircularProgress size={20} /> : <PlayIcon />}
                onClick={handleAddSampleLiveTests}
                disabled={loading}
                color={getResultColor(results.liveTests)}
                fullWidth
              >
                Add Sample Live Tests
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Firebase Connection Test */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <CheckIcon sx={{ mr: 1, color: 'info.main' }} />
                <Typography variant="h6">
                  Firebase Connection Test
                </Typography>
                {getResultIcon(results.firebaseTest)}
              </Box>

              <Typography variant="body2" color="textSecondary" paragraph>
                Test the basic Firebase connection and permissions before adding sample data.
              </Typography>

              <Button
                variant="outlined"
                startIcon={loading ? <CircularProgress size={20} /> : <PlayIcon />}
                onClick={handleTestFirebaseConnection}
                disabled={loading}
                color={getResultColor(results.firebaseTest)}
                sx={{ mr: 2 }}
              >
                Test Firebase Connection
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Combined Testing */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <CheckIcon sx={{ mr: 1, color: 'success.main' }} />
                <Typography variant="h6">
                  Complete Integration Test
                </Typography>
                {getResultIcon(results.all)}
              </Box>
              
              <Typography variant="body2" color="textSecondary" paragraph>
                Add all sample data at once to fully test the integration between
                web admin and mobile app.
              </Typography>

              <Button
                variant="contained"
                size="large"
                startIcon={loading ? <CircularProgress size={24} /> : <PlayIcon />}
                onClick={handleAddAllSampleData}
                disabled={loading}
                color={getResultColor(results.all)}
                sx={{ mr: 2 }}
              >
                Add All Sample Data
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Divider sx={{ my: 4 }} />

      {/* Instructions */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Testing Instructions
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>1. Add Sample Data:</strong> Use the buttons above to add sample banners and live tests to Firebase.
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>2. Check Web Admin:</strong> Navigate to Banner Management and Live Test Management pages to see the added data.
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>3. Check Mobile App:</strong> Open the mobile app and verify that:
            <br />• Promotional banners appear on the home screen
            <br />• Live tests appear in the live test section
            <br />• Data updates in real-time when you make changes in the admin
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>4. Test Admin Features:</strong>
            <br />• Edit banner colors, text, and dates
            <br />• Toggle banner active/inactive status
            <br />• Schedule new live tests
            <br />• Update live test status (upcoming → live → completed)
          </Typography>
          
          <Typography variant="body2" color="textSecondary">
            <strong>Note:</strong> Changes made in the web admin should appear immediately in the mobile app
            due to real-time Firebase synchronization.
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default IntegrationTestPage;
