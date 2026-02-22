import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Autocomplete,
  Chip,
  IconButton,
  Tooltip,
  CircularProgress,
  Typography,
} from '@mui/material';
import {
  Delete as DeleteIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import { collection, getDocs, addDoc, deleteDoc, doc, Timestamp } from 'firebase/firestore';
import { db } from '../../config/firebase';
import toast from 'react-hot-toast';

interface FreeQuizAccess {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  examId: string;
  examName: string;
  grantedAt: Date;
  expiresAt?: Date;
  reason?: string;
  isActive: boolean;
}

interface User {
  id: string;
  name: string;
  email: string;
}

interface Exam {
  id: string;
  name: string;
}

const FreeQuizAccessManagement: React.FC = () => {
  const [accesses, setAccesses] = useState<FreeQuizAccess[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [exams, setExams] = useState<Exam[]>([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [selectedExam, setSelectedExam] = useState<Exam | null>(null);
  const [reason, setReason] = useState('');
  const [expiryDays, setExpiryDays] = useState<number | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      await Promise.all([
        fetchFreeQuizAccesses(),
        fetchUsers(),
        fetchExams(),
      ]);
    } catch (error) {
      console.error('Error fetching data:', error);
      toast.error('Failed to load data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const fetchFreeQuizAccesses = async () => {
    try {
      const snapshot = await getDocs(collection(db, 'free_quiz_access'));
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        grantedAt: doc.data().grantedAt?.toDate() || new Date(),
        expiresAt: doc.data().expiresAt?.toDate(),
      } as FreeQuizAccess));
      setAccesses(data);
    } catch (error) {
      console.error('Error fetching free quiz accesses:', error);
    }
  };

  const fetchUsers = async () => {
    try {
      // Fetch from mobile_users collection (where actual app users are stored)
      const snapshot = await getDocs(collection(db, 'mobile_users'));
      const data = snapshot.docs.map(doc => ({
        id: doc.id, // Document ID is the actual user ID (phone number or Firebase UID)
        name: doc.data().name || doc.data().displayName || 'Unknown',
        email: doc.data().email || '',
      }));
      setUsers(data);
      console.log(`Loaded ${data.length} mobile users`);
    } catch (error) {
      console.error('Error fetching users:', error);
    }
  };

  const fetchExams = async () => {
    try {
      const snapshot = await getDocs(collection(db, 'exams'));
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name || 'Unknown',
      }));
      setExams(data);
    } catch (error) {
      console.error('Error fetching exams:', error);
    }
  };

  const handleAddAccess = async () => {
    if (!selectedUser || !selectedExam) {
      toast.error('Please select both user and exam');
      return;
    }

    try {
      const grantedAt = new Date();
      const expiresAt = expiryDays ? new Date(grantedAt.getTime() + expiryDays * 24 * 60 * 60 * 1000) : null;

      await addDoc(collection(db, 'free_quiz_access'), {
        userId: selectedUser.id,
        userName: selectedUser.name,
        userEmail: selectedUser.email,
        examId: selectedExam.id,
        examName: selectedExam.name,
        grantedAt: Timestamp.now(),
        expiresAt: expiresAt ? Timestamp.fromDate(expiresAt) : null,
        reason: reason || null,
        isActive: true,
        createdAt: Timestamp.now(),
      });

      toast.success('Free quiz access granted successfully');
      setOpenDialog(false);
      setSelectedUser(null);
      setSelectedExam(null);
      setReason('');
      setExpiryDays(null);
      fetchFreeQuizAccesses();
    } catch (error) {
      console.error('Error adding free quiz access:', error);
      toast.error('Failed to grant access');
    }
  };

  const handleDeleteAccess = async (id: string) => {
    if (window.confirm('Are you sure you want to revoke this access?')) {
      try {
        await deleteDoc(doc(db, 'free_quiz_access', id));
        toast.success('Access revoked successfully');
        fetchFreeQuizAccesses();
      } catch (error) {
        console.error('Error deleting access:', error);
        toast.error('Failed to revoke access');
      }
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
            <Typography variant="h6">Free Quiz Access Management</Typography>
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={() => setOpenDialog(true)}
            >
              Grant Free Access
            </Button>
          </Box>

          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow sx={{ backgroundColor: '#f5f5f5' }}>
                  <TableCell><strong>User Name</strong></TableCell>
                  <TableCell><strong>Email</strong></TableCell>
                  <TableCell><strong>Exam Name</strong></TableCell>
                  <TableCell><strong>Granted At</strong></TableCell>
                  <TableCell><strong>Expires At</strong></TableCell>
                  <TableCell><strong>Reason</strong></TableCell>
                  <TableCell align="right"><strong>Actions</strong></TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {accesses.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} align="center" sx={{ py: 3 }}>
                      <Typography color="text.secondary">No free quiz access records found</Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  accesses.map(access => (
                    <TableRow key={access.id}>
                      <TableCell>{access.userName}</TableCell>
                      <TableCell>{access.userEmail}</TableCell>
                      <TableCell>{access.examName}</TableCell>
                      <TableCell>{access.grantedAt.toLocaleDateString()}</TableCell>
                      <TableCell>
                        {access.expiresAt ? (
                          <Chip
                            label={access.expiresAt.toLocaleDateString()}
                            size="small"
                            color={new Date() > access.expiresAt ? 'error' : 'success'}
                          />
                        ) : (
                          <Chip label="Permanent" size="small" color="primary" />
                        )}
                      </TableCell>
                      <TableCell>{access.reason || '-'}</TableCell>
                      <TableCell align="right">
                        <Tooltip title="Revoke Access">
                          <IconButton
                            size="small"
                            onClick={() => handleDeleteAccess(access.id)}
                            color="error"
                          >
                            <DeleteIcon />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Grant Free Quiz Access</DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <Autocomplete
              options={users}
              getOptionLabel={option => `${option.name} (${option.email})`}
              value={selectedUser}
              onChange={(_, value) => setSelectedUser(value)}
              renderInput={params => <TextField {...params} label="Select User" />}
            />
            <Autocomplete
              options={exams}
              getOptionLabel={option => option.name}
              value={selectedExam}
              onChange={(_, value) => setSelectedExam(value)}
              renderInput={params => <TextField {...params} label="Select Exam" />}
            />
            <TextField
              label="Reason (Optional)"
              value={reason}
              onChange={e => setReason(e.target.value)}
              multiline
              rows={2}
            />
            <TextField
              label="Expiry Days (Optional - leave empty for permanent)"
              type="number"
              value={expiryDays || ''}
              onChange={e => setExpiryDays(e.target.value ? parseInt(e.target.value) : null)}
              inputProps={{ min: 1 }}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button onClick={handleAddAccess} variant="contained">Grant Access</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default FreeQuizAccessManagement;

