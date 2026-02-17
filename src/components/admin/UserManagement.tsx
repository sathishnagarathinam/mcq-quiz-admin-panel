import React, { useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Button,
  Chip,
  Box,
  Alert,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  CheckCircle,
  Cancel,
  Person,
  AdminPanelSettings,
  SupervisorAccount,
  Refresh,
} from '@mui/icons-material';
import { collection, getDocs, doc, updateDoc } from 'firebase/firestore';
import { db } from '../../config/firebase';
import { useAuth } from '../../contexts/AuthContext';
import { getFirebaseErrorMessage, logError } from '../../utils/errorUtils';
import toast from 'react-hot-toast';

interface PendingUser {
  uid: string;
  email: string;
  name: string;
  role: string;
  createdAt: any;
  isActive: boolean;
  status?: 'pending' | 'approved' | 'rejected';
  approvedBy?: string;
  approvedAt?: any;
  lastLogin?: any;
}

const UserManagement: React.FC = () => {
  const { adminUser } = useAuth();
  const [users, setUsers] = useState<PendingUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [editDialog, setEditDialog] = useState<{ open: boolean; user: PendingUser | null }>({
    open: false,
    user: null,
  });


  const fetchUsers = async () => {
    try {
      setLoading(true);
      console.log('🔍 Fetching users from admin_users collection...');

      const usersRef = collection(db, 'admin_users');
      const snapshot = await getDocs(usersRef);

      console.log('📊 Total documents found:', snapshot.size);

      const usersList: PendingUser[] = [];
      snapshot.forEach((doc) => {
        const userData = doc.data() as Omit<PendingUser, 'uid'>;
        console.log('👤 User found:', {
          id: doc.id,
          email: userData.email,
          name: userData.name,
          status: userData.status,
          isActive: userData.isActive,
          role: userData.role
        });

        // Ensure required fields have default values
        const safeUserData: PendingUser = {
          uid: doc.id,
          email: userData.email || '',
          name: userData.name || 'Unknown User',
          role: userData.role || 'admin',
          createdAt: userData.createdAt || null,
          isActive: userData.isActive ?? false,
          status: userData.status || 'pending',
          approvedBy: userData.approvedBy,
          approvedAt: userData.approvedAt,
          lastLogin: userData.lastLogin,
        };

        usersList.push(safeUserData);
      });

      // Sort by creation date (newest first)
      usersList.sort((a, b) => {
        if (a.createdAt && b.createdAt) {
          return b.createdAt.seconds - a.createdAt.seconds;
        }
        return 0;
      });

      console.log('📋 Final users list:', usersList.length, 'users');
      setUsers(usersList);
    } catch (error) {
      logError('UserManagement.fetchUsers', error);
      const errorMessage = getFirebaseErrorMessage(error);
      toast.error('Failed to fetch users: ' + errorMessage);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    console.log('🔐 Current admin user:', {
      role: adminUser?.role,
      email: adminUser?.email,
      isSystemAdmin: adminUser?.role === 'system_admin'
    });

    if (adminUser?.role === 'system_admin') {
      console.log('✅ System admin detected, fetching users...');
      fetchUsers();
    } else {
      console.log('❌ Not a system admin, role:', adminUser?.role);
    }
  }, [adminUser]);

  const handleApproveUser = async (userId: string) => {
    try {
      setActionLoading(userId);
      const userRef = doc(db, 'admin_users', userId);

      const updateData: any = {
        isActive: true,
        status: 'approved',
        approvedAt: new Date(),
        role: 'admin', // Set default role as admin
      };

      // Only add approvedBy if adminUser exists
      if (adminUser?.uid) {
        updateData.approvedBy = adminUser.uid;
      }

      await updateDoc(userRef, updateData);

      toast.success('User approved successfully! They can now login to the admin panel.');
      fetchUsers(); // Refresh the list
    } catch (error) {
      logError('UserManagement.handleApproveUser', error, { userId });
      const errorMessage = getFirebaseErrorMessage(error);
      toast.error('Failed to approve user: ' + errorMessage);
    } finally {
      setActionLoading(null);
    }
  };

  const handleRejectUser = async (userId: string) => {
    try {
      setActionLoading(userId);
      const userRef = doc(db, 'admin_users', userId);

      const updateData: any = {
        isActive: false,
        status: 'rejected',
        approvedAt: new Date(),
      };

      // Only add approvedBy if adminUser exists
      if (adminUser?.uid) {
        updateData.approvedBy = adminUser.uid;
      }

      await updateDoc(userRef, updateData);

      toast.success('User rejected. They will not be able to access the admin panel.');
      fetchUsers(); // Refresh the list
    } catch (error) {
      logError('UserManagement.handleRejectUser', error, { userId });
      const errorMessage = getFirebaseErrorMessage(error);
      toast.error('Failed to reject user: ' + errorMessage);
    } finally {
      setActionLoading(null);
    }
  };

  const handleEditUser = (user: PendingUser) => {
    setEditDialog({ open: true, user });
  };

  const handleSaveEdit = async () => {
    if (!editDialog.user) return;

    try {
      setActionLoading(editDialog.user.uid);
      const userRef = doc(db, 'admin_users', editDialog.user.uid);
      await updateDoc(userRef, {
        role: editDialog.user.role,
        isActive: editDialog.user.isActive,
      });
      
      toast.success('User updated successfully!');
      setEditDialog({ open: false, user: null });
      fetchUsers(); // Refresh the list
    } catch (error) {
      logError('UserManagement.handleSaveEdit', error, { userId: editDialog.user?.uid });
      const errorMessage = getFirebaseErrorMessage(error);
      toast.error('Failed to update user: ' + errorMessage);
    } finally {
      setActionLoading(null);
    }
  };

  const getRoleIcon = (role: string) => {
    switch (role) {
      case 'system_admin':
        return <SupervisorAccount />;
      case 'super_admin':
        return <AdminPanelSettings />;
      case 'admin':
        return <Person />;
      default:
        return <Person />;
    }
  };

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'system_admin':
        return 'error';
      case 'super_admin':
        return 'warning';
      case 'admin':
        return 'primary';
      default:
        return 'default';
    }
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    return new Date(timestamp.seconds * 1000).toLocaleDateString();
  };

  // Debug: Show component for all admin roles in development
  const shouldShowComponent = adminUser?.role === 'system_admin' ||
    (process.env.NODE_ENV === 'development' && adminUser?.role);

  if (!shouldShowComponent) {
    console.log('🚫 UserManagement not shown - Current role:', adminUser?.role);
    return null; // Don't render for non-system admins
  }

  console.log('✅ UserManagement component rendering for role:', adminUser?.role);

  return (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
          <Box>
            <Typography variant="h6" component="h3">
              👥 Admin User Management
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {users.length} admin user(s) found | Role: {adminUser?.role}
            </Typography>
          </Box>
          <Tooltip title="Refresh user list">
            <IconButton onClick={fetchUsers} disabled={loading}>
              <Refresh />
            </IconButton>
          </Tooltip>
        </Box>

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
            <CircularProgress />
          </Box>
        ) : users.length === 0 ? (
          <Box>
            <Alert severity="info" sx={{ mb: 2 }}>
              No users found. Users will appear here when they register for admin access.
            </Alert>

            {process.env.NODE_ENV === 'development' && (
              <Alert severity="warning" sx={{ mb: 2 }}>
                <Typography variant="body2" gutterBottom>
                  <strong>Debug Mode:</strong> If you've registered users but don't see them:
                </Typography>
                <Typography variant="body2" component="div">
                  1. Check browser console for errors<br/>
                  2. Verify Firestore rules allow access<br/>
                  3. Confirm users exist in Firebase Console<br/>
                  4. Try refreshing the page
                </Typography>
              </Alert>
            )}
          </Box>
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Name</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Role</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Created</TableCell>
                  <TableCell align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {users.map((user) => (
                  <TableRow key={user.uid}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        {getRoleIcon(user.role || 'unknown')}
                        {user.name || 'Unknown User'}
                      </Box>
                    </TableCell>
                    <TableCell>{user.email || 'No email'}</TableCell>
                    <TableCell>
                      <Chip
                        label={(user.role || 'unknown').replace('_', ' ').toUpperCase()}
                        color={getRoleColor(user.role || 'unknown') as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={
                          user.status === 'pending' ? 'Pending Approval' :
                          user.status === 'approved' ? 'Approved' :
                          user.status === 'rejected' ? 'Rejected' :
                          user.isActive ? 'Active' : 'Inactive'
                        }
                        color={
                          user.status === 'pending' ? 'warning' :
                          user.status === 'approved' ? 'success' :
                          user.status === 'rejected' ? 'error' :
                          user.isActive ? 'success' : 'default'
                        }
                        size="small"
                      />
                    </TableCell>
                    <TableCell>{formatDate(user.createdAt)}</TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center', flexWrap: 'wrap' }}>
                        {user.status === 'pending' && (
                          <>
                            <Tooltip title="Approve user registration">
                              <Button
                                size="small"
                                variant="contained"
                                color="success"
                                startIcon={<CheckCircle />}
                                onClick={() => handleApproveUser(user.uid)}
                                disabled={actionLoading === user.uid}
                              >
                                Approve
                              </Button>
                            </Tooltip>

                            <Tooltip title="Reject user registration">
                              <Button
                                size="small"
                                variant="outlined"
                                color="error"
                                startIcon={<Cancel />}
                                onClick={() => handleRejectUser(user.uid)}
                                disabled={actionLoading === user.uid}
                              >
                                Reject
                              </Button>
                            </Tooltip>
                          </>
                        )}

                        {user.status !== 'pending' && (
                          <Tooltip title="Edit admin user">
                            <Button
                              size="small"
                              variant="outlined"
                              onClick={() => handleEditUser(user)}
                              disabled={actionLoading === user.uid}
                            >
                              Edit
                            </Button>
                          </Tooltip>
                        )}

                        {user.status === 'approved' && user.isActive && (
                          <Tooltip title="Deactivate user">
                            <Button
                              size="small"
                              variant="outlined"
                              color="error"
                              startIcon={<Cancel />}
                              onClick={() => handleRejectUser(user.uid)}
                              disabled={actionLoading === user.uid}
                            >
                              Deactivate
                            </Button>
                          </Tooltip>
                        )}
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}

        {/* Edit User Dialog */}
        <Dialog open={editDialog.open} onClose={() => setEditDialog({ open: false, user: null })}>
          <DialogTitle>Edit User</DialogTitle>
          <DialogContent>
            <Box sx={{ pt: 2, minWidth: 300 }}>
              <TextField
                fullWidth
                label="Name"
                value={editDialog.user?.name || ''}
                disabled
                sx={{ mb: 2 }}
              />
              <TextField
                fullWidth
                label="Email"
                value={editDialog.user?.email || ''}
                disabled
                sx={{ mb: 2 }}
              />
              <TextField
                fullWidth
                select
                label="Role"
                value={editDialog.user?.role || 'admin'}
                onChange={(e) =>
                  setEditDialog({
                    ...editDialog,
                    user: editDialog.user ? { ...editDialog.user, role: e.target.value } : null,
                  })
                }
                sx={{ mb: 2 }}
              >
                <MenuItem value="user">User</MenuItem>
                <MenuItem value="admin">Admin</MenuItem>
                <MenuItem value="super_admin">Super Admin</MenuItem>
                <MenuItem value="system_admin">System Admin</MenuItem>
              </TextField>
              <TextField
                fullWidth
                select
                label="Status"
                value={editDialog.user?.isActive ? 'active' : 'inactive'}
                onChange={(e) =>
                  setEditDialog({
                    ...editDialog,
                    user: editDialog.user
                      ? { ...editDialog.user, isActive: e.target.value === 'active' }
                      : null,
                  })
                }
              >
                <MenuItem value="active">Active</MenuItem>
                <MenuItem value="inactive">Inactive</MenuItem>
              </TextField>
            </Box>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setEditDialog({ open: false, user: null })}>Cancel</Button>
            <Button onClick={handleSaveEdit} variant="contained">
              Save Changes
            </Button>
          </DialogActions>
        </Dialog>
      </CardContent>
    </Card>
  );
};

export default UserManagement;
