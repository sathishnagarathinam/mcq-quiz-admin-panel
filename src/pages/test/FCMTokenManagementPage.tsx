import React, { useState } from 'react';
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
  List,
  ListItem,
  ListItemText,
  Divider,
  Chip,
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  ArrowBack as ArrowBackIcon,
  Token as TokenIcon,
  Add as AddIcon,
  Check as CheckIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { addFCMTokenFieldToUsers, checkFCMTokenStatus, addTestFCMTokens } from '../../utils/updateFCMTokens';

interface TokenStatus {
  success: boolean;
  message: string;
  details: any;
}

const FCMTokenManagementPage: React.FC = () => {
  const navigate = useNavigate();
  
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState<TokenStatus | null>(null);
  const [operation, setOperation] = useState<string>('');

  const handleCheckStatus = async () => {
    setLoading(true);
    setOperation('Checking FCM token status...');
    try {
      const result = await checkFCMTokenStatus();
      setStatus(result);
    } catch (error) {
      setStatus({
        success: false,
        message: `Error checking status: ${error}`,
        details: {}
      });
    } finally {
      setLoading(false);
      setOperation('');
    }
  };

  const handleAddTokenFields = async () => {
    setLoading(true);
    setOperation('Adding FCM token fields to users...');
    try {
      const result = await addFCMTokenFieldToUsers();
      setStatus(result);
    } catch (error) {
      setStatus({
        success: false,
        message: `Error adding token fields: ${error}`,
        details: {}
      });
    } finally {
      setLoading(false);
      setOperation('');
    }
  };

  const handleAddTestTokens = async () => {
    setLoading(true);
    setOperation('Adding test FCM tokens...');
    try {
      const result = await addTestFCMTokens();
      setStatus(result);
    } catch (error) {
      setStatus({
        success: false,
        message: `Error adding test tokens: ${error}`,
        details: {}
      });
    } finally {
      setLoading(false);
      setOperation('');
    }
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
          FCM Token Management
        </Typography>
      </Box>

      {/* Action Buttons */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={4}>
          <Button
            fullWidth
            variant="outlined"
            startIcon={<CheckIcon />}
            onClick={handleCheckStatus}
            disabled={loading}
            sx={{ py: 2 }}
          >
            Check Token Status
          </Button>
        </Grid>
        <Grid item xs={12} md={4}>
          <Button
            fullWidth
            variant="contained"
            startIcon={<AddIcon />}
            onClick={handleAddTokenFields}
            disabled={loading}
            sx={{ py: 2 }}
          >
            Add Token Fields
          </Button>
        </Grid>
        <Grid item xs={12} md={4}>
          <Button
            fullWidth
            variant="contained"
            color="secondary"
            startIcon={<TokenIcon />}
            onClick={handleAddTestTokens}
            disabled={loading}
            sx={{ py: 2 }}
          >
            Add Test Tokens
          </Button>
        </Grid>
      </Grid>

      {/* Loading */}
      {loading && (
        <Paper sx={{ p: 3, mb: 3, textAlign: 'center' }}>
          <CircularProgress sx={{ mb: 2 }} />
          <Typography variant="body1">{operation}</Typography>
        </Paper>
      )}

      {/* Status Results */}
      {status && (
        <Paper sx={{ p: 3, mb: 3 }}>
          <Alert severity={status.success ? 'success' : 'error'} sx={{ mb: 2 }}>
            {status.message}
          </Alert>

          {status.details && (
            <>
              {/* Summary Stats */}
              {status.details.totalUsers !== undefined && (
                <Grid container spacing={2} sx={{ mb: 3 }}>
                  <Grid item xs={6} md={3}>
                    <Card>
                      <CardContent sx={{ textAlign: 'center', py: 2 }}>
                        <Typography variant="h4" color="primary.main">
                          {status.details.totalUsers}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Total Users
                        </Typography>
                      </CardContent>
                    </Card>
                  </Grid>
                  <Grid item xs={6} md={3}>
                    <Card>
                      <CardContent sx={{ textAlign: 'center', py: 2 }}>
                        <Typography variant="h4" color="success.main">
                          {status.details.usersWithTokens || status.details.updatedCount || 0}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          With Tokens
                        </Typography>
                      </CardContent>
                    </Card>
                  </Grid>
                  <Grid item xs={6} md={3}>
                    <Card>
                      <CardContent sx={{ textAlign: 'center', py: 2 }}>
                        <Typography variant="h4" color="warning.main">
                          {status.details.usersWithNullTokens || 0}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Null Tokens
                        </Typography>
                      </CardContent>
                    </Card>
                  </Grid>
                  <Grid item xs={6} md={3}>
                    <Card>
                      <CardContent sx={{ textAlign: 'center', py: 2 }}>
                        <Typography variant="h4" color="error.main">
                          {status.details.usersWithoutTokens || status.details.errorCount || 0}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Without Tokens
                        </Typography>
                      </CardContent>
                    </Card>
                  </Grid>
                </Grid>
              )}

              {/* Sample Users with Tokens */}
              {status.details.sampleUsersWithTokens && status.details.sampleUsersWithTokens.length > 0 && (
                <Box sx={{ mb: 3 }}>
                  <Typography variant="h6" gutterBottom>
                    Sample Users with FCM Tokens:
                  </Typography>
                  <List dense>
                    {status.details.sampleUsersWithTokens.map((user: any, index: number) => (
                      <React.Fragment key={user.id}>
                        <ListItem>
                          <ListItemText
                            primary={user.name}
                            secondary={`${user.email} | Token: ${user.tokenPreview}`}
                          />
                          <Chip label="Has Token" color="success" size="small" />
                        </ListItem>
                        {index < status.details.sampleUsersWithTokens.length - 1 && <Divider />}
                      </React.Fragment>
                    ))}
                  </List>
                </Box>
              )}

              {/* Sample Users without Tokens */}
              {status.details.sampleUsersWithoutTokens && status.details.sampleUsersWithoutTokens.length > 0 && (
                <Box sx={{ mb: 3 }}>
                  <Typography variant="h6" gutterBottom>
                    Sample Users without FCM Tokens:
                  </Typography>
                  <List dense>
                    {status.details.sampleUsersWithoutTokens.map((user: any, index: number) => (
                      <React.Fragment key={user.id}>
                        <ListItem>
                          <ListItemText
                            primary={user.name}
                            secondary={`${user.email} | Has field: ${user.hasTokenField ? 'Yes' : 'No'}`}
                          />
                          <Chip 
                            label={user.hasTokenField ? 'Null Token' : 'No Field'} 
                            color="warning" 
                            size="small" 
                          />
                        </ListItem>
                        {index < status.details.sampleUsersWithoutTokens.length - 1 && <Divider />}
                      </React.Fragment>
                    ))}
                  </List>
                </Box>
              )}

              {/* Errors */}
              {status.details.errors && status.details.errors.length > 0 && (
                <Box sx={{ mb: 3 }}>
                  <Typography variant="h6" gutterBottom color="error">
                    Errors:
                  </Typography>
                  <List dense>
                    {status.details.errors.map((error: string, index: number) => (
                      <ListItem key={index}>
                        <ListItemText primary={error} />
                      </ListItem>
                    ))}
                  </List>
                </Box>
              )}
            </>
          )}
        </Paper>
      )}

      {/* Instructions */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Instructions:
        </Typography>
        <Typography variant="body2" paragraph>
          <strong>1. Check Token Status:</strong> See how many users have FCM tokens vs those who don't.
        </Typography>
        <Typography variant="body2" paragraph>
          <strong>2. Add Token Fields:</strong> Add fcmToken and lastTokenUpdate fields to users who don't have them (one-time setup).
        </Typography>
        <Typography variant="body2" paragraph>
          <strong>3. Add Test Tokens:</strong> Add fake FCM tokens to all users for testing push notifications (for development only).
        </Typography>
        <Typography variant="body2" paragraph>
          <strong>Note:</strong> In production, real FCM tokens are automatically saved when users log into the mobile app.
        </Typography>
      </Paper>
    </Box>
  );
};

export default FCMTokenManagementPage;
