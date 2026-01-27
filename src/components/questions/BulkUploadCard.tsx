import React, { useState } from 'react';
import {
  Card,
  CardContent,
  CardActions,
  Typography,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Box,
  Grid,
  Alert,
  Chip,
  OutlinedInput,
  SelectChangeEvent,
  IconButton,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControlLabel,
  Switch,
  Checkbox,
  Tooltip,
} from '@mui/material';
import {
  CloudUpload as CloudUploadIcon,
  Preview as PreviewIcon,
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material';

interface Question {
  id: string;
  question: string;
  options: string[];
  correctAnswer: number;
  explanation?: string;
  difficulty: 'Easy' | 'Medium' | 'Hard';
  isFree?: boolean; // Mark if this question is part of free questions in freemium model
}

interface LiveTestData {
  title: string;
  description: string;
  startTime: Date;
  endTime: Date;
  durationMinutes: number;
  maxParticipants: number;
  instructorName: string;
  difficulty: 'easy' | 'medium' | 'hard';
  passingScore: number;
  showResults: boolean;
}

interface BulkUploadData {
  examName: string;
  examType: string;
  timeLimit: number;
  suitableFor: string[];
  questions: Question[];
  createLiveTest?: boolean;
  liveTestData?: LiveTestData;
  price: number;
  currency: string;
  isFree: boolean;
  freeQuestionsLimit?: number;
  unlockPrice?: number;
}

interface ExamType {
  id: string;
  name: string;
  icon: string;
  isDefault: boolean;
  createdAt: Date;
}

interface BulkUploadCardProps {
  onUploadComplete: (data: BulkUploadData) => void;
  examTypes: ExamType[];
}

// Helper functions for datetime-local input handling
const formatDateTimeLocal = (date: Date): string => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  return `${year}-${month}-${day}T${hours}:${minutes}`;
};

const parseDateTimeLocal = (value: string): Date => {
  // datetime-local input returns a string in format "YYYY-MM-DDTHH:mm"
  // This is interpreted as local time, so we need to create a Date object
  // that represents that local time
  const [datePart, timePart] = value.split('T');
  const [year, month, day] = datePart.split('-').map(Number);
  const [hours, minutes] = timePart.split(':').map(Number);
  return new Date(year, month - 1, day, hours, minutes);
};

