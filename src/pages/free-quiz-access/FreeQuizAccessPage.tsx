import React from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Alert,
} from '@mui/material';
import { ArrowBack } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import FreeQuizAccessManagement from '../../components/admin/FreeQuizAccessManagement';

const FreeQuizAccessPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Container maxWidth="lg">
      <Box sx={{ py: 4 }}>
        {/* Header */}
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 4 }}>
          <Button
            variant="outlined"
            startIcon={<ArrowBack />}
            onClick={() => navigate('/dashboard')}
            sx={{ mr: 2 }}
          >
            Back
          </Button>
          
          <Box>
            <Typography variant="h4" component="h1" gutterBottom>
              🎁 Free Quiz Access Management
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Grant free access to paid quizzes for specific users
            </Typography>
          </Box>
        </Box>

        {/* Info Alert */}
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="body2" gutterBottom>
            <strong>How it works:</strong> You can grant free access to any paid quiz for specific users. 
            Access can be permanent or set to expire after a certain number of days.
          </Typography>
        </Alert>

        {/* Management Component */}
        <FreeQuizAccessManagement />

        {/* Help Section */}
        <Box sx={{ mt: 4, p: 3, bgcolor: 'background.paper', borderRadius: 2 }}>
          <Typography variant="h6" gutterBottom>
            💡 How to Use
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Grant Access:</strong> Click "Grant Free Access" button to open the dialog. Select a user and exam, 
            optionally set an expiry date and reason.
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Permanent Access:</strong> Leave the "Expiry Days" field empty to grant permanent access.
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Temporary Access:</strong> Enter a number of days to automatically expire the access after that period.
          </Typography>
          
          <Typography variant="body2">
            <strong>Revoke Access:</strong> Click the delete icon in the Actions column to revoke access from a user.
          </Typography>
        </Box>
      </Box>
    </Container>
  );
};

export default FreeQuizAccessPage;

