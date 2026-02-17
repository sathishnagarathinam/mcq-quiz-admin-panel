import React, { useState } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  Typography,
  Alert,
  LinearProgress,
  Grid,
  Chip,
  Paper,
  List,
  ListItem,
  ListItemText,
  Divider,
} from '@mui/material';
import {
  CloudUpload as CloudUploadIcon,
  BugReport as BugReportIcon,
  CheckCircle as CheckIcon,
  Error as ErrorIcon,
  Info as InfoIcon,
} from '@mui/icons-material';
import { FileUploadService } from '../../services/fileUploadService';
import { PDFCompressionService } from '../../utils/pdfCompression';
import { UploadProgress } from '../../types/examHub';

interface DebugLog {
  timestamp: string;
  level: 'info' | 'warn' | 'error' | 'success';
  message: string;
}

const UploadDebugPage: React.FC = () => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<UploadProgress | null>(null);
  const [debugLogs, setDebugLogs] = useState<DebugLog[]>([]);
  const [uploadResult, setUploadResult] = useState<any>(null);

  const addLog = (level: 'info' | 'warn' | 'error' | 'success', message: string) => {
    const log: DebugLog = {
      timestamp: new Date().toLocaleTimeString(),
      level,
      message,
    };
    setDebugLogs(prev => [...prev, log]);
    console.log(`[${level.toUpperCase()}] ${message}`);
  };

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      setDebugLogs([]);
      setUploadProgress(null);
      setUploadResult(null);
      
      addLog('info', `File selected: ${file.name} (${PDFCompressionService.formatFileSize(file.size)})`);
      addLog('info', `File type: ${file.type}`);
      
      // Check if file should be compressed
      if (PDFCompressionService.shouldCompress(file)) {
        const recommendation = PDFCompressionService.getCompressionRecommendation(file.size / (1024 * 1024));
        addLog('info', `File will be compressed with quality: ${recommendation.quality}, target: ${recommendation.maxSizeMB}MB`);
      } else {
        addLog('info', 'File will not be compressed (not a PDF or too small)');
      }
    }
  };

  const testCompression = async () => {
    if (!selectedFile) return;

    addLog('info', 'Starting compression test...');
    
    try {
      const result = await PDFCompressionService.compressPDF(selectedFile, {
        onProgress: (progress) => {
          addLog('info', `Compression progress: ${progress.toFixed(1)}%`);
        },
      });

      if (result.success) {
        addLog('success', `Compression successful: ${PDFCompressionService.formatFileSize(result.originalSize)} → ${PDFCompressionService.formatFileSize(result.compressedSize)} (${result.compressionRatio.toFixed(1)}% reduction)`);
      } else {
        addLog('warn', `Compression failed: ${result.error || 'Unknown error'}`);
      }
    } catch (error) {
      addLog('error', `Compression error: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  const testUpload = async () => {
    if (!selectedFile) return;

    setUploading(true);
    setUploadProgress(null);
    setUploadResult(null);
    addLog('info', 'Starting upload test...');

    try {
      const result = await FileUploadService.uploadFile(selectedFile, {
        category: 'papers',
        enableCompression: true,
        saveToFirestore: true, // Test automatic Firestore saving
        createdBy: 'debug-test-user',
        metadata: {
          title: `Debug Test - ${selectedFile.name}`,
          description: 'File uploaded via debug tool',
          examType: 'OTHER',
          examYear: new Date().getFullYear(),
        },
        onProgress: (progress) => {
          setUploadProgress(progress);
          addLog('info', `Upload progress: ${progress.progress.toFixed(1)}% (${progress.status})`);
        },
        onError: (error) => {
          addLog('error', `Upload error: ${error}`);
        },
        onSuccess: (attachment) => {
          addLog('success', `Upload successful: ${attachment.name}`);
        },
      });

      setUploadResult(result);
      addLog('success', 'Upload completed successfully');
    } catch (error) {
      addLog('error', `Upload failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      setUploading(false);
    }
  };

  const clearLogs = () => {
    setDebugLogs([]);
    setUploadProgress(null);
    setUploadResult(null);
  };

  const getLogColor = (level: string) => {
    switch (level) {
      case 'success': return 'success';
      case 'error': return 'error';
      case 'warn': return 'warning';
      default: return 'info';
    }
  };

  const getLogIcon = (level: string) => {
    switch (level) {
      case 'success': return <CheckIcon fontSize="small" />;
      case 'error': return <ErrorIcon fontSize="small" />;
      case 'warn': return <ErrorIcon fontSize="small" />;
      default: return <InfoIcon fontSize="small" />;
    }
  };

  return (
    <Box p={3}>
      <Box display="flex" alignItems="center" mb={3}>
        <BugReportIcon sx={{ mr: 1, color: 'primary.main' }} />
        <Typography variant="h4">
          Upload Debug Tool
        </Typography>
      </Box>

      <Grid container spacing={3}>
        {/* File Selection */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                File Selection
              </Typography>
              
              <Box mb={2}>
                <input
                  type="file"
                  accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
                  onChange={handleFileSelect}
                  style={{ marginBottom: 16 }}
                />
              </Box>

              {selectedFile && (
                <Paper sx={{ p: 2, mb: 2 }}>
                  <Typography variant="subtitle2">Selected File:</Typography>
                  <Typography variant="body2">Name: {selectedFile.name}</Typography>
                  <Typography variant="body2">Size: {PDFCompressionService.formatFileSize(selectedFile.size)}</Typography>
                  <Typography variant="body2">Type: {selectedFile.type}</Typography>
                </Paper>
              )}

              <Box display="flex" gap={1} flexWrap="wrap">
                <Button
                  variant="outlined"
                  onClick={testCompression}
                  disabled={!selectedFile || selectedFile.type !== 'application/pdf'}
                  startIcon={<CloudUploadIcon />}
                >
                  Test Compression
                </Button>
                
                <Button
                  variant="contained"
                  onClick={testUpload}
                  disabled={!selectedFile || uploading}
                  startIcon={<CloudUploadIcon />}
                >
                  Test Upload
                </Button>
                
                <Button
                  variant="outlined"
                  onClick={clearLogs}
                  color="secondary"
                >
                  Clear Logs
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Progress */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Upload Progress
              </Typography>
              
              {uploadProgress && (
                <Box mb={2}>
                  <Box display="flex" justifyContent="space-between" mb={1}>
                    <Typography variant="body2">
                      {uploadProgress.fileName}
                    </Typography>
                    <Typography variant="body2">
                      {uploadProgress.progress.toFixed(1)}%
                    </Typography>
                  </Box>
                  
                  <LinearProgress
                    variant="determinate"
                    value={uploadProgress.progress}
                    sx={{ mb: 1 }}
                  />
                  
                  <Chip
                    label={uploadProgress.status}
                    color={uploadProgress.status === 'completed' ? 'success' : 'primary'}
                    size="small"
                  />
                </Box>
              )}

              {uploadResult && (
                <Paper sx={{ p: 2 }}>
                  <Typography variant="subtitle2" gutterBottom>Upload Result:</Typography>
                  <Typography variant="body2">ID: {uploadResult.id}</Typography>
                  <Typography variant="body2">Name: {uploadResult.name}</Typography>
                  <Typography variant="body2">Size: {PDFCompressionService.formatFileSize(uploadResult.size)}</Typography>
                  <Typography variant="body2" sx={{ wordBreak: 'break-all' }}>
                    URL: {uploadResult.url}
                  </Typography>
                </Paper>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Debug Logs */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Debug Logs
              </Typography>
              
              {debugLogs.length === 0 ? (
                <Alert severity="info">
                  No logs yet. Select a file and test compression or upload to see debug information.
                </Alert>
              ) : (
                <Paper sx={{ maxHeight: 400, overflow: 'auto' }}>
                  <List dense>
                    {debugLogs.map((log, index) => (
                      <React.Fragment key={index}>
                        <ListItem>
                          <Box display="flex" alignItems="center" width="100%">
                            <Box mr={1} color={`${getLogColor(log.level)}.main`}>
                              {getLogIcon(log.level)}
                            </Box>
                            <Box flexGrow={1}>
                              <ListItemText
                                primary={log.message}
                                secondary={log.timestamp}
                                primaryTypographyProps={{
                                  color: getLogColor(log.level),
                                  variant: 'body2',
                                }}
                                secondaryTypographyProps={{
                                  variant: 'caption',
                                }}
                              />
                            </Box>
                          </Box>
                        </ListItem>
                        {index < debugLogs.length - 1 && <Divider />}
                      </React.Fragment>
                    ))}
                  </List>
                </Paper>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default UploadDebugPage;
