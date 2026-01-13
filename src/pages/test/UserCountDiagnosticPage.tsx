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
  Refresh as RefreshIcon,
  ArrowBack as ArrowBackIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../../config/firebase';

interface UserData {
  id: string;
  name: string;
  email: string;
  designation: string;
  officeName: string;
  isActive: boolean;
  userType?: string;
  role?: string;
}

interface CollectionData {
  name: string;
  totalUsers: number;
  activeUsers: number;
  mobileUsers: number;
  sampleUsers: UserData[];
  designations: string[];
  offices: string[];
  error?: string;
}

const UserCountDiagnosticPage: React.FC = () => {
  const navigate = useNavigate();
  
  const [loading, setLoading] = useState(true);
  const [collections, setCollections] = useState<CollectionData[]>([]);

  useEffect(() => {
    loadDiagnosticData();
  }, []);

  const loadDiagnosticData = async () => {
    try {
      setLoading(true);
      
      const collectionsToCheck = ['mobile_users', 'users'];
      const results: CollectionData[] = [];

      for (const collectionName of collectionsToCheck) {
        try {
          console.log(`Checking collection: ${collectionName}`);
          
          const snapshot = await getDocs(collection(db, collectionName));
          const users: UserData[] = [];
          const designations = new Set<string>();
          const offices = new Set<string>();
          
          snapshot.docs.forEach(doc => {
            const userData = doc.data();
            const user: UserData = {
              id: doc.id,
              name: userData.name || 'Unknown',
              email: userData.email || 'No email',
              designation: userData.designation || 'Not specified',
              officeName: userData.officeName || 'Not specified',
              isActive: userData.isActive !== false,
              userType: userData.userType,
              role: userData.role,
            };
            
            users.push(user);
            
            if (userData.designation) {
              designations.add(userData.designation);
            }
            if (userData.officeName) {
              offices.add(userData.officeName);
            }
          });

          const activeUsers = users.filter(u => u.isActive);
          const mobileUsers = users.filter(u => 
            u.userType === 'mobile_user' || 
            u.role === 'user' || 
            (!u.userType && !u.role) ||
            (u.designation && u.designation !== 'Not specified')
          );

          results.push({
            name: collectionName,
            totalUsers: users.length,
            activeUsers: activeUsers.length,
            mobileUsers: mobileUsers.length,
            sampleUsers: users.slice(0, 5), // First 5 users for preview
            designations: Array.from(designations).sort(),
            offices: Array.from(offices).sort(),
          });

        } catch (error) {
          console.error(`Error checking collection ${collectionName}:`, error);
          results.push({
            name: collectionName,
            totalUsers: 0,
            activeUsers: 0,
            mobileUsers: 0,
            sampleUsers: [],
            designations: [],
            offices: [],
            error: String(error),
          });
        }
      }

      setCollections(results);
    } catch (error) {
      console.error('Error loading diagnostic data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getCollectionStatus = (collection: CollectionData) => {
    if (collection.error) return 'error';
    if (collection.totalUsers === 0) return 'warning';
    return 'success';
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'success': return 'success';
      case 'warning': return 'warning';
      case 'error': return 'error';
      default: return 'default';
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
          User Count Diagnostic
        </Typography>
        <Button
          startIcon={<RefreshIcon />}
          onClick={loadDiagnosticData}
          variant="contained"
          disabled={loading}
        >
          Refresh
        </Button>
      </Box>

      {loading ? (
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
          <CircularProgress />
        </Box>
      ) : (
        <Grid container spacing={3}>
          {collections.map((collection) => (
            <Grid item xs={12} md={6} key={collection.name}>
              <Paper sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                  <Typography variant="h6">
                    {collection.name} Collection
                  </Typography>
                  <Chip
                    label={getCollectionStatus(collection)}
                    color={getStatusColor(getCollectionStatus(collection)) as any}
                    size="small"
                  />
                </Box>

                {collection.error ? (
                  <Alert severity="error" sx={{ mb: 2 }}>
                    Error: {collection.error}
                  </Alert>
                ) : (
                  <>
                    {/* Stats */}
                    <Grid container spacing={2} sx={{ mb: 3 }}>
                      <Grid item xs={4}>
                        <Card>
                          <CardContent sx={{ textAlign: 'center', py: 2 }}>
                            <Typography variant="h4" color="primary.main">
                              {collection.totalUsers}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              Total Users
                            </Typography>
                          </CardContent>
                        </Card>
                      </Grid>
                      <Grid item xs={4}>
                        <Card>
                          <CardContent sx={{ textAlign: 'center', py: 2 }}>
                            <Typography variant="h4" color="success.main">
                              {collection.activeUsers}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              Active Users
                            </Typography>
                          </CardContent>
                        </Card>
                      </Grid>
                      <Grid item xs={4}>
                        <Card>
                          <CardContent sx={{ textAlign: 'center', py: 2 }}>
                            <Typography variant="h4" color="info.main">
                              {collection.mobileUsers}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              Mobile Users
                            </Typography>
                          </CardContent>
                        </Card>
                      </Grid>
                    </Grid>

                    {/* Sample Users */}
                    {collection.sampleUsers.length > 0 && (
                      <>
                        <Typography variant="subtitle1" gutterBottom>
                          Sample Users:
                        </Typography>
                        <List dense>
                          {collection.sampleUsers.map((user, index) => (
                            <React.Fragment key={user.id}>
                              <ListItem>
                                <ListItemText
                                  primary={user.name}
                                  secondary={`${user.designation} at ${user.officeName} | ${user.email}`}
                                />
                                <Box sx={{ display: 'flex', gap: 1 }}>
                                  {user.isActive && (
                                    <Chip label="Active" color="success" size="small" />
                                  )}
                                  {user.userType && (
                                    <Chip label={user.userType} color="primary" size="small" />
                                  )}
                                </Box>
                              </ListItem>
                              {index < collection.sampleUsers.length - 1 && <Divider />}
                            </React.Fragment>
                          ))}
                        </List>
                      </>
                    )}

                    {/* Designations */}
                    {collection.designations.length > 0 && (
                      <Box sx={{ mt: 2 }}>
                        <Typography variant="subtitle2" gutterBottom>
                          Designations ({collection.designations.length}):
                        </Typography>
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                          {collection.designations.slice(0, 6).map((designation) => (
                            <Chip key={designation} label={designation} size="small" variant="outlined" />
                          ))}
                          {collection.designations.length > 6 && (
                            <Chip label={`+${collection.designations.length - 6} more`} size="small" />
                          )}
                        </Box>
                      </Box>
                    )}

                    {/* Offices */}
                    {collection.offices.length > 0 && (
                      <Box sx={{ mt: 2 }}>
                        <Typography variant="subtitle2" gutterBottom>
                          Offices ({collection.offices.length}):
                        </Typography>
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                          {collection.offices.slice(0, 4).map((office) => (
                            <Chip key={office} label={office} size="small" variant="outlined" />
                          ))}
                          {collection.offices.length > 4 && (
                            <Chip label={`+${collection.offices.length - 4} more`} size="small" />
                          )}
                        </Box>
                      </Box>
                    )}
                  </>
                )}
              </Paper>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Summary */}
      <Paper sx={{ p: 3, mt: 3 }}>
        <Typography variant="h6" gutterBottom>
          Summary & Recommendations
        </Typography>
        
        {collections.length > 0 && (
          <>
            <Alert severity="info" sx={{ mb: 2 }}>
              <strong>Notification System Status:</strong> The notification system uses the <code>mobile_users</code> collection.
              {collections.find(c => c.name === 'mobile_users')?.totalUsers || 0} users found.
            </Alert>

            {collections.find(c => c.name === 'mobile_users')?.totalUsers === 8 && (
              <Alert severity="warning" sx={{ mb: 2 }}>
                <strong>Only 8 users found:</strong> These are likely test users. To see more users:
                <br />• Register more users through your mobile app
                <br />• Create additional test users using "Create Test Users" page
                <br />• Check if real users are registering in the correct collection
              </Alert>
            )}

            <Typography variant="body2" paragraph>
              <strong>Next Steps:</strong>
            </Typography>
            <Typography variant="body2" paragraph>
              1. If you want more test users: Go to "Create Test Users" and run it again (now creates 20 users)
            </Typography>
            <Typography variant="body2" paragraph>
              2. For real users: Have people register through your mobile app
            </Typography>
            <Typography variant="body2">
              3. The notification system will automatically pick up all users from the mobile_users collection
            </Typography>
          </>
        )}
      </Paper>
    </Box>
  );
};

export default UserCountDiagnosticPage;
