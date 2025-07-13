import React from 'react';
import { Box, Typography, Paper, Button } from '@mui/material';
import { ArrowBack } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

const SettingsPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <Button
          variant="outlined"
          startIcon={<ArrowBack />}
          onClick={() => navigate('/dashboard')}
          sx={{ minWidth: 'auto' }}
        >
          Back to Dashboard
        </Button>
        <Typography variant="h4" component="h1">
          Settings
        </Typography>
      </Box>
      
      <Paper sx={{ p: 3 }}>
        <Typography color="textSecondary">
          Settings interface will be implemented here...
        </Typography>
      </Paper>
    </Box>
  );
};

export default SettingsPage;
