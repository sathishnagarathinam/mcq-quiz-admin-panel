import React, { useState, useEffect, useCallback } from 'react';
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
  Rating,
  Avatar,
  Divider,
  Alert,
  CircularProgress,
  Pagination,
  Stack,
} from '@mui/material';
import {
  Feedback as FeedbackIcon,
  Star as StarIcon,
  FilterList as FilterIcon,
  Search as SearchIcon,
  Reply as ReplyIcon,
  Archive as ArchiveIcon,
  Visibility as ViewIcon,
} from '@mui/icons-material';
import { collection, getDocs, query, orderBy, where, updateDoc, doc } from 'firebase/firestore';
import { db } from '../../config/firebase';
import toast from 'react-hot-toast';

interface FeedbackData {
  id: string;
  userId: string;
  userEmail: string;
  userName: string;
  examId?: string;
  examName?: string;
  examType?: string;
  rating: number;
  comment?: string;
  message?: string;
  userScore?: number;
  totalQuestions?: number;
  percentage?: number;
  category?: string;
  subject?: string;
  submittedAt: Date;
  status: 'pending' | 'reviewed' | 'responded' | 'archived';
  adminResponse?: string;
  respondedAt?: Date;
  respondedBy?: string;
  feedbackType?: 'quiz' | 'general';
}

