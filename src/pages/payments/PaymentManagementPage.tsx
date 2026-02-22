import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  CircularProgress,
  TextField,
  MenuItem,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  AppBar,
  Toolbar,
} from '@mui/material';
import {
  Payment as PaymentIcon,
  CheckCircle as SuccessIcon,
  Error as ErrorIcon,
  Schedule as PendingIcon,
  Download as DownloadIcon,
  ArrowBack as ArrowBackIcon,
} from '@mui/icons-material';
import { collection, doc, getDoc, onSnapshot } from 'firebase/firestore';
import { db } from '../../config/firebase';

interface Payment {
  id: string;
  userId: string;
  userName?: string;
  userEmail?: string;
  userPhone?: string;
  examId: string;
  examName: string;
  amount: number;
  currency: string;
  status: 'COMPLETED' | 'FAILED' | 'PENDING' | 'CANCELLED' | 'PAID';
  gateway: string;
  razorpayPaymentId?: string;
  razorpayOrderId?: string;
  createdAt: Date;
  updatedAt: Date;
  metadata?: Record<string, any>;
}

interface PaymentStats {
  totalTransactions: number;
  successfulPayments: number;
  failedPayments: number;
  pendingPayments: number;
  totalRevenue: number;
  averageTransactionValue: number;
}

const PaymentManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const [payments, setPayments] = useState<Payment[]>([]);
  const [filteredPayments, setFilteredPayments] = useState<Payment[]>([]);
  const [stats, setStats] = useState<PaymentStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [fromDate, setFromDate] = useState<string>('');
  const [toDate, setToDate] = useState<string>('');
  const [selectedPayment, setSelectedPayment] = useState<Payment | null>(null);
  const [detailsOpen, setDetailsOpen] = useState(false);

  useEffect(() => {
    setLoading(true);
    // Query from 'orders' collection where payment data is actually stored
    // No limit - load ALL payments for real-time display
    // Using simple collection reference without orderBy to avoid index requirements
    const ordersCollection = collection(db, 'orders');

    console.log('🔄 Setting up real-time listener for orders collection...');

    // Set up real-time listener
    const unsubscribe = onSnapshot(
      ordersCollection,
      async (snapshot) => {
        try {
          console.log(`📦 Received ${snapshot.docs.length} orders from Firestore`);

          const paymentsList: Payment[] = await Promise.all(
            snapshot.docs.map(async (paymentDoc) => {
              const data = paymentDoc.data();
              console.log(`📝 Processing order: ${paymentDoc.id}`, data);

              let userName = '';
              let userEmail = '';
              let userPhone = '';
              let examName = 'N/A';

              // Use email/phone from order data first (stored during order creation)
              userEmail = data.userEmail || '';
              userPhone = data.userPhone || '';

              // Fetch user details directly by document ID (userId is the document ID in mobile_users collection)
              try {
                if (data.userId) {
                  const userDocRef = doc(db, 'mobile_users', data.userId);
                  const userSnapshot = await getDoc(userDocRef);
                  if (userSnapshot.exists()) {
                    const userData = userSnapshot.data();
                    // Try 'name' first, then 'displayName'
                    userName = userData?.name || userData?.displayName || '';
                    // Only override if not already set from order data
                    if (!userEmail) userEmail = userData?.email || '';
                    if (!userPhone) userPhone = userData?.phoneNumber || '';
                    console.log(`✅ Fetched user data for ${data.userId}:`, { userName, userEmail, userPhone });
                  } else {
                    console.warn(`⚠️ User document not found for ${data.userId}`);
                  }
                }
              } catch (err) {
                console.warn(`❌ Could not fetch user details for ${data.userId}:`, err);
              }

              // Fetch exam name from exams collection using examId
              try {
                if (data.examId) {
                  const examDocRef = doc(db, 'exams', data.examId);
                  const examSnapshot = await getDoc(examDocRef);
                  if (examSnapshot.exists()) {
                    const examData = examSnapshot.data();
                    // Use 'name' field from exam document (same as exam management page)
                    examName = examData?.name || data.examName || data.examId || 'N/A';
                    console.log(`✅ Fetched exam name for ${data.examId}:`, examName);
                  } else {
                    console.warn(`⚠️ Exam document not found for ${data.examId}`);
                    examName = data.examName || data.examId || 'N/A';
                  }
                } else {
                  examName = data.examName || 'N/A';
                }
              } catch (err) {
                console.warn(`❌ Could not fetch exam details for ${data.examId}:`, err);
                examName = data.examName || data.examId || 'N/A';
              }

              // Normalize status: convert 'paid' to 'COMPLETED', 'pending' to 'PENDING'
              let status = (data.status || 'PENDING').toUpperCase();
              if (status === 'PAID') {
                status = 'COMPLETED';
              }

              // Handle createdAt - could be Firestore Timestamp or null
              let createdAtDate = new Date();
              if (data.createdAt) {
                if (typeof data.createdAt.toDate === 'function') {
                  createdAtDate = data.createdAt.toDate();
                } else if (data.createdAt instanceof Date) {
                  createdAtDate = data.createdAt;
                }
              }

              let updatedAtDate = new Date();
              if (data.updatedAt) {
                if (typeof data.updatedAt.toDate === 'function') {
                  updatedAtDate = data.updatedAt.toDate();
                } else if (data.updatedAt instanceof Date) {
                  updatedAtDate = data.updatedAt;
                }
              }

              return {
                id: paymentDoc.id,
                ...data,
                status,
                userName,
                userEmail,
                userPhone,
                examName,
                gateway: 'Razorpay', // Payment backend uses Razorpay
                createdAt: createdAtDate,
                updatedAt: updatedAtDate,
              } as Payment;
            })
          );

          // Sort by createdAt descending (newest first) on client side
          paymentsList.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

          console.log(`✅ Processed ${paymentsList.length} payments successfully`);
          setPayments(paymentsList);
          calculateStats(paymentsList);
          setLoading(false);
        } catch (error) {
          console.error('❌ Error processing payments snapshot:', error);
          setLoading(false);
        }
      },
      (error) => {
        console.error('❌ Error listening to orders:', error);
        setLoading(false);
      }
    );

    // Cleanup: unsubscribe from listener when component unmounts
    return () => unsubscribe();
  }, []);

  useEffect(() => {
    filterPayments();
  }, [payments, statusFilter, fromDate, toDate]);

  const calculateStats = (paymentsList: Payment[]) => {
    const successful = paymentsList.filter(p => p.status === 'COMPLETED');
    const failed = paymentsList.filter(p => p.status === 'FAILED');
    const pending = paymentsList.filter(p => p.status === 'PENDING');
    
    const totalRevenue = successful.reduce((sum, p) => sum + p.amount, 0);
    const averageValue = successful.length > 0 ? totalRevenue / successful.length : 0;

    setStats({
      totalTransactions: paymentsList.length,
      successfulPayments: successful.length,
      failedPayments: failed.length,
      pendingPayments: pending.length,
      totalRevenue,
      averageTransactionValue: averageValue,
    });
  };

  const filterPayments = () => {
    let filtered = payments;

    // Filter by status
    if (statusFilter !== 'ALL') {
      filtered = filtered.filter(p => p.status === statusFilter);
    }

    // Filter by date range (handle timezone correctly)
    if (fromDate) {
      // Parse date string (YYYY-MM-DD format from input)
      const [year, month, day] = fromDate.split('-').map(Number);
      const fromDateTime = new Date(year, month - 1, day, 0, 0, 0, 0).getTime();
      filtered = filtered.filter(p => p.createdAt.getTime() >= fromDateTime);
    }

    if (toDate) {
      // Parse date string (YYYY-MM-DD format from input)
      const [year, month, day] = toDate.split('-').map(Number);
      const toDateTime = new Date(year, month - 1, day, 23, 59, 59, 999).getTime();
      filtered = filtered.filter(p => p.createdAt.getTime() <= toDateTime);
    }

    setFilteredPayments(filtered);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'COMPLETED':
        return 'success';
      case 'FAILED':
        return 'error';
      case 'PENDING':
        return 'warning';
      case 'CANCELLED':
        return 'default';
      default:
        return 'default';
    }
  };

  const getStatusIcon = (status: string): React.ReactElement | undefined => {
    switch (status) {
      case 'COMPLETED':
        return <SuccessIcon sx={{ fontSize: 16 }} />;
      case 'FAILED':
        return <ErrorIcon sx={{ fontSize: 16 }} />;
      case 'PENDING':
        return <PendingIcon sx={{ fontSize: 16 }} />;
      default:
        return undefined;
    }
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      {/* Header with Back Button */}
      <AppBar position="static" sx={{ mb: 3 }}>
        <Toolbar>
          <Button
            color="inherit"
            startIcon={<ArrowBackIcon />}
            onClick={() => navigate('/dashboard')}
            sx={{ mr: 2 }}
          >
            Back to Dashboard
          </Button>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            💳 Payment Management
          </Typography>
        </Toolbar>
      </AppBar>

      <Box sx={{ p: 3 }}>
        {/* Filters Section */}
        <Card sx={{ mb: 4, p: 2 }}>
          <Grid container spacing={2} alignItems="flex-end">
            <Grid item xs={12} sm={6} md={3}>
              <TextField
                label="Status"
                select
                fullWidth
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <MenuItem value="ALL">All Payments</MenuItem>
                <MenuItem value="COMPLETED">Completed</MenuItem>
                <MenuItem value="FAILED">Failed</MenuItem>
                <MenuItem value="PENDING">Pending</MenuItem>
                <MenuItem value="CANCELLED">Cancelled</MenuItem>
              </TextField>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <TextField
                label="From Date"
                type="date"
                fullWidth
                value={fromDate}
                onChange={(e) => setFromDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <TextField
                label="To Date"
                type="date"
                fullWidth
                value={toDate}
                onChange={(e) => setToDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Button
                variant="contained"
                startIcon={<DownloadIcon />}
                fullWidth
                sx={{ height: '56px' }}
              >
                Export
              </Button>
            </Grid>
          </Grid>
        </Card>

      {/* Payment Statistics */}
      {stats && (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={2.4}>
            <Card>
              <CardContent>
                <Typography color="textSecondary" gutterBottom>
                  Total Transactions
                </Typography>
                <Typography variant="h5">{stats.totalTransactions}</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <Card sx={{ bgcolor: '#e8f5e9' }}>
              <CardContent>
                <Typography color="textSecondary" gutterBottom>
                  Successful
                </Typography>
                <Typography variant="h5" sx={{ color: '#2e7d32' }}>
                  {stats.successfulPayments}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <Card sx={{ bgcolor: '#ffebee' }}>
              <CardContent>
                <Typography color="textSecondary" gutterBottom>
                  Failed
                </Typography>
                <Typography variant="h5" sx={{ color: '#c62828' }}>
                  {stats.failedPayments}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <Card sx={{ bgcolor: '#fff3e0' }}>
              <CardContent>
                <Typography color="textSecondary" gutterBottom>
                  Pending
                </Typography>
                <Typography variant="h5" sx={{ color: '#e65100' }}>
                  {stats.pendingPayments}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <Card sx={{ bgcolor: '#e3f2fd' }}>
              <CardContent>
                <Typography color="textSecondary" gutterBottom>
                  Total Revenue
                </Typography>
                <Typography variant="h5" sx={{ color: '#1565c0' }}>
                  ₹{stats.totalRevenue.toFixed(2)}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}



      {/* Payments Table */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
          <CircularProgress />
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead sx={{ bgcolor: '#f5f5f5' }}>
              <TableRow>
                <TableCell><strong>Transaction ID</strong></TableCell>
                <TableCell><strong>User (Name/Email/Phone)</strong></TableCell>
                <TableCell><strong>Exam Name</strong></TableCell>
                <TableCell align="right"><strong>Amount</strong></TableCell>
                <TableCell><strong>Gateway</strong></TableCell>
                <TableCell><strong>Status</strong></TableCell>
                <TableCell><strong>Date</strong></TableCell>
                <TableCell align="center"><strong>Action</strong></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredPayments.map((payment) => (
                <TableRow key={payment.id} hover>
                  <TableCell sx={{ fontFamily: 'monospace', fontSize: '0.85rem' }}>
                    {payment.id.substring(0, 12)}...
                  </TableCell>
                  <TableCell>
                    <Box sx={{ fontSize: '0.9rem' }}>
                      <Box><strong>{payment.userName || 'N/A'}</strong></Box>
                      <Box sx={{ fontSize: '0.85rem', color: '#666' }}>{payment.userEmail || 'N/A'}</Box>
                      <Box sx={{ fontSize: '0.85rem', color: '#666' }}>{payment.userPhone || 'N/A'}</Box>
                    </Box>
                  </TableCell>
                  <TableCell>{payment.examName}</TableCell>
                  <TableCell align="right">
                    <strong>₹{payment.amount.toFixed(2)}</strong>
                  </TableCell>
                  <TableCell>{payment.gateway}</TableCell>
                  <TableCell>
                    <Chip
                      icon={getStatusIcon(payment.status)}
                      label={payment.status}
                      color={getStatusColor(payment.status) as any}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>{payment.createdAt.toLocaleDateString()}</TableCell>
                  <TableCell align="center">
                    <Button
                      size="small"
                      variant="outlined"
                      onClick={() => {
                        setSelectedPayment(payment);
                        setDetailsOpen(true);
                      }}
                    >
                      View
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

        {/* Payment Details Dialog */}
        <Dialog open={detailsOpen} onClose={() => setDetailsOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Payment Details</DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          {selectedPayment && (
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <Box>
                <Typography variant="body2" color="textSecondary">Transaction ID</Typography>
                <Typography variant="body1" sx={{ fontFamily: 'monospace' }}>{selectedPayment.id}</Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">User Name</Typography>
                <Typography variant="body1">{selectedPayment.userName || 'N/A'}</Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">User Email</Typography>
                <Typography variant="body1">{selectedPayment.userEmail || 'N/A'}</Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">User Phone</Typography>
                <Typography variant="body1">{selectedPayment.userPhone || 'N/A'}</Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">User ID</Typography>
                <Typography variant="body1" sx={{ fontFamily: 'monospace', fontSize: '0.85rem' }}>{selectedPayment.userId}</Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">Exam Name</Typography>
                <Typography variant="body1">{selectedPayment.examName}</Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">Amount</Typography>
                <Typography variant="body1">₹{selectedPayment.amount.toFixed(2)} {selectedPayment.currency}</Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">Payment Gateway</Typography>
                <Typography variant="body1">{selectedPayment.gateway}</Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">Status</Typography>
                <Chip
                  icon={getStatusIcon(selectedPayment.status)}
                  label={selectedPayment.status}
                  color={getStatusColor(selectedPayment.status) as any}
                  sx={{ mt: 1 }}
                />
              </Box>
              {selectedPayment.razorpayPaymentId && (
                <Box>
                  <Typography variant="body2" color="textSecondary">Razorpay Payment ID</Typography>
                  <Typography variant="body1" sx={{ fontFamily: 'monospace', fontSize: '0.85rem' }}>
                    {selectedPayment.razorpayPaymentId}
                  </Typography>
                </Box>
              )}
              {selectedPayment.razorpayOrderId && (
                <Box>
                  <Typography variant="body2" color="textSecondary">Razorpay Order ID</Typography>
                  <Typography variant="body1" sx={{ fontFamily: 'monospace', fontSize: '0.85rem' }}>
                    {selectedPayment.razorpayOrderId}
                  </Typography>
                </Box>
              )}
              <Box>
                <Typography variant="body2" color="textSecondary">Created At</Typography>
                <Typography variant="body1">{selectedPayment.createdAt.toLocaleString()}</Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">Updated At</Typography>
                <Typography variant="body1">{selectedPayment.updatedAt.toLocaleString()}</Typography>
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailsOpen(false)}>Close</Button>
        </DialogActions>
        </Dialog>
      </Box>
    </Box>
  );
};

export default PaymentManagementPage;

