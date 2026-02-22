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
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  PlayArrow as PlayIcon,
  Pause as PauseIcon,
  Fullscreen as FullscreenIcon,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDocs,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
  where,
} from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { db } from '../../config/firebase';

interface InterstitialAd {
  id: string;
  title: string;
  description: string;
  primaryColor: string;
  secondaryColor: string;
  iconName: string;
  isActive: boolean;
  startDate: Date;
  endDate: Date;
  examId?: string;
  examName?: string;
  displayDurationSeconds: number;
  priority: number;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}

interface Exam {
  id: string;
  name: string;
  examType: string;
  isActive: boolean;
}

const iconOptions = [
  'campaign', 'star', 'celebration', 'local_offer', 'quiz',
  'school', 'emoji_events', 'lightbulb', 'flash_on', 'new_releases',
];

const colorOptions = [
  '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3',
  '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
  '#FFEB3B', '#FFC107', '#FF9800', '#FF5722', '#795548',
];

const InterstitialAdManagementPage: React.FC = () => {
  const [ads, setAds] = useState<InterstitialAd[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingAd, setEditingAd] = useState<InterstitialAd | null>(null);
  const [exams, setExams] = useState<Exam[]>([]);
  const [loadingExams, setLoadingExams] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    primaryColor: '#E91E63',
    secondaryColor: '#9C27B0',
    iconName: 'campaign',
    isActive: true,
    startDate: new Date(),
    endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    examId: '',
    examName: '',
    displayDurationSeconds: 5,
    priority: 0,
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load exams for linking
  const loadExams = async () => {
    const auth = getAuth();
    const currentUser = auth.currentUser;
    if (!currentUser) {
      setLoadingExams(false);
      return;
    }

    setLoadingExams(true);
    try {
      let snapshot;
      try {
        const q = query(collection(db, 'exams'), where('isActive', '==', true));
        snapshot = await getDocs(q);
      } catch {
        snapshot = await getDocs(collection(db, 'exams'));
      }

      const examsData = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          name: data.name || data.examName || data.title || `Exam ${doc.id.substring(0, 8)}`,
          examType: data.examType || data.type || 'General',
          isActive: data.isActive !== undefined ? data.isActive : true,
        };
      });
      setExams(examsData);
    } catch (error) {
      console.error('Error loading exams:', error);
    } finally {
      setLoadingExams(false);
    }
  };

  useEffect(() => {
    loadExams();
  }, []);

  // Listen to interstitial ads collection
  useEffect(() => {
    const q = query(
      collection(db, 'interstitial_ads'),
      orderBy('priority', 'desc'),
      orderBy('createdAt', 'desc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const adsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        startDate: doc.data().startDate?.toDate() || new Date(),
        endDate: doc.data().endDate?.toDate() || new Date(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate() || new Date(),
      })) as InterstitialAd[];
      setAds(adsData);
      setLoading(false);
    }, (error) => {
      console.error('Error fetching interstitial ads:', error);
      setError(`Failed to load ads: ${error.message}`);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleOpenDialog = (ad?: InterstitialAd) => {
    if (ad) {
      setEditingAd(ad);
      setFormData({
        title: ad.title,
        description: ad.description,
        primaryColor: ad.primaryColor,
        secondaryColor: ad.secondaryColor,
        iconName: ad.iconName,
        isActive: ad.isActive,
        startDate: ad.startDate,
        endDate: ad.endDate,
        examId: ad.examId || '',
        examName: ad.examName || '',
        displayDurationSeconds: ad.displayDurationSeconds,
        priority: ad.priority,
      });
    } else {
      setEditingAd(null);
      setFormData({
        title: '',
        description: '',
        primaryColor: '#E91E63',
        secondaryColor: '#9C27B0',
        iconName: 'campaign',
        isActive: true,
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        examId: '',
        examName: '',
        displayDurationSeconds: 5,
        priority: 0,
      });
    }
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setEditingAd(null);
    setError(null);
  };

  const handleSave = async () => {
    if (!formData.title.trim() || !formData.description.trim()) {
      setError('Title and description are required');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const adData = {
        ...formData,
        updatedAt: serverTimestamp(),
      };

      if (editingAd) {
        await updateDoc(doc(db, 'interstitial_ads', editingAd.id), adData);
      } else {
        await addDoc(collection(db, 'interstitial_ads'), {
          ...adData,
          createdAt: serverTimestamp(),
          createdBy: 'admin',
        });
      }
      handleCloseDialog();
    } catch (error) {
      console.error('Error saving ad:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      setError(`Failed to save ad: ${errorMessage}`);
    } finally {
      setSaving(false);
    }
  };

  const handleToggleStatus = async (adId: string, isActive: boolean) => {
    try {
      await updateDoc(doc(db, 'interstitial_ads', adId), {
        isActive,
        updatedAt: serverTimestamp(),
      });
    } catch (error) {
      console.error('Error updating ad status:', error);
      setError('Failed to update ad status');
    }
  };

  const handleDelete = async (adId: string) => {
    if (window.confirm('Are you sure you want to delete this interstitial ad?')) {
      try {
        await deleteDoc(doc(db, 'interstitial_ads', adId));
      } catch (error) {
        console.error('Error deleting ad:', error);
        setError('Failed to delete ad');
      }
    }
  };

  const isCurrentlyActive = (ad: InterstitialAd) => {
    const now = new Date();
    return ad.isActive && now >= ad.startDate && now <= ad.endDate;
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
            Interstitial Ad Management
          </Typography>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => handleOpenDialog()}
            sx={{ backgroundColor: '#9C27B0' }}
          >
            Add Interstitial Ad
          </Button>
        </Box>

        <Typography variant="body2" color="textSecondary" mb={3}>
          Create full-screen ads that flash in the mobile app when activated
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {ads.length === 0 ? (
          <Card>
            <CardContent>
              <Box textAlign="center" py={4}>
                <FullscreenIcon sx={{ fontSize: 64, color: 'grey.400', mb: 2 }} />
                <Typography variant="h6" color="textSecondary" gutterBottom>
                  No interstitial ads created yet
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Create your first full-screen ad to display in the mobile app
                </Typography>
              </Box>
            </CardContent>
          </Card>
        ) : (
          <Grid container spacing={3}>
            {ads.map((ad) => (
              <Grid item xs={12} md={6} lg={4} key={ad.id}>
                <Card>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                      <Typography variant="h6" component="h2" noWrap>
                        {ad.title}
                      </Typography>
                      <Chip
                        label={
                          isCurrentlyActive(ad) ? 'LIVE' :
                          ad.isActive ? 'SCHEDULED' : 'INACTIVE'
                        }
                        color={
                          isCurrentlyActive(ad) ? 'success' :
                          ad.isActive ? 'warning' : 'default'
                        }
                        size="small"
                      />
                    </Box>

                    <Typography variant="body2" color="textSecondary" gutterBottom noWrap>
                      {ad.description}
                    </Typography>

                    <Box display="flex" gap={1} mb={2} flexWrap="wrap">
                      <Chip label={`Duration: ${ad.displayDurationSeconds}s`} size="small" />
                      <Chip label={`Priority: ${ad.priority}`} size="small" />
                      {ad.examName && (
                        <Chip label={`Links to: ${ad.examName}`} size="small" color="primary" />
                      )}
                    </Box>

                    <Typography variant="caption" color="textSecondary" display="block" mb={2}>
                      Active: {ad.startDate.toLocaleDateString()} - {ad.endDate.toLocaleDateString()}
                    </Typography>

                    <Box display="flex" justifyContent="space-between">
                      <Box>
                        <IconButton size="small" onClick={() => handleOpenDialog(ad)} title="Edit Ad">
                          <EditIcon />
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => handleToggleStatus(ad.id, !ad.isActive)}
                          title={ad.isActive ? 'Deactivate' : 'Activate'}
                        >
                          {ad.isActive ? <PauseIcon /> : <PlayIcon />}
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => handleDelete(ad.id)}
                          title="Delete Ad"
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

        {/* Ad Form Dialog */}
        <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
          <DialogTitle>
            {editingAd ? 'Edit Interstitial Ad' : 'Create Interstitial Ad'}
          </DialogTitle>
          <DialogContent>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Title *"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Description *"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  multiline
                  rows={3}
                />
              </Grid>
              <Grid item xs={12} sm={4}>
                <FormControl fullWidth>
                  <InputLabel>Primary Color</InputLabel>
                  <Select
                    value={formData.primaryColor}
                    onChange={(e) => setFormData({ ...formData, primaryColor: e.target.value })}
                    label="Primary Color"
                  >
                    {colorOptions.map((color) => (
                      <MenuItem key={color} value={color}>
                        <Box display="flex" alignItems="center" gap={1}>
                          <Box width={20} height={20} bgcolor={color} borderRadius="50%" />
                          {color}
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={4}>
                <FormControl fullWidth>
                  <InputLabel>Secondary Color</InputLabel>
                  <Select
                    value={formData.secondaryColor}
                    onChange={(e) => setFormData({ ...formData, secondaryColor: e.target.value })}
                    label="Secondary Color"
                  >
                    {colorOptions.map((color) => (
                      <MenuItem key={color} value={color}>
                        <Box display="flex" alignItems="center" gap={1}>
                          <Box width={20} height={20} bgcolor={color} borderRadius="50%" />
                          {color}
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={4}>
                <FormControl fullWidth>
                  <InputLabel>Icon</InputLabel>
                  <Select
                    value={formData.iconName}
                    onChange={(e) => setFormData({ ...formData, iconName: e.target.value })}
                    label="Icon"
                  >
                    {iconOptions.map((icon) => (
                      <MenuItem key={icon} value={icon}>
                        {icon}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Display Duration (seconds)"
                  type="number"
                  value={formData.displayDurationSeconds}
                  onChange={(e) => setFormData({ ...formData, displayDurationSeconds: parseInt(e.target.value) || 5 })}
                  inputProps={{ min: 3, max: 30 }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Priority"
                  type="number"
                  value={formData.priority}
                  onChange={(e) => setFormData({ ...formData, priority: parseInt(e.target.value) || 0 })}
                />
              </Grid>
              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Link to Exam (optional)</InputLabel>
                  <Select
                    value={formData.examId}
                    onChange={(e) => {
                      const selectedExamId = e.target.value;
                      const selectedExam = exams.find(exam => exam.id === selectedExamId);
                      setFormData({
                        ...formData,
                        examId: selectedExamId,
                        examName: selectedExam?.name || ''
                      });
                    }}
                    label="Link to Exam (optional)"
                    disabled={loadingExams}
                  >
                    <MenuItem value="">
                      <em>No exam selected</em>
                    </MenuItem>
                    {exams.map((exam) => (
                      <MenuItem key={exam.id} value={exam.id}>
                        {exam.name} ({exam.examType})
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <DatePicker
                  label="Start Date"
                  value={formData.startDate}
                  onChange={(date) => setFormData({ ...formData, startDate: date || new Date() })}
                  slotProps={{ textField: { fullWidth: true } }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <DatePicker
                  label="End Date"
                  value={formData.endDate}
                  onChange={(date) => setFormData({ ...formData, endDate: date || new Date() })}
                  slotProps={{ textField: { fullWidth: true } }}
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
                  label="Active (Ad will be displayed when active and within date range)"
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
              sx={{ backgroundColor: '#9C27B0' }}
            >
              {editingAd ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </LocalizationProvider>
  );
};

export default InterstitialAdManagementPage;