const BulkUploadCard: React.FC<BulkUploadCardProps> = ({ onUploadComplete, examTypes }) => {
  const [file, setFile] = useState<File | null>(null);
  const [examConfig, setExamConfig] = useState({
    examName: '',
    examType: '',
    timeLimit: 30,
    suitableFor: [] as string[],
    price: 0,
    currency: 'INR',
    isFree: true,
    freeQuestionsLimit: -1,
    unlockPrice: 0,
  });
  const [parsedQuestions, setParsedQuestions] = useState<Question[]>([]);
  const [showPreview, setShowPreview] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [editingQuestion, setEditingQuestion] = useState<Question | null>(null);
  const [openEditDialog, setOpenEditDialog] = useState(false);
  const [freeQuestionsSelection, setFreeQuestionsSelection] = useState<Set<string>>(new Set()); // Track which questions are marked as free

  // Live test state
  const [createLiveTest, setCreateLiveTest] = useState(false);
  const [liveTestForm, setLiveTestForm] = useState<LiveTestData>({
    title: '',
    description: '',
    startTime: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
    endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000), // Tomorrow + 2 hours
    durationMinutes: 60,
    maxParticipants: 1000,
    instructorName: '',
    difficulty: 'medium',
    passingScore: 60,
    showResults: true,
  });

  const suitableForOptions = [
    'GDS', 'MTS', 'Postman', 'Postal Assistant', 'Inspector', 'ASP', 'SP', 'Others'
  ];

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const getExamTypeIcon = (examType: string) => {
    const type = examTypes.find(et => et.name === examType);
    return type?.icon || '📝';
  };

  const handleFileSelect = async (selectedFile: File) => {
    setFile(selectedFile);
    setError(null);
    
    if (selectedFile) {
      try {
        const text = await selectedFile.text();
        const questions = await parseCSV(text);
        setParsedQuestions(questions);
        setShowPreview(true);
      } catch (err) {
        setError('Failed to parse CSV file. Please check the format.');
        console.error('CSV parsing error:', err);
      }
    }
  };

  const parseCSV = async (text: string): Promise<Question[]> => {
    const lines = text.split('\n').filter(line => line.trim());
    
    if (lines.length < 2) {
      throw new Error('File must contain at least a header row and one question');
    }

    const headers = lines[0].split(',').map(h => h.trim().toLowerCase());
    const questionIndex = headers.indexOf('question');
    const option1Index = headers.findIndex(h => h.includes('option1') || h.includes('option_1'));
    const option2Index = headers.findIndex(h => h.includes('option2') || h.includes('option_2'));
    const option3Index = headers.findIndex(h => h.includes('option3') || h.includes('option_3'));
    const option4Index = headers.findIndex(h => h.includes('option4') || h.includes('option_4'));
    const correctIndex = headers.findIndex(h => h.includes('correct'));
    const difficultyIndex = headers.findIndex(h => h.includes('difficulty'));
    const explanationIndex = headers.findIndex(h => h.includes('explanation'));

    if (questionIndex === -1 || option1Index === -1 || correctIndex === -1) {
      throw new Error('CSV must contain at least: question, option1, option2, option3, option4, correct columns');
    }

    const questions: Question[] = [];
    
    for (let i = 1; i < lines.length; i++) {
      const values = lines[i].split(',').map(v => v.trim().replace(/"/g, ''));
      
      if (values.length < headers.length) continue;
      
      const question: Question = {
        id: `bulk_${Date.now()}_${i}`,
        question: values[questionIndex],
        options: [
          values[option1Index] || '',
          values[option2Index] || '',
          values[option3Index] || '',
          values[option4Index] || ''
        ].filter(opt => opt.trim()),
        correctAnswer: Math.max(0, parseInt(values[correctIndex]) - 1) || 0,
        difficulty: (values[difficultyIndex] || 'Medium') as 'Easy' | 'Medium' | 'Hard',
        explanation: values[explanationIndex] || undefined,
      };

      if (question.question && question.options.length >= 2) {
        questions.push(question);
      }
    }

    return questions;
  };

  const handleSuitableForChange = (event: SelectChangeEvent<string[]>) => {
    const value = event.target.value;
    setExamConfig({
      ...examConfig,
      suitableFor: typeof value === 'string' ? value.split(',') : value,
    });
  };

  const handleCreateExam = () => {
    if (!examConfig.examName || !examConfig.examType || examConfig.suitableFor.length === 0) {
      setError('Please fill in all exam configuration fields');
      return;
    }

    if (parsedQuestions.length === 0) {
      setError('No valid questions found');
      return;
    }

    // Validate freemium configuration
    if (examConfig.freeQuestionsLimit && examConfig.freeQuestionsLimit > 0) {
      if (freeQuestionsSelection.size !== examConfig.freeQuestionsLimit) {
        setError(`Please select exactly ${examConfig.freeQuestionsLimit} questions as free`);
        return;
      }
    }

    // Mark questions with isFree flag based on selection
    const questionsWithFreeFlag = parsedQuestions.map(q => ({
      ...q,
      isFree: freeQuestionsSelection.has(q.id),
    }));

    const uploadData: BulkUploadData = {
      ...examConfig,
      questions: questionsWithFreeFlag,
      createLiveTest,
      liveTestData: createLiveTest ? {
        ...liveTestForm,
        title: liveTestForm.title || examConfig.examName,
        description: liveTestForm.description || `Live test for ${examConfig.examName}`,
      } : undefined,
    };

    onUploadComplete(uploadData);

    // Reset form
    setFile(null);
    setExamConfig({
      examName: '',
      examType: '',
      timeLimit: 30,
      suitableFor: [],
      price: 0,
      currency: 'INR',
      isFree: true,
      freeQuestionsLimit: -1,
      unlockPrice: 0,
    });
    setParsedQuestions([]);
    setShowPreview(false);
    setError(null);
    setFreeQuestionsSelection(new Set());

    // Reset live test form
    setCreateLiveTest(false);
    setLiveTestForm({
      title: '',
      description: '',
      startTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
      endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      durationMinutes: 60,
      maxParticipants: 1000,
      instructorName: '',
      difficulty: 'medium',
      passingScore: 60,
      showResults: true,
    });
  };

  const handleEditQuestion = (question: Question) => {
    setEditingQuestion({ ...question });
    setOpenEditDialog(true);
  };

  const handleSaveEdit = () => {
    if (editingQuestion) {
      const updatedQuestions = parsedQuestions.map(q =>
        q.id === editingQuestion.id ? editingQuestion : q
      );
      setParsedQuestions(updatedQuestions);
      setOpenEditDialog(false);
      setEditingQuestion(null);
    }
  };

  const handleDeleteQuestion = (questionId: string) => {
    const updatedQuestions = parsedQuestions.filter(q => q.id !== questionId);
    setParsedQuestions(updatedQuestions);
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Easy': return 'success';
      case 'Medium': return 'warning';
      case 'Hard': return 'error';
      default: return 'default';
    }
  };

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box display="flex" alignItems="center" mb={2}>
          <CloudUploadIcon sx={{ mr: 1, color: 'primary.main' }} />
          <Typography variant="h6">
            Bulk Upload Questions
          </Typography>
        </Box>

        <Typography variant="body2" color="text.secondary" paragraph>
          Upload questions via CSV and create a new exam automatically
        </Typography>

        {!file && (
          <Alert severity="info" sx={{ mb: 2 }}>
            <Typography variant="body2">
              <strong>Step 1:</strong> Upload a CSV file with your questions
              <br />
              <strong>Step 2:</strong> Configure exam settings
              <br />
              <strong>Step 3:</strong> Preview and create your exam
            </Typography>
          </Alert>
        )}

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Grid container spacing={2}>
          {/* File Upload Section */}
          <Grid item xs={12}>
            <Box
              sx={{
                border: '2px dashed #ccc',
                borderRadius: 2,
                p: 3,
                textAlign: 'center',
                cursor: 'pointer',
                backgroundColor: 'grey.50',
                transition: 'all 0.3s ease',
                '&:hover': {
                  borderColor: 'primary.main',
                  backgroundColor: 'primary.light',
                  '& .MuiTypography-root': { color: 'primary.contrastText' },
                  '& .MuiSvgIcon-root': { color: 'primary.contrastText' }
                },
                mb: 2,
                minHeight: 120,
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
              }}
              onClick={() => document.getElementById('bulk-upload-input')?.click()}
            >
              <input
                id="bulk-upload-input"
                type="file"
                accept=".csv"
                style={{ display: 'none' }}
                onChange={(e) => {
                  const selectedFile = e.target.files?.[0];
                  if (selectedFile) handleFileSelect(selectedFile);
                }}
              />
              <CloudUploadIcon sx={{ fontSize: 48, color: 'primary.main', mb: 2 }} />
              <Typography variant="h6" gutterBottom>
                {file ? file.name : 'Upload CSV File'}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                {file ? 'File selected successfully' : 'Click here or drag and drop your CSV file'}
              </Typography>
              {file && (
                <Typography variant="caption" color="success.main" sx={{ fontWeight: 'bold' }}>
                  ✓ {(file.size / 1024).toFixed(1)} KB
                </Typography>
              )}
              {!file && (
                <Typography variant="caption" color="text.secondary">
                  Supported format: .csv
                </Typography>
              )}
            </Box>
          </Grid>

          {/* Exam Configuration */}
          {file && (
            <>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Exam Name"
                  value={examConfig.examName}
                  onChange={(e) => setExamConfig({ ...examConfig, examName: e.target.value })}
                  required
                />
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth required>
                  <InputLabel>Exam Type</InputLabel>
                  <Select
                    value={examConfig.examType}
                    label="Exam Type"
                    onChange={(e) => setExamConfig({ ...examConfig, examType: e.target.value })}
                    renderValue={(selected) => (
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Typography sx={{ fontSize: '1.2rem' }}>
                          {getExamTypeIcon(selected)}
                        </Typography>
                        <Typography>{selected}</Typography>
                      </Box>
                    )}
                  >
                    {examTypes.map((type) => (
                      <MenuItem key={type.id} value={type.name}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography sx={{ fontSize: '1.2rem' }}>{type.icon}</Typography>
                          <Typography>{type.name}</Typography>
                          {type.isDefault && (
                            <Typography variant="caption" color="primary.main" sx={{ ml: 'auto' }}>
                              Default
                            </Typography>
                          )}
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  type="number"
                  label="Time Limit (minutes)"
                  value={examConfig.timeLimit}
                  onChange={(e) => setExamConfig({ ...examConfig, timeLimit: parseInt(e.target.value) })}
                  inputProps={{ min: 1, max: 300 }}
                  required
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth required>
                  <InputLabel>Suitable For</InputLabel>
                  <Select
                    multiple
                    value={examConfig.suitableFor}
                    onChange={handleSuitableForChange}
                    input={<OutlinedInput label="Suitable For" />}
                    renderValue={(selected) => (
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {selected.map((value) => (
                          <Chip key={value} label={value} size="small" />
                        ))}
                      </Box>
                    )}
                  >
                    {suitableForOptions.map((option) => (
                      <MenuItem key={option} value={option}>
                        {option}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              {/* Price Configuration */}
              <Grid item xs={12}>
                <Box sx={{ p: 2, border: '1px solid #e0e0e0', borderRadius: 1, backgroundColor: '#f0f8ff' }}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={examConfig.isFree}
                        onChange={(e) => setExamConfig({ ...examConfig, isFree: e.target.checked, price: e.target.checked ? 0 : examConfig.price })}
                        color="primary"
                      />
                    }
                    label={
                      <Box>
                        <Typography variant="subtitle2" fontWeight="bold">
                          💰 Pricing Configuration
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {examConfig.isFree ? 'This exam will be free for all users' : 'This exam requires payment to access'}
                        </Typography>
                      </Box>
                    }
                  />

                  {!examConfig.isFree && (
                    <Box sx={{ mt: 2 }}>
                      <Grid container spacing={2}>
                        <Grid item xs={12} sm={6}>
                          <TextField
                            fullWidth
                            type="number"
                            label="Price"
                            value={examConfig.price}
                            onChange={(e) => setExamConfig({ ...examConfig, price: parseFloat(e.target.value) || 0 })}
                            inputProps={{ min: 0, step: 0.01 }}
                            size="small"
                            required={!examConfig.isFree}
                          />
                        </Grid>
                        <Grid item xs={12} sm={6}>
                          <FormControl fullWidth size="small">
                            <InputLabel>Currency</InputLabel>
                            <Select
                              value={examConfig.currency}
                              label="Currency"
                              onChange={(e) => setExamConfig({ ...examConfig, currency: e.target.value })}
                            >
                              <MenuItem value="INR">INR (₹)</MenuItem>
                              <MenuItem value="USD">USD ($)</MenuItem>
                              <MenuItem value="EUR">EUR (€)</MenuItem>
                            </Select>
                          </FormControl>
                        </Grid>
                      </Grid>
                    </Box>
                  )}
                </Box>
              </Grid>

              {/* Freemium Configuration */}
              <Grid item xs={12}>
                <Box sx={{ p: 2, border: '1px solid #e0e0e0', borderRadius: 1, backgroundColor: '#fff3e0' }}>
                  <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 2 }}>
                    🎯 Freemium Model Configuration
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Allow users to attempt a limited number of questions for free before requiring payment to unlock remaining questions.
                  </Typography>

                  <Grid container spacing={2}>
                    <Grid item xs={12} sm={6}>
                      <TextField
                        fullWidth
                        type="number"
                        label="Free Questions Limit"
                        value={examConfig.freeQuestionsLimit}
                        onChange={(e) => setExamConfig({ ...examConfig, freeQuestionsLimit: parseInt(e.target.value) })}
                        inputProps={{ min: -1 }}
                        size="small"
                        helperText="0 = Fully Paid | -1 = Fully Free | >0 = Freemium (e.g., 5)"
                      />
                    </Grid>

                    {examConfig.freeQuestionsLimit > 0 && (
                      <Grid item xs={12} sm={6}>
                        <TextField
                          fullWidth
                          type="number"
                          label="Unlock Price"
                          value={examConfig.unlockPrice}
                          onChange={(e) => setExamConfig({ ...examConfig, unlockPrice: parseFloat(e.target.value) || 0 })}
                          inputProps={{ min: 0, step: 0.01 }}
                          size="small"
                          helperText="Price to unlock remaining questions"
                        />
                      </Grid>
                    )}
                  </Grid>

                  {examConfig.freeQuestionsLimit > 0 && (
                    <Box sx={{ mt: 2, p: 1.5, backgroundColor: '#e3f2fd', borderRadius: 1 }}>
                      <Typography variant="caption" color="primary">
                        ℹ️ Users can attempt {examConfig.freeQuestionsLimit} questions for free, then pay ₹{examConfig.unlockPrice || 0} to unlock the remaining questions.
                      </Typography>
                    </Box>
                  )}
                </Box>
              </Grid>

              {/* Live Test Option */}
              <Grid item xs={12}>
                <Box sx={{ p: 2, border: '1px solid #e0e0e0', borderRadius: 1, backgroundColor: '#f8f9fa' }}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={createLiveTest}
                        onChange={(e) => setCreateLiveTest(e.target.checked)}
                        color="primary"
                      />
                    }
                    label={
                      <Box>
                        <Typography variant="subtitle2" fontWeight="bold">
                          📅 Schedule as Live Test
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Create a scheduled live test that all users can participate in at a specific time
                        </Typography>
                      </Box>
                    }
                  />

                  {createLiveTest && (
                    <Box sx={{ mt: 2 }}>
                      <Grid container spacing={2}>
                        <Grid item xs={12} sm={6}>
                          <TextField
                            fullWidth
                            label="Live Test Title"
                            value={liveTestForm.title}
                            onChange={(e) => setLiveTestForm({ ...liveTestForm, title: e.target.value })}
                            placeholder={examConfig.examName || 'Enter title'}
                            size="small"
                          />
                        </Grid>
                        <Grid item xs={12} sm={6}>
                          <TextField
                            fullWidth
                            label="Instructor Name"
                            value={liveTestForm.instructorName}
                            onChange={(e) => setLiveTestForm({ ...liveTestForm, instructorName: e.target.value })}
                            placeholder="System Admin"
                            size="small"
                          />
                        </Grid>
                        <Grid item xs={12}>
                          <TextField
                            fullWidth
                            multiline
                            rows={2}
                            label="Description"
                            value={liveTestForm.description}
                            onChange={(e) => setLiveTestForm({ ...liveTestForm, description: e.target.value })}
                            placeholder={`Live test for ${examConfig.examName || 'this exam'}`}
                            size="small"
                          />
                        </Grid>
                        <Grid item xs={12} sm={6}>
                          <TextField
                            fullWidth
                            type="datetime-local"
                            label="Start Time"
                            value={formatDateTimeLocal(liveTestForm.startTime)}
                            onChange={(e) => setLiveTestForm({ ...liveTestForm, startTime: parseDateTimeLocal(e.target.value) })}
                            size="small"
                            InputLabelProps={{ shrink: true }}
                          />
                        </Grid>
                        <Grid item xs={12} sm={6}>
                          <TextField
                            fullWidth
                            type="datetime-local"
                            label="End Time"
                            value={formatDateTimeLocal(liveTestForm.endTime)}
                            onChange={(e) => setLiveTestForm({ ...liveTestForm, endTime: parseDateTimeLocal(e.target.value) })}
                            size="small"
                            InputLabelProps={{ shrink: true }}
                          />
                        </Grid>
                        <Grid item xs={12} sm={4}>
                          <TextField
                            fullWidth
                            type="number"
                            label="Duration (minutes)"
                            value={liveTestForm.durationMinutes}
                            onChange={(e) => setLiveTestForm({ ...liveTestForm, durationMinutes: parseInt(e.target.value) || 60 })}
                            size="small"
                          />
                        </Grid>
                        <Grid item xs={12} sm={4}>
                          <TextField
                            fullWidth
                            type="number"
                            label="Max Participants"
                            value={liveTestForm.maxParticipants}
                            onChange={(e) => setLiveTestForm({ ...liveTestForm, maxParticipants: parseInt(e.target.value) || 1000 })}
                            size="small"
                          />
                        </Grid>
                        <Grid item xs={12} sm={4}>
                          <TextField
                            fullWidth
                            type="number"
                            label="Passing Score (%)"
                            value={liveTestForm.passingScore}
                            onChange={(e) => setLiveTestForm({ ...liveTestForm, passingScore: parseInt(e.target.value) || 60 })}
                            size="small"
                          />
                        </Grid>
                      </Grid>
                    </Box>
                  )}
                </Box>
              </Grid>
            </>
          )}
        </Grid>

        {/* Exam Configuration Summary */}
        {showPreview && parsedQuestions.length > 0 && examConfig.examName && (
          <Box mt={3} mb={2}>
            <Alert severity="info" sx={{ backgroundColor: '#f8f9fa' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
                <Typography sx={{ fontSize: '1.5rem' }}>
                  {getExamTypeIcon(examConfig.examType)}
                </Typography>
                <Box>
                  <Typography variant="h6" component="div">
                    {examConfig.examName}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {examConfig.examType} • {examConfig.timeLimit} minutes • {parsedQuestions.length} questions
                  </Typography>
                </Box>
              </Box>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5, mt: 1 }}>
                {examConfig.suitableFor.map((role) => (
                  <Chip key={role} label={role} size="small" color="primary" variant="outlined" />
                ))}
              </Box>
              {createLiveTest && (
                <Box sx={{ mt: 1, p: 1, backgroundColor: '#e3f2fd', borderRadius: 1 }}>
                  <Typography variant="body2" color="primary.main" fontWeight="bold">
                    📅 Scheduled as Live Test: {liveTestForm.title || examConfig.examName}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {liveTestForm.startTime.toLocaleDateString()} at {liveTestForm.startTime.toLocaleTimeString()}
                  </Typography>
                </Box>
              )}
            </Alert>
          </Box>
        )}

        {/* Questions Preview */}
        {showPreview && parsedQuestions.length > 0 && (
          <Box mt={2}>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
              <Typography variant="h6">
                Questions Preview ({parsedQuestions.length} questions)
              </Typography>
              {examConfig.freeQuestionsLimit && examConfig.freeQuestionsLimit > 0 && (
                <Tooltip
                  title={
                    freeQuestionsSelection.size !== examConfig.freeQuestionsLimit
                      ? `Select exactly ${examConfig.freeQuestionsLimit} questions as free`
                      : 'Perfect! All free questions selected'
                  }
                >
                  <Chip
                    label={`${freeQuestionsSelection.size}/${examConfig.freeQuestionsLimit} free questions`}
                    color={freeQuestionsSelection.size === examConfig.freeQuestionsLimit ? 'success' : 'warning'}
                    variant="outlined"
                  />
                </Tooltip>
              )}
            </Box>
            <Box sx={{ maxHeight: 400, overflow: 'auto', border: '1px solid #e0e0e0', borderRadius: 1 }}>
              {parsedQuestions.map((question, index) => (
                <Accordion key={question.id} sx={{ boxShadow: 'none', '&:before': { display: 'none' } }}>
                  <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                    <Box display="flex" justifyContent="space-between" alignItems="center" width="100%">
                      {examConfig.freeQuestionsLimit && examConfig.freeQuestionsLimit > 0 && (
                        <Checkbox
                          checked={freeQuestionsSelection.has(question.id)}
                          onChange={(e) => {
                            const newSelection = new Set(freeQuestionsSelection);
                            if (e.target.checked) {
                              newSelection.add(question.id);
                            } else {
                              newSelection.delete(question.id);
                            }
                            setFreeQuestionsSelection(newSelection);
                          }}
                          onClick={(e) => e.stopPropagation()}
                          sx={{ mr: 1 }}
                        />
                      )}
                      <Box flex={1}>
                        <Typography variant="subtitle2">
                          Q{index + 1}: {question.question.substring(0, 60)}
                          {question.question.length > 60 && '...'}
                        </Typography>
                        <Box display="flex" alignItems="center" gap={1} mt={0.5}>
                          {freeQuestionsSelection.has(question.id) && (
                            <Chip
                              label="FREE"
                              size="small"
                              color="success"
                              variant="outlined"
                            />
                          )}
                          <Chip
                            label={question.difficulty}
                            size="small"
                            color={getDifficultyColor(question.difficulty) as any}
                          />
                          <Typography variant="caption" color="text.secondary">
                            {question.options.length} options • Correct: Option {question.correctAnswer + 1}
                          </Typography>
                        </Box>
                      </Box>
                      <Box display="flex" gap={1} onClick={(e) => e.stopPropagation()}>
                        <IconButton
                          size="small"
                          onClick={() => handleEditQuestion(question)}
                          color="primary"
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => handleDeleteQuestion(question.id)}
                          color="error"
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Box>
                    </Box>
                  </AccordionSummary>
                  <AccordionDetails>
                    <Box>
                      <Typography variant="body2" fontWeight="medium" mb={1}>
                        {question.question}
                      </Typography>
                      <Grid container spacing={1} mb={2}>
                        {question.options.map((option, optIndex) => (
                          <Grid item xs={12} sm={6} key={optIndex}>
                            <Typography
                              variant="body2"
                              sx={{
                                p: 1,
                                borderRadius: 1,
                                backgroundColor: optIndex === question.correctAnswer ? 'success.light' : 'grey.100',
                                color: optIndex === question.correctAnswer ? 'success.contrastText' : 'text.primary',
                              }}
                            >
                              {optIndex + 1}. {option}
                              {optIndex === question.correctAnswer && ' ✓'}
                            </Typography>
                          </Grid>
                        ))}
                      </Grid>
                      {question.explanation && (
                        <Typography variant="body2" color="text.secondary">
                          <strong>Explanation:</strong> {question.explanation}
                        </Typography>
                      )}
                    </Box>
                  </AccordionDetails>
                </Accordion>
              ))}
            </Box>
          </Box>
        )}
      </CardContent>

      <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
        <Button
          startIcon={<PreviewIcon />}
          onClick={() => setShowPreview(!showPreview)}
          disabled={!file || parsedQuestions.length === 0}
        >
          {showPreview ? 'Hide Preview' : 'Preview Questions'}
        </Button>

        <Tooltip
          title={
            examConfig.freeQuestionsLimit && examConfig.freeQuestionsLimit > 0
              ? freeQuestionsSelection.size !== examConfig.freeQuestionsLimit
                ? `Please select exactly ${examConfig.freeQuestionsLimit} questions as free`
                : ''
              : ''
          }
        >
          <span>
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={handleCreateExam}
              disabled={
                !file ||
                parsedQuestions.length === 0 ||
                !examConfig.examName ||
                !examConfig.examType ||
                examConfig.suitableFor.length === 0 ||
                (examConfig.freeQuestionsLimit && examConfig.freeQuestionsLimit > 0
                  ? freeQuestionsSelection.size !== examConfig.freeQuestionsLimit
                  : false)
              }
              sx={{
                background: 'linear-gradient(45deg, #6366F1 30%, #8B5CF6 90%)',
                boxShadow: '0 3px 5px 2px rgba(99, 102, 241, .3)',
              }}
            >
              Create Exam ({parsedQuestions.length} questions)
            </Button>
          </span>
        </Tooltip>
      </CardActions>

      {/* Edit Question Dialog */}
      <Dialog
        open={openEditDialog}
        onClose={() => setOpenEditDialog(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Edit Question</DialogTitle>
        <DialogContent>
          {editingQuestion && (
            <Box sx={{ pt: 2 }}>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    label="Question"
                    value={editingQuestion.question}
                    onChange={(e) => setEditingQuestion({ ...editingQuestion, question: e.target.value })}
                  />
                </Grid>

                {editingQuestion.options.map((option, index) => (
                  <Grid item xs={12} sm={6} key={index}>
                    <TextField
                      fullWidth
                      label={`Option ${index + 1}`}
                      value={option}
                      onChange={(e) => {
                        const newOptions = [...editingQuestion.options];
                        newOptions[index] = e.target.value;
                        setEditingQuestion({ ...editingQuestion, options: newOptions });
                      }}
                    />
                  </Grid>
                ))}

                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth>
                    <InputLabel>Correct Answer</InputLabel>
                    <Select
                      value={editingQuestion.correctAnswer}
                      label="Correct Answer"
                      onChange={(e) => setEditingQuestion({ ...editingQuestion, correctAnswer: e.target.value as number })}
                    >
                      {editingQuestion.options.map((option, index) => (
                        <MenuItem key={index} value={index}>
                          Option {index + 1}: {option.substring(0, 30)}{option.length > 30 ? '...' : ''}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth>
                    <InputLabel>Difficulty</InputLabel>
                    <Select
                      value={editingQuestion.difficulty}
                      label="Difficulty"
                      onChange={(e) => setEditingQuestion({ ...editingQuestion, difficulty: e.target.value as 'Easy' | 'Medium' | 'Hard' })}
                    >
                      <MenuItem value="Easy">🟢 Easy</MenuItem>
                      <MenuItem value="Medium">🟡 Medium</MenuItem>
                      <MenuItem value="Hard">🔴 Hard</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>

                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    multiline
                    rows={2}
                    label="Explanation (Optional)"
                    value={editingQuestion.explanation || ''}
                    onChange={(e) => setEditingQuestion({ ...editingQuestion, explanation: e.target.value })}
                  />
                </Grid>

                {examConfig.freeQuestionsLimit && examConfig.freeQuestionsLimit > 0 && (
                  <Grid item xs={12}>
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={freeQuestionsSelection.has(editingQuestion.id)}
                          onChange={(e) => {
                            const newSelection = new Set(freeQuestionsSelection);
                            if (e.target.checked) {
                              newSelection.add(editingQuestion.id);
                            } else {
                              newSelection.delete(editingQuestion.id);
                            }
                            setFreeQuestionsSelection(newSelection);
                          }}
                        />
                      }
                      label="Mark as free question"
                    />
                  </Grid>
                )}
              </Grid>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenEditDialog(false)}>
            Cancel
          </Button>
          <Button variant="contained" onClick={handleSaveEdit}>
            Save Changes
          </Button>
        </DialogActions>
      </Dialog>
    </Card>
  );
};

export default BulkUploadCard;
