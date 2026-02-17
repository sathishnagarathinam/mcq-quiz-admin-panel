import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  CircularProgress,
  Box,
  Typography,
  Chip,
  Tooltip,
  TextField,
  InputAdornment,
} from '@mui/material';
import { Search as SearchIcon, Close as CloseIcon } from '@mui/icons-material';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { db } from '../../config/firebase';
import toast from 'react-hot-toast';

interface QuizAttempt {
  id: string;
  userId: string;
  userName?: string;
  userEmail?: string;
  examId: string;
  examName: string;
  score?: number;
  correctAnswers?: number;
  totalQuestions?: number;
  scorePercentage?: number;
  timeSpent?: number;
  isCompleted: boolean;
  status: string;
  attemptedAt?: Date;
  completedAt?: Date;
}

interface ExamAttemptsDialogProps {
  open: boolean;
  examId: string;
  examName: string;
  onClose: () => void;
}

const ExamAttemptsDialog: React.FC<ExamAttemptsDialogProps> = ({
  open,
  examId,
  examName,
  onClose,
}) => {
  const [attempts, setAttempts] = useState<QuizAttempt[]>([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    if (open && examId) {
      fetchAttempts();
    }
  }, [open, examId]);

  const fetchAttempts = async () => {
    try {
      setLoading(true);
      const attemptsQuery = query(
        collection(db, 'quiz_attempts'),
        where('examId', '==', examId)
      );
      const snapshot = await getDocs(attemptsQuery);
      
      const attemptsList: QuizAttempt[] = [];
      const userIds = new Set<string>();

      // First pass: collect all attempts and user IDs
      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        attemptsList.push({
          id: doc.id,
          userId: data.userId || '',
          examId: data.examId,
          examName: data.examName,
          score: data.score,
          correctAnswers: data.correctAnswers,
          totalQuestions: data.totalQuestions,
          scorePercentage: data.scorePercentage,
          timeSpent: data.timeSpent,
          isCompleted: data.isCompleted || false,
          status: data.status || 'in_progress',
          attemptedAt: data.attemptedAt?.toDate?.() || new Date(data.attemptedAt),
          completedAt: data.completedAt?.toDate?.() || (data.completedAt ? new Date(data.completedAt) : undefined),
        });
        userIds.add(data.userId);
      });

      // Fetch user details for all users
      const userDetailsMap = new Map<string, { name: string; email: string }>();
      const userIdArray = Array.from(userIds);
      for (const userId of userIdArray) {
        try {
          const userQuery = query(
            collection(db, 'mobile_users'),
            where('__name__', '==', userId)
          );
          const userSnapshot = await getDocs(userQuery);
          if (!userSnapshot.empty) {
            const userData = userSnapshot.docs[0].data();
            userDetailsMap.set(userId, {
              name: userData.name || 'Unknown',
              email: userData.email || 'No email',
            });
          }
        } catch (error) {
          console.warn(`Could not fetch user details for ${userId}:`, error);
        }
      }

      // Enrich attempts with user details
      const enrichedAttempts = attemptsList.map((attempt) => ({
        ...attempt,
        userName: userDetailsMap.get(attempt.userId)?.name || 'Unknown User',
        userEmail: userDetailsMap.get(attempt.userId)?.email || 'No email',
      }));

      setAttempts(enrichedAttempts);
    } catch (error) {
      console.error('Error fetching attempts:', error);
      toast.error('Failed to fetch exam attempts');
    } finally {
      setLoading(false);
    }
  };

  const filteredAttempts = attempts.filter((attempt) =>
    attempt.userName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    attempt.userEmail?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const formatTime = (seconds?: number) => {
    if (!seconds) return '-';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}m ${secs}s`;
  };

  const formatDate = (date?: Date) => {
    if (!date) return '-';
    return new Date(date).toLocaleString('en-IN', {
      timeZone: 'Asia/Kolkata',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Typography variant="h6">
            Exam Attempts: {examName}
          </Typography>
          <Button
            size="small"
            onClick={onClose}
            startIcon={<CloseIcon />}
          >
            Close
          </Button>
        </Box>
      </DialogTitle>

      <DialogContent>
        {loading ? (
          <Box display="flex" justifyContent="center" py={4}>
            <CircularProgress />
          </Box>
        ) : (
          <>
            <TextField
              fullWidth
              placeholder="Search by user name or email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
              }}
              sx={{ mb: 2 }}
            />

            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Total Attempts: {filteredAttempts.length}
            </Typography>

            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow sx={{ backgroundColor: '#f5f5f5' }}>
                    <TableCell><strong>User Name</strong></TableCell>
                    <TableCell><strong>Email</strong></TableCell>
                    <TableCell align="center"><strong>Score</strong></TableCell>
                    <TableCell align="center"><strong>Time Spent</strong></TableCell>
                    <TableCell><strong>Attempted At</strong></TableCell>
                    <TableCell><strong>Status</strong></TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredAttempts.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} align="center" sx={{ py: 3 }}>
                        <Typography color="text.secondary">
                          No attempts found
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredAttempts.map((attempt) => (
                      <TableRow key={attempt.id} hover>
                        <TableCell>{attempt.userName}</TableCell>
                        <TableCell>{attempt.userEmail}</TableCell>
                        <TableCell align="center">
                          {attempt.isCompleted ? (
                            <Tooltip title={`${attempt.correctAnswers}/${attempt.totalQuestions} correct`}>
                              <Chip
                                label={`${attempt.scorePercentage || 0}%`}
                                color={attempt.scorePercentage! >= 60 ? 'success' : 'error'}
                                size="small"
                              />
                            </Tooltip>
                          ) : (
                            <Chip label="In Progress" size="small" variant="outlined" />
                          )}
                        </TableCell>
                        <TableCell align="center">
                          {formatTime(attempt.timeSpent)}
                        </TableCell>
                        <TableCell>{formatDate(attempt.attemptedAt)}</TableCell>
                        <TableCell>
                          <Chip
                            label={attempt.status}
                            size="small"
                            color={attempt.isCompleted ? 'success' : 'warning'}
                            variant="outlined"
                          />
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          </>
        )}
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose} variant="contained">
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ExamAttemptsDialog;

