import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  FormControlLabel,
  Grid,
  IconButton,
  InputLabel,
  MenuItem,
  Select,
  Switch,
  TextField,
  Typography,
  Alert,
  CircularProgress,
  Autocomplete,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  PlayArrow as PlayIcon,
  Pause as PauseIcon,
  LiveTv as LiveTvIcon,
  Schedule as ScheduleIcon,
  People as PeopleIcon,
} from '@mui/icons-material';
import { DateTimePicker } from '@mui/x-date-pickers/DateTimePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import {
  collection,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from '../../config/firebase';

interface LiveTest {
  id: string;
  title: string;
  description: string;
  examType: string;
  suitableFor: string[];
  startTime: Date;
  endTime: Date;
  durationMinutes: number;
  totalQuestions: number;
  isActive: boolean;
  isLive: boolean;
  status: 'upcoming' | 'live' | 'completed' | 'cancelled';
  maxParticipants: number;
  currentParticipants: number;
  instructorName: string;
  instructorImage: string;
  tags: string[];
  difficulty: 'easy' | 'medium' | 'hard';
  passingScore: number;
  showResults: boolean;
  examId: string;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}

const suitabilityOptions = [
  'MTS', 'Postman', 'Postal Assistant', 'Inspector', 'ASP', 'SP', 'Group B', 'Others'
];

const difficultyOptions = ['easy', 'medium', 'hard'];
const statusOptions = ['upcoming', 'live', 'completed', 'cancelled'];

