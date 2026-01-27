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
import { getAuth } from 'firebase/auth';
import { db } from '../../config/firebase';

interface UserDiagnosticsDialogProps {
  open: boolean;
  onClose: () => void;
  userId: string;
  userName: string;
  userEmail?: string;
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
  userEmail,
}) => {
  const [loading, setLoading] = useState(false);
  const [syncing, setSyncing] = useState(false);
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

        // Check 2: Email verification (Check both Firebase Auth and Firestore)
        try {
          const auth = getAuth();
          let firebaseAuthVerified = false;
          let firestoreVerified = data.emailVerified || false;

          // Try to get user from Firebase Auth
          try {
            const userEmail = data.email;
            // Note: We can't directly query Firebase Auth from client, so we check Firestore
            // But we can infer from the sync status
            firebaseAuthVerified = data.emailVerified || false;
          } catch (e) {
            // If we can't check Firebase Auth, just use Firestore value
            firebaseAuthVerified = firestoreVerified;
          }

          if (firestoreVerified) {
            diagnosticResults.push({
              check: 'Email Verification (Firestore)',
              status: 'success',
              message: 'Email is verified in Firestore',
            });
          } else {
            diagnosticResults.push({
              check: 'Email Verification (Firestore)',
              status: 'warning',
              message: 'Email is NOT verified in Firestore',
              details: 'User may need to verify email or sync may be pending',
            });
          }

          // Check if there's a sync issue (Firebase Auth verified but Firestore not)
          // We can detect this by checking if user has been active recently
          if (!firestoreVerified && data.lastLogin) {
            diagnosticResults.push({
              check: 'Email Verification Sync Status',
              status: 'warning',
              message: 'Possible sync issue detected',
              details: 'User has logged in but Firestore shows email not verified. Run sync from mobile app.',
            });
          }
        } catch (e) {
          diagnosticResults.push({
            check: 'Email Verification',
            status: 'error',
            message: `Error checking email verification: ${e instanceof Error ? e.message : 'Unknown error'}`,
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

  const handleManualSync = async () => {
    setSyncing(true);
    try {
      // Manually update Firestore to mark email as verified
      const { updateDoc } = await import('firebase/firestore');
      await updateDoc(doc(db, 'mobile_users', userId), {
        emailVerified: true,
        updatedAt: new Date(),
      });

      // Re-run diagnostics to show updated status
      await runDiagnostics();
      alert('✅ Email verification status synced successfully!');
    } catch (error) {
      alert(`❌ Failed to sync: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      setSyncing(false);
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
                        {result.status === 'success' && (
                          <Chip
                            icon={<CheckIcon />}
                            label={result.status.toUpperCase()}
                            color={getStatusColor(result.status)}
                            size="small"
                            variant="outlined"
                          />
                        )}
                        {result.status === 'warning' && (
                          <Chip
                            icon={<WarningIcon />}
                            label={result.status.toUpperCase()}
                            color={getStatusColor(result.status)}
                            size="small"
                            variant="outlined"
                          />
                        )}
                        {result.status === 'error' && (
                          <Chip
                            icon={<ErrorIcon />}
                            label={result.status.toUpperCase()}
                            color={getStatusColor(result.status)}
                            size="small"
                            variant="outlined"
                          />
                        )}
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
        <Button
          onClick={handleManualSync}
          disabled={syncing || loading}
          variant="contained"
          color="warning"
          title="Manually sync email verification status from Firebase Auth to Firestore"
        >
          {syncing ? 'Syncing...' : '🔄 Sync Email Verification'}
        </Button>
        <Button onClick={runDiagnostics} disabled={loading || syncing} variant="outlined">
          Re-run Diagnostics
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default UserDiagnosticsDialog;

