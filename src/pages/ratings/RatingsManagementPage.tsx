import React, { useEffect, useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
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
  Rating,
  CircularProgress,
  Alert,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  TableSortLabel,
  Stack,
} from '@mui/material';
import { collection, getDocs, deleteDoc, doc, updateDoc, addDoc, query, where, Timestamp } from 'firebase/firestore';
import { db } from '../../config/firebase';
import { Edit as EditIcon, Delete as DeleteIcon, Add as AddIcon } from '@mui/icons-material';

interface Rating {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  examId: string;
  examName: string;
  rating: number;
  comment: string;
  userScore: number;
  totalQuestions: number;
  submittedAt: any;
}

interface User {
  id: string;
  name: string;
  email: string;
}

type SortOrder = 'asc' | 'desc';

const RatingsManagementPage: React.FC = () => {
  const [ratings, setRatings] = useState<Rating[]>([]);
  const [exams, setExams] = useState<any[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedExam, setSelectedExam] = useState<string>('');
  const [openDialog, setOpenDialog] = useState(false);
  const [openCreateDialog, setOpenCreateDialog] = useState(false);
  const [editingRating, setEditingRating] = useState<Rating | null>(null);
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState({
    rating: 5,
    comment: '',
    examId: '',
  });
  const [createFormData, setCreateFormData] = useState({
    userId: '',
    userName: '',
    userEmail: '',
    examId: '',
    examName: '',
    rating: 5,
    comment: '',
    userScore: 0,
    totalQuestions: 0,
  });

  useEffect(() => {
    fetchExams();
    fetchUsers();
    fetchRatings();
  }, [selectedExam]);

  const fetchExams = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, 'exams'));
      const examsList = querySnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
      }));
      setExams(examsList);
    } catch (error) {
      console.error('Error fetching exams:', error);
    }
  };

  const fetchUsers = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, 'mobile_users'));
      const usersList = querySnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name || doc.data().displayName || 'Unknown User',
        email: doc.data().email || '',
      }));
      setUsers(usersList);
    } catch (error) {
      console.error('Error fetching users:', error);
    }
  };

  const fetchRatings = async () => {
    try {
      setLoading(true);
      let q;
      if (selectedExam) {
        q = query(collection(db, 'feedback'), where('examId', '==', selectedExam));
      } else {
        q = collection(db, 'feedback');
      }
      const querySnapshot = await getDocs(q);
      let ratingsList = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      } as Rating));

      // Sort by submission time
      ratingsList.sort((a, b) => {
        const dateA = a.submittedAt?.toDate?.() || new Date(a.submittedAt);
        const dateB = b.submittedAt?.toDate?.() || new Date(b.submittedAt);
        return sortOrder === 'desc'
          ? dateB.getTime() - dateA.getTime()
          : dateA.getTime() - dateB.getTime();
      });

      setRatings(ratingsList);
    } catch (error) {
      console.error('Error fetching ratings:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteRating = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this rating?')) {
      try {
        await deleteDoc(doc(db, 'feedback', id));
        setRatings(ratings.filter(r => r.id !== id));
      } catch (error) {
        console.error('Error deleting rating:', error);
      }
    }
  };

  const handleEditRating = (rating: Rating) => {
    setEditingRating(rating);
    setFormData({
      rating: rating.rating,
      comment: rating.comment,
      examId: rating.examId,
    });
    setOpenDialog(true);
  };

  const handleSaveRating = async () => {
    try {
      if (editingRating) {
        await updateDoc(doc(db, 'feedback', editingRating.id), {
          rating: formData.rating,
          comment: formData.comment,
        });
      }
      setOpenDialog(false);
      setEditingRating(null);
      fetchRatings();
    } catch (error) {
      console.error('Error saving rating:', error);
    }
  };

  const handleOpenCreateDialog = () => {
    setCreateFormData({
      userId: '',
      userName: '',
      userEmail: '',
      examId: '',
      examName: '',
      rating: 5,
      comment: '',
      userScore: 0,
      totalQuestions: 0,
    });
    setOpenCreateDialog(true);
  };

  const handleCloseCreateDialog = () => {
    setOpenCreateDialog(false);
  };

  const handleUserChange = (userId: string) => {
    const selectedUser = users.find(u => u.id === userId);
    if (selectedUser) {
      setCreateFormData({
        ...createFormData,
        userId,
        userName: selectedUser.name,
        userEmail: selectedUser.email,
      });
    }
  };

  const handleExamChange = (examId: string) => {
    const selectedExam = exams.find(e => e.id === examId);
    if (selectedExam) {
      setCreateFormData({
        ...createFormData,
        examId,
        examName: selectedExam.name,
      });
    }
  };

  const handleSortChange = () => {
    const newSortOrder = sortOrder === 'desc' ? 'asc' : 'desc';
    setSortOrder(newSortOrder);
  };

  const handleCreateReview = async () => {
    if (!createFormData.userId || !createFormData.examId) {
      alert('Please select both user and exam');
      return;
    }

    if (createFormData.totalQuestions <= 0) {
      alert('Total questions must be greater than 0');
      return;
    }

    if (createFormData.userScore > createFormData.totalQuestions) {
      alert('User score cannot be greater than total questions');
      return;
    }

    setSaving(true);
    try {
      const percentage = (createFormData.userScore / createFormData.totalQuestions) * 100;

      const newReview = {
        userId: createFormData.userId,
        userName: createFormData.userName,
        userEmail: createFormData.userEmail,
        examId: createFormData.examId,
        examName: createFormData.examName,
        rating: createFormData.rating,
        comment: createFormData.comment,
        userScore: createFormData.userScore,
        totalQuestions: createFormData.totalQuestions,
        percentage,
        submittedAt: Timestamp.now(),
        status: 'pending',
      };

      await addDoc(collection(db, 'feedback'), newReview);
      alert('Review created successfully');
      handleCloseCreateDialog();
      fetchRatings();
    } catch (error) {
      console.error('Error creating review:', error);
      alert('Failed to create review');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h4">
          Ratings Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenCreateDialog}
          sx={{ bgcolor: '#4CAF50' }}
        >
          Add New Review
        </Button>
      </Box>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <FormControl fullWidth sx={{ mb: 2 }}>
            <InputLabel>Filter by Exam</InputLabel>
            <Select
              value={selectedExam}
              label="Filter by Exam"
              onChange={(e) => setSelectedExam(e.target.value)}
            >
              <MenuItem value="">All Exams</MenuItem>
              {exams.map(exam => (
                <MenuItem key={exam.id} value={exam.id}>{exam.name}</MenuItem>
              ))}
            </Select>
          </FormControl>
        </CardContent>
      </Card>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
          <CircularProgress />
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow sx={{ backgroundColor: '#f5f5f5' }}>
                <TableCell>User</TableCell>
                <TableCell>Exam</TableCell>
                <TableCell align="center">Rating</TableCell>
                <TableCell>Comment</TableCell>
                <TableCell>Score</TableCell>
                <TableCell align="center">
                  <TableSortLabel
                    active={true}
                    direction={sortOrder}
                    onClick={handleSortChange}
                    title={`Sort by submission time (${sortOrder === 'desc' ? 'Newest First' : 'Oldest First'})`}
                  >
                    Submitted
                  </TableSortLabel>
                </TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {ratings.map(rating => {
                const submittedDate = rating.submittedAt?.toDate?.() || new Date(rating.submittedAt);
                const formattedDate = submittedDate.toLocaleDateString() + ' ' + submittedDate.toLocaleTimeString();
                return (
                  <TableRow key={rating.id}>
                    <TableCell>{rating.userName}</TableCell>
                    <TableCell>{rating.examName}</TableCell>
                    <TableCell align="center">
                      <Rating value={rating.rating} readOnly size="small" />
                    </TableCell>
                    <TableCell>{rating.comment}</TableCell>
                    <TableCell>{rating.userScore}/{rating.totalQuestions}</TableCell>
                    <TableCell align="center">{formattedDate}</TableCell>
                    <TableCell align="right">
                      <Button
                        size="small"
                        startIcon={<EditIcon />}
                        onClick={() => handleEditRating(rating)}
                      >
                        Edit
                      </Button>
                      <Button
                        size="small"
                        color="error"
                        startIcon={<DeleteIcon />}
                        onClick={() => handleDeleteRating(rating.id)}
                      >
                        Delete
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Edit Rating</DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Box sx={{ mb: 2 }}>
            <Typography variant="subtitle2" sx={{ mb: 1 }}>Rating</Typography>
            <Rating
              value={formData.rating}
              onChange={(e, value) => setFormData({ ...formData, rating: value || 5 })}
            />
          </Box>
          <TextField
            fullWidth
            label="Comment"
            multiline
            rows={4}
            value={formData.comment}
            onChange={(e) => setFormData({ ...formData, comment: e.target.value })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button onClick={handleSaveRating} variant="contained">Save</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={openCreateDialog} onClose={handleCloseCreateDialog} maxWidth="sm" fullWidth>
        <DialogTitle>Add New Review</DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Stack spacing={2}>
            <FormControl fullWidth>
              <InputLabel>Select User</InputLabel>
              <Select
                value={createFormData.userId}
                label="Select User"
                onChange={(e) => handleUserChange(e.target.value)}
              >
                <MenuItem value="">-- Choose a user --</MenuItem>
                {users.map(user => (
                  <MenuItem key={user.id} value={user.id}>
                    {user.name} ({user.email})
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl fullWidth>
              <InputLabel>Select Quiz/Exam</InputLabel>
              <Select
                value={createFormData.examId}
                label="Select Quiz/Exam"
                onChange={(e) => handleExamChange(e.target.value)}
              >
                <MenuItem value="">-- Choose a quiz --</MenuItem>
                {exams.map(exam => (
                  <MenuItem key={exam.id} value={exam.id}>{exam.name}</MenuItem>
                ))}
              </Select>
            </FormControl>

            <Box>
              <Typography variant="subtitle2" sx={{ mb: 1 }}>Rating (1-5 stars)</Typography>
              <Rating
                value={createFormData.rating}
                onChange={(e, value) => setCreateFormData({ ...createFormData, rating: value || 5 })}
              />
            </Box>

            <TextField
              fullWidth
              label="Review Comment"
              multiline
              rows={3}
              value={createFormData.comment}
              onChange={(e) => setCreateFormData({ ...createFormData, comment: e.target.value })}
              placeholder="Enter review comment (optional)"
            />

            <TextField
              fullWidth
              label="User Score"
              type="number"
              inputProps={{ min: 0 }}
              value={createFormData.userScore}
              onChange={(e) => setCreateFormData({ ...createFormData, userScore: parseInt(e.target.value) || 0 })}
            />

            <TextField
              fullWidth
              label="Total Questions"
              type="number"
              inputProps={{ min: 1 }}
              value={createFormData.totalQuestions}
              onChange={(e) => setCreateFormData({ ...createFormData, totalQuestions: parseInt(e.target.value) || 0 })}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseCreateDialog}>Cancel</Button>
          <Button onClick={handleCreateReview} variant="contained" disabled={saving}>
            {saving ? 'Creating...' : 'Create Review'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default RatingsManagementPage;

