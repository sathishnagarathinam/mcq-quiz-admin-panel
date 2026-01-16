import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Alert,
  CircularProgress,
  Divider,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
} from '@mui/material';
import { CheckCircle as CheckIcon, Error as ErrorIcon, Warning as WarningIcon } from '@mui/icons-material';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../../config/firebase';

interface UserDiagnosticsDialogProps {
  open: boolean;
  onClose: () => void;
  userId: string;
  userName: string;
}

interface DiagnosticResult {
  check: string;
  status: 'success' | 'warning' | 'error';
  message: string;
  details?: string;
}

const UserDiagnosticsDialog: React.FC<UserDiagnosticsDialogProps> = ({
  open,
  onClose,
  userId,
  userName,
}) => {
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState<DiagnosticResult[]>([]);
  const [userData, setUserData] = useState<any>(null);

  useEffect(() => {
    if (open) {
      runDiagnostics();
    }
  }, [open]);

  const runDiagnostics = async () => {
    setLoading(true);
    const diagnosticResults: DiagnosticResult[] = [];

    try {
      // Check 1: User document exists
      const userDoc = await getDoc(doc(db, 'mobile_users', userId));
      if (userDoc.exists()) {
        diagnosticResults.push({
          check: 'User Document',
          status: 'success',
          message: 'User document found in mobile_users collection',
        });
        setUserData(userDoc.data());
      } else {
        diagnosticResults.push({
          check: 'User Document',
          status: 'error',
          message: 'User document NOT found in mobile_users collection',
          details: 'This is the root cause of device registration failure',
        });
      }

      if (userDoc.exists()) {
        const data = userDoc.data();

        // Check 2: Email verification
        if (data.emailVerified) {
          diagnosticResults.push({
            check: 'Email Verification',
            status: 'success',
            message: 'Email is verified',
          });
        } else {
          diagnosticResults.push({
            check: 'Email Verification',
            status: 'warning',
            message: 'Email is NOT verified',
            details: 'User may need to verify email before device binding',
          });
        }

        // Check 3: Device binding status
        if (data.isDeviceBound) {
          diagnosticResults.push({
            check: 'Device Binding',
            status: 'success',
            message: 'Device is bound to this account',
            details: `Device ID: ${data.registeredDeviceId}`,
          });
        } else {
          diagnosticResults.push({
            check: 'Device Binding',
            status: 'warning',
            message: 'Device is NOT bound',
            details: 'User needs to complete device binding on next login',
          });
        }

        // Check 4: Required fields
        const requiredFields = ['uid', 'email', 'name', 'phoneNumber', 'isActive'];
        const missingFields = requiredFields.filter(field => !data[field]);
        
        if (missingFields.length === 0) {
          diagnosticResults.push({
            check: 'Required Fields',
            status: 'success',
            message: 'All required fields present',
          });
        } else {
          diagnosticResults.push({
            check: 'Required Fields',
            status: 'error',
            message: `Missing fields: ${missingFields.join(', ')}`,
          });
        }

        // Check 5: Account active status
        if (data.isActive) {
          diagnosticResults.push({
            check: 'Account Status',
            status: 'success',
            message: 'Account is active',
          });
        } else {
          diagnosticResults.push({
            check: 'Account Status',
            status: 'error',
            message: 'Account is INACTIVE',
            details: 'Inactive accounts cannot bind devices',
          });
        }
      }
    } catch (error) {
      diagnosticResults.push({
        check: 'Firestore Access',
        status: 'error',
        message: `Error accessing Firestore: ${error instanceof Error ? error.message : 'Unknown error'}`,
      });
    }

    setResults(diagnosticResults);
    setLoading(false);
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success':
        return CheckIcon;
      case 'warning':
        return WarningIcon;
      case 'error':
        return ErrorIcon;
      default:
        return undefined;
    }
  };

  const getStatusColor = (status: string): any => {
    switch (status) {
      case 'success':
        return 'success';
      case 'warning':
        return 'warning';
      case 'error':
        return 'error';
      default:
        return 'default';
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>User Diagnostics - {userName}</DialogTitle>
      <DialogContent sx={{ pt: 2 }}>
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 300 }}>
            <CircularProgress />
          </Box>
        ) : (
          <>
            <Alert severity="info" sx={{ mb: 2 }}>
              Running diagnostic checks for device registration issues...
            </Alert>

            <TableContainer component={Paper} sx={{ mb: 2 }}>
              <Table size="small">
                <TableHead>
                  <TableRow sx={{ backgroundColor: '#f5f5f5' }}>
                    <TableCell>Check</TableCell>
                    <TableCell align="center">Status</TableCell>
                    <TableCell>Details</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {results.map((result, index) => (
                    <TableRow key={index}>
                      <TableCell>{result.check}</TableCell>
                      <TableCell align="center">
                        <Chip
                          icon={getStatusIcon(result.status)}
                          label={result.status.toUpperCase()}
                          color={getStatusColor(result.status)}
                          size="small"
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">{result.message}</Typography>
                        {result.details && (
                          <Typography variant="caption" color="text.secondary" display="block">
                            {result.details}
                          </Typography>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>

            {userData && (
              <>
                <Divider sx={{ my: 2 }} />
                <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1 }}>
                  User Data Summary
                </Typography>
                <Box sx={{ bgcolor: 'background.default', p: 1.5, borderRadius: 1, fontSize: '0.875rem' }}>
                  <Typography variant="caption" display="block">
                    <strong>Email:</strong> {userData.email}
                  </Typography>
                  <Typography variant="caption" display="block">
                    <strong>Phone:</strong> {userData.phoneNumber}
                  </Typography>
                  <Typography variant="caption" display="block">
                    <strong>Active:</strong> {userData.isActive ? 'Yes' : 'No'}
                  </Typography>
                  <Typography variant="caption" display="block">
                    <strong>Device Bound:</strong> {userData.isDeviceBound ? 'Yes' : 'No'}
                  </Typography>
                </Box>
              </>
            )}
          </>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Close</Button>
        <Button onClick={runDiagnostics} disabled={loading} variant="outlined">
          Re-run Diagnostics
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default UserDiagnosticsDialog;

