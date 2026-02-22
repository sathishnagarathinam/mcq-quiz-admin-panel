import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Chip,
  Button,
  TextField,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Tooltip,
  CircularProgress,
  Pagination,
  Stack,
  Switch,
  FormControlLabel,
  Tab,
  Tabs,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Slider,
} from '@mui/material';
import {
  SmartToy as ChatbotIcon,
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  TrendingUp as TrendingIcon,
  SupportAgent as TicketIcon,
  Analytics as AnalyticsIcon,
  Visibility as ViewIcon,
  CheckCircle as ResolveIcon,
  CloudUpload as SeedIcon,
} from '@mui/icons-material';
import {
  collection,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  query,
  orderBy,
  where,
  Timestamp,
  onSnapshot,
} from 'firebase/firestore';
import { db } from '../../config/firebase';
import { useAuth } from '../../contexts/AuthContext';
import toast from 'react-hot-toast';
import { chatbotSolutions, TOTAL_SOLUTIONS } from '../../data/chatbotSolutions';

// Types
interface SupportSolution {
  id: string;
  title: string;
  description: string;
  keywords: string[];
  patterns: string[];
  category: string;
  priority: number;
  isActive: boolean;
  triggerCount: number;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}

interface SupportTicket {
  id: string;
  userId: string;
  userName: string;
  userMessage: string;
  originalQuery?: string; // The user's original typed query
  solutionProvided?: string; // Solution that was provided (if any)
  isCustomerCareRequest?: boolean; // True if user clicked "Contact Customer Care"
  category: string;
  status: 'open' | 'inProgress' | 'resolved' | 'closed';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  createdAt: Date;
  resolvedAt?: Date;
  assignedTo?: string;
  resolution?: string;
}

interface ChatbotAnalytics {
  totalSolutions: number;
  activeSolutions: number;
  totalTickets: number;
  openTickets: number;
  resolutionRate: number;
  topTriggeredSolutions: { id: string; title: string; count: number }[];
}

const CATEGORIES = [
  'general',
  'payment',
  'quiz',
  'account',
  'technical',
  'exam',
  'subscription',
  'other',
];

const PRIORITY_COLORS: Record<string, 'default' | 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning'> = {
  low: 'success',
  medium: 'info',
  high: 'warning',
  urgent: 'error',
};

const STATUS_COLORS: Record<string, 'default' | 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning'> = {
  open: 'error',
  inProgress: 'warning',
  resolved: 'success',
  closed: 'default',
};

