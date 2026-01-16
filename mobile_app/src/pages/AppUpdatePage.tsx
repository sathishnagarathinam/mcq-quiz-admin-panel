import React from 'react';
import {
  Container,
  Typography,
  Box,
  Breadcrumbs,
  Link,
  Paper,
} from '@mui/material';
import {
  Home as HomeIcon,
  Notifications as NotificationsIcon,
  Smartphone as SmartphoneIcon,
} from '@mui/icons-material';
import AppUpdateNotifications from '../components/AppUpdateNotifications';

const AppUpdatePage: React.FC = () => {
  const handleNotificationSent = () => {
    // You can add any additional logic here when a notification is sent
    console.log('App update notification sent successfully');
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* Breadcrumbs */}
      <Breadcrumbs aria-label="breadcrumb" sx={{ mb: 3 }}>
        <Link
          underline="hover"
          sx={{ display: 'flex', alignItems: 'center' }}
          color="inherit"
          href="/admin"
        >
          <HomeIcon sx={{ mr: 0.5 }} fontSize="inherit" />
          Admin
        </Link>
        <Link
          underline="hover"
          sx={{ display: 'flex', alignItems: 'center' }}
          color="inherit"
          href="/admin/notifications"
        >
          <NotificationsIcon sx={{ mr: 0.5 }} fontSize="inherit" />
          Notifications
        </Link>
        <Typography
          sx={{ display: 'flex', alignItems: 'center' }}
          color="text.primary"
        >
          <SmartphoneIcon sx={{ mr: 0.5 }} fontSize="inherit" />
          App Updates
        </Typography>
      </Breadcrumbs>

      {/* Page Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          App Update Notifications
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Send push notifications to all app users when a new version is available.
          Users will receive the notification and can tap to open the app store for updates.
        </Typography>
      </Box>

      {/* Main Content */}
      <Paper elevation={1} sx={{ p: 0 }}>
        <AppUpdateNotifications onNotificationSent={handleNotificationSent} />
      </Paper>

      {/* Help Section */}
      <Box sx={{ mt: 4 }}>
        <Typography variant="h6" gutterBottom>
          How it works:
        </Typography>
        <Box component="ul" sx={{ pl: 2 }}>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>Generate Content:</strong> Enter your app version and select platform to auto-generate notification text
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>Customize Message:</strong> Edit the title and body to match your update announcement
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>Add Store URL:</strong> Provide the Google Play Store or Apple App Store URL for the update
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>Send Notification:</strong> The notification will be sent to all app users who have notifications enabled
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>User Experience:</strong> Users tap the notification and are taken directly to the app store to update
          </Typography>
        </Box>
      </Box>

      {/* Best Practices */}
      <Box sx={{ mt: 3 }}>
        <Typography variant="h6" gutterBottom>
          Best Practices:
        </Typography>
        <Box component="ul" sx={{ pl: 2 }}>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            Send update notifications only for significant updates with new features or important bug fixes
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            Keep the message concise and highlight the key benefits of updating
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            Test the app store URLs before sending to ensure they work correctly
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            Consider timing - avoid sending during off-hours or when users are less likely to update
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            Monitor the notification history to avoid sending duplicate notifications
          </Typography>
        </Box>
      </Box>
    </Container>
  );
};

export default AppUpdatePage;
