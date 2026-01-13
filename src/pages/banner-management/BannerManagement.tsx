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
  Campaign as CampaignIcon,
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

interface Banner {
  id: string;
  title: string;
  subtitle: string;
  couponCode: string;
  discount: string;
  primaryColor: string;
  secondaryColor: string;
  iconName: string;
  isActive: boolean;
  startDate: Date;
  endDate: Date;
  targetUrl: string;
  examId?: string;
  examName?: string;
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
  'lightbulb',
  'star',
  'gift',
  'discount',
  'sale',
  'percent',
];

const colorOptions = [
  '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3',
  '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
  '#FFEB3B', '#FFC107', '#FF9800', '#FF5722', '#795548',
];

const BannerManagement: React.FC = () => {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingBanner, setEditingBanner] = useState<Banner | null>(null);
  const [exams, setExams] = useState<Exam[]>([]);
  const [loadingExams, setLoadingExams] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    subtitle: '',
    couponCode: '',
    discount: '',
    primaryColor: '#E91E63',
    secondaryColor: '#9C27B0',
    iconName: 'lightbulb',
    isActive: true,
    startDate: new Date(),
    endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
    targetUrl: '',
    examId: '',
    examName: '',
    priority: 0,
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadExams = async () => {
    console.log('🔄 Loading exams...');

    // Check authentication first
    const auth = getAuth();
    const currentUser = auth.currentUser;
    console.log('🔐 Current user:', currentUser ? {
      uid: currentUser.uid,
      email: currentUser.email,
      emailVerified: currentUser.emailVerified
    } : 'Not authenticated');

    if (!currentUser) {
      console.error('❌ User not authenticated - cannot load exams');
      setLoadingExams(false);
      return;
    }

    setLoadingExams(true);
    try {
      // First, try to get all exams without filtering to see what's available
      console.log('📡 Querying exams collection...');
      const allExamsQuery = query(collection(db, 'exams'));
      const allSnapshot = await getDocs(allExamsQuery);
      console.log(`📊 Found ${allSnapshot.docs.length} total exams in database`);

      // Log first few exams for debugging
      allSnapshot.docs.slice(0, 3).forEach((doc, index) => {
        console.log(`📝 Exam ${index + 1}:`, {
          id: doc.id,
          data: doc.data()
        });
      });

      // Now try to get active exams - try different approaches
      let snapshot;
      let examsData = [];

      try {
        // First try with isActive filter
        const q = query(
          collection(db, 'exams'),
          where('isActive', '==', true)
        );
        snapshot = await getDocs(q);
        console.log(`✅ Found ${snapshot.docs.length} active exams with isActive=true`);
      } catch (error) {
        console.log('⚠️ Failed to query with isActive filter, trying without filter:', error);
        // If that fails, try without the isActive filter
        snapshot = await getDocs(collection(db, 'exams'));
        console.log(`✅ Found ${snapshot.docs.length} total exams (no filter)`);
      }

      examsData = snapshot.docs.map(doc => {
        const data = doc.data();
        console.log(`🔍 Processing exam: ${doc.id}`, data);

        // Try different possible field names for exam name
        const examName = data.name || data.examName || data.title || `Exam ${doc.id.substring(0, 8)}`;
        const examType = data.examType || data.type || data.category || 'General';
        const isActive = data.isActive !== undefined ? data.isActive : true; // Default to true if not specified

        return {
          id: doc.id,
          name: examName,
          examType: examType,
          isActive: isActive,
        };
      });

      console.log('📋 Final exams data:', examsData);
      setExams(examsData);

      // Also check quiz_attempts to see what exam names are being used
      try {
        console.log('🔍 Checking quiz_attempts for exam names...');
        const attemptsQuery = query(collection(db, 'quiz_attempts'));
        const attemptsSnapshot = await getDocs(attemptsQuery);
        console.log(`📊 Found ${attemptsSnapshot.docs.length} quiz attempts`);

        const examNames = new Set();
        attemptsSnapshot.docs.slice(0, 5).forEach((doc, index) => {
          const data = doc.data();
          console.log(`📝 Attempt ${index + 1}:`, {
            id: doc.id,
            examName: data.examName || data.quizName || data.category,
            data: data
          });
          if (data.examName) examNames.add(data.examName);
          if (data.quizName) examNames.add(data.quizName);
          if (data.category) examNames.add(data.category);
        });

        console.log('📚 Unique exam names from attempts:', Array.from(examNames));
      } catch (error) {
        console.log('⚠️ Could not check quiz_attempts:', error);
      }

    } catch (error) {
      console.error('❌ Error loading exams:', error);
    } finally {
      setLoadingExams(false);
    }
  };

  useEffect(() => {
    loadExams();
  }, []);

  useEffect(() => {
    console.log('🔥 Setting up Firebase listener for banners...');
    console.log('🔥 Database instance:', db);

    const q = query(
      collection(db, 'banners'),
      orderBy('priority', 'desc'),
      orderBy('createdAt', 'desc')
    );

    console.log('🔥 Query created:', q);

    const unsubscribe = onSnapshot(q, (snapshot) => {
      console.log('🔥 Received snapshot update:', snapshot);
      console.log('🔥 Number of documents:', snapshot.docs.length);

      const bannersData = snapshot.docs.map(doc => {
        console.log('🔥 Processing document:', doc.id, doc.data());
        return {
          id: doc.id,
          ...doc.data(),
          startDate: doc.data().startDate?.toDate() || new Date(),
          endDate: doc.data().endDate?.toDate() || new Date(),
          createdAt: doc.data().createdAt?.toDate() || new Date(),
          updatedAt: doc.data().updatedAt?.toDate() || new Date(),
        };
      }) as Banner[];

      console.log('✅ Processed banners:', bannersData);
      setBanners(bannersData);
      setLoading(false);
    }, (error) => {
      console.error('❌ Error fetching banners:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('❌ Error details:', {
        message: errorMessage,
        error: error
      });
      setError(`Failed to load banners: ${errorMessage}`);
      setLoading(false);
    });

    return () => {
      console.log('🔥 Cleaning up Firebase listener');
      unsubscribe();
    };
  }, []);

  const handleOpenDialog = (banner?: Banner) => {
    if (banner) {
      setEditingBanner(banner);
      setFormData({
        title: banner.title,
        subtitle: banner.subtitle,
        couponCode: banner.couponCode,
        discount: banner.discount,
        primaryColor: banner.primaryColor,
        secondaryColor: banner.secondaryColor,
        iconName: banner.iconName,
        isActive: banner.isActive,
        startDate: banner.startDate,
        endDate: banner.endDate,
        targetUrl: banner.targetUrl,
        examId: banner.examId || '',
        examName: banner.examName || '',
        priority: banner.priority,
      });
    } else {
      setEditingBanner(null);
      setFormData({
        title: '',
        subtitle: '',
        couponCode: '',
        discount: '',
        primaryColor: '#E91E63',
        secondaryColor: '#9C27B0',
        iconName: 'lightbulb',
        isActive: true,
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        targetUrl: '',
        examId: '',
        examName: '',
        priority: 0,
      });
    }
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setEditingBanner(null);
    setError(null);
  };

  const handleSave = async () => {
    if (!formData.title.trim() || !formData.subtitle.trim()) {
      setError('Title and subtitle are required');
      return;
    }

    // Validate discount format if provided
    if (formData.discount.trim()) {
      const discountStr = formData.discount.trim().replace('%', '').trim();
      const discountNum = parseFloat(discountStr);

      if (isNaN(discountNum) || discountNum < 0 || discountNum > 100) {
        setError('Discount must be a number between 0 and 100 (e.g., "30" or "30%")');
        return;
      }

      // Format discount to ensure it has % sign
      formData.discount = `${discountNum}%`;
    }

    setSaving(true);
    setError(null);

    try {
      console.log('🔥 Attempting to save banner...', formData);
      console.log('🔥 Firebase db instance:', db);

      const bannerData = {
        ...formData,
        updatedAt: serverTimestamp(),
      };

      console.log('🔥 Banner data to save:', bannerData);

      if (editingBanner) {
        console.log('🔥 Updating existing banner:', editingBanner.id);
        await updateDoc(doc(db, 'banners', editingBanner.id), bannerData);
        console.log('✅ Banner updated successfully');
      } else {
        console.log('🔥 Creating new banner...');
        const docRef = await addDoc(collection(db, 'banners'), {
          ...bannerData,
          createdAt: serverTimestamp(),
          createdBy: 'admin', // TODO: Get actual admin user
        });
        console.log('✅ Banner created successfully with ID:', docRef.id);
      }

      handleCloseDialog();
    } catch (error) {
      console.error('❌ Error saving banner:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('❌ Error details:', {
        message: errorMessage,
        error: error
      });
      setError(`Failed to save banner: ${errorMessage}`);
    } finally {
      setSaving(false);
    }
  };

  const handleToggleStatus = async (bannerId: string, isActive: boolean) => {
    try {
      await updateDoc(doc(db, 'banners', bannerId), {
        isActive,
        updatedAt: serverTimestamp(),
      });
    } catch (error) {
      console.error('Error updating banner status:', error);
      setError('Failed to update banner status');
    }
  };

  const handleDelete = async (bannerId: string) => {
    if (window.confirm('Are you sure you want to delete this banner?')) {
      try {
        await deleteDoc(doc(db, 'banners', bannerId));
      } catch (error) {
        console.error('Error deleting banner:', error);
        setError('Failed to delete banner');
      }
    }
  };

  const isCurrentlyActive = (banner: Banner) => {
    const now = new Date();
    return banner.isActive && 
           now >= banner.startDate && 
           now <= banner.endDate;
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
            Banner Management
          </Typography>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => handleOpenDialog()}
          >
            Add Banner
          </Button>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {banners.length === 0 ? (
          <Card>
            <CardContent>
              <Box textAlign="center" py={4}>
                <CampaignIcon sx={{ fontSize: 64, color: 'grey.400', mb: 2 }} />
                <Typography variant="h6" color="textSecondary" gutterBottom>
                  No banners created yet
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Create your first promotional banner to display in the mobile app
                </Typography>
              </Box>
            </CardContent>
          </Card>
        ) : (
          <Grid container spacing={3}>
            {banners.map((banner) => (
              <Grid item xs={12} md={6} lg={4} key={banner.id}>
                <Card>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                      <Typography variant="h6" component="h2" noWrap>
                        {banner.title}
                      </Typography>
                      <Chip
                        label={
                          isCurrentlyActive(banner) ? 'LIVE' :
                          banner.isActive ? 'SCHEDULED' : 'INACTIVE'
                        }
                        color={
                          isCurrentlyActive(banner) ? 'success' :
                          banner.isActive ? 'warning' : 'default'
                        }
                        size="small"
                      />
                    </Box>
                    
                    <Typography variant="body2" color="textSecondary" gutterBottom>
                      {banner.subtitle}
                    </Typography>

                    <Box display="flex" gap={1} mb={2}>
                      {banner.couponCode && (
                        <Chip label={`Code: ${banner.couponCode}`} size="small" />
                      )}
                      {banner.discount && (
                        <Chip label={`${banner.discount} OFF`} size="small" color="primary" />
                      )}
                    </Box>

                    <Typography variant="caption" color="textSecondary" display="block" mb={2}>
                      Priority: {banner.priority} | 
                      Active: {banner.startDate.toLocaleDateString()} - {banner.endDate.toLocaleDateString()}
                    </Typography>

                    <Box display="flex" justifyContent="space-between">
                      <Box>
                        <IconButton
                          size="small"
                          onClick={() => handleOpenDialog(banner)}
                          title="Edit Banner"
                        >
                          <EditIcon />
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => handleToggleStatus(banner.id, !banner.isActive)}
                          title={banner.isActive ? 'Deactivate' : 'Activate'}
                        >
                          {banner.isActive ? <PauseIcon /> : <PlayIcon />}
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => handleDelete(banner.id)}
                          title="Delete Banner"
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

        {/* Banner Form Dialog */}
        <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
          <DialogTitle>
            {editingBanner ? 'Edit Banner' : 'Create Banner'}
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
                  label="Subtitle *"
                  value={formData.subtitle}
                  onChange={(e) => setFormData({ ...formData, subtitle: e.target.value })}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Coupon Code"
                  value={formData.couponCode}
                  onChange={(e) => setFormData({ ...formData, couponCode: e.target.value })}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Discount (e.g., 30 or 30%)"
                  value={formData.discount}
                  onChange={(e) => {
                    let value = e.target.value.trim();
                    // Remove % if user types it
                    value = value.replace('%', '').trim();
                    // Only allow numbers and decimal point
                    if (value === '' || /^\d*\.?\d*$/.test(value)) {
                      setFormData({ ...formData, discount: value });
                    }
                  }}
                  placeholder="0-100"
                  helperText="Enter discount percentage (0-100)"
                />
              </Grid>
              <Grid item xs={12} sm={8}>
                <TextField
                  fullWidth
                  label="Target URL (optional)"
                  value={formData.targetUrl}
                  onChange={(e) => setFormData({ ...formData, targetUrl: e.target.value })}
                />
              </Grid>
              <Grid item xs={12} sm={4}>
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
                {loadingExams && (
                  <Box display="flex" justifyContent="center" mt={1}>
                    <CircularProgress size={20} />
                  </Box>
                )}
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
                          <Box
                            width={20}
                            height={20}
                            bgcolor={color}
                            borderRadius="50%"
                          />
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
                          <Box
                            width={20}
                            height={20}
                            bgcolor={color}
                            borderRadius="50%"
                          />
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
                  label="Active (Banner will be displayed when active and within date range)"
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
              {editingBanner ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </LocalizationProvider>
  );
};

export default BannerManagement;
