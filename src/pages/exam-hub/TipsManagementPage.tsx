import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
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
  Divider,
  FormControl,
  InputLabel,
  Select,
  OutlinedInput,
} from '@mui/material';
import {
  ArrowBack,
  Add,
  Edit,
  Delete,
  CloudUpload,
  AttachFile,
  PlayCircle,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useAuth } from '../../contexts/AuthContext';
import { 
  ExamHubTips, 
  TipsFormData, 
  TIPS_CATEGORIES, 
  DIFFICULTY_LEVELS,
  EXAM_TYPES,
  FileAttachment, 
  UploadProgress 
} from '../../types/examHub';
import { ExamHubService } from '../../services/examHubService';
import { FileUploadService } from '../../services/fileUploadService';

const TipsManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  const [tips, setTips] = useState<ExamHubTips[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingTips, setEditingTips] = useState<ExamHubTips | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<UploadProgress[]>([]);
  const [attachments, setAttachments] = useState<FileAttachment[]>([]);

  const [formData, setFormData] = useState<TipsFormData>({
    title: '',
    description: '',
    content: '',
    category: 'study_tips',
    difficulty: 'beginner',
    estimatedReadTime: 5,
    relatedExamTypes: [],
    isVideoContent: false,
    videoUrl: '',
    tags: [],
    priority: 0,
    isActive: true,
  });

  useEffect(() => {
    loadTips();
  }, []);

  const loadTips = async () => {
    try {
      setLoading(true);
      const tipsData = await ExamHubService.getAllTips({
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      setTips(tipsData);
    } catch (error) {
      console.error('Error loading tips:', error);
      toast.error('Failed to load tips items');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = (tipsItem?: ExamHubTips) => {
    if (tipsItem) {
      setEditingTips(tipsItem);
      setFormData({
        title: tipsItem.title,
        description: tipsItem.description,
        content: tipsItem.content || '',
        category: tipsItem.category,
        difficulty: tipsItem.difficulty,
        estimatedReadTime: tipsItem.estimatedReadTime,
        relatedExamTypes: tipsItem.relatedExamTypes,
        isVideoContent: tipsItem.isVideoContent,
        videoUrl: tipsItem.videoUrl || '',
        tags: tipsItem.tags,
        priority: tipsItem.priority,
        isActive: tipsItem.isActive,
      });
      setAttachments(tipsItem.attachments || []);
    } else {
      setEditingTips(null);
      setFormData({
        title: '',
        description: '',
        content: '',
        category: 'study_tips',
        difficulty: 'beginner',
        estimatedReadTime: 5,
        relatedExamTypes: [],
        isVideoContent: false,
        videoUrl: '',
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
    setEditingTips(null);
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
          category: 'tips',
          saveToFirestore: true, // Automatically save to Firestore
          createdBy: adminUser?.uid || 'unknown',
          metadata: {
            title: `Tips - ${file.name}`,
            description: 'Tips and shortcuts uploaded via admin panel',
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

      // Refresh the tips list to show newly uploaded files
      loadTips();
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
      toast.error('You must be logged in to save tips');
      return;
    }

    if (!formData.title.trim() || !formData.description.trim()) {
      toast.error('Please fill in all required fields');
      return;
    }

    setSaving(true);
    try {
      if (editingTips) {
        await ExamHubService.updateTips(editingTips.id, formData, attachments);
        toast.success('Tips updated successfully');
      } else {
        await ExamHubService.createTips(formData, attachments, adminUser.uid);
        toast.success('Tips created successfully');
      }
      
      handleCloseDialog();
      loadTips();
    } catch (error) {
      console.error('Error saving tips:', error);
      toast.error('Failed to save tips');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (tipsItem: ExamHubTips) => {
    if (!window.confirm('Are you sure you want to delete this tips item?')) {
      return;
    }

    try {
      await ExamHubService.deleteTips(tipsItem.id);
      toast.success('Tips deleted successfully');
      loadTips();
    } catch (error) {
      console.error('Error deleting tips:', error);
      toast.error('Failed to delete tips');
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
          Tips & Shortcuts Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
          sx={{ ml: 'auto' }}
        >
          Add Tips
        </Button>
      </Box>

      {/* Tips Grid */}
      {tips.length === 0 ? (
        <Card>
          <CardContent>
            <Box textAlign="center" py={4}>
              <Typography variant="h6" color="textSecondary" gutterBottom>
                No tips found
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Create your first tips item to get started
              </Typography>
            </Box>
          </CardContent>
        </Card>
      ) : (
        <Grid container spacing={3}>
          {tips.map((tipsItem) => (
            <Grid item xs={12} md={6} lg={4} key={tipsItem.id}>
              <Card>
                <CardContent>
                  <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                    <Typography variant="h6" component="h2" noWrap>
                      {tipsItem.title}
                    </Typography>
                    <Box display="flex" gap={1}>
                      {tipsItem.isVideoContent && (
                        <Chip icon={<PlayCircle />} label="VIDEO" color="primary" size="small" />
                      )}
                      <Chip
                        label={tipsItem.isActive ? 'ACTIVE' : 'INACTIVE'}
                        color={tipsItem.isActive ? 'success' : 'default'}
                        size="small"
                      />
                    </Box>
                  </Box>

                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    {tipsItem.description}
                  </Typography>

                  <Box sx={{ mb: 2 }}>
                    <Chip label={tipsItem.category.replace('_', ' ')} size="small" sx={{ mr: 1 }} />
                    <Chip label={tipsItem.difficulty} color="info" size="small" sx={{ mr: 1 }} />
                    <Typography variant="caption" color="text.secondary" display="block">
                      Read time: {tipsItem.estimatedReadTime} min
                    </Typography>
                  </Box>

                  {tipsItem.relatedExamTypes && tipsItem.relatedExamTypes.length > 0 && (
                    <Box sx={{ mb: 2 }}>
                      <Typography variant="caption" color="text.secondary" display="block">
                        Exam Types: {tipsItem.relatedExamTypes.join(', ')}
                      </Typography>
                    </Box>
                  )}

                  {tipsItem.attachments && tipsItem.attachments.length > 0 && (
                    <Box sx={{ mb: 2 }}>
                      <Typography variant="caption" color="text.secondary">
                        <AttachFile fontSize="small" /> {tipsItem.attachments.length} attachment(s)
                      </Typography>
                    </Box>
                  )}

                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="caption" color="text.secondary">
                      Views: {tipsItem.viewCount || 0}
                    </Typography>
                    <Box>
                      <IconButton size="small" onClick={() => handleOpenDialog(tipsItem)}>
                        <Edit />
                      </IconButton>
                      <IconButton size="small" onClick={() => handleDelete(tipsItem)} color="error">
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
          {editingTips ? 'Edit Tips' : 'Create Tips'}
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
                  helperText="Detailed tips content"
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
                  {TIPS_CATEGORIES.map((category) => (
                    <MenuItem key={category} value={category}>
                      {category.replace('_', ' ').toUpperCase()}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  select
                  label="Difficulty"
                  value={formData.difficulty}
                  onChange={(e) => setFormData({ ...formData, difficulty: e.target.value as any })}
                >
                  {DIFFICULTY_LEVELS.map((level) => (
                    <MenuItem key={level} value={level}>
                      {level.toUpperCase()}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  type="number"
                  label="Estimated Read Time (minutes)"
                  value={formData.estimatedReadTime}
                  onChange={(e) => setFormData({ ...formData, estimatedReadTime: parseInt(e.target.value) || 5 })}
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
                <FormControl fullWidth>
                  <InputLabel>Related Exam Types</InputLabel>
                  <Select
                    multiple
                    value={formData.relatedExamTypes}
                    onChange={(e) => setFormData({ ...formData, relatedExamTypes: e.target.value as string[] })}
                    input={<OutlinedInput label="Related Exam Types" />}
                    renderValue={(selected) => (
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {selected.map((value) => (
                          <Chip key={value} label={value} size="small" />
                        ))}
                      </Box>
                    )}
                  >
                    {EXAM_TYPES.map((type) => (
                      <MenuItem key={type} value={type}>
                        {type}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.isVideoContent}
                      onChange={(e) => setFormData({ ...formData, isVideoContent: e.target.checked })}
                    />
                  }
                  label="Video Content"
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

              {formData.isVideoContent && (
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Video URL"
                    value={formData.videoUrl}
                    onChange={(e) => setFormData({ ...formData, videoUrl: e.target.value })}
                    helperText="YouTube, Vimeo, or other video platform URL"
                  />
                </Grid>
              )}

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
            {saving ? 'Saving...' : editingTips ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default TipsManagementPage;
