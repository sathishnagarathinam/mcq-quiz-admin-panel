import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Grid,
  Card,
  CardContent,
  CircularProgress,
  Tooltip,
  Alert,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,

  ArrowBack as ArrowBackIcon,
  Notifications as NotificationsIcon,
  People as PeopleIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { NotificationService } from '../../services/notificationService';
import { Notification } from '../../types/notification';

const NotificationManagementPage: React.FC = () => {
  const navigate = useNavigate();
  
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedNotification, setSelectedNotification] = useState<Notification | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  useEffect(() => {
    loadNotifications();
  }, []);

  const loadNotifications = async () => {
    try {
      setLoading(true);
      const data = await NotificationService.getNotifications();
      setNotifications(data);
    } catch (error) {
      console.error('Error loading notifications:', error);
      toast.error('Failed to load notifications');
    } finally {
      setLoading(false);
    }
  };

  const handleViewNotification = (notification: Notification) => {
    setSelectedNotification(notification);
    setViewDialogOpen(true);
  };

  const handleDeleteNotification = async () => {
    if (!selectedNotification) return;

    try {
      setActionLoading(selectedNotification.id);
      await NotificationService.deleteNotification(selectedNotification.id);
      toast.success('Notification deleted successfully');
      setDeleteDialogOpen(false);
      setSelectedNotification(null);
      loadNotifications();
    } catch (error) {
      console.error('Error deleting notification:', error);
      toast.error('Failed to delete notification');
    } finally {
      setActionLoading(null);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'sent':
        return 'success';
      case 'sending':
        return 'warning';
      case 'failed':
        return 'error';
      case 'draft':
        return 'default';
      default:
        return 'default';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent':
        return 'error';
      case 'high':
        return 'warning';
      case 'normal':
        return 'primary';
      case 'low':
        return 'default';
      default:
        return 'default';
    }
  };

  const formatTargetType = (target: any) => {
    switch (target.type) {
      case 'all':
        return 'All Users';
      case 'specific_users':
        return `${target.userIds?.length || 0} Specific Users`;
      case 'designation':
        return `Designation: ${target.designation}`;
      case 'office':
        return `Office: ${target.officeName}`;
      default:
        return 'Unknown';
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

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
          Notification Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => navigate('/notifications/send')}
        >
          Send New Notification
        </Button>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <NotificationsIcon sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
              <Typography variant="h4" color="primary.main">
                {notifications.length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total Notifications
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <CheckCircleIcon sx={{ fontSize: 40, color: 'success.main', mb: 1 }} />
              <Typography variant="h4" color="success.main">
                {notifications.filter(n => n.status === 'sent').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Sent Successfully
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <PeopleIcon sx={{ fontSize: 40, color: 'info.main', mb: 1 }} />
              <Typography variant="h4" color="info.main">
                {notifications.reduce((sum, n) => sum + n.sentCount, 0)}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total Recipients
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <ErrorIcon sx={{ fontSize: 40, color: 'error.main', mb: 1 }} />
              <Typography variant="h4" color="error.main">
                {notifications.filter(n => n.status === 'failed').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Failed
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Notifications Table */}
      <Paper>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Title</TableCell>
                <TableCell>Target</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Priority</TableCell>
                <TableCell>Category</TableCell>
                <TableCell>Recipients</TableCell>
                <TableCell>Created</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {notifications.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center">
                    <Alert severity="info">
                      No notifications found. Create your first notification!
                    </Alert>
                  </TableCell>
                </TableRow>
              ) : (
                notifications.map((notification) => (
                  <TableRow key={notification.id}>
                    <TableCell>
                      <Typography variant="subtitle2" noWrap>
                        {notification.title}
                      </Typography>
                      <Typography variant="body2" color="text.secondary" noWrap>
                        {notification.body.substring(0, 50)}...
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {formatTargetType(notification.target)}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={notification.status.toUpperCase()}
                        color={getStatusColor(notification.status) as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={notification.priority.toUpperCase()}
                        color={getPriorityColor(notification.priority) as any}
                        size="small"
                        variant="outlined"
                      />
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {notification.category.replace('_', ' ').toUpperCase()}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {notification.sentCount} / {notification.totalTargets}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {notification.createdAt?.toLocaleDateString()}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Tooltip title="View Details">
                        <IconButton
                          size="small"
                          onClick={() => handleViewNotification(notification)}
                        >
                          <ViewIcon />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Delete">
                        <IconButton
                          size="small"
                          onClick={() => {
                            setSelectedNotification(notification);
                            setDeleteDialogOpen(true);
                          }}
                          disabled={actionLoading === notification.id}
                        >
                          {actionLoading === notification.id ? (
                            <CircularProgress size={16} />
                          ) : (
                            <DeleteIcon />
                          )}
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* View Notification Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Notification Details</DialogTitle>
        <DialogContent>
          {selectedNotification && (
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <Typography variant="h6">{selectedNotification.title}</Typography>
                <Typography variant="body1" sx={{ mt: 1 }}>
                  {selectedNotification.body}
                </Typography>
              </Grid>
              {selectedNotification.imageUrl && (
                <Grid item xs={12}>
                  <img
                    src={selectedNotification.imageUrl}
                    alt="Notification"
                    style={{ maxWidth: '100%', height: 'auto' }}
                  />
                </Grid>
              )}
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2">Status:</Typography>
                <Chip
                  label={selectedNotification.status.toUpperCase()}
                  color={getStatusColor(selectedNotification.status) as any}
                  size="small"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2">Priority:</Typography>
                <Chip
                  label={selectedNotification.priority.toUpperCase()}
                  color={getPriorityColor(selectedNotification.priority) as any}
                  size="small"
                  variant="outlined"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2">Category:</Typography>
                <Typography variant="body2">
                  {selectedNotification.category.replace('_', ' ').toUpperCase()}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2">Target:</Typography>
                <Typography variant="body2">
                  {formatTargetType(selectedNotification.target)}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2">Recipients:</Typography>
                <Typography variant="body2">
                  {selectedNotification.sentCount} / {selectedNotification.totalTargets}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2">Created:</Typography>
                <Typography variant="body2">
                  {selectedNotification.createdAt?.toLocaleString()}
                </Typography>
              </Grid>
              {selectedNotification.sentAt && (
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2">Sent:</Typography>
                  <Typography variant="body2">
                    {selectedNotification.sentAt.toLocaleString()}
                  </Typography>
                </Grid>
              )}
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
      >
        <DialogTitle>Delete Notification</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete this notification? This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={handleDeleteNotification}
            color="error"
            disabled={!!actionLoading}
          >
            {actionLoading ? <CircularProgress size={20} /> : 'Delete'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default NotificationManagementPage;
