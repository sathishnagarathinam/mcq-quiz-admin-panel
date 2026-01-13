import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  TextField,
  Alert,
  CircularProgress,
} from '@mui/material';
import { createUserWithEmailAndPassword, updateProfile } from 'firebase/auth';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../../config/firebase';
import toast from 'react-hot-toast';

const TestRegistration: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [testEmail, setTestEmail] = useState('test@example.com');
  const [testName, setTestName] = useState('Test User');

  const createTestUser = async () => {
    try {
      setLoading(true);
      console.log('🧪 Creating test user...');
      
      // Create user in Firebase Auth
      const result = await createUserWithEmailAndPassword(auth, testEmail, 'test123');
      console.log('✅ User created in Auth:', result.user.uid);
      
      // Update user profile
      await updateProfile(result.user, {
        displayName: testName
      });
      console.log('✅ Profile updated');
      
      // Create admin user document in Firestore (pending approval)
      const adminUserData = {
        uid: result.user.uid,
        email: testEmail,
        name: testName,
        role: 'admin',
        createdAt: serverTimestamp(),
        isActive: false,
        status: 'pending',
      };
      
      await setDoc(doc(db, 'admin_users', result.user.uid), adminUserData);
      console.log('✅ User document created in Firestore');
      
      // Sign out the test user
      await auth.signOut();
      console.log('✅ Test user signed out');
      
      toast.success('Test user created successfully! Check User Management.');
      
    } catch (error: any) {
      console.error('❌ Error creating test user:', error);
      toast.error('Failed to create test user: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card sx={{ mb: 3 }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          🧪 Test User Registration
        </Typography>
        
        <Typography variant="body2" color="text.secondary" paragraph>
          Create a test user to verify the approval workflow is working.
        </Typography>
        
        <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
          <TextField
            label="Test Email"
            value={testEmail}
            onChange={(e) => setTestEmail(e.target.value)}
            size="small"
            sx={{ flex: 1 }}
          />
          <TextField
            label="Test Name"
            value={testName}
            onChange={(e) => setTestName(e.target.value)}
            size="small"
            sx={{ flex: 1 }}
          />
        </Box>
        
        <Button
          variant="contained"
          onClick={createTestUser}
          disabled={loading || !testEmail || !testName}
          startIcon={loading ? <CircularProgress size={16} /> : null}
        >
          {loading ? 'Creating Test User...' : 'Create Test User'}
        </Button>
        
        <Alert severity="info" sx={{ mt: 2 }}>
          <Typography variant="body2">
            This will create a test user with status "pending" that should appear in the User Management table above.
            Password will be "test123".
          </Typography>
        </Alert>
      </CardContent>
    </Card>
  );
};

export default TestRegistration;
