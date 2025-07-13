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

interface FCMResult {
  success: boolean;
  message: string;
  details: any;
}

const FCMTokenManagerPage: React.FC = () => {
  const navigate = useNavigate();
  
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<FCMResult | null>(null);
  const [statusResult, setStatusResult] = useState<FCMResult | null>(null);

  const handleAddFCMFields = async () => {
    try {
      setLoading(true);
      setResult(null);
      
      const response = await addFCMTokenFieldToUsers();
      setResult(response);
    } catch (error) {
      setResult({
        success: false,
        message: `Error: ${error}`,
        details: { error: String(error) }
      });
    } finally {
      setLoading(false);
    }
  };

  const handleCheckStatus = async () => {
    try {
      setLoading(true);
      setStatusResult(null);
      
      const response = await checkFCMTokenStatus();
      setStatusResult(response);
    } catch (error) {
      setStatusResult({
        success: false,
        message: `Error: ${error}`,
        details: { error: String(error) }
      });
    } finally {
      setLoading(false);
    }
  };

  const handleAddTestTokens = async () => {
    try {
      setLoading(true);
      setResult(null);
      
      const response = await addTestFCMTokens();
      setResult(response);
    } catch (error) {
      setResult({
        success: false,
        message: `Error: ${error}`,
        details: { error: String(error) }
      });
    } finally {
      setLoading(false);
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
          FCM Token Manager
        </Typography>
      </Box>

      {/* Action Buttons */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Check Token Status
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Check how many users have FCM tokens for push notifications
              </Typography>
              <Button
                variant="contained"
                startIcon={<CheckIcon />}
                onClick={handleCheckStatus}
                disabled={loading}
                fullWidth
              >
                Check Status
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Add FCM Fields
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Add FCM token fields to existing users (one-time setup)
              </Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={handleAddFCMFields}
                disabled={loading}
                fullWidth
                color="secondary"
              >
                Add Fields
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Add Test Tokens
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Add fake FCM tokens for testing notifications (testing only)
              </Typography>
              <Button
                variant="contained"
                startIcon={<TokenIcon />}
                onClick={handleAddTestTokens}
                disabled={loading}
                fullWidth
                color="warning"
              >
                Add Test Tokens
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Loading */}
      {loading && (
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="200px">
          <CircularProgress />
        </Box>
      )}

      {/* Status Result */}
      {statusResult && (
        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h6" gutterBottom>
            FCM Token Status
          </Typography>
          
          <Alert severity={statusResult.success ? 'info' : 'error'} sx={{ mb: 2 }}>
            {statusResult.message}
          </Alert>

          {statusResult.success && statusResult.details && (
            <>
              <Grid container spacing={2} sx={{ mb: 3 }}>
                <Grid item xs={3}>
                  <Card>
                    <CardContent sx={{ textAlign: 'center', py: 2 }}>
                      <Typography variant="h4" color="primary.main">
                        {statusResult.details.totalUsers}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Total Users
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
                <Grid item xs={3}>
                  <Card>
                    <CardContent sx={{ textAlign: 'center', py: 2 }}>
                      <Typography variant="h4" color="success.main">
                        {statusResult.details.usersWithTokens}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        With Tokens
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
                <Grid item xs={3}>
                  <Card>
                    <CardContent sx={{ textAlign: 'center', py: 2 }}>
                      <Typography variant="h4" color="warning.main">
                        {statusResult.details.usersWithNullTokens}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Null Tokens
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
                <Grid item xs={3}>
                  <Card>
                    <CardContent sx={{ textAlign: 'center', py: 2 }}>
                      <Typography variant="h4" color="error.main">
                        {statusResult.details.usersWithoutTokens}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        No Token Field
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>

              {/* Sample Users with Tokens */}
              {statusResult.details.sampleUsersWithTokens?.length > 0 && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="subtitle1" gutterBottom>
                    Sample Users with FCM Tokens:
                  </Typography>
                  <List dense>
                    {statusResult.details.sampleUsersWithTokens.map((user: any, index: number) => (
                      <React.Fragment key={user.id}>
                        <ListItem>
                          <ListItemText
                            primary={user.name}
                            secondary={`${user.email} | Token: ${user.tokenPreview}`}
                          />
                          <Chip label="Has Token" color="success" size="small" />
                        </ListItem>
                        {index < statusResult.details.sampleUsersWithTokens.length - 1 && <Divider />}
                      </React.Fragment>
                    ))}
                  </List>
                </Box>
              )}

              {/* Sample Users without Tokens */}
              {statusResult.details.sampleUsersWithoutTokens?.length > 0 && (
                <Box>
                  <Typography variant="subtitle1" gutterBottom>
                    Sample Users without FCM Tokens:
                  </Typography>
                  <List dense>
                    {statusResult.details.sampleUsersWithoutTokens.map((user: any, index: number) => (
                      <React.Fragment key={user.id}>
                        <ListItem>
                          <ListItemText
                            primary={user.name}
                            secondary={`${user.email} | Has field: ${user.hasTokenField ? 'Yes' : 'No'}`}
                          />
                          <Chip 
                            label={user.hasTokenField ? "Null Token" : "No Field"} 
                            color={user.hasTokenField ? "warning" : "error"} 
                            size="small" 
                          />
                        </ListItem>
                        {index < statusResult.details.sampleUsersWithoutTokens.length - 1 && <Divider />}
                      </React.Fragment>
                    ))}
                  </List>
                </Box>
              )}
            </>
          )}
        </Paper>
      )}

      {/* Action Result */}
      {result && (
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Operation Result
          </Typography>
          
          <Alert severity={result.success ? 'success' : 'error'} sx={{ mb: 2 }}>
            {result.message}
          </Alert>

          {result.details && (
            <Box>
              <Typography variant="subtitle2" gutterBottom>
                Details:
              </Typography>
              <pre style={{ 
                background: '#f5f5f5', 
                padding: '10px', 
                borderRadius: '4px',
                fontSize: '12px',
                overflow: 'auto'
              }}>
                {JSON.stringify(result.details, null, 2)}
              </pre>
            </Box>
          )}
        </Paper>
      )}

      {/* Instructions */}
      <Paper sx={{ p: 3, mt: 3 }}>
        <Typography variant="h6" gutterBottom>
          Instructions
        </Typography>
        
        <Typography variant="body2" paragraph>
          <strong>1. Check Token Status:</strong> See how many users have FCM tokens for push notifications.
        </Typography>
        
        <Typography variant="body2" paragraph>
          <strong>2. Add FCM Fields:</strong> One-time operation to add FCM token fields to existing users. 
          Run this if users don't have the fcmToken field in their documents.
        </Typography>
        
        <Typography variant="body2" paragraph>
          <strong>3. Add Test Tokens:</strong> For testing only - adds fake FCM tokens to all users so you can test 
          the notification system without waiting for real mobile app logins.
        </Typography>
        
        <Alert severity="info" sx={{ mt: 2 }}>
          <strong>Note:</strong> In production, FCM tokens are automatically saved when users log into the mobile app. 
          The test tokens are only for development/testing purposes.
        </Alert>
      </Paper>
    </Box>
  );
};

export default FCMTokenManagerPage;
