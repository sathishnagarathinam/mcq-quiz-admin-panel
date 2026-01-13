import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  CardActions,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  FormControlLabel,
  Switch,
  Chip,
  IconButton,
  CircularProgress,
  Alert,
  Divider,
} from '@mui/material';
import {
  ArrowBack,
  Add,
  Edit,
  Delete,
  Visibility,
  CloudUpload,
  AttachFile,
  Download,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import toast from 'react-hot-toast';
import { useAuth } from '../../contexts/AuthContext';
import { ExamHubNews, NewsFormData, NEWS_CATEGORIES, FileAttachment, UploadProgress } from '../../types/examHub';
import { ExamHubService } from '../../services/examHubService';
import { FileUploadService } from '../../services/fileUploadService';

const NewsManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  const [news, setNews] = useState<ExamHubNews[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingNews, setEditingNews] = useState<ExamHubNews | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<UploadProgress[]>([]);
  const [attachments, setAttachments] = useState<FileAttachment[]>([]);

  const [formData, setFormData] = useState<NewsFormData>({
    title: '',
    description: '',
    content: '',
    category: 'general',
    publishDate: new Date(),
    expiryDate: undefined,
    isBreaking: false,
    targetAudience: ['ALL'],
    tags: [],
    priority: 0,
    isActive: true,
  });

  useEffect(() => {
    loadNews();
  }, []);

  const loadNews = async () => {
    try {
      setLoading(true);
      const newsData = await ExamHubService.getAllNews({
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      setNews(newsData);
    } catch (error) {
      console.error('Error loading news:', error);
      toast.error('Failed to load news items');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = (newsItem?: ExamHubNews) => {
    if (newsItem) {
      setEditingNews(newsItem);
      setFormData({
        title: newsItem.title,
        description: newsItem.description,
        content: newsItem.content || '',
        category: newsItem.category,
        publishDate: newsItem.publishDate.toDate(),
        expiryDate: newsItem.expiryDate?.toDate(),
        isBreaking: newsItem.isBreaking,
        targetAudience: newsItem.targetAudience,
        tags: newsItem.tags,
        priority: newsItem.priority,
        isActive: newsItem.isActive,
      });
      setAttachments(newsItem.attachments || []);
    } else {
      setEditingNews(null);
      setFormData({
        title: '',
        description: '',
        content: '',
        category: 'general',
        publishDate: new Date(),
        expiryDate: undefined,
        isBreaking: false,
        targetAudience: ['ALL'],
        tags: [],
        priority: 0,
        isActive: true,
      });
      setAttachments([]);
    }
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setEditingNews(null);
    setUploadProgress([]);
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    if (files.length === 0) return;

    setUploading(true);
    setUploadProgress([]);

    try {
      const uploadPromises = files.map(file =>
        FileUploadService.uploadFile(file, {
          category: 'news',
          saveToFirestore: true, // Automatically save to Firestore
          createdBy: adminUser?.uid || 'unknown',
          metadata: {
            title: `News - ${file.name}`,
            description: 'News item uploaded via admin panel',
          },
          onProgress: (progress) => {
            setUploadProgress(prev => {
              const existing = prev.find(p => p.fileName === progress.fileName);
              if (existing) {
                return prev.map(p => p.fileName === progress.fileName ? progress : p);
              }
              return [...prev, progress];
            });
          },
          onError: (error) => {
            toast.error(`Upload failed: ${error}`);
          },
        })
      );

      const uploadedFiles = await Promise.all(uploadPromises);
      setAttachments(prev => [...prev, ...uploadedFiles]);
      toast.success(`Successfully uploaded ${uploadedFiles.length} file(s) and saved to database`);

      // Refresh the news list to show newly uploaded files
      loadNews();
    } catch (error) {
      console.error('Upload error:', error);
      toast.error('Failed to upload files');
    } finally {
      setUploading(false);
    }
  };

  const handleRemoveAttachment = async (attachment: FileAttachment) => {
    try {
      await FileUploadService.deleteFile(attachment);
      setAttachments(prev => prev.filter(a => a.id !== attachment.id));
      toast.success('File removed successfully');
    } catch (error) {
      console.error('Error removing file:', error);
      toast.error('Failed to remove file');
    }
  };

  const handleSave = async () => {
    if (!adminUser) {
      toast.error('You must be logged in to save news');
      return;
    }

    if (!formData.title.trim() || !formData.description.trim()) {
      toast.error('Please fill in all required fields');
      return;
    }

    setSaving(true);
    try {
      if (editingNews) {
        await ExamHubService.updateNews(editingNews.id, formData, attachments);
        toast.success('News updated successfully');
      } else {
        await ExamHubService.createNews(formData, attachments, adminUser.uid);
        toast.success('News created successfully');
      }
      
      handleCloseDialog();
      loadNews();
    } catch (error) {
      console.error('Error saving news:', error);
      toast.error('Failed to save news');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (newsItem: ExamHubNews) => {
    if (!window.confirm('Are you sure you want to delete this news item?')) {
      return;
    }

    try {
      await ExamHubService.deleteNews(newsItem.id);
      toast.success('News deleted successfully');
      loadNews();
    } catch (error) {
      console.error('Error deleting news:', error);
      toast.error('Failed to delete news');
    }
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString();
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
      <Box>
        {/* Header */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
          <Button
            variant="outlined"
            startIcon={<ArrowBack />}
            onClick={() => navigate('/exam-hub')}
          >
            Back to Exam Hub
          </Button>
          <Typography variant="h4" component="h1">
            News Management
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => handleOpenDialog()}
            sx={{ ml: 'auto' }}
          >
            Add News
          </Button>
        </Box>

        {/* News Grid */}
        {news.length === 0 ? (
          <Card>
            <CardContent>
              <Box textAlign="center" py={4}>
                <Typography variant="h6" color="textSecondary" gutterBottom>
                  No news items found
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Create your first news item to get started
                </Typography>
              </Box>
            </CardContent>
          </Card>
        ) : (
          <Grid container spacing={3}>
            {news.map((newsItem) => (
              <Grid item xs={12} md={6} lg={4} key={newsItem.id}>
                <Card>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                      <Typography variant="h6" component="h2" noWrap>
                        {newsItem.title}
                      </Typography>
                      <Box display="flex" gap={1}>
                        {newsItem.isBreaking && (
                          <Chip label="BREAKING" color="error" size="small" />
                        )}
                        <Chip
                          label={newsItem.isActive ? 'ACTIVE' : 'INACTIVE'}
                          color={newsItem.isActive ? 'success' : 'default'}
                          size="small"
                        />
                      </Box>
                    </Box>

                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      {newsItem.description}
                    </Typography>

                    <Box sx={{ mb: 2 }}>
                      <Chip label={newsItem.category} size="small" sx={{ mr: 1 }} />
                      <Typography variant="caption" color="text.secondary">
                        Published: {formatDate(newsItem.publishDate)}
                      </Typography>
                    </Box>

                    {newsItem.attachments && newsItem.attachments.length > 0 && (
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="caption" color="text.secondary">
                          <AttachFile fontSize="small" /> {newsItem.attachments.length} attachment(s)
                        </Typography>
                      </Box>
                    )}

                    <Box display="flex" justifyContent="space-between" alignItems="center">
                      <Typography variant="caption" color="text.secondary">
                        Views: {newsItem.viewCount || 0}
                      </Typography>
                      <Box>
                        <IconButton size="small" onClick={() => handleOpenDialog(newsItem)}>
                          <Edit />
                        </IconButton>
                        <IconButton size="small" onClick={() => handleDelete(newsItem)} color="error">
                          <Delete />
                        </IconButton>
                      </Box>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}

        {/* Create/Edit Dialog */}
        <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
          <DialogTitle>
            {editingNews ? 'Edit News' : 'Create News'}
          </DialogTitle>
          <DialogContent>
            <Box sx={{ pt: 2 }}>
              <Grid container spacing={3}>
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
                    multiline
                    rows={3}
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  />
                </Grid>

                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Content"
                    multiline
                    rows={5}
                    value={formData.content}
                    onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                    helperText="Detailed content of the news article"
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    select
                    label="Category"
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value as any })}
                  >
                    {NEWS_CATEGORIES.map((category) => (
                      <MenuItem key={category} value={category}>
                        {category.replace('_', ' ').toUpperCase()}
                      </MenuItem>
                    ))}
                  </TextField>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <DatePicker
                    label="Publish Date"
                    value={formData.publishDate}
                    onChange={(date) => setFormData({ ...formData, publishDate: date || new Date() })}
                    slotProps={{ textField: { fullWidth: true } }}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <DatePicker
                    label="Expiry Date (Optional)"
                    value={formData.expiryDate || null}
                    onChange={(date) => setFormData({ ...formData, expiryDate: date || undefined })}
                    slotProps={{ textField: { fullWidth: true } }}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    type="number"
                    label="Priority"
                    value={formData.priority}
                    onChange={(e) => setFormData({ ...formData, priority: parseInt(e.target.value) || 0 })}
                    helperText="Higher numbers appear first"
                  />
                </Grid>

                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.isBreaking}
                        onChange={(e) => setFormData({ ...formData, isBreaking: e.target.checked })}
                      />
                    }
                    label="Breaking News"
                  />
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.isActive}
                        onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                      />
                    }
                    label="Active"
                    sx={{ ml: 2 }}
                  />
                </Grid>

                {/* File Upload Section */}
                <Grid item xs={12}>
                  <Divider sx={{ my: 2 }} />
                  <Typography variant="h6" gutterBottom>
                    Attachments
                  </Typography>
                  
                  <input
                    type="file"
                    multiple
                    accept=".pdf,.doc,.docx,.jpg,.jpeg,.png,.webp"
                    style={{ display: 'none' }}
                    id="file-upload"
                    onChange={handleFileUpload}
                  />
                  <label htmlFor="file-upload">
                    <Button
                      variant="outlined"
                      component="span"
                      startIcon={<CloudUpload />}
                      disabled={uploading}
                    >
                      {uploading ? 'Uploading...' : 'Upload Files'}
                    </Button>
                  </label>

                  {/* Upload Progress */}
                  {uploadProgress.length > 0 && (
                    <Box sx={{ mt: 2 }}>
                      {uploadProgress.map((progress, index) => (
                        <Box key={index} sx={{ mb: 1 }}>
                          <Typography variant="caption">
                            {progress.fileName}: {progress.progress.toFixed(0)}%
                          </Typography>
                          <Box sx={{ width: '100%', height: 4, bgcolor: 'grey.300', borderRadius: 2 }}>
                            <Box
                              sx={{
                                width: `${progress.progress}%`,
                                height: '100%',
                                bgcolor: progress.status === 'error' ? 'error.main' : 'primary.main',
                                borderRadius: 2,
                                transition: 'width 0.3s ease',
                              }}
                            />
                          </Box>
                        </Box>
                      ))}
                    </Box>
                  )}

                  {/* Attached Files */}
                  {attachments.length > 0 && (
                    <Box sx={{ mt: 2 }}>
                      <Typography variant="subtitle2" gutterBottom>
                        Attached Files:
                      </Typography>
                      {attachments.map((attachment) => (
                        <Box key={attachment.id} sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <AttachFile fontSize="small" />
                          <Typography variant="body2" sx={{ ml: 1, flex: 1 }}>
                            {attachment.originalName} ({FileUploadService.formatFileSize(attachment.size)})
                          </Typography>
                          <IconButton size="small" onClick={() => handleRemoveAttachment(attachment)}>
                            <Delete />
                          </IconButton>
                        </Box>
                      ))}
                    </Box>
                  )}
                </Grid>
              </Grid>
            </Box>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleCloseDialog}>Cancel</Button>
            <Button
              onClick={handleSave}
              variant="contained"
              disabled={saving || uploading}
            >
              {saving ? 'Saving...' : editingNews ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </LocalizationProvider>
  );
};

export default NewsManagementPage;
