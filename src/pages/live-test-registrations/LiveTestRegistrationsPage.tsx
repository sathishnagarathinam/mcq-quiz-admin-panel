import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  TextField,
  InputAdornment,
  CircularProgress,
  Card,
  CardContent,
  Grid,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Search,
  Refresh,
  Download as DownloadIcon,
  ArrowBack,
  CurrencyRupee,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import {
  collection,
  query,
  onSnapshot,
  orderBy,
  getDocs,
  doc,
  getDoc,
  deleteDoc,
} from 'firebase/firestore';
import { db } from '../../config/firebase';
import * as XLSX from 'xlsx';
import toast from 'react-hot-toast';

interface LiveTestRegistration {
  id: string;
  userId: string;
  testId: string;
  testTitle: string;
  registeredAt: Date;
  isPaid: boolean;
  paymentId?: string;
  hasAttended: boolean;
  attendedAt?: Date;
  score?: number;
  isActive: boolean;
  // User details (fetched separately)
  userName?: string;
  userEmail?: string;
  userPhone?: string;
  amount?: number;
}

interface RegistrationStats {
  totalRegistrations: number;
  paidRegistrations: number;
  freeRegistrations: number;
  totalRevenue: number;
  attendedCount: number;
}

const LiveTestRegistrationsPage: React.FC = () => {
  const navigate = useNavigate();
  const [registrations, setRegistrations] = useState<LiveTestRegistration[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [stats, setStats] = useState<RegistrationStats>({
    totalRegistrations: 0,
    paidRegistrations: 0,
    freeRegistrations: 0,
    totalRevenue: 0,
    attendedCount: 0,
  });
  const [selectedTest, setSelectedTest] = useState<string>('');
  const [detailsDialogOpen, setDetailsDialogOpen] = useState(false);
  const [selectedRegistration, setSelectedRegistration] = useState<LiveTestRegistration | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [registrationToDelete, setRegistrationToDelete] = useState<LiveTestRegistration | null>(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    fetchRegistrations();
  }, []);

  const fetchRegistrations = async () => {
    try {
      setLoading(true);
      const registrationsRef = collection(db, 'live_test_registrations');
      const q = query(registrationsRef, orderBy('registeredAt', 'desc'));

      const unsubscribe = onSnapshot(q, async (snapshot) => {
        const regs: LiveTestRegistration[] = [];
        let totalRevenue = 0;
        let paidCount = 0;
        let attendedCount = 0;

        for (const docSnapshot of snapshot.docs) {
          const data = docSnapshot.data();
          const reg: LiveTestRegistration = {
            id: docSnapshot.id,
            userId: data.userId,
            testId: data.testId,
            testTitle: data.testTitle,
            registeredAt: data.registeredAt?.toDate() || new Date(),
            isPaid: data.isPaid || false,
            paymentId: data.paymentId,
            hasAttended: data.hasAttended || false,
            attendedAt: data.attendedAt?.toDate(),
            score: data.score,
            isActive: data.isActive !== false,
          };

          // Fetch user details
          try {
            const userDocRef = doc(db, 'mobile_users', data.userId);
            const userDoc = await getDoc(userDocRef);
            if (userDoc.exists()) {
              const userData = userDoc.data() as any;
              reg.userName = userData.name || 'Unknown';
              reg.userEmail = userData.email || 'N/A';
              reg.userPhone = userData.phoneNumber || 'N/A';
            }
          } catch (err) {
            console.error('Error fetching user:', err);
          }

          // Fetch payment amount if paid
          if (data.isPaid && data.paymentId) {
            try {
              const paymentDocRef = doc(db, 'payments', data.paymentId);
              const paymentDoc = await getDoc(paymentDocRef);
              if (paymentDoc.exists()) {
                const paymentData = paymentDoc.data() as any;
                reg.amount = paymentData.amount;
                totalRevenue += reg.amount || 0;
              }
            } catch (err) {
              console.error('Error fetching payment:', err);
            }
          }

          if (data.isPaid) paidCount++;
          if (data.hasAttended) attendedCount++;

          regs.push(reg);
        }

        setRegistrations(regs);
        setStats({
          totalRegistrations: regs.length,
          paidRegistrations: paidCount,
          freeRegistrations: regs.length - paidCount,
          totalRevenue,
          attendedCount,
        });
        setLoading(false);
      });

      return unsubscribe;
    } catch (error) {
      console.error('Error fetching registrations:', error);
      toast.error('Failed to load registrations');
      setLoading(false);
    }
  };

  const filteredRegistrations = registrations.filter((reg) => {
    const matchesSearch =
      reg.userName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      reg.userEmail?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      reg.userPhone?.includes(searchTerm) ||
      reg.testTitle.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesTest = !selectedTest || reg.testId === selectedTest;

    return matchesSearch && matchesTest;
  });

  const handleExportToExcel = () => {
    const data = filteredRegistrations.map((reg) => ({
      'User Name': reg.userName,
      'Email': reg.userEmail,
      'Phone': reg.userPhone,
      'Test Name': reg.testTitle,
      'Registered At': reg.registeredAt.toLocaleString(),
      'Type': reg.isPaid ? 'Paid' : 'Free',
      'Amount': reg.amount || '-',
      'Attended': reg.hasAttended ? 'Yes' : 'No',
      'Score': reg.score || '-',
    }));

    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Registrations');
    XLSX.writeFile(wb, `live-test-registrations-${new Date().toISOString().split('T')[0]}.xlsx`);
    toast.success('Exported successfully');
  };

  const handleDeleteRegistration = async () => {
    if (!registrationToDelete) return;

    try {
      setDeleting(true);
      await deleteDoc(doc(db, 'live_test_registrations', registrationToDelete.id));
      toast.success(`Removed ${registrationToDelete.userName} from the test`);
      setDeleteDialogOpen(false);
      setRegistrationToDelete(null);
    } catch (error) {
      console.error('Error deleting registration:', error);
      toast.error('Failed to remove user from test');
    } finally {
      setDeleting(false);
    }
  };

  const openDeleteDialog = (registration: LiveTestRegistration) => {
    setRegistrationToDelete(registration);
    setDeleteDialogOpen(true);
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
        <Button
          startIcon={<ArrowBack />}
          onClick={() => navigate('/dashboard')}
          sx={{ mr: 2 }}
        >
          Back
        </Button>
        <Typography variant="h4" sx={{ fontWeight: 'bold' }}>
          Live Test Registrations
        </Typography>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={2.4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total Registrations
              </Typography>
              <Typography variant="h5">{stats.totalRegistrations}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={2.4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Paid
              </Typography>
              <Typography variant="h5">{stats.paidRegistrations}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={2.4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Free
              </Typography>
              <Typography variant="h5">{stats.freeRegistrations}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={2.4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total Revenue
              </Typography>
              <Typography variant="h5">₹{stats.totalRevenue}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={2.4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Attended
              </Typography>
              <Typography variant="h5">{stats.attendedCount}</Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Search and Export */}
      <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
        <TextField
          placeholder="Search by name, email, phone, or test..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search />
              </InputAdornment>
            ),
          }}
          sx={{ flex: 1 }}
        />
        <Button
          variant="contained"
          startIcon={<DownloadIcon />}
          onClick={handleExportToExcel}
        >
          Export
        </Button>
        <Button
          variant="outlined"
          startIcon={<Refresh />}
          onClick={fetchRegistrations}
        >
          Refresh
        </Button>
      </Box>

      {/* Table */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
          <CircularProgress />
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead sx={{ backgroundColor: '#f5f5f5' }}>
              <TableRow>
                <TableCell><strong>User Name</strong></TableCell>
                <TableCell><strong>Email</strong></TableCell>
                <TableCell><strong>Phone</strong></TableCell>
                <TableCell><strong>Test Name</strong></TableCell>
                <TableCell><strong>Registered At</strong></TableCell>
                <TableCell><strong>Type</strong></TableCell>
                <TableCell><strong>Amount</strong></TableCell>
                <TableCell><strong>Attended</strong></TableCell>
                <TableCell><strong>Score</strong></TableCell>
                <TableCell align="center"><strong>Action</strong></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredRegistrations.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={10} align="center" sx={{ py: 3 }}>
                    <Typography color="textSecondary">
                      No registrations found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                filteredRegistrations.map((reg) => (
                  <TableRow key={reg.id} hover>
                    <TableCell>{reg.userName}</TableCell>
                    <TableCell>{reg.userEmail}</TableCell>
                    <TableCell>{reg.userPhone}</TableCell>
                    <TableCell>{reg.testTitle}</TableCell>
                    <TableCell>{reg.registeredAt.toLocaleString()}</TableCell>
                    <TableCell>
                      <Chip
                        label={reg.isPaid ? 'Paid' : 'Free'}
                        color={reg.isPaid ? 'success' : 'default'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      {reg.isPaid ? `₹${reg.amount || '-'}` : '-'}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={reg.hasAttended ? 'Yes' : 'No'}
                        color={reg.hasAttended ? 'success' : 'default'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>{reg.score || '-'}</TableCell>
                    <TableCell align="center">
                      <Button
                        size="small"
                        color="error"
                        startIcon={<DeleteIcon />}
                        onClick={() => openDeleteDialog(reg)}
                      >
                        Delete
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
      >
        <DialogTitle>Remove User from Test</DialogTitle>
        <DialogContent>
          <Typography sx={{ mt: 2 }}>
            Are you sure you want to remove <strong>{registrationToDelete?.userName}</strong> from the test <strong>{registrationToDelete?.testTitle}</strong>?
          </Typography>
          <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }}>
            This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setDeleteDialogOpen(false)}
            disabled={deleting}
          >
            Cancel
          </Button>
          <Button
            onClick={handleDeleteRegistration}
            color="error"
            variant="contained"
            disabled={deleting}
          >
            {deleting ? 'Removing...' : 'Remove'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default LiveTestRegistrationsPage;

