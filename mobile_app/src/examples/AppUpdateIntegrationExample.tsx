import React, { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  Tabs,
  Tab,
  Paper,
  Button,
  Alert,
} from '@mui/material';
import {
  Notifications as NotificationsIcon,
  Smartphone as SmartphoneIcon,
  Send as SendIcon,
  History as HistoryIcon,
} from '@mui/icons-material';
import AppUpdateNotifications from '../components/AppUpdateNotifications';

// This is an example of how to integrate the App Update functionality
// into your existing notification management page

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`notification-tabpanel-${index}`}
      aria-labelledby={`notification-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const AppUpdateIntegrationExample: React.FC = () => {
  const [tabValue, setTabValue] = useState(0);
  const [updateNotificationSent, setUpdateNotificationSent] = useState(false);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleAppUpdateNotificationSent = () => {
    setUpdateNotificationSent(true);
    // You can add additional logic here, such as:
    // - Refreshing other notification lists
    // - Showing a success message
    // - Logging the action
    console.log('App update notification sent successfully!');
    
    // Reset the flag after a few seconds
    setTimeout(() => {
      setUpdateNotificationSent(false);
    }, 5000);
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Notification Management
      </Typography>
      
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Manage all types of notifications sent to mobile app users.
      </Typography>

      {updateNotificationSent && (
        <Alert severity="success" sx={{ mb: 3 }}>
          App update notification sent successfully! Users will receive the notification shortly.
        </Alert>
      )}

      <Paper sx={{ width: '100%' }}>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={tabValue} onChange={handleTabChange} aria-label="notification tabs">
            <Tab
              icon={<NotificationsIcon />}
              label="General Notifications"
              id="notification-tab-0"
              aria-controls="notification-tabpanel-0"
            />
            <Tab
              icon={<SmartphoneIcon />}
              label="App Updates"
              id="notification-tab-1"
              aria-controls="notification-tabpanel-1"
            />
            <Tab
              icon={<HistoryIcon />}
              label="Notification History"
              id="notification-tab-2"
              aria-controls="notification-tabpanel-2"
            />
          </Tabs>
        </Box>

        <TabPanel value={tabValue} index={0}>
          {/* Your existing general notification management component would go here */}
          <Box sx={{ textAlign: 'center', py: 4 }}>
            <NotificationsIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
            <Typography variant="h6" gutterBottom>
              General Notifications
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
              This is where your existing notification management component would be integrated.
              You can send quiz notifications, announcements, and other general messages here.
            </Typography>
            <Button
              variant="outlined"
              startIcon={<SendIcon />}
              onClick={() => {
                // Navigate to your existing notification sender
                console.log('Navigate to general notification sender');
              }}
            >
              Send General Notification
            </Button>
          </Box>
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          {/* App Update Notifications Component */}
          <AppUpdateNotifications onNotificationSent={handleAppUpdateNotificationSent} />
        </TabPanel>

        <TabPanel value={tabValue} index={2}>
          {/* Notification History would go here */}
          <Box sx={{ textAlign: 'center', py: 4 }}>
            <HistoryIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
            <Typography variant="h6" gutterBottom>
              Notification History
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
              View all sent notifications including general notifications and app updates.
              This would show a combined history from your existing notification system
              and the new app update notifications.
            </Typography>
            <Button
              variant="outlined"
              startIcon={<HistoryIcon />}
              onClick={() => {
                // Load and display notification history
                console.log('Load notification history');
              }}
            >
              View All History
            </Button>
          </Box>
        </TabPanel>
      </Paper>

      {/* Integration Instructions */}
      <Box sx={{ mt: 4 }}>
        <Typography variant="h6" gutterBottom>
          Integration Instructions:
        </Typography>
        <Box component="ol" sx={{ pl: 2 }}>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>Import the component:</strong> Add <code>AppUpdateNotifications</code> to your existing notification management page
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>Add to navigation:</strong> Include an "App Updates" tab or menu item in your admin dashboard
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>Handle callbacks:</strong> Use the <code>onNotificationSent</code> prop to refresh other parts of your UI
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>Customize styling:</strong> The component uses Material-UI and can be styled to match your theme
          </Typography>
          <Typography component="li" variant="body2" sx={{ mb: 1 }}>
            <strong>Add permissions:</strong> Ensure admin users have the appropriate permissions to send app update notifications
          </Typography>
        </Box>
      </Box>

      {/* Code Example */}
      <Box sx={{ mt: 3 }}>
        <Typography variant="h6" gutterBottom>
          Quick Integration Code:
        </Typography>
        <Paper sx={{ p: 2, bgcolor: 'grey.100' }}>
          <Typography variant="body2" component="pre" sx={{ fontFamily: 'monospace' }}>
{`import AppUpdateNotifications from '../components/AppUpdateNotifications';

// In your notification management component:
<AppUpdateNotifications 
  onNotificationSent={() => {
    // Handle successful notification send
    console.log('App update notification sent!');
    // Refresh notification history, show success message, etc.
  }} 
/>`}
          </Typography>
        </Paper>
      </Box>
    </Container>
  );
};

export default AppUpdateIntegrationExample;
