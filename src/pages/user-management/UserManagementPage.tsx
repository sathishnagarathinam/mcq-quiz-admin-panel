import React from 'react';
import {
  Box,
  Container,
  Typography,
  Alert,
  Button,
} from '@mui/material';
import { ArrowBack } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import UserManagement from '../../components/admin/UserManagement';
import TestRegistration from '../../components/admin/TestRegistration';

const UserManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();

  // Check if user has system admin role
  if (adminUser?.role !== 'system_admin') {
    return (
      <Container maxWidth="lg">
        <Box sx={{ py: 4 }}>
          <Alert severity="error" sx={{ mb: 3 }}>
            <Typography variant="h6" gutterBottom>
              Access Denied
            </Typography>
            <Typography variant="body1">
              You need system administrator privileges to access this page.
            </Typography>
          </Alert>
          
          <Button
            variant="outlined"
            startIcon={<ArrowBack />}
            onClick={() => navigate('/dashboard')}
          >
            Back to Dashboard
          </Button>
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg">
      <Box sx={{ py: 4 }}>
        {/* Header */}
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 4 }}>
          <Button
            variant="outlined"
            startIcon={<ArrowBack />}
            onClick={() => navigate('/dashboard')}
            sx={{ mr: 2 }}
          >
            Back
          </Button>
          
          <Box>
            <Typography variant="h4" component="h1" gutterBottom>
              👑 User Management
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Manage admin users, approve registrations, and assign roles
            </Typography>
          </Box>
        </Box>

        {/* Test Registration (Development Only) */}
        {process.env.NODE_ENV === 'development' && (
          <TestRegistration />
        )}

        {/* User Management Component */}
        <UserManagement />

        {/* Help Section */}
        <Box sx={{ mt: 4, p: 3, bgcolor: 'background.paper', borderRadius: 2 }}>
          <Typography variant="h6" gutterBottom>
            💡 How to Use
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Approve Users:</strong> New admin registrations appear as "Pending". Click "Approve" to activate their accounts.
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Edit Roles:</strong> Click "Edit" to change user roles (Admin, Super Admin, System Admin) and account status.
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Deactivate Users:</strong> Click "Deactivate" to disable user accounts. They can be reactivated later.
          </Typography>
          
          <Typography variant="body2">
            <strong>Role Hierarchy:</strong> System Admin → Super Admin → Admin
          </Typography>
        </Box>
      </Box>
    </Container>
  );
};

export default UserManagementPage;