const ChatbotManagementPage: React.FC = () => {
  const { adminUser } = useAuth();
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(true);
  
  // Solutions state
  const [solutions, setSolutions] = useState<SupportSolution[]>([]);
  const [filteredSolutions, setFilteredSolutions] = useState<SupportSolution[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [solutionDialogOpen, setSolutionDialogOpen] = useState(false);
  const [editingSolution, setEditingSolution] = useState<SupportSolution | null>(null);
  
  // Tickets state
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [filteredTickets, setFilteredTickets] = useState<SupportTicket[]>([]);
  const [ticketStatusFilter, setTicketStatusFilter] = useState('all');
  const [ticketDialogOpen, setTicketDialogOpen] = useState(false);
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null);
  
  // Analytics state
  const [analytics, setAnalytics] = useState<ChatbotAnalytics>({
    totalSolutions: 0,
    activeSolutions: 0,
    totalTickets: 0,
    openTickets: 0,
    resolutionRate: 0,
    topTriggeredSolutions: [],
  });
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Seed state
  const [seeding, setSeeding] = useState(false);
  const [seedDialogOpen, setSeedDialogOpen] = useState(false);

  // Solution form state
  const [solutionForm, setSolutionForm] = useState({
    title: '',
    description: '',
    keywords: '',
    patterns: '',
    category: 'general',
    priority: 5,
    isActive: true,
  });

  // Real-time listeners for solutions and tickets
  useEffect(() => {
    setLoading(true);

    // Solutions real-time listener
    const solutionsQuery = query(
      collection(db, 'support_solutions'),
      orderBy('priority', 'desc')
    );
    const unsubscribeSolutions = onSnapshot(
      solutionsQuery,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({
          id: d.id,
          ...d.data(),
          createdAt: d.data().createdAt?.toDate() || new Date(),
          updatedAt: d.data().updatedAt?.toDate() || new Date(),
        })) as SupportSolution[];
        setSolutions(data);
        setFilteredSolutions(data);
        setLoading(false);
      },
      (error) => {
        console.error('Error listening to solutions:', error);
        toast.error('Failed to load solutions');
        setLoading(false);
      }
    );

    // Tickets real-time listener
    const ticketsQuery = query(
      collection(db, 'support_tickets'),
      orderBy('createdAt', 'desc')
    );
    const unsubscribeTickets = onSnapshot(
      ticketsQuery,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({
          id: d.id,
          ...d.data(),
          createdAt: d.data().createdAt?.toDate() || new Date(),
          resolvedAt: d.data().resolvedAt?.toDate(),
        })) as SupportTicket[];
        setTickets(data);
        setFilteredTickets(data);
      },
      (error) => {
        console.error('Error listening to tickets:', error);
        toast.error('Failed to load tickets');
      }
    );

    // Cleanup listeners on unmount
    return () => {
      unsubscribeSolutions();
      unsubscribeTickets();
    };
  }, []);

  // Calculate analytics whenever solutions or tickets change
  useEffect(() => {
    const totalSolutions = solutions.length;
    const activeSolutions = solutions.filter((s) => s.isActive).length;
    const totalTickets = tickets.length;
    const openTickets = tickets.filter(
      (t) => t.status === 'open' || t.status === 'inProgress'
    ).length;
    const resolvedTickets = tickets.filter(
      (t) => t.status === 'resolved' || t.status === 'closed'
    ).length;
    const resolutionRate =
      totalTickets > 0 ? (resolvedTickets / totalTickets) * 100 : 0;

    const topTriggeredSolutions = [...solutions]
      .sort((a, b) => b.triggerCount - a.triggerCount)
      .slice(0, 5)
      .map((s) => ({ id: s.id, title: s.title, count: s.triggerCount }));

    setAnalytics({
      totalSolutions,
      activeSolutions,
      totalTickets,
      openTickets,
      resolutionRate,
      topTriggeredSolutions,
    });
  }, [solutions, tickets]);

  // Filter solutions
  useEffect(() => {
    let filtered = solutions;
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(
        (s) =>
          s.title.toLowerCase().includes(term) ||
          s.description.toLowerCase().includes(term) ||
          s.keywords.some((k) => k.toLowerCase().includes(term))
      );
    }
    if (categoryFilter !== 'all') {
      filtered = filtered.filter((s) => s.category === categoryFilter);
    }
    setFilteredSolutions(filtered);
    setCurrentPage(1);
  }, [searchTerm, categoryFilter, solutions]);

  // Filter tickets
  useEffect(() => {
    let filtered = tickets;
    if (ticketStatusFilter !== 'all') {
      filtered = filtered.filter((t) => t.status === ticketStatusFilter);
    }
    setFilteredTickets(filtered);
  }, [ticketStatusFilter, tickets]);

  // CRUD operations
  const handleSaveSolution = async () => {
    try {
      const now = Timestamp.now();
      const solutionData = {
        title: solutionForm.title,
        description: solutionForm.description,
        keywords: solutionForm.keywords.split(',').map((k) => k.trim()).filter(Boolean),
        patterns: solutionForm.patterns.split(',').map((p) => p.trim()).filter(Boolean),
        category: solutionForm.category,
        priority: solutionForm.priority,
        isActive: solutionForm.isActive,
        updatedAt: now,
      };

      if (editingSolution) {
        await updateDoc(doc(db, 'support_solutions', editingSolution.id), solutionData);
        toast.success('Solution updated successfully');
      } else {
        await addDoc(collection(db, 'support_solutions'), {
          ...solutionData,
          triggerCount: 0,
          createdAt: now,
          createdBy: adminUser?.email || 'admin',
        });
        toast.success('Solution created successfully');
      }

      setSolutionDialogOpen(false);
      resetSolutionForm();
      // Real-time listener will automatically update the data
    } catch (error) {
      console.error('Error saving solution:', error);
      toast.error('Failed to save solution');
    }
  };

  const handleDeleteSolution = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this solution?')) return;
    try {
      await deleteDoc(doc(db, 'support_solutions', id));
      toast.success('Solution deleted');
      // Real-time listener will automatically update the data
    } catch (error) {
      toast.error('Failed to delete solution');
    }
  };

  const handleToggleActive = async (solution: SupportSolution) => {
    try {
      await updateDoc(doc(db, 'support_solutions', solution.id), {
        isActive: !solution.isActive,
        updatedAt: Timestamp.now(),
      });
      // Real-time listener will automatically update the data
    } catch (error) {
      toast.error('Failed to update solution');
    }
  };

  const handleResolveTicket = async (resolution: string) => {
    if (!selectedTicket) return;
    try {
      await updateDoc(doc(db, 'support_tickets', selectedTicket.id), {
        status: 'resolved',
        resolution,
        resolvedAt: Timestamp.now(),
        assignedTo: adminUser?.email,
      });
      toast.success('Ticket resolved');
      setTicketDialogOpen(false);
      setSelectedTicket(null);
      // Real-time listener will automatically update the data
    } catch (error) {
      toast.error('Failed to resolve ticket');
    }
  };

  const resetSolutionForm = () => {
    setSolutionForm({
      title: '',
      description: '',
      keywords: '',
      patterns: '',
      category: 'general',
      priority: 5,
      isActive: true,
    });
    setEditingSolution(null);
  };

  // Seed pre-configured solutions
  const handleSeedSolutions = async () => {
    setSeeding(true);
    setSeedDialogOpen(false);

    let success = 0;
    let failed = 0;
    let skipped = 0;

    // Get existing solution titles to avoid duplicates
    const existingTitles = new Set(solutions.map(s => s.title.toLowerCase()));

    try {
      for (const solution of chatbotSolutions) {
        // Skip if solution with same title already exists
        if (existingTitles.has(solution.title.toLowerCase())) {
          skipped++;
          continue;
        }

        try {
          await addDoc(collection(db, 'support_solutions'), {
            ...solution,
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
            createdBy: adminUser?.email || 'admin',
          });
          success++;
        } catch (error) {
          console.error(`Failed to add solution: ${solution.title}`, error);
          failed++;
        }
      }

      if (success > 0) {
        toast.success(`Successfully added ${success} solutions${skipped > 0 ? ` (${skipped} skipped - already exist)` : ''}`);
      } else if (skipped > 0) {
        toast(`All ${skipped} solutions already exist`, { icon: 'ℹ️' });
      }

      if (failed > 0) {
        toast.error(`Failed to add ${failed} solutions`);
      }
    } catch (error) {
      console.error('Error seeding solutions:', error);
      toast.error('Failed to seed solutions');
    } finally {
      setSeeding(false);
    }
  };

  const openEditDialog = (solution: SupportSolution) => {
    setEditingSolution(solution);
    setSolutionForm({
      title: solution.title,
      description: solution.description,
      keywords: solution.keywords.join(', '),
      patterns: solution.patterns.join(', '),
      category: solution.category,
      priority: solution.priority,
      isActive: solution.isActive,
    });
    setSolutionDialogOpen(true);
  };

  // Pagination
  const paginatedSolutions = filteredSolutions.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );
  const totalPages = Math.ceil(filteredSolutions.length / itemsPerPage);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: 1 }}>
          <ChatbotIcon color="primary" /> Chatbot Management
        </Typography>
      </Box>

      {/* Analytics Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ bgcolor: 'primary.main', color: 'white' }}>
            <CardContent>
              <Typography variant="h4">{analytics.totalSolutions}</Typography>
              <Typography variant="body2">Total Solutions</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ bgcolor: 'success.main', color: 'white' }}>
            <CardContent>
              <Typography variant="h4">{analytics.activeSolutions}</Typography>
              <Typography variant="body2">Active Solutions</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ bgcolor: 'warning.main', color: 'white' }}>
            <CardContent>
              <Typography variant="h4">{analytics.openTickets}</Typography>
              <Typography variant="body2">Open Tickets</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ bgcolor: 'info.main', color: 'white' }}>
            <CardContent>
              <Typography variant="h4">{analytics.resolutionRate.toFixed(1)}%</Typography>
              <Typography variant="body2">Resolution Rate</Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Tabs */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)}>
          <Tab icon={<ChatbotIcon />} label="Solutions" />
          <Tab icon={<TicketIcon />} label={`Tickets (${analytics.openTickets})`} />
          <Tab icon={<AnalyticsIcon />} label="Analytics" />
        </Tabs>
      </Paper>

      {/* Solutions Tab */}
      {tabValue === 0 && (
        <Box>
          {/* Toolbar */}
          <Box sx={{ display: 'flex', gap: 2, mb: 2, flexWrap: 'wrap' }}>
            <TextField
              size="small"
              placeholder="Search solutions..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{ startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} /> }}
              sx={{ minWidth: 250 }}
            />
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>Category</InputLabel>
              <Select
                value={categoryFilter}
                label="Category"
                onChange={(e) => setCategoryFilter(e.target.value)}
              >
                <MenuItem value="all">All Categories</MenuItem>
                {CATEGORIES.map((cat) => (
                  <MenuItem key={cat} value={cat}>{cat.charAt(0).toUpperCase() + cat.slice(1)}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <Box sx={{ flexGrow: 1 }} />
            <Tooltip title={`Seed ${TOTAL_SOLUTIONS} pre-configured solutions to database`}>
              <Button
                variant="outlined"
                color="secondary"
                startIcon={seeding ? <CircularProgress size={20} /> : <SeedIcon />}
                onClick={() => setSeedDialogOpen(true)}
                disabled={seeding}
                sx={{ mr: 1 }}
              >
                {seeding ? 'Seeding...' : 'Seed Solutions'}
              </Button>
            </Tooltip>
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={() => { resetSolutionForm(); setSolutionDialogOpen(true); }}
            >
              Add Solution
            </Button>
          </Box>

          {/* Solutions Table */}
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Title</TableCell>
                  <TableCell>Category</TableCell>
                  <TableCell>Priority</TableCell>
                  <TableCell>Triggers</TableCell>
                  <TableCell>Active</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginatedSolutions.map((solution) => (
                  <TableRow key={solution.id}>
                    <TableCell>
                      <Typography fontWeight={500}>{solution.title}</Typography>
                      <Typography variant="caption" color="text.secondary">
                        {solution.description.substring(0, 80)}...
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip label={solution.category} size="small" />
                    </TableCell>
                    <TableCell>{solution.priority}</TableCell>
                    <TableCell>
                      <Chip
                        icon={<TrendingIcon />}
                        label={solution.triggerCount}
                        size="small"
                        color="primary"
                        variant="outlined"
                      />
                    </TableCell>
                    <TableCell>
                      <Switch
                        checked={solution.isActive}
                        onChange={() => handleToggleActive(solution)}
                        color="success"
                      />
                    </TableCell>
                    <TableCell>
                      <Tooltip title="Edit">
                        <IconButton onClick={() => openEditDialog(solution)} size="small">
                          <EditIcon />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Delete">
                        <IconButton onClick={() => handleDeleteSolution(solution.id)} size="small" color="error">
                          <DeleteIcon />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>

          {totalPages > 1 && (
            <Box sx={{ display: 'flex', justifyContent: 'center', mt: 2 }}>
              <Pagination count={totalPages} page={currentPage} onChange={(_, p) => setCurrentPage(p)} />
            </Box>
          )}
        </Box>
      )}

      {/* Tickets Tab */}
      {tabValue === 1 && (
        <Box>
          <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={ticketStatusFilter}
                label="Status"
                onChange={(e) => setTicketStatusFilter(e.target.value)}
              >
                <MenuItem value="all">All Status</MenuItem>
                <MenuItem value="open">Open</MenuItem>
                <MenuItem value="inProgress">In Progress</MenuItem>
                <MenuItem value="resolved">Resolved</MenuItem>
                <MenuItem value="closed">Closed</MenuItem>
              </Select>
            </FormControl>
          </Box>

          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>User</TableCell>
                  <TableCell>Message</TableCell>
                  <TableCell>Category</TableCell>
                  <TableCell>Priority</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Created</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredTickets.map((ticket) => (
                  <TableRow key={ticket.id}>
                    <TableCell>
                      {ticket.userName}
                      {ticket.isCustomerCareRequest && (
                        <Chip
                          icon={<TicketIcon sx={{ fontSize: 14 }} />}
                          label="CC"
                          size="small"
                          color="warning"
                          sx={{ ml: 1, height: 20, '& .MuiChip-label': { px: 0.5 } }}
                        />
                      )}
                    </TableCell>
                    <TableCell sx={{ maxWidth: 300 }}>
                      {/* Show original query if available, otherwise show userMessage */}
                      <Typography noWrap sx={{ fontWeight: ticket.originalQuery ? 500 : 400 }}>
                        {ticket.originalQuery || ticket.userMessage}
                      </Typography>
                    </TableCell>
                    <TableCell><Chip label={ticket.category} size="small" /></TableCell>
                    <TableCell>
                      <Chip label={ticket.priority} size="small" color={PRIORITY_COLORS[ticket.priority]} />
                    </TableCell>
                    <TableCell>
                      <Chip label={ticket.status} size="small" color={STATUS_COLORS[ticket.status]} />
                    </TableCell>
                    <TableCell>{ticket.createdAt.toLocaleDateString()}</TableCell>
                    <TableCell>
                      <Tooltip title="View & Resolve">
                        <IconButton
                          onClick={() => { setSelectedTicket(ticket); setTicketDialogOpen(true); }}
                          size="small"
                          color="primary"
                        >
                          <ViewIcon />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Box>
      )}

      {/* Analytics Tab */}
      {tabValue === 2 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>Top Triggered Solutions</Typography>
                {analytics.topTriggeredSolutions.map((item, index) => (
                  <Box key={item.id} sx={{ display: 'flex', justifyContent: 'space-between', py: 1, borderBottom: '1px solid #eee' }}>
                    <Typography>
                      {index + 1}. {item.title}
                    </Typography>
                    <Chip label={`${item.count} triggers`} size="small" color="primary" />
                  </Box>
                ))}
                {analytics.topTriggeredSolutions.length === 0 && (
                  <Typography color="text.secondary">No data yet</Typography>
                )}
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>Summary</Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography>Total Solutions:</Typography>
                    <Typography fontWeight={600}>{analytics.totalSolutions}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography>Active Solutions:</Typography>
                    <Typography fontWeight={600} color="success.main">{analytics.activeSolutions}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography>Total Tickets:</Typography>
                    <Typography fontWeight={600}>{analytics.totalTickets}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography>Open Tickets:</Typography>
                    <Typography fontWeight={600} color="warning.main">{analytics.openTickets}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography>Resolution Rate:</Typography>
                    <Typography fontWeight={600} color="info.main">{analytics.resolutionRate.toFixed(1)}%</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Solution Dialog */}
      <Dialog open={solutionDialogOpen} onClose={() => setSolutionDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>{editingSolution ? 'Edit Solution' : 'Add New Solution'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Title"
              value={solutionForm.title}
              onChange={(e) => setSolutionForm({ ...solutionForm, title: e.target.value })}
              fullWidth
              required
            />
            <TextField
              label="Description (Bot Response)"
              value={solutionForm.description}
              onChange={(e) => setSolutionForm({ ...solutionForm, description: e.target.value })}
              fullWidth
              multiline
              rows={4}
              required
            />
            <TextField
              label="Keywords (comma-separated)"
              value={solutionForm.keywords}
              onChange={(e) => setSolutionForm({ ...solutionForm, keywords: e.target.value })}
              fullWidth
              placeholder="payment, refund, money"
              helperText="Keywords that trigger this solution (+1 score each)"
            />
            <TextField
              label="Patterns (comma-separated)"
              value={solutionForm.patterns}
              onChange={(e) => setSolutionForm({ ...solutionForm, patterns: e.target.value })}
              fullWidth
              placeholder="how to pay, payment failed"
              helperText="Exact phrases that trigger this solution (+5 score each)"
            />
            <FormControl fullWidth>
              <InputLabel>Category</InputLabel>
              <Select
                value={solutionForm.category}
                label="Category"
                onChange={(e) => setSolutionForm({ ...solutionForm, category: e.target.value })}
              >
                {CATEGORIES.map((cat) => (
                  <MenuItem key={cat} value={cat}>{cat.charAt(0).toUpperCase() + cat.slice(1)}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <Box>
              <Typography gutterBottom>Priority: {solutionForm.priority}</Typography>
              <Slider
                value={solutionForm.priority}
                onChange={(_, v) => setSolutionForm({ ...solutionForm, priority: v as number })}
                min={1}
                max={10}
                marks
                valueLabelDisplay="auto"
              />
            </Box>
            <FormControlLabel
              control={
                <Switch
                  checked={solutionForm.isActive}
                  onChange={(e) => setSolutionForm({ ...solutionForm, isActive: e.target.checked })}
                />
              }
              label="Active"
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSolutionDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleSaveSolution} variant="contained" disabled={!solutionForm.title || !solutionForm.description}>
            {editingSolution ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Seed Confirmation Dialog */}
      <Dialog open={seedDialogOpen} onClose={() => setSeedDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <SeedIcon color="secondary" />
            Seed Pre-configured Solutions
          </Box>
        </DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Typography>
              This will add <strong>{TOTAL_SOLUTIONS} pre-configured chatbot solutions</strong> to your database.
            </Typography>
            <Typography variant="body2" color="text.secondary">
              The solutions cover the following categories:
            </Typography>
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
              {CATEGORIES.filter(c => c !== 'other').map((cat) => (
                <Chip key={cat} label={cat.charAt(0).toUpperCase() + cat.slice(1)} size="small" />
              ))}
            </Box>
            <Typography variant="body2" color="text.secondary">
              ⚠️ Solutions with matching titles will be skipped to avoid duplicates.
            </Typography>
            {solutions.length > 0 && (
              <Typography variant="body2" color="info.main">
                You already have {solutions.length} solution(s) in the database.
              </Typography>
            )}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSeedDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={handleSeedSolutions}
            variant="contained"
            color="secondary"
            startIcon={<SeedIcon />}
          >
            Seed {TOTAL_SOLUTIONS} Solutions
          </Button>
        </DialogActions>
      </Dialog>

      {/* Ticket Dialog */}
      <TicketResolveDialog
        open={ticketDialogOpen}
        ticket={selectedTicket}
        onClose={() => { setTicketDialogOpen(false); setSelectedTicket(null); }}
        onResolve={handleResolveTicket}
      />
    </Box>
  );
};

// Ticket Resolve Dialog Component
interface TicketResolveDialogProps {
  open: boolean;
  ticket: SupportTicket | null;
  onClose: () => void;
  onResolve: (resolution: string) => void;
}

const TicketResolveDialog: React.FC<TicketResolveDialogProps> = ({ open, ticket, onClose, onResolve }) => {
  const [resolution, setResolution] = useState('');

  if (!ticket) return null;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Support Ticket</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ mt: 1 }}>
          <Box>
            <Typography variant="subtitle2" color="text.secondary">User</Typography>
            <Typography>{ticket.userName} ({ticket.userId})</Typography>
          </Box>
          {/* Show original query prominently if available */}
          {ticket.originalQuery && (
            <Box sx={{
              p: 2,
              bgcolor: 'primary.50',
              borderRadius: 1,
              border: '1px solid',
              borderColor: 'primary.200'
            }}>
              <Typography variant="subtitle2" color="primary.main" sx={{ fontWeight: 600, mb: 0.5 }}>
                📝 User's Original Query
              </Typography>
              <Typography sx={{ fontWeight: 500 }}>{ticket.originalQuery}</Typography>
            </Box>
          )}
          {/* Show solution that was provided if available */}
          {ticket.solutionProvided && (
            <Box sx={{
              p: 2,
              bgcolor: 'grey.100',
              borderRadius: 1,
              border: '1px solid',
              borderColor: 'grey.300'
            }}>
              <Typography variant="subtitle2" color="text.secondary" sx={{ fontWeight: 600, mb: 0.5 }}>
                💬 Solution Provided by Bot
              </Typography>
              <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>{ticket.solutionProvided}</Typography>
            </Box>
          )}
          {/* Show customer care request badge if applicable */}
          {ticket.isCustomerCareRequest && (
            <Chip
              icon={<TicketIcon />}
              label="Customer Care Request"
              color="warning"
              size="small"
              sx={{ width: 'fit-content' }}
            />
          )}
          <Box>
            <Typography variant="subtitle2" color="text.secondary">Message</Typography>
            <Typography>{ticket.userMessage}</Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Box>
              <Typography variant="subtitle2" color="text.secondary">Category</Typography>
              <Chip label={ticket.category} size="small" />
            </Box>
            <Box>
              <Typography variant="subtitle2" color="text.secondary">Priority</Typography>
              <Chip label={ticket.priority} size="small" color={PRIORITY_COLORS[ticket.priority]} />
            </Box>
            <Box>
              <Typography variant="subtitle2" color="text.secondary">Status</Typography>
              <Chip label={ticket.status} size="small" color={STATUS_COLORS[ticket.status]} />
            </Box>
          </Box>
          <Box>
            <Typography variant="subtitle2" color="text.secondary">Created</Typography>
            <Typography>{ticket.createdAt.toLocaleString()}</Typography>
          </Box>
          {ticket.status !== 'resolved' && ticket.status !== 'closed' && (
            <TextField
              label="Resolution"
              value={resolution}
              onChange={(e) => setResolution(e.target.value)}
              fullWidth
              multiline
              rows={3}
              placeholder="Enter resolution notes..."
            />
          )}
          {ticket.resolution && (
            <Box>
              <Typography variant="subtitle2" color="text.secondary">Resolution</Typography>
              <Typography>{ticket.resolution}</Typography>
            </Box>
          )}
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Close</Button>
        {ticket.status !== 'resolved' && ticket.status !== 'closed' && (
          <Button
            onClick={() => onResolve(resolution)}
            variant="contained"
            color="success"
            startIcon={<ResolveIcon />}
            disabled={!resolution}
          >
            Resolve Ticket
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default ChatbotManagementPage;
