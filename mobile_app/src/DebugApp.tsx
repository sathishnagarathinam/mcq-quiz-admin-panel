import React from 'react';
import { Box, Typography, Paper, Alert } from '@mui/material';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
  },
});

const DebugApp: React.FC = () => {
  console.log('🔧 DebugApp rendering...');
  
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ p: 4 }}>
        <Typography variant="h3" gutterBottom color="primary">
          🔧 Debug Mode - MCQ Quiz Admin
        </Typography>
        
        <Paper sx={{ p: 3, mb: 3 }}>
          <Alert severity="info" sx={{ mb: 2 }}>
            This is a debug version to test if the basic React app is working.
          </Alert>
          
          <Typography variant="h6" gutterBottom>
            Environment Check:
          </Typography>
          
          <Typography variant="body2" component="pre" sx={{ fontSize: '0.8rem', mb: 2 }}>
            {JSON.stringify({
              NODE_ENV: process.env.NODE_ENV,
              REACT_APP_FIREBASE_PROJECT_ID: process.env.REACT_APP_FIREBASE_PROJECT_ID || '[NOT SET]',
              REACT_APP_FIREBASE_AUTH_DOMAIN: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN || '[NOT SET]',
              timestamp: new Date().toISOString(),
            }, null, 2)}
          </Typography>
          
          <Typography variant="body1">
            ✅ React is working<br/>
            ✅ Material-UI is working<br/>
            ✅ Environment variables are {process.env.REACT_APP_FIREBASE_PROJECT_ID ? 'loaded' : 'missing'}
          </Typography>
        </Paper>
        
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Next Steps:
          </Typography>
          <Typography variant="body2">
            1. If you can see this page, the basic React app is working<br/>
            2. Check browser console for any JavaScript errors<br/>
            3. Verify Firebase configuration is loaded correctly<br/>
            4. Test Firebase connection
          </Typography>
        </Paper>
      </Box>
    </ThemeProvider>
  );
};

export default DebugApp;
