import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Alert,
  Chip,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Send as SendIcon,
  History as HistoryIcon,
  Smartphone as SmartphoneIcon,
  Apple as AppleIcon,
  Android as AndroidIcon,
  Link as LinkIcon,
  Preview as PreviewIcon,
} from '@mui/icons-material';
import { appUpdateService, AppUpdateNotification, AppUpdateStats } from '../services/appUpdateService';

interface AppUpdateNotificationsProps {
  onNotificationSent?: () => void;
}

const AppUpdateNotifications: React.FC<AppUpdateNotificationsProps> = ({ onNotificationSent }) => {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [updateUrl, setUpdateUrl] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [appVersion, setAppVersion] = useState('');
  const [platform, setPlatform] = useState<'android' | 'ios' | 'both'>('both');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [stats, setStats] = useState<AppUpdateStats | null>(null);
  const [historyOpen, setHistoryOpen] = useState(false);
  const [previewOpen, setPreviewOpen] = useState(false);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const statsData = await appUpdateService.getAppUpdateStats();
      setStats(statsData);
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  };

  const handleGenerateContent = () => {
    if (!appVersion) {
      setError('Please enter app version first');
      return;
    }

    const content = appUpdateService.generateUpdateNotificationContent(appVersion, platform);
    setTitle(content.title);
    setBody(content.body);
    setError(null);
  };

  const handleUrlValidation = (url: string) => {
    if (!url) return;
    
    const validation = appUpdateService.validateAppStoreUrl(url);
    if (!validation.isValid) {
      setError(validation.error || 'Invalid URL');
    } else {
      setError(null);
      if (validation.platform) {
        setPlatform(validation.platform);
      }
    }
  };

  const handleSendNotification = async () => {
    if (!title || !body || !updateUrl) {
      setError('Title, body, and update URL are required');
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const notificationId = await appUpdateService.sendAppUpdateNotification({
        title,
        body,
        updateUrl,
        imageUrl: imageUrl || undefined,
        sentBy: 'admin', // You might want to get this from auth context
        targetAudience: 'all_users',
      });

      setSuccess(`App update notification sent successfully! ID: ${notificationId}`);
      
      // Clear form
      setTitle('');
      setBody('');
      setUpdateUrl('');
      setImageUrl('');
      setAppVersion('');
      setPlatform('both');

      // Reload stats
      await loadStats();
      
      // Notify parent component
      onNotificationSent?.();
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to send notification');
    } finally {
      setLoading(false);
    }
  };

  const handlePreview = () => {
    if (!title || !body) {
      setError('Title and body are required for preview');
      return;
    }
    setPreviewOpen(true);
  };

  return (
    <Box>
      <Card>
        <CardContent>
          <Typography variant="h5" gutterBottom>
            <SmartphoneIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
            Send App Update Notification
          </Typography>

          {/* Stats Display */}
          {stats && (
            <Box sx={{ mb: 3 }}>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <Chip
                    icon={<SendIcon />}
                    label={`${stats.totalNotificationsSent} notifications sent`}
                    color="primary"
                    variant="outlined"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  {stats.lastNotificationSent && (
                    <Chip
                      icon={<HistoryIcon />}
                      label={`Last sent: ${stats.lastNotificationSent.toLocaleDateString()}`}
                      color="secondary"
                      variant="outlined"
                    />
                  )}
                </Grid>
              </Grid>
            </Box>
          )}

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          {success && (
            <Alert severity="success" sx={{ mb: 2 }}>
              {success}
            </Alert>
          )}

          <Grid container spacing={2}>
            {/* App Version and Platform */}
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="App Version"
                value={appVersion}
                onChange={(e) => setAppVersion(e.target.value)}
                placeholder="e.g., 1.5.2"
                helperText="Used to generate notification content"
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Platform</InputLabel>
                <Select
                  value={platform}
                  label="Platform"
                  onChange={(e) => setPlatform(e.target.value as 'android' | 'ios' | 'both')}
                >
                  <MenuItem value="both">
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <AndroidIcon sx={{ mr: 1 }} />
                      <AppleIcon sx={{ mr: 1 }} />
                      Both Platforms
                    </Box>
                  </MenuItem>
                  <MenuItem value="android">
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <AndroidIcon sx={{ mr: 1 }} />
                      Android Only
                    </Box>
                  </MenuItem>
                  <MenuItem value="ios">
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <AppleIcon sx={{ mr: 1 }} />
                      iOS Only
                    </Box>
                  </MenuItem>
                </Select>
              </FormControl>
            </Grid>

            {/* Generate Content Button */}
            <Grid item xs={12}>
              <Button
                variant="outlined"
                onClick={handleGenerateContent}
                disabled={!appVersion}
                sx={{ mb: 2 }}
              >
                Generate Notification Content
              </Button>
            </Grid>

            {/* Notification Content */}
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Notification Title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
                inputProps={{ maxLength: 100 }}
                helperText={`${title.length}/100 characters`}
              />
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Notification Body"
                value={body}
                onChange={(e) => setBody(e.target.value)}
                required
                multiline
                rows={3}
                inputProps={{ maxLength: 250 }}
                helperText={`${body.length}/250 characters`}
              />
            </Grid>

            {/* Update URL */}
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="App Store/Update URL"
                value={updateUrl}
                onChange={(e) => {
                  setUpdateUrl(e.target.value);
                  handleUrlValidation(e.target.value);
                }}
                required
                placeholder="https://play.google.com/store/apps/details?id=..."
                helperText="Google Play Store, Apple App Store, or direct download URL"
                InputProps={{
                  startAdornment: <LinkIcon sx={{ mr: 1, color: 'action.active' }} />,
                }}
              />
            </Grid>

            {/* Optional Image URL */}
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Image URL (Optional)"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://example.com/update-image.jpg"
                helperText="Optional image to display in the notification"
              />
            </Grid>

            {/* Action Buttons */}
            <Grid item xs={12}>
              <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                <Button
                  variant="outlined"
                  startIcon={<PreviewIcon />}
                  onClick={handlePreview}
                  disabled={!title || !body}
                >
                  Preview
                </Button>
                
                <Button
                  variant="outlined"
                  startIcon={<HistoryIcon />}
                  onClick={() => setHistoryOpen(true)}
                >
                  View History
                </Button>

                <Button
                  variant="contained"
                  startIcon={<SendIcon />}
                  onClick={handleSendNotification}
                  disabled={loading || !title || !body || !updateUrl}
                  sx={{ ml: 'auto' }}
                >
                  {loading ? 'Sending...' : 'Send Notification'}
                </Button>
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Preview Dialog */}
      <Dialog open={previewOpen} onClose={() => setPreviewOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Notification Preview</DialogTitle>
        <DialogContent>
          <Box sx={{ p: 2, border: '1px solid #ddd', borderRadius: 1, bgcolor: 'grey.50' }}>
            <Typography variant="subtitle1" fontWeight="bold">
              {title}
            </Typography>
            <Typography variant="body2" sx={{ mt: 1 }}>
              {body}
            </Typography>
            {imageUrl && (
              <Box sx={{ mt: 2 }}>
                <img
                  src={imageUrl}
                  alt="Notification"
                  style={{ maxWidth: '100%', height: 'auto', borderRadius: 4 }}
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                  }}
                />
              </Box>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPreviewOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* History Dialog */}
      <Dialog open={historyOpen} onClose={() => setHistoryOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Notification History</DialogTitle>
        <DialogContent>
          {stats?.recentNotifications.length ? (
            <List>
              {stats.recentNotifications.map((notification) => (
                <ListItem key={notification.id} divider>
                  <ListItemText
                    primary={notification.title}
                    secondary={
                      <Box>
                        <Typography variant="body2">{notification.body}</Typography>
                        <Typography variant="caption" color="text.secondary">
                          Sent: {notification.sentAt?.toDate().toLocaleString()}
                        </Typography>
                      </Box>
                    }
                  />
                  <ListItemSecondaryAction>
                    <Tooltip title="Open Update URL">
                      <IconButton
                        edge="end"
                        onClick={() => window.open(notification.updateUrl, '_blank')}
                      >
                        <LinkIcon />
                      </IconButton>
                    </Tooltip>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          ) : (
            <Typography>No notifications sent yet.</Typography>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setHistoryOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default AppUpdateNotifications;
