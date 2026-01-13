import React from 'react';
import { Box, Typography, Paper, Button, Grid, Card, CardContent, CardActions } from '@mui/material';
import { ArrowBack, Payment, Security, Notifications, Storage } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

const SettingsPage: React.FC = () => {
  const navigate = useNavigate();

  const settingsCategories = [
    {
      title: 'Payment Settings',
      description: 'Configure payment gateways, pricing, and transaction settings',
      icon: <Payment />,
      path: '/settings/payments',
      color: 'primary',
    },
    {
      title: 'Security Settings',
      description: 'Manage authentication, permissions, and security policies',
      icon: <Security />,
      path: '/settings/security',
      color: 'error',
    },
    {
      title: 'Notification Settings',
      description: 'Configure email, SMS, and push notification preferences',
      icon: <Notifications />,
      path: '/settings/notifications',
      color: 'warning',
    },
    {
      title: 'Data Management',
      description: 'Backup, export, and data retention settings',
      icon: <Storage />,
      path: '/settings/data',
      color: 'info',
    },
  ];

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <Button
          variant="outlined"
          startIcon={<ArrowBack />}
          onClick={() => navigate('/dashboard')}
          sx={{ minWidth: 'auto' }}
        >
          Back to Dashboard
        </Button>
        <Typography variant="h4" component="h1">
          ⚙️ Settings
        </Typography>
      </Box>

      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Manage system configuration and preferences
      </Typography>

      <Grid container spacing={3}>
        {settingsCategories.map((category) => (
          <Grid item xs={12} md={6} key={category.path}>
            <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
              <CardContent sx={{ flexGrow: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                  <Box
                    sx={{
                      p: 1,
                      borderRadius: 1,
                      backgroundColor: `${category.color}.light`,
                      color: `${category.color}.contrastText`,
                    }}
                  >
                    {category.icon}
                  </Box>
                  <Typography variant="h6" component="h2">
                    {category.title}
                  </Typography>
                </Box>
                <Typography variant="body2" color="text.secondary">
                  {category.description}
                </Typography>
              </CardContent>
              <CardActions>
                <Button
                  variant="contained"
                  color={category.color as any}
                  onClick={() => navigate(category.path)}
                  fullWidth
                >
                  Configure
                </Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

export default SettingsPage;
