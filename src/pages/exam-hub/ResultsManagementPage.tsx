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
  Link as LinkIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import toast from 'react-hot-toast';
import { useAuth } from '../../contexts/AuthContext';
import { 
  ExamHubResults, 
  ResultsFormData, 
  EXAM_TYPES, 
  RESULT_TYPES,
  FileAttachment, 
  UploadProgress 
} from '../../types/examHub';
import { ExamHubService } from '../../services/examHubService';
import { FileUploadService } from '../../services/fileUploadService';

const ResultsManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  const [results, setResults] = useState<ExamHubResults[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingResults, setEditingResults] = useState<ExamHubResults | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<UploadProgress[]>([]);
  const [attachments, setAttachments] = useState<FileAttachment[]>([]);

  const [formData, setFormData] = useState<ResultsFormData>({
    title: '',
    description: '',
    examType: 'MTS',
    examYear: new Date().getFullYear(),
    resultType: 'final_result',
    publishDate: new Date(),
    examDate: new Date(),
    totalCandidates: undefined,
    selectedCandidates: undefined,
    cutoffMarks: undefined,
    isOfficial: true,
    resultUrl: '',
    tags: [],
    priority: 0,
    isActive: true,
  });

  useEffect(() => {
    loadResults();
  }, []);

  const loadResults = async () => {
    try {
      setLoading(true);
      const resultsData = await ExamHubService.getAllResults({
        sortBy: 'publishDate',
        sortOrder: 'desc',
      });
      setResults(resultsData);
    } catch (error) {
      console.error('Error loading results:', error);
      toast.error('Failed to load results');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = (resultsItem?: ExamHubResults) => {
    if (resultsItem) {
      setEditingResults(resultsItem);
      setFormData({
        title: resultsItem.title,
        description: resultsItem.description,
        examType: resultsItem.examType,
        examYear: resultsItem.examYear,
        resultType: resultsItem.resultType,
        publishDate: resultsItem.publishDate.toDate(),
        examDate: resultsItem.examDate.toDate(),
        totalCandidates: resultsItem.totalCandidates,
        selectedCandidates: resultsItem.selectedCandidates,
        cutoffMarks: resultsItem.cutoffMarks,
        isOfficial: resultsItem.isOfficial,
        resultUrl: resultsItem.resultUrl || '',
        tags: resultsItem.tags,
        priority: resultsItem.priority,
        isActive: resultsItem.isActive,
      });
      setAttachments(resultsItem.attachments || []);
    } else {
      setEditingResults(null);
      setFormData({
        title: '',
        description: '',
        examType: 'MTS',
        examYear: new Date().getFullYear(),
        resultType: 'final_result',
        publishDate: new Date(),
        examDate: new Date(),
        totalCandidates: undefined,
        selectedCandidates: undefined,
        cutoffMarks: undefined,
        isOfficial: true,
        resultUrl: '',
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
    setEditingResults(null);
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
          category: 'results',
          saveToFirestore: true, // Automatically save to Firestore
          createdBy: adminUser?.uid || 'unknown',
          metadata: {
            title: `Results - ${file.name}`,
            description: 'Exam results uploaded via admin panel',
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
            toast.error(`Upload failed: ${error}`);
          },
        })
      );

      const uploadedFiles = await Promise.all(uploadPromises);
      setAttachments(prev => [...prev, ...uploadedFiles]);
      toast.success(`Successfully uploaded ${uploadedFiles.length} file(s) and saved to database`);

      // Refresh the results list to show newly uploaded files
      loadResults();
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
      toast.error('You must be logged in to save results');
      return;
    }

    if (!formData.title.trim() || !formData.description.trim()) {
      toast.error('Please fill in all required fields');
      return;
    }

    setSaving(true);
    try {
      if (editingResults) {
        await ExamHubService.updateResults(editingResults.id, formData, attachments);
        toast.success('Results updated successfully');
      } else {
        await ExamHubService.createResults(formData, attachments, adminUser.uid);
        toast.success('Results created successfully');
      }
      
      handleCloseDialog();
      loadResults();
    } catch (error) {
      console.error('Error saving results:', error);
      toast.error('Failed to save results');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (resultsItem: ExamHubResults) => {
    if (!window.confirm('Are you sure you want to delete this results item?')) {
      return;
    }

    try {
      await ExamHubService.deleteResults(resultsItem.id);
      toast.success('Results deleted successfully');
      loadResults();
    } catch (error) {
      console.error('Error deleting results:', error);
      toast.error('Failed to delete results');
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
            Results Management
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => handleOpenDialog()}
            sx={{ ml: 'auto' }}
          >
            Add Results
          </Button>
        </Box>

        {/* Results Grid */}
        {results.length === 0 ? (
          <Card>
            <CardContent>
              <Box textAlign="center" py={4}>
                <Typography variant="h6" color="textSecondary" gutterBottom>
                  No results found
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Publish your first exam result to get started
                </Typography>
              </Box>
            </CardContent>
          </Card>
        ) : (
          <Grid container spacing={3}>
            {results.map((resultsItem) => (
              <Grid item xs={12} md={6} lg={4} key={resultsItem.id}>
                <Card>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                      <Typography variant="h6" component="h2" noWrap>
                        {resultsItem.title}
                      </Typography>
                      <Box display="flex" gap={1}>
                        {resultsItem.isOfficial && (
                          <Chip icon={<Verified />} label="OFFICIAL" color="primary" size="small" />
                        )}
                        <Chip
                          label={resultsItem.isActive ? 'ACTIVE' : 'INACTIVE'}
                          color={resultsItem.isActive ? 'success' : 'default'}
                          size="small"
                        />
                      </Box>
                    </Box>

                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      {resultsItem.description}
                    </Typography>

                    <Box sx={{ mb: 2 }}>
                      <Chip label={resultsItem.examType} size="small" sx={{ mr: 1 }} />
                      <Chip label={resultsItem.resultType.replace('_', ' ')} color="info" size="small" sx={{ mr: 1 }} />
                      <Typography variant="caption" color="text.secondary" display="block">
                        Year: {resultsItem.examYear} | Published: {formatDate(resultsItem.publishDate)}
                      </Typography>
                    </Box>

                    {(resultsItem.totalCandidates || resultsItem.selectedCandidates) && (
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="caption" color="text.secondary" display="block">
                          {resultsItem.totalCandidates && `Total: ${resultsItem.totalCandidates}`}
                          {resultsItem.selectedCandidates && ` | Selected: ${resultsItem.selectedCandidates}`}
                        </Typography>
                      </Box>
                    )}

                    {resultsItem.resultUrl && (
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="caption" color="text.secondary">
                          <LinkIcon fontSize="small" /> External Result Link
                        </Typography>
                      </Box>
                    )}

                    {resultsItem.attachments && resultsItem.attachments.length > 0 && (
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="caption" color="text.secondary">
                          <AttachFile fontSize="small" /> {resultsItem.attachments.length} attachment(s)
                        </Typography>
                      </Box>
                    )}

                    <Box display="flex" justifyContent="space-between" alignItems="center">
                      <Typography variant="caption" color="text.secondary">
                        Downloads: {resultsItem.downloadCount || 0}
                      </Typography>
                      <Box>
                        <IconButton size="small" onClick={() => handleOpenDialog(resultsItem)}>
                          <Edit />
                        </IconButton>
                        <IconButton size="small" onClick={() => handleDelete(resultsItem)} color="error">
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
            {editingResults ? 'Edit Results' : 'Add Results'}
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
                    placeholder="e.g., MTS 2023 Final Result"
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
                    label="Result Type"
                    value={formData.resultType}
                    onChange={(e) => setFormData({ ...formData, resultType: e.target.value as any })}
                  >
                    {RESULT_TYPES.map((type) => (
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
                    label="Publish Date"
                    value={formData.publishDate}
                    onChange={(date) => setFormData({ ...formData, publishDate: date || new Date() })}
                    slotProps={{ textField: { fullWidth: true } }}
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
                    type="number"
                    label="Priority"
                    value={formData.priority}
                    onChange={(e) => setFormData({ ...formData, priority: parseInt(e.target.value) || 0 })}
                    helperText="Higher numbers appear first"
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    type="number"
                    label="Total Candidates (Optional)"
                    value={formData.totalCandidates || ''}
                    onChange={(e) => setFormData({ ...formData, totalCandidates: e.target.value ? parseInt(e.target.value) : undefined })}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    type="number"
                    label="Selected Candidates (Optional)"
                    value={formData.selectedCandidates || ''}
                    onChange={(e) => setFormData({ ...formData, selectedCandidates: e.target.value ? parseInt(e.target.value) : undefined })}
                  />
                </Grid>

                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="External Result URL (Optional)"
                    value={formData.resultUrl}
                    onChange={(e) => setFormData({ ...formData, resultUrl: e.target.value })}
                    placeholder="https://example.com/result"
                    helperText="Link to external result page"
                  />
                </Grid>

                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.isOfficial}
                        onChange={(e) => setFormData({ ...formData, isOfficial: e.target.checked })}
                      />
                    }
                    label="Official Result"
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
                    Result Documents
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
                        Uploaded Files:
                      </Typography>
                      {attachments.map((attachment) => (
                        <Box key={attachment.id} sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          {FileUploadService.isPDF(attachment as any) ? (
                            <PictureAsPdf fontSize="small" color="error" />
                          ) : (
                            <AttachFile fontSize="small" />
                          )}
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
              {saving ? 'Saving...' : editingResults ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </LocalizationProvider>
  );
};

export default ResultsManagementPage;
