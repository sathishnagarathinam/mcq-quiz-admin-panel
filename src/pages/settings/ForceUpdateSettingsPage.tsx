import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  Switch,
  FormControlLabel,
  TextField,
  Button,
  Divider,
  Alert,
  Chip,
  CircularProgress,
} from '@mui/material';
import {
  SystemUpdate as UpdateIcon,
  Save as SaveIcon,
  Refresh as RefreshIcon,
  PhoneAndroid as PhoneIcon,
  ArrowBack,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { ForceUpdateService, ForceUpdateConfig } from '../../services/forceUpdateService';
import { useAuth } from '../../contexts/AuthContext';
import toast from 'react-hot-toast';

const ForceUpdateSettingsPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  const [config, setConfig] = useState<ForceUpdateConfig>(ForceUpdateService.getDefaultConfig());
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [versionError, setVersionError] = useState<string | null>(null);

  useEffect(() => {
    loadConfig();
  }, []);

  useEffect(() => {
    // Subscribe to real-time updates
    const unsubscribe = ForceUpdateService.subscribeToConfig(
      (newConfig) => {
        setConfig(newConfig);
        setLoading(false);
      },
      (error) => {
        console.error('Error subscribing to config:', error);
        toast.error('Failed to subscribe to config updates');
      }
    );

    return () => unsubscribe();
  }, []);

  const loadConfig = async () => {
    try {
      setLoading(true);
      const fetchedConfig = await ForceUpdateService.getConfig();
      setConfig(fetchedConfig);
    } catch (error) {
      console.error('Error loading config:', error);
      toast.error('Failed to load force update configuration');
    } finally {
      setLoading(false);
    }
  };

  const handleVersionChange = (value: string) => {
    setConfig({ ...config, minRequiredVersion: value });
    if (value && !ForceUpdateService.isValidVersion(value)) {
      setVersionError('Version must be in format X.Y.Z (e.g., 1.0.5)');
    } else {
      setVersionError(null);
    }
  };

  const handleSave = async () => {
    if (versionError) {
      toast.error('Please fix the version format before saving');
      return;
    }

    if (!ForceUpdateService.isValidVersion(config.minRequiredVersion)) {
      toast.error('Invalid version format. Use X.Y.Z (e.g., 1.0.5)');
      return;
    }

    try {
      setSaving(true);
      await ForceUpdateService.saveConfig(
        {
          minRequiredVersion: config.minRequiredVersion,
          isForceUpdateEnabled: config.isForceUpdateEnabled,
          updateMessage: config.updateMessage,
          playStoreUrl: config.playStoreUrl,
        },
        adminUser?.email || 'unknown'
      );
      toast.success('Force update configuration saved successfully!');
    } catch (error) {
      console.error('Error saving config:', error);
      toast.error('Failed to save configuration');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <Button
          variant="outlined"
          startIcon={<ArrowBack />}
          onClick={() => navigate('/settings')}
        >
          Back to Settings
        </Button>
        <Typography variant="h4" component="h1">
          📱 Force App Update Settings
        </Typography>
      </Box>

      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Control when users must update the mobile app. When enabled, users with older app versions will be blocked from using the app until they update.
      </Typography>

      {/* Current Status Card */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <UpdateIcon color={config.isForceUpdateEnabled ? 'error' : 'disabled'} sx={{ fontSize: 40 }} />
              <Box>
                <Typography variant="h6">Force Update Status</Typography>
                <Typography variant="body2" color="text.secondary">
                  {config.isForceUpdateEnabled
                    ? `Users with version below ${config.minRequiredVersion} will be blocked`
                    : 'Force update is currently disabled'}
                </Typography>
              </Box>
            </Box>
            <Chip
              label={config.isForceUpdateEnabled ? 'ACTIVE' : 'DISABLED'}
              color={config.isForceUpdateEnabled ? 'error' : 'default'}
              size="medium"
            />
          </Box>
        </CardContent>
      </Card>

      <Grid container spacing={3}>
        {/* Configuration Section */}
        <Grid item xs={12} md={7}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <UpdateIcon /> Configuration
            </Typography>
            <Divider sx={{ mb: 3 }} />

            {/* Enable/Disable Toggle */}
            <FormControlLabel
              control={
                <Switch
                  checked={config.isForceUpdateEnabled}
                  onChange={(e) => setConfig({ ...config, isForceUpdateEnabled: e.target.checked })}
                  color="error"
                />
              }
              label={
                <Box>
                  <Typography variant="body1">Enable Force Update</Typography>
                  <Typography variant="caption" color="text.secondary">
                    When enabled, users with older versions will be blocked
                  </Typography>
                </Box>
              }
              sx={{ mb: 3, display: 'flex' }}
            />

            {/* Minimum Required Version */}
            <TextField
              fullWidth
              label="Minimum Required Version"
              value={config.minRequiredVersion}
              onChange={(e) => handleVersionChange(e.target.value)}
              error={!!versionError}
              helperText={versionError || 'Format: X.Y.Z (e.g., 1.0.5)'}
              placeholder="1.0.5"
              sx={{ mb: 3 }}
            />

            {/* Update Message */}
            <TextField
              fullWidth
              label="Update Message"
              value={config.updateMessage}
              onChange={(e) => setConfig({ ...config, updateMessage: e.target.value })}
              multiline
              rows={3}
              helperText="This message will be displayed to users who need to update"
              sx={{ mb: 3 }}
            />

            {/* Play Store URL */}
            <TextField
              fullWidth
              label="Play Store URL"
              value={config.playStoreUrl}
              onChange={(e) => setConfig({ ...config, playStoreUrl: e.target.value })}
              helperText="URL where users will be redirected to update the app"
              placeholder="https://play.google.com/store/apps/details?id=com.mcqquiz1.app"
              sx={{ mb: 3 }}
            />

            {/* Action Buttons */}
            <Box sx={{ display: 'flex', gap: 2, mt: 3 }}>
              <Button
                variant="contained"
                color="primary"
                startIcon={saving ? <CircularProgress size={20} color="inherit" /> : <SaveIcon />}
                onClick={handleSave}
                disabled={saving || !!versionError}
              >
                {saving ? 'Saving...' : 'Save Configuration'}
              </Button>
              <Button
                variant="outlined"
                startIcon={<RefreshIcon />}
                onClick={loadConfig}
                disabled={loading}
              >
                Refresh
              </Button>
            </Box>

            {/* Last Updated Info */}
            {config.lastUpdatedAt && (
              <Alert severity="info" sx={{ mt: 3 }}>
                Last updated on {config.lastUpdatedAt.toLocaleString()} by {config.updatedBy || 'Unknown'}
              </Alert>
            )}
          </Paper>
        </Grid>

        {/* Preview Section */}
        <Grid item xs={12} md={5}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <PhoneIcon /> Mobile App Preview
            </Typography>
            <Divider sx={{ mb: 3 }} />

            {/* Phone Mockup */}
            <Box
              sx={{
                bgcolor: '#f5f5f5',
                borderRadius: 4,
                p: 2,
                border: '8px solid #333',
                minHeight: 400,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <UpdateIcon sx={{ fontSize: 80, color: '#ff5722', mb: 2 }} />
              <Typography variant="h6" align="center" gutterBottom>
                Update Required
              </Typography>
              <Typography variant="body2" color="text.secondary" align="center" sx={{ mb: 3, px: 2 }}>
                {config.updateMessage || 'Please update the app to continue.'}
              </Typography>
              <Typography variant="caption" color="text.secondary" sx={{ mb: 2 }}>
                Minimum version: {config.minRequiredVersion}
              </Typography>
              <Button variant="contained" color="primary" size="large" sx={{ borderRadius: 3 }}>
                Update Now
              </Button>
            </Box>

            <Alert severity="warning" sx={{ mt: 2 }}>
              This preview shows what users will see when force update is enabled and their app version is below the minimum required version.
            </Alert>
          </Paper>
        </Grid>
      </Grid>

      {/* Important Notes */}
      <Paper sx={{ p: 3, mt: 3 }}>
        <Typography variant="h6" gutterBottom>
          ⚠️ Important Notes
        </Typography>
        <Divider sx={{ mb: 2 }} />
        <Box component="ul" sx={{ m: 0, pl: 3 }}>
          <li>
            <Typography variant="body2" color="text.secondary">
              Force update affects all mobile app users immediately after saving.
            </Typography>
          </li>
          <li>
            <Typography variant="body2" color="text.secondary">
              Make sure the new app version is published on the Play Store before enabling force update.
            </Typography>
          </li>
          <li>
            <Typography variant="body2" color="text.secondary">
              Users will be blocked from using the app until they update - use this feature carefully.
            </Typography>
          </li>
          <li>
            <Typography variant="body2" color="text.secondary">
              Version comparison uses semantic versioning (major.minor.patch).
            </Typography>
          </li>
        </Box>
      </Paper>
    </Box>
  );
};

export default ForceUpdateSettingsPage;