const LiveTestManagement: React.FC = () => {
  const [liveTests, setLiveTests] = useState<LiveTest[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingTest, setEditingTest] = useState<LiveTest | null>(null);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    examType: '',
    suitableFor: [] as string[],
    startTime: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
    endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000), // Tomorrow + 2 hours
    durationMinutes: 60,
    totalQuestions: 50,
    isActive: true,
    isLive: false,
    status: 'upcoming' as 'upcoming' | 'live' | 'completed' | 'cancelled',
    maxParticipants: 1000,
    currentParticipants: 0,
    instructorName: '',
    instructorImage: '',
    tags: [] as string[],
    difficulty: 'medium' as 'easy' | 'medium' | 'hard',
    passingScore: 60,
    showResults: true,
    examId: '',
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, 'live_tests'),
      orderBy('startTime', 'asc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const testsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        startTime: doc.data().startTime?.toDate() || new Date(),
        endTime: doc.data().endTime?.toDate() || new Date(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate() || new Date(),
      })) as LiveTest[];
      
      setLiveTests(testsData);
      setLoading(false);
    }, (error) => {
      console.error('Error fetching live tests:', error);
      setError('Failed to load live tests');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleOpenDialog = (test?: LiveTest) => {
    if (test) {
      setEditingTest(test);
      setFormData({
        title: test.title,
        description: test.description,
        examType: test.examType,
        suitableFor: test.suitableFor,
        startTime: test.startTime,
        endTime: test.endTime,
        durationMinutes: test.durationMinutes,
        totalQuestions: test.totalQuestions,
        isActive: test.isActive,
        isLive: test.isLive,
        status: test.status,
        maxParticipants: test.maxParticipants,
        currentParticipants: test.currentParticipants,
        instructorName: test.instructorName,
        instructorImage: test.instructorImage,
        tags: test.tags,
        difficulty: test.difficulty,
        passingScore: test.passingScore,
        showResults: test.showResults,
        examId: test.examId,
      });
    } else {
      setEditingTest(null);
      setFormData({
        title: '',
        description: '',
        examType: '',
        suitableFor: [],
        startTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
        endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
        durationMinutes: 60,
        totalQuestions: 50,
        isActive: true,
        isLive: false,
        status: 'upcoming',
        maxParticipants: 1000,
        currentParticipants: 0,
        instructorName: '',
        instructorImage: '',
        tags: [],
        difficulty: 'medium',
        passingScore: 60,
        showResults: true,
        examId: '',
      });
    }
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setEditingTest(null);
    setError(null);
  };

  const handleSave = async () => {
    if (!formData.title.trim() || !formData.examType.trim()) {
      setError('Title and exam type are required');
      return;
    }

    if (formData.startTime >= formData.endTime) {
      setError('End time must be after start time');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const testData = {
        ...formData,
        updatedAt: serverTimestamp(),
      };

      if (editingTest) {
        await updateDoc(doc(db, 'live_tests', editingTest.id), testData);
      } else {
        await addDoc(collection(db, 'live_tests'), {
          ...testData,
          createdAt: serverTimestamp(),
          createdBy: 'admin', // TODO: Get actual admin user
        });
      }

      handleCloseDialog();
    } catch (error) {
      console.error('Error saving live test:', error);
      setError('Failed to save live test');
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateStatus = async (testId: string, status: string) => {
    try {
      await updateDoc(doc(db, 'live_tests', testId), {
        status,
        isLive: status === 'live',
        updatedAt: serverTimestamp(),
      });
    } catch (error) {
      console.error('Error updating test status:', error);
      setError('Failed to update test status');
    }
  };

  const handleDelete = async (testId: string) => {
    if (window.confirm('Are you sure you want to delete this live test?')) {
      try {
        await deleteDoc(doc(db, 'live_tests', testId));
      } catch (error) {
        console.error('Error deleting live test:', error);
        setError('Failed to delete live test');
      }
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'live': return 'error';
      case 'upcoming': return 'primary';
      case 'completed': return 'success';
      case 'cancelled': return 'default';
      default: return 'default';
    }
  };

  const formatDateTime = (date: Date) => {
    return date.toLocaleString();
  };

  const getTimeUntilStart = (startTime: Date) => {
    const now = new Date();
    const diff = startTime.getTime() - now.getTime();
    
    if (diff <= 0) return 'Started';
    
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    
    if (days > 0) return `${days}d ${hours}h`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns}>
      <Box p={3}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Typography variant="h4" component="h1">
            Live Test Management
          </Typography>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => handleOpenDialog()}
          >
            Schedule Live Test
          </Button>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {liveTests.length === 0 ? (
          <Card>
            <CardContent>
              <Box textAlign="center" py={4}>
                <LiveTvIcon sx={{ fontSize: 64, color: 'grey.400', mb: 2 }} />
                <Typography variant="h6" color="textSecondary" gutterBottom>
                  No live tests scheduled
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Schedule your first live test to engage students in real-time
                </Typography>
              </Box>
            </CardContent>
          </Card>
        ) : (
          <Grid container spacing={3}>
            {liveTests.map((test) => (
              <Grid item xs={12} md={6} lg={4} key={test.id}>
                <Card>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                      <Typography variant="h6" component="h2" noWrap>
                        {test.title}
                      </Typography>
                      <Chip
                        label={test.status.toUpperCase()}
                        color={getStatusColor(test.status)}
                        size="small"
                        icon={test.status === 'live' ? <LiveTvIcon /> : <ScheduleIcon />}
                      />
                    </Box>
                    
                    <Typography variant="body2" color="textSecondary" gutterBottom>
                      {test.description}
                    </Typography>

                    <Box display="flex" gap={1} mb={2} flexWrap="wrap">
                      <Chip label={test.examType} size="small" />
                      <Chip label={test.difficulty} size="small" color="secondary" />
                      {test.suitableFor.slice(0, 2).map((suit) => (
                        <Chip key={suit} label={suit} size="small" variant="outlined" />
                      ))}
                      {test.suitableFor.length > 2 && (
                        <Chip label={`+${test.suitableFor.length - 2}`} size="small" variant="outlined" />
                      )}
                    </Box>

                    <Box mb={2}>
                      <Typography variant="caption" color="textSecondary" display="block">
                        <ScheduleIcon sx={{ fontSize: 14, mr: 0.5 }} />
                        Starts: {formatDateTime(test.startTime)}
                      </Typography>
                      <Typography variant="caption" color="textSecondary" display="block">
                        Duration: {test.durationMinutes} minutes | Questions: {test.totalQuestions}
                      </Typography>
                      <Typography variant="caption" color="textSecondary" display="block">
                        <PeopleIcon sx={{ fontSize: 14, mr: 0.5 }} />
                        Participants: {test.currentParticipants}/{test.maxParticipants}
                      </Typography>
                      {test.status === 'upcoming' && (
                        <Typography variant="caption" color="primary" display="block" fontWeight="bold">
                          Starts in: {getTimeUntilStart(test.startTime)}
                        </Typography>
                      )}
                    </Box>

                    <Box display="flex" justifyContent="space-between">
                      <Box>
                        <IconButton
                          size="small"
                          onClick={() => handleOpenDialog(test)}
                          title="Edit Test"
                        >
                          <EditIcon />
                        </IconButton>
                        {test.status === 'upcoming' && (
                          <IconButton
                            size="small"
                            onClick={() => handleUpdateStatus(test.id, 'live')}
                            title="Start Live"
                            color="error"
                          >
                            <PlayIcon />
                          </IconButton>
                        )}
                        {test.status === 'live' && (
                          <IconButton
                            size="small"
                            onClick={() => handleUpdateStatus(test.id, 'completed')}
                            title="End Test"
                          >
                            <PauseIcon />
                          </IconButton>
                        )}
                        <IconButton
                          size="small"
                          onClick={() => handleDelete(test.id)}
                          title="Delete Test"
                          color="error"
                        >
                          <DeleteIcon />
                        </IconButton>
                      </Box>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}

        {/* Live Test Form Dialog */}
        <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
          <DialogTitle>
            {editingTest ? 'Edit Live Test' : 'Schedule Live Test'}
          </DialogTitle>
          <DialogContent>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Title *"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Exam Type *"
                  value={formData.examType}
                  onChange={(e) => setFormData({ ...formData, examType: e.target.value })}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Description"
                  multiline
                  rows={3}
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Autocomplete
                  multiple
                  options={suitabilityOptions}
                  value={formData.suitableFor}
                  onChange={(_, newValue) => setFormData({ ...formData, suitableFor: newValue })}
                  renderInput={(params) => (
                    <TextField {...params} label="Suitable For" />
                  )}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Difficulty</InputLabel>
                  <Select
                    value={formData.difficulty}
                    onChange={(e) => setFormData({ ...formData, difficulty: e.target.value as any })}
                    label="Difficulty"
                  >
                    {difficultyOptions.map((diff) => (
                      <MenuItem key={diff} value={diff}>
                        {diff.charAt(0).toUpperCase() + diff.slice(1)}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <DateTimePicker
                  label="Start Time"
                  value={formData.startTime}
                  onChange={(date) => setFormData({ ...formData, startTime: date || new Date() })}
                  slotProps={{ textField: { fullWidth: true } }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <DateTimePicker
                  label="End Time"
                  value={formData.endTime}
                  onChange={(date) => setFormData({ ...formData, endTime: date || new Date() })}
                  slotProps={{ textField: { fullWidth: true } }}
                />
              </Grid>
              <Grid item xs={12} sm={4}>
                <TextField
                  fullWidth
                  label="Duration (minutes)"
                  type="number"
                  value={formData.durationMinutes}
                  onChange={(e) => setFormData({ ...formData, durationMinutes: parseInt(e.target.value) || 0 })}
                />
              </Grid>
              <Grid item xs={12} sm={4}>
                <TextField
                  fullWidth
                  label="Total Questions"
                  type="number"
                  value={formData.totalQuestions}
                  onChange={(e) => setFormData({ ...formData, totalQuestions: parseInt(e.target.value) || 0 })}
                />
              </Grid>
              <Grid item xs={12} sm={4}>
                <TextField
                  fullWidth
                  label="Max Participants"
                  type="number"
                  value={formData.maxParticipants}
                  onChange={(e) => setFormData({ ...formData, maxParticipants: parseInt(e.target.value) || 0 })}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Instructor Name"
                  value={formData.instructorName}
                  onChange={(e) => setFormData({ ...formData, instructorName: e.target.value })}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Passing Score (%)"
                  type="number"
                  value={formData.passingScore}
                  onChange={(e) => setFormData({ ...formData, passingScore: parseInt(e.target.value) || 0 })}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Status</InputLabel>
                  <Select
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value as any })}
                    label="Status"
                  >
                    {statusOptions.map((status) => (
                      <MenuItem key={status} value={status}>
                        {status.charAt(0).toUpperCase() + status.slice(1)}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Exam ID (Reference)"
                  value={formData.examId}
                  onChange={(e) => setFormData({ ...formData, examId: e.target.value })}
                />
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.isActive}
                      onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                    />
                  }
                  label="Active"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.showResults}
                      onChange={(e) => setFormData({ ...formData, showResults: e.target.checked })}
                    />
                  }
                  label="Show Results to Participants"
                />
              </Grid>
            </Grid>

            {error && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {error}
              </Alert>
            )}
          </DialogContent>
          <DialogActions>
            <Button onClick={handleCloseDialog}>Cancel</Button>
            <Button
              onClick={handleSave}
              variant="contained"
              disabled={saving}
              startIcon={saving ? <CircularProgress size={20} /> : null}
            >
              {editingTest ? 'Update' : 'Schedule'}
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </LocalizationProvider>
  );
};

export default LiveTestManagement;