const FeedbackManagementPage: React.FC = () => {
  const [feedbacks, setFeedbacks] = useState<FeedbackData[]>([]);
  const [filteredFeedbacks, setFilteredFeedbacks] = useState<FeedbackData[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [ratingFilter, setRatingFilter] = useState<string>('all');
  const [selectedFeedback, setSelectedFeedback] = useState<FeedbackData | null>(null);
  const [detailsDialogOpen, setDetailsDialogOpen] = useState(false);
  const [responseDialogOpen, setResponseDialogOpen] = useState(false);
  const [adminResponse, setAdminResponse] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);

  // Load feedbacks from Firestore
  const loadFeedbacks = useCallback(async () => {
    try {
      setLoading(true);

      // Load quiz feedback
      const quizFeedbackQuery = query(
        collection(db, 'feedback'),
        orderBy('submittedAt', 'desc')
      );

      // Load general feedback
      const generalFeedbackQuery = query(
        collection(db, 'general_feedback'),
        orderBy('submittedAt', 'desc')
      );

      const [quizSnapshot, generalSnapshot] = await Promise.all([
        getDocs(quizFeedbackQuery),
        getDocs(generalFeedbackQuery)
      ]);

      const quizFeedbackData: FeedbackData[] = quizSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        submittedAt: doc.data().submittedAt?.toDate() || new Date(),
        respondedAt: doc.data().respondedAt?.toDate(),
        feedbackType: 'quiz' as const,
      })) as FeedbackData[];

      const generalFeedbackData: FeedbackData[] = generalSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        submittedAt: doc.data().submittedAt?.toDate() || new Date(),
        respondedAt: doc.data().respondedAt?.toDate(),
        feedbackType: 'general' as const,
      })) as FeedbackData[];

      // Combine and sort by submission date
      const allFeedback = [...quizFeedbackData, ...generalFeedbackData]
        .sort((a, b) => b.submittedAt.getTime() - a.submittedAt.getTime());

      setFeedbacks(allFeedback);
      setFilteredFeedbacks(allFeedback);
    } catch (error) {
      console.error('Error loading feedbacks:', error);
      toast.error('Failed to load feedbacks');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadFeedbacks();
  }, [loadFeedbacks]);

  // Filter feedbacks based on search and filters
  useEffect(() => {
    let filtered = feedbacks;

    // Search filter
    if (searchTerm) {
      filtered = filtered.filter(feedback =>
        feedback.userName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        feedback.userEmail.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (feedback.examName?.toLowerCase().includes(searchTerm.toLowerCase()) ?? false) ||
        (feedback.comment?.toLowerCase().includes(searchTerm.toLowerCase()) ?? false) ||
        (feedback.message?.toLowerCase().includes(searchTerm.toLowerCase()) ?? false) ||
        (feedback.subject?.toLowerCase().includes(searchTerm.toLowerCase()) ?? false)
      );
    }

    // Status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter(feedback => feedback.status === statusFilter);
    }

    // Rating filter
    if (ratingFilter !== 'all') {
      filtered = filtered.filter(feedback => feedback.rating === parseInt(ratingFilter));
    }

    setFilteredFeedbacks(filtered);
    setCurrentPage(1);
  }, [feedbacks, searchTerm, statusFilter, ratingFilter]);

  // Handle admin response
  const handleAdminResponse = async () => {
    if (!selectedFeedback || !adminResponse.trim()) {
      toast.error('Please provide a response');
      return;
    }

    try {
      const collection = selectedFeedback.feedbackType === 'general' ? 'general_feedback' : 'feedback';
      const feedbackRef = doc(db, collection, selectedFeedback.id);
      await updateDoc(feedbackRef, {
        adminResponse: adminResponse.trim(),
        respondedAt: new Date(),
        respondedBy: 'admin', // You can get this from auth context
        status: 'responded',
      });

      toast.success('Response sent successfully');
      setResponseDialogOpen(false);
      setAdminResponse('');
      loadFeedbacks();
    } catch (error) {
      console.error('Error sending response:', error);
      toast.error('Failed to send response');
    }
  };

  // Handle status update
  const handleStatusUpdate = async (feedbackId: string, newStatus: string, feedbackType?: 'quiz' | 'general') => {
    try {
      const collection = feedbackType === 'general' ? 'general_feedback' : 'feedback';
      const feedbackRef = doc(db, collection, feedbackId);
      await updateDoc(feedbackRef, {
        status: newStatus,
      });

      toast.success('Status updated successfully');
      loadFeedbacks();
    } catch (error) {
      console.error('Error updating status:', error);
      toast.error('Failed to update status');
    }
  };

  // Get status color
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'warning';
      case 'reviewed': return 'info';
      case 'responded': return 'success';
      case 'archived': return 'default';
      default: return 'default';
    }
  };

  // Get rating color
  const getRatingColor = (rating: number) => {
    if (rating >= 4) return '#4caf50';
    if (rating >= 3) return '#ff9800';
    return '#f44336';
  };

  // Pagination
  const totalPages = Math.ceil(filteredFeedbacks.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedFeedbacks = filteredFeedbacks.slice(startIndex, startIndex + itemsPerPage);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom>
        📝 Feedback Management
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        View and manage user feedback from quiz results
      </Typography>

      {/* Statistics Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Total Feedback
                  </Typography>
                  <Typography variant="h4">
                    {feedbacks.length}
                  </Typography>
                </Box>
                <FeedbackIcon color="primary" sx={{ fontSize: 40 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Pending Review
                  </Typography>
                  <Typography variant="h4">
                    {feedbacks.filter(f => f.status === 'pending').length}
                  </Typography>
                </Box>
                <StarIcon color="warning" sx={{ fontSize: 40 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Average Rating
                  </Typography>
                  <Typography variant="h4">
                    {feedbacks.length > 0 
                      ? (feedbacks.reduce((sum, f) => sum + f.rating, 0) / feedbacks.length).toFixed(1)
                      : '0.0'
                    }
                  </Typography>
                </Box>
                <StarIcon color="success" sx={{ fontSize: 40 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Response Rate
                  </Typography>
                  <Typography variant="h4">
                    {feedbacks.length > 0 
                      ? Math.round((feedbacks.filter(f => f.adminResponse).length / feedbacks.length) * 100)
                      : 0
                    }%
                  </Typography>
                </Box>
                <ReplyIcon color="info" sx={{ fontSize: 40 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filters */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                placeholder="Search by user, exam, or comment..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                }}
              />
            </Grid>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Status</InputLabel>
                <Select
                  value={statusFilter}
                  label="Status"
                  onChange={(e) => setStatusFilter(e.target.value)}
                >
                  <MenuItem value="all">All Status</MenuItem>
                  <MenuItem value="pending">Pending</MenuItem>
                  <MenuItem value="reviewed">Reviewed</MenuItem>
                  <MenuItem value="responded">Responded</MenuItem>
                  <MenuItem value="archived">Archived</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Rating</InputLabel>
                <Select
                  value={ratingFilter}
                  label="Rating"
                  onChange={(e) => setRatingFilter(e.target.value)}
                >
                  <MenuItem value="all">All Ratings</MenuItem>
                  <MenuItem value="5">5 Stars</MenuItem>
                  <MenuItem value="4">4 Stars</MenuItem>
                  <MenuItem value="3">3 Stars</MenuItem>
                  <MenuItem value="2">2 Stars</MenuItem>
                  <MenuItem value="1">1 Star</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={2}>
              <Button
                fullWidth
                variant="outlined"
                startIcon={<FilterIcon />}
                onClick={() => {
                  setSearchTerm('');
                  setStatusFilter('all');
                  setRatingFilter('all');
                }}
              >
                Clear
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Feedback List */}
      {filteredFeedbacks.length === 0 ? (
        <Alert severity="info">
          No feedback found matching your criteria.
        </Alert>
      ) : (
        <>
          <Grid container spacing={2}>
            {paginatedFeedbacks.map((feedback) => (
              <Grid item xs={12} key={feedback.id}>
                <Card>
                  <CardContent>
                    <Grid container spacing={2} alignItems="center">
                      <Grid item xs={12} md={8}>
                        <Box display="flex" alignItems="center" mb={1}>
                          <Avatar sx={{ mr: 2, bgcolor: 'primary.main' }}>
                            {feedback.userName.charAt(0).toUpperCase()}
                          </Avatar>
                          <Box>
                            <Typography variant="subtitle1" fontWeight="bold">
                              {feedback.userName}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              {feedback.userEmail}
                            </Typography>
                          </Box>
                        </Box>
                        
                        <Box display="flex" alignItems="center" gap={1} mb={1}>
                          <Chip
                            label={feedback.feedbackType === 'general' ? 'General' : 'Quiz'}
                            color={feedback.feedbackType === 'general' ? 'primary' : 'secondary'}
                            size="small"
                          />
                          <Typography variant="h6">
                            {feedback.feedbackType === 'general' ? feedback.subject : feedback.examName}
                          </Typography>
                        </Box>

                        <Box display="flex" alignItems="center" mb={1}>
                          <Rating value={feedback.rating} readOnly size="small" />
                          {feedback.feedbackType === 'quiz' && (
                            <Typography variant="body2" sx={{ ml: 1 }}>
                              Score: {feedback.userScore}/{feedback.totalQuestions} ({feedback.percentage?.toFixed(1)}%)
                            </Typography>
                          )}
                          {feedback.feedbackType === 'general' && feedback.category && (
                            <Typography variant="body2" sx={{ ml: 1 }}>
                              Category: {feedback.category.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                            </Typography>
                          )}
                        </Box>

                        <Typography variant="body2" color="text.secondary" noWrap>
                          {feedback.feedbackType === 'general' ? feedback.message : feedback.comment}
                        </Typography>
                      </Grid>
                      
                      <Grid item xs={12} md={4}>
                        <Box display="flex" flexDirection="column" alignItems="flex-end" gap={1}>
                          <Chip 
                            label={feedback.status.charAt(0).toUpperCase() + feedback.status.slice(1)}
                            color={getStatusColor(feedback.status) as any}
                            size="small"
                          />
                          
                          <Typography variant="caption" color="text.secondary">
                            {feedback.submittedAt.toLocaleDateString()}
                          </Typography>
                          
                          <Box display="flex" gap={1}>
                            <Button
                              size="small"
                              startIcon={<ViewIcon />}
                              onClick={() => {
                                setSelectedFeedback(feedback);
                                setDetailsDialogOpen(true);
                              }}
                            >
                              View
                            </Button>
                            
                            {feedback.status !== 'responded' && (
                              <Button
                                size="small"
                                startIcon={<ReplyIcon />}
                                onClick={() => {
                                  setSelectedFeedback(feedback);
                                  setResponseDialogOpen(true);
                                }}
                              >
                                Respond
                              </Button>
                            )}
                          </Box>
                        </Box>
                      </Grid>
                    </Grid>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>

          {/* Pagination */}
          {totalPages > 1 && (
            <Box display="flex" justifyContent="center" mt={4}>
              <Pagination
                count={totalPages}
                page={currentPage}
                onChange={(_, page) => setCurrentPage(page)}
                color="primary"
              />
            </Box>
          )}
        </>
      )}

      {/* Feedback Details Dialog */}
      <Dialog
        open={detailsDialogOpen}
        onClose={() => setDetailsDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          Feedback Details
        </DialogTitle>
        <DialogContent>
          {selectedFeedback && (
            <Box>
              <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" gutterBottom>User Information</Typography>
                  <Typography variant="body2">Name: {selectedFeedback.userName}</Typography>
                  <Typography variant="body2">Email: {selectedFeedback.userEmail}</Typography>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" gutterBottom>
                    {selectedFeedback.feedbackType === 'general' ? 'Feedback Information' : 'Quiz Information'}
                  </Typography>
                  {selectedFeedback.feedbackType === 'general' ? (
                    <>
                      <Typography variant="body2">Type: General Feedback</Typography>
                      <Typography variant="body2">Category: {selectedFeedback.category?.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}</Typography>
                      <Typography variant="body2">Subject: {selectedFeedback.subject}</Typography>
                    </>
                  ) : (
                    <>
                      <Typography variant="body2">Exam: {selectedFeedback.examName}</Typography>
                      <Typography variant="body2">Type: {selectedFeedback.examType}</Typography>
                      <Typography variant="body2">
                        Score: {selectedFeedback.userScore}/{selectedFeedback.totalQuestions} ({selectedFeedback.percentage?.toFixed(1)}%)
                      </Typography>
                    </>
                  )}
                </Grid>
              </Grid>
              
              <Divider sx={{ my: 2 }} />
              
              <Typography variant="subtitle2" gutterBottom>Rating</Typography>
              <Rating value={selectedFeedback.rating} readOnly />
              
              <Typography variant="subtitle2" gutterBottom sx={{ mt: 2 }}>
                {selectedFeedback.feedbackType === 'general' ? 'Message' : 'Comment'}
              </Typography>
              <Typography variant="body2" sx={{ mb: 2 }}>
                {selectedFeedback.feedbackType === 'general' ? selectedFeedback.message : selectedFeedback.comment}
              </Typography>
              
              {selectedFeedback.adminResponse && (
                <>
                  <Divider sx={{ my: 2 }} />
                  <Typography variant="subtitle2" gutterBottom>Admin Response</Typography>
                  <Typography variant="body2">
                    {selectedFeedback.adminResponse}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Responded on: {selectedFeedback.respondedAt?.toLocaleDateString()}
                  </Typography>
                </>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailsDialogOpen(false)}>Close</Button>
          {selectedFeedback && selectedFeedback.status !== 'responded' && (
            <Button
              variant="contained"
              startIcon={<ReplyIcon />}
              onClick={() => {
                setDetailsDialogOpen(false);
                setResponseDialogOpen(true);
              }}
            >
              Respond
            </Button>
          )}
        </DialogActions>
      </Dialog>

      {/* Response Dialog */}
      <Dialog
        open={responseDialogOpen}
        onClose={() => setResponseDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          Respond to Feedback
        </DialogTitle>
        <DialogContent>
          {selectedFeedback && (
            <Box>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Responding to feedback from {selectedFeedback.userName} for "{selectedFeedback.examName}"
              </Typography>
              
              <TextField
                fullWidth
                multiline
                rows={4}
                label="Your Response"
                value={adminResponse}
                onChange={(e) => setAdminResponse(e.target.value)}
                placeholder="Thank you for your feedback. We appreciate your input..."
                sx={{ mt: 2 }}
              />
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setResponseDialogOpen(false)}>Cancel</Button>
          <Button
            variant="contained"
            onClick={handleAdminResponse}
            disabled={!adminResponse.trim()}
          >
            Send Response
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default FeedbackManagementPage;
