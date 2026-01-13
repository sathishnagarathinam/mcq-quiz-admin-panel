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
  List,
  ListItem,
  ListItemText,
  Divider,
  Chip,
} from '@mui/material';
import {
  PersonAdd as PersonAddIcon,
  People as PeopleIcon,
  ArrowBack as ArrowBackIcon,
  Refresh as RefreshIcon,
  CheckCircle as CheckIcon,
  Error as ErrorIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { createTestUsers, checkExistingUsers } from '../../utils/createTestUsers';

const CreateTestUsersPage: React.FC = () => {
  const navigate = useNavigate();
  
  const [loading, setLoading] = useState(false);
  const [checkingUsers, setCheckingUsers] = useState(true);
  const [creationResults, setCreationResults] = useState<string[]>([]);
  const [existingUsers, setExistingUsers] = useState<{ collectionName: string; count: number; users: any[] }[]>([]);

  useEffect(() => {
    checkUsers();
  }, []);

  const checkUsers = async () => {
    try {
      setCheckingUsers(true);
      const results = await checkExistingUsers();
      setExistingUsers(results);
    } catch (error) {
      console.error('Error checking existing users:', error);
      toast.error('Failed to check existing users');
    } finally {
      setCheckingUsers(false);
    }
  };

  const handleCreateTestUsers = async () => {
    try {
      setLoading(true);
      setCreationResults([]);
      
      const result = await createTestUsers();
      setCreationResults(result.details);
      
      if (result.success) {
        toast.success(result.message);
        // Refresh the existing users check
        await checkUsers();
      } else {
        toast.error(result.message);
      }
    } catch (error) {
      console.error('Error creating test users:', error);
      toast.error('Failed to create test users');
      setCreationResults([`❌ Error: ${error}`]);
    } finally {
      setLoading(false);
    }
  };

  const totalUsers = existingUsers.reduce((sum, collection) => sum + Math.max(0, collection.count), 0);
  const hasUsers = totalUsers > 0;

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
          Create Test Users
        </Typography>
        <Button
          startIcon={<RefreshIcon />}
          onClick={checkUsers}
          variant="outlined"
          disabled={checkingUsers}
        >
          Refresh
        </Button>
      </Box>

      <Grid container spacing={3}>
        {/* Current Status */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Current User Status
            </Typography>

            {checkingUsers ? (
              <Box display="flex" justifyContent="center" alignItems="center" minHeight="200px">
                <CircularProgress />
              </Box>
            ) : (
              <>
                {/* Summary Cards */}
                <Grid container spacing={2} sx={{ mb: 3 }}>
                  <Grid item xs={12} sm={6}>
                    <Card>
                      <CardContent sx={{ textAlign: 'center' }}>
                        <PeopleIcon sx={{ fontSize: 40, color: hasUsers ? 'success.main' : 'error.main', mb: 1 }} />
                        <Typography variant="h4" color={hasUsers ? 'success.main' : 'error.main'}>
                          {totalUsers}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Total Users Found
                        </Typography>
                      </CardContent>
                    </Card>
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Card>
                      <CardContent sx={{ textAlign: 'center' }}>
                        {hasUsers ? (
                          <CheckIcon sx={{ fontSize: 40, color: 'success.main', mb: 1 }} />
                        ) : (
                          <ErrorIcon sx={{ fontSize: 40, color: 'error.main', mb: 1 }} />
                        )}
                        <Typography variant="h6" color={hasUsers ? 'success.main' : 'error.main'}>
                          {hasUsers ? 'Ready' : 'No Users'}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Notification Status
                        </Typography>
                      </CardContent>
                    </Card>
                  </Grid>
                </Grid>

                {/* Collection Details */}
                <Typography variant="subtitle1" gutterBottom>
                  Collections Status:
                </Typography>
                <List>
                  {existingUsers.map((collection, index) => (
                    <React.Fragment key={collection.collectionName}>
                      <ListItem>
                        <ListItemText
                          primary={
                            <Box display="flex" alignItems="center" gap={1}>
                              <Typography variant="subtitle2">
                                {collection.collectionName}
                              </Typography>
                              <Chip
                                label={collection.count >= 0 ? `${collection.count} users` : 'Error'}
                                color={collection.count > 0 ? 'success' : collection.count === 0 ? 'warning' : 'error'}
                                size="small"
                              />
                            </Box>
                          }
                          secondary={
                            collection.count > 0 && collection.users.length > 0 ? (
                              <Typography variant="body2" color="text.secondary">
                                Sample users: {collection.users.map(u => u.name || u.email || u.id).slice(0, 2).join(', ')}
                                {collection.users.length > 2 && '...'}
                              </Typography>
                            ) : collection.count === 0 ? (
                              'Collection exists but is empty'
                            ) : collection.count === -1 ? (
                              'Collection not accessible or doesn\'t exist'
                            ) : null
                          }
                        />
                      </ListItem>
                      {index < existingUsers.length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>

                {/* Status Alert */}
                {!hasUsers && (
                  <Alert severity="error" sx={{ mt: 2 }}>
                    <strong>No users found!</strong> This is why your notifications are failing. 
                    Create test users to fix the issue.
                  </Alert>
                )}
                {hasUsers && (
                  <Alert severity="success" sx={{ mt: 2 }}>
                    <strong>Users found!</strong> Your notification system should work properly.
                  </Alert>
                )}
              </>
            )}
          </Paper>
        </Grid>

        {/* Create Test Users */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Create Test Users
            </Typography>

            <Typography variant="body2" paragraph>
              This will create 8 test users with different designations and office names 
              to test the notification system.
            </Typography>

            <Box sx={{ mb: 3 }}>
              <Typography variant="subtitle2" gutterBottom>
                Test users will include:
              </Typography>
              <List dense>
                <ListItem>
                  <ListItemText primary="• GDS, MTS, Postman, Postal Assistant" />
                </ListItem>
                <ListItem>
                  <ListItemText primary="• Inspector, ASP, SP designations" />
                </ListItem>
                <ListItem>
                  <ListItemText primary="• Multiple office locations" />
                </ListItem>
                <ListItem>
                  <ListItemText primary="• Complete user profiles with stats" />
                </ListItem>
              </List>
            </Box>

            <Button
              fullWidth
              variant="contained"
              size="large"
              onClick={handleCreateTestUsers}
              disabled={loading}
              startIcon={loading ? <CircularProgress size={20} /> : <PersonAddIcon />}
              sx={{ mb: 2 }}
            >
              {loading ? 'Creating Users...' : 'Create Test Users'}
            </Button>

            <Button
              fullWidth
              variant="outlined"
              onClick={() => navigate('/notification-test')}
              disabled={!hasUsers}
            >
              Test Notifications
            </Button>

            {/* Creation Results */}
            {creationResults.length > 0 && (
              <Box sx={{ mt: 3 }}>
                <Typography variant="subtitle2" gutterBottom>
                  Creation Results:
                </Typography>
                <Box
                  sx={{
                    maxHeight: 300,
                    overflow: 'auto',
                    bgcolor: 'grey.50',
                    p: 2,
                    borderRadius: 1,
                    fontFamily: 'monospace',
                    fontSize: '0.875rem',
                  }}
                >
                  {creationResults.map((result, index) => (
                    <Box key={index} sx={{ mb: 0.5 }}>
                      {result}
                    </Box>
                  ))}
                </Box>
              </Box>
            )}
          </Paper>
        </Grid>
      </Grid>

      {/* Instructions */}
      <Paper sx={{ p: 3, mt: 3 }}>
        <Typography variant="h6" gutterBottom>
          Next Steps
        </Typography>
        <Typography variant="body2" paragraph>
          1. <strong>Create Test Users:</strong> Click the "Create Test Users" button above
        </Typography>
        <Typography variant="body2" paragraph>
          2. <strong>Test Notifications:</strong> Go to "Notification Test" page to verify the system works
        </Typography>
        <Typography variant="body2" paragraph>
          3. <strong>Send Real Notifications:</strong> Use "Notification Management" to send notifications to users
        </Typography>
        <Typography variant="body2">
          4. <strong>Check Mobile App:</strong> Verify notifications appear in the mobile app's exam section
        </Typography>
      </Paper>
    </Box>
  );
};

export default CreateTestUsersPage;
