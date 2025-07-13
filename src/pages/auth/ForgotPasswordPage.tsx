import React, { useState } from 'react';
import { Navigate, Link } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Container,
  Alert,
} from '@mui/material';
import { LockReset, ArrowBack } from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';

const ForgotPasswordPage: React.FC = () => {
  const { resetPassword, user } = useAuth();

  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // Redirect if already authenticated
  if (user) {
    return <Navigate to="/dashboard" replace />;
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess(false);

    if (!email.trim()) {
      setError('Email is required');
      return;
    }

    setIsLoading(true);

    try {
      await resetPassword(email);
      setSuccess(true);
    } catch (error: any) {
      setError(error.message || 'Failed to send password reset email');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Container component="main" maxWidth="sm">
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          py: 4,
        }}
      >
        <Card elevation={3}>
          <CardContent sx={{ p: 4 }}>
            {/* Header */}
            <Box sx={{ textAlign: 'center', mb: 4 }}>
              <LockReset 
                sx={{ 
                  fontSize: 48, 
                  color: 'primary.main', 
                  mb: 2 
                }} 
              />
              <Typography
                component="h1"
                variant="h4"
                gutterBottom
                sx={{ fontWeight: 600 }}
              >
                Reset Password
              </Typography>
              <Typography variant="body1" color="text.secondary">
                Enter your email address and we'll send you a link to reset your password
              </Typography>
            </Box>

            {error && (
              <Alert severity="error" sx={{ mb: 3 }}>
                {error}
              </Alert>
            )}

            {success && (
              <Alert severity="success" sx={{ mb: 3 }}>
                Password reset email sent! Check your inbox and follow the instructions to reset your password.
              </Alert>
            )}

            {!success ? (
              <Box component="form" onSubmit={handleSubmit}>
                <TextField
                  margin="normal"
                  required
                  fullWidth
                  id="email"
                  label="Email Address"
                  name="email"
                  autoComplete="email"
                  autoFocus
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={isLoading}
                  sx={{ mb: 3 }}
                />

                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  size="large"
                  disabled={isLoading || !email.trim()}
                  sx={{ mb: 3, py: 1.5 }}
                >
                  {isLoading ? 'Sending...' : 'Send Reset Email'}
                </Button>
              </Box>
            ) : (
              <Box sx={{ textAlign: 'center', mb: 3 }}>
                <Button
                  variant="outlined"
                  size="large"
                  onClick={() => {
                    setSuccess(false);
                    setEmail('');
                  }}
                  sx={{ py: 1.5 }}
                >
                  Send Another Email
                </Button>
              </Box>
            )}

            {/* Back to Login */}
            <Box sx={{ textAlign: 'center' }}>
              <Button
                component={Link}
                to="/login"
                startIcon={<ArrowBack />}
                variant="text"
                sx={{ textTransform: 'none' }}
              >
                Back to Login
              </Button>
            </Box>

            {/* Footer */}
            <Box sx={{ mt: 4, textAlign: 'center' }}>
              <Typography variant="caption" color="text.secondary">
                MCQ Quiz System Admin Panel v1.0
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Box>
    </Container>
  );
};

export default ForgotPasswordPage;
