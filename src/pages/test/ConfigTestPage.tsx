import React, { useEffect, useState } from 'react';
import { Box, Typography, Paper, Alert, CircularProgress } from '@mui/material';
import { db, auth } from '../../config/firebase';
import { collection, getDocs } from 'firebase/firestore';

const ConfigTestPage: React.FC = () => {
  const [firebaseStatus, setFirebaseStatus] = useState<'loading' | 'success' | 'error'>('loading');
  const [errorMessage, setErrorMessage] = useState<string>('');
  const [configInfo, setConfigInfo] = useState<any>(null);

  useEffect(() => {
    const testFirebaseConnection = async () => {
      try {
        console.log('🔥 Testing Firebase connection...');
        
        // Test Firebase config
        const config = {
          hasApiKey: !!process.env.REACT_APP_FIREBASE_API_KEY,
          hasAuthDomain: !!process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
          hasProjectId: !!process.env.REACT_APP_FIREBASE_PROJECT_ID,
          projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
          authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
        };
        
        setConfigInfo(config);
        console.log('🔥 Firebase Config:', config);

        // Test Firestore connection
        const testCollection = collection(db, 'test');
        await getDocs(testCollection);
        
        console.log('✅ Firebase connection successful!');
        setFirebaseStatus('success');
      } catch (error: any) {
        console.error('❌ Firebase connection failed:', error);
        setErrorMessage(error.message || 'Unknown error');
        setFirebaseStatus('error');
      }
    };

    testFirebaseConnection();
  }, []);

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        🔧 Firebase Configuration Test
      </Typography>
      
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          Configuration Status
        </Typography>
        
        {configInfo && (
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2">
              <strong>Has API Key:</strong> {configInfo.hasApiKey ? '✅' : '❌'}
            </Typography>
            <Typography variant="body2">
              <strong>Has Auth Domain:</strong> {configInfo.hasAuthDomain ? '✅' : '❌'}
            </Typography>
            <Typography variant="body2">
              <strong>Has Project ID:</strong> {configInfo.hasProjectId ? '✅' : '❌'}
            </Typography>
            <Typography variant="body2">
              <strong>Project ID:</strong> {configInfo.projectId || 'Not set'}
            </Typography>
            <Typography variant="body2">
              <strong>Auth Domain:</strong> {configInfo.authDomain || 'Not set'}
            </Typography>
          </Box>
        )}
        
        {firebaseStatus === 'loading' && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <CircularProgress size={20} />
            <Typography>Testing Firebase connection...</Typography>
          </Box>
        )}
        
        {firebaseStatus === 'success' && (
          <Alert severity="success">
            🎉 Firebase is configured correctly and connection is working!
          </Alert>
        )}
        
        {firebaseStatus === 'error' && (
          <Alert severity="error">
            ❌ Firebase connection failed: {errorMessage}
          </Alert>
        )}
      </Paper>

      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Environment Variables
        </Typography>
        <Typography variant="body2" component="pre" sx={{ fontSize: '0.8rem' }}>
          {JSON.stringify({
            REACT_APP_FIREBASE_API_KEY: process.env.REACT_APP_FIREBASE_API_KEY ? '[SET]' : '[NOT SET]',
            REACT_APP_FIREBASE_AUTH_DOMAIN: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN || '[NOT SET]',
            REACT_APP_FIREBASE_PROJECT_ID: process.env.REACT_APP_FIREBASE_PROJECT_ID || '[NOT SET]',
            REACT_APP_FIREBASE_STORAGE_BUCKET: process.env.REACT_APP_FIREBASE_STORAGE_BUCKET || '[NOT SET]',
            REACT_APP_FIREBASE_MESSAGING_SENDER_ID: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID || '[NOT SET]',
            REACT_APP_FIREBASE_APP_ID: process.env.REACT_APP_FIREBASE_APP_ID ? '[SET]' : '[NOT SET]',
          }, null, 2)}
        </Typography>
      </Paper>
    </Box>
  );
};

export default ConfigTestPage;
