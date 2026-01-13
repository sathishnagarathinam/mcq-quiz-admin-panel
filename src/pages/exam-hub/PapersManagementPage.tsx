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
  PictureAsPdf,
  Verified,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import toast from 'react-hot-toast';
import { useAuth } from '../../contexts/AuthContext';
import { 
  ExamHubPapers, 
  PapersFormData, 
  EXAM_TYPES, 
  PAPER_TYPES,
  LANGUAGES,
  FileAttachment, 
  UploadProgress 
} from '../../types/examHub';
import { ExamHubService } from '../../services/examHubService';
import { FileUploadService } from '../../services/fileUploadService';

const PapersManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  const [papers, setPapers] = useState<ExamHubPapers[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingPapers, setEditingPapers] = useState<ExamHubPapers | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<UploadProgress[]>([]);
  const [attachments, setAttachments] = useState<FileAttachment[]>([]);

  const [formData, setFormData] = useState<PapersFormData>({
    title: '',
    description: '',
    examType: 'MTS',
    examYear: new Date().getFullYear(),
    examDate: new Date(),
    paperType: 'question_paper',
    subject: '',
    duration: 120,
    totalMarks: 100,
    totalQuestions: 100,
    language: ['English'],
    isOfficial: true,
    tags: [],
    priority: 0,
    isActive: true,
  });

  useEffect(() => {
    loadPapers();
  }, []);

  const loadPapers = async () => {
    try {
      setLoading(true);
      const papersData = await ExamHubService.getAllPapers({
        sortBy: 'examDate',
        sortOrder: 'desc',
      });
      setPapers(papersData);
    } catch (error) {
      console.error('Error loading papers:', error);
      toast.error('Failed to load papers');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = (papersItem?: ExamHubPapers) => {
    if (papersItem) {
      setEditingPapers(papersItem);
      setFormData({
        title: papersItem.title,
        description: papersItem.description,
        examType: papersItem.examType,
        examYear: papersItem.examYear,
        examDate: papersItem.examDate.toDate(),
        paperType: papersItem.paperType,
        subject: papersItem.subject || '',
        duration: papersItem.duration,
        totalMarks: papersItem.totalMarks,
        totalQuestions: papersItem.totalQuestions,
        language: papersItem.language,
        isOfficial: papersItem.isOfficial,
        tags: papersItem.tags,
        priority: papersItem.priority,
        isActive: papersItem.isActive,
      });
      setAttachments(papersItem.attachments || []);
    } else {
      setEditingPapers(null);
      setFormData({
        title: '',
        description: '',
        examType: 'MTS',
        examYear: new Date().getFullYear(),
        examDate: new Date(),
        paperType: 'question_paper',
        subject: '',
        duration: 120,
        totalMarks: 100,
        totalQuestions: 100,
        language: ['English'],
        isOfficial: true,
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
    setEditingPapers(null);
    setUploadProgress([]);
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    if (files.length === 0) return;

    // Validate that files are PDFs for papers
    const invalidFiles = files.filter(file => !FileUploadService.isPDF(file));
    if (invalidFiles.length > 0) {
      toast.error('Only PDF files are allowed for exam papers');
      return;
    }

    setUploading(true);
    setUploadProgress([]);

    try {
      // Use optimized upload with compression and queue management
      const result = await FileUploadService.uploadFilesWithQueue(
        files,
        {
          category: 'papers',
          enableCompression: true, // Enable PDF compression
          compression: {
            quality: 0.7,
            maxSizeMB: 15,
          },
          saveToFirestore: true, // Automatically save to Firestore
          createdBy: adminUser?.uid || 'unknown',
          metadata: {
            title: `Uploaded Paper - ${new Date().toLocaleDateString()}`,
            description: 'Paper uploaded via admin panel',
            examType: 'OTHER',
            examYear: new Date().getFullYear(),
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
            console.error('Upload error:', error);
          },
        },
        2, // Max 2 concurrent uploads
        (overallProgress) => {
          // Overall progress can be used for a global progress bar if needed
          console.log(`Overall upload progress: ${overallProgress.toFixed(1)}%`);
        },
        (fileName, success, error) => {
          if (success) {
            console.log(`✓ ${fileName} uploaded successfully`);
          } else {
            console.error(`✗ ${fileName} failed: ${error}`);
            toast.error(`Failed to upload ${fileName}: ${error}`);
          }
        }
      );

      // Add successful uploads to attachments
      setAttachments(prev => [...prev, ...result.successful]);

      // Show results
      if (result.successful.length > 0) {
        toast.success(`Successfully uploaded ${result.successful.length} PDF file(s) and saved to database`);

        // Refresh the papers list to show newly uploaded files
        loadPapers();
      }

      if (result.failed.length > 0) {
        toast.error(`Failed to upload ${result.failed.length} file(s). Check console for details.`);
      }

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
      toast.error('You must be logged in to save papers');
      return;
    }

    if (!formData.title.trim() || !formData.description.trim()) {
      toast.error('Please fill in all required fields');
      return;
    }

    if (attachments.length === 0) {
      toast.error('Please upload at least one PDF file');
      return;
    }

    setSaving(true);
    try {
      if (editingPapers) {
        await ExamHubService.updatePapers(editingPapers.id, formData, attachments);
        toast.success('Papers updated successfully');
      } else {
        await ExamHubService.createPapers(formData, attachments, adminUser.uid);
        toast.success('Papers created successfully');
      }
      
      handleCloseDialog();
      loadPapers();
    } catch (error) {
      console.error('Error saving papers:', error);
      toast.error('Failed to save papers');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (papersItem: ExamHubPapers) => {
    if (!window.confirm('Are you sure you want to delete this papers item?')) {
      return;
    }

    try {
      await ExamHubService.deletePapers(papersItem.id);
      toast.success('Papers deleted successfully');
      loadPapers();
    } catch (error) {
      console.error('Error deleting papers:', error);
      toast.error('Failed to delete papers');
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
            Previous Year Papers Management
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => handleOpenDialog()}
            sx={{ ml: 'auto' }}
          >
            Add Papers
          </Button>
        </Box>

        {/* Papers Grid */}
        {papers.length === 0 ? (
          <Card>
            <CardContent>
              <Box textAlign="center" py={4}>
                <Typography variant="h6" color="textSecondary" gutterBottom>
                  No papers found
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Upload your first exam paper to get started
                </Typography>
              </Box>
            </CardContent>
          </Card>
        ) : (
          <Grid container spacing={3}>
            {papers.map((papersItem) => (
              <Grid item xs={12} md={6} lg={4} key={papersItem.id}>
                <Card>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                      <Typography variant="h6" component="h2" noWrap>
                        {papersItem.title}
                      </Typography>
                      <Box display="flex" gap={1}>
                        {papersItem.isOfficial && (
                          <Chip icon={<Verified />} label="OFFICIAL" color="primary" size="small" />
                        )}
                        <Chip
                          label={papersItem.isActive ? 'ACTIVE' : 'INACTIVE'}
                          color={papersItem.isActive ? 'success' : 'default'}
                          size="small"
                        />
                      </Box>
                    </Box>

                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      {papersItem.description}
                    </Typography>

                    <Box sx={{ mb: 2 }}>
                      <Chip label={papersItem.examType} size="small" sx={{ mr: 1 }} />
                      <Chip label={papersItem.paperType.replace('_', ' ')} color="info" size="small" sx={{ mr: 1 }} />
                      <Typography variant="caption" color="text.secondary" display="block">
                        Year: {papersItem.examYear} | Date: {formatDate(papersItem.examDate)}
                      </Typography>
                    </Box>

                    <Box sx={{ mb: 2 }}>
                      <Typography variant="caption" color="text.secondary" display="block">
                        Duration: {papersItem.duration} min | Marks: {papersItem.totalMarks} | Questions: {papersItem.totalQuestions}
                      </Typography>
                      <Typography variant="caption" color="text.secondary" display="block">
                        Languages: {papersItem.language.join(', ')}
                      </Typography>
                    </Box>

                    {papersItem.attachments && papersItem.attachments.length > 0 && (
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="caption" color="text.secondary">
                          <PictureAsPdf fontSize="small" /> {papersItem.attachments.length} PDF file(s)
                        </Typography>
                      </Box>
                    )}

                    <Box display="flex" justifyContent="space-between" alignItems="center">
                      <Typography variant="caption" color="text.secondary">
                        Downloads: {papersItem.downloadCount || 0}
                      </Typography>
                      <Box>
                        <IconButton size="small" onClick={() => handleOpenDialog(papersItem)}>
                          <Edit />
                        </IconButton>
                        <IconButton size="small" onClick={() => handleDelete(papersItem)} color="error">
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
            {editingPapers ? 'Edit Papers' : 'Add Papers'}
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
                    placeholder="e.g., MTS 2023 Question Paper"
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

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    select
                    label="Exam Type"
                    value={formData.examType}
                    onChange={(e) => setFormData({ ...formData, examType: e.target.value as any })}
                  >
                    {EXAM_TYPES.map((type) => (
                      <MenuItem key={type} value={type}>
                        {type}
                      </MenuItem>
                    ))}
                  </TextField>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    select
                    label="Paper Type"
                    value={formData.paperType}
                    onChange={(e) => setFormData({ ...formData, paperType: e.target.value as any })}
                  >
                    {PAPER_TYPES.map((type) => (
                      <MenuItem key={type} value={type}>
                        {type.replace('_', ' ').toUpperCase()}
                      </MenuItem>
                    ))}
                  </TextField>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    type="number"
                    label="Exam Year"
                    value={formData.examYear}
                    onChange={(e) => setFormData({ ...formData, examYear: parseInt(e.target.value) || new Date().getFullYear() })}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <DatePicker
                    label="Exam Date"
                    value={formData.examDate}
                    onChange={(date) => setFormData({ ...formData, examDate: date || new Date() })}
                    slotProps={{ textField: { fullWidth: true } }}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Subject (Optional)"
                    value={formData.subject}
                    onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
                    placeholder="e.g., General Knowledge, Mathematics"
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    type="number"
                    label="Duration (minutes)"
                    value={formData.duration}
                    onChange={(e) => setFormData({ ...formData, duration: parseInt(e.target.value) || 120 })}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    type="number"
                    label="Total Marks"
                    value={formData.totalMarks}
                    onChange={(e) => setFormData({ ...formData, totalMarks: parseInt(e.target.value) || 100 })}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    type="number"
                    label="Total Questions"
                    value={formData.totalQuestions}
                    onChange={(e) => setFormData({ ...formData, totalQuestions: parseInt(e.target.value) || 100 })}
                  />
                </Grid>

                <Grid item xs={12}>
                  <FormControl fullWidth>
                    <InputLabel>Languages</InputLabel>
                    <Select
                      multiple
                      value={formData.language}
                      onChange={(e) => setFormData({ ...formData, language: e.target.value as string[] })}
                      input={<OutlinedInput label="Languages" />}
                      renderValue={(selected) => (
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                          {selected.map((value) => (
                            <Chip key={value} label={value} size="small" />
                          ))}
                        </Box>
                      )}
                    >
                      {LANGUAGES.map((lang) => (
                        <MenuItem key={lang} value={lang}>
                          {lang}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
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

                <Grid item xs={12} sm={6}>
                  <Box sx={{ pt: 2 }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={formData.isOfficial}
                          onChange={(e) => setFormData({ ...formData, isOfficial: e.target.checked })}
                        />
                      }
                      label="Official Paper"
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
                  </Box>
                </Grid>

                {/* File Upload Section */}
                <Grid item xs={12}>
                  <Divider sx={{ my: 2 }} />
                  <Typography variant="h6" gutterBottom>
                    PDF Files *
                  </Typography>
                  
                  <input
                    type="file"
                    multiple
                    accept=".pdf"
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
                      {uploading ? 'Uploading...' : 'Upload PDF Files'}
                    </Button>
                  </label>

                  {/* Upload Progress */}
                  {uploadProgress.length > 0 && (
                    <Box sx={{ mt: 2 }}>
                      {uploadProgress.map((progress, index) => (
                        <Box key={index} sx={{ mb: 1 }}>
                          <Typography variant="caption">
                            {progress.fileName}: {progress.status === 'compressing' ? 'Compressing' : progress.status === 'uploading' ? 'Uploading' : 'Processing'} - {progress.progress.toFixed(0)}%
                          </Typography>
                          <Box sx={{ width: '100%', height: 4, bgcolor: 'grey.300', borderRadius: 2 }}>
                            <Box
                              sx={{
                                width: `${progress.progress}%`,
                                height: '100%',
                                bgcolor: progress.status === 'error' ? 'error.main' :
                                        progress.status === 'compressing' ? 'warning.main' :
                                        progress.status === 'completed' ? 'success.main' : 'primary.main',
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
                        Uploaded PDF Files:
                      </Typography>
                      {attachments.map((attachment) => (
                        <Box key={attachment.id} sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <PictureAsPdf fontSize="small" color="error" />
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
              {saving ? 'Saving...' : editingPapers ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </LocalizationProvider>
  );
};

export default PapersManagementPage;
