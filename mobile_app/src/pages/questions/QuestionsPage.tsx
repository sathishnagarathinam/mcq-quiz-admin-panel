import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Tooltip,

  CircularProgress,
  Stack,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  QuestionAnswer as QuestionIcon,
  Refresh as RefreshIcon,
  ArrowBack,
} from '@mui/icons-material';
import { collection, addDoc, getDocs, doc, updateDoc, deleteDoc, getDoc, Timestamp, query, where } from 'firebase/firestore';
import { db } from '../../config/firebase';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';

interface Question {
  id: string;
  question: string;
  options: string[];
  correctAnswer: number;
  explanation?: string;
  difficulty: 'Easy' | 'Medium' | 'Hard';
  examType?: string;
  category?: string;
  examId?: string;
  examName?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

interface Exam {
  id: string;
  name: string;
  examType: string;
  numberOfQuestions: number;
  timeLimit: number;
  suitableFor: string[];
  questions: Question[];
  createdAt: Date | Timestamp;
  updatedAt: Date | Timestamp;
  isActive: boolean;
}



const QuestionsPage: React.FC = () => {
  const navigate = useNavigate();
  const [questions, setQuestions] = useState<Question[]>([]);
  const [filteredQuestions, setFilteredQuestions] = useState<Question[]>([]);
  const [loading, setLoading] = useState(false);
  const [openDialog, setOpenDialog] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState<Question | null>(null);


  // Pagination
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // Filters
  const [filters, setFilters] = useState({
    difficulty: '',
    examType: '',
    examName: '',
    search: '',
  });

  // Form state
  const [questionForm, setQuestionForm] = useState<Partial<Question>>({
    question: '',
    options: ['', '', '', ''],
    correctAnswer: 0,
    explanation: '',
    difficulty: 'Medium',
    examType: '',
    category: '',
  });

  const [examTypes, setExamTypes] = useState<string[]>([
    'Postal Guide',
    'Postal Volumes',
    'Custom Exam',
  ]);

  const [examNames, setExamNames] = useState<string[]>([]);
  const [availableExams, setAvailableExams] = useState<Exam[]>([]);

  useEffect(() => {
    fetchQuestions();
    fetchExamTypes();
  }, []);

  const fetchQuestions = async () => {
    try {
      setLoading(true);

      // Fetch only active questions from individual questions collection and only active exams
      const [questionsSnapshot, examsSnapshot] = await Promise.all([
        // Fetch individual questions (no specific active filter for individual questions yet)
        getDocs(collection(db, 'questions')),
        // Fetch only active exams
        getDocs(query(collection(db, 'exams'), where('isActive', '==', true)))
      ]);

      const questionsList: Question[] = [];

      // Add individual questions from questions collection
      // Filter out questions that might be marked as inactive or deleted
      questionsSnapshot.forEach((doc) => {
        const data = doc.data();

        // Skip questions that are explicitly marked as inactive
        if (data.isActive === false) {
          return;
        }

        // Skip questions that belong to inactive exams (if examId is present)
        // We'll validate this against active exams later

        questionsList.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate(),
          updatedAt: data.updatedAt?.toDate(),
        } as Question);
      });

      // Store available active exams for assignment
      const examsList: Exam[] = [];
      const activeExamIds = new Set<string>();

      // Add questions from active exams collection only
      examsSnapshot.forEach((examDoc) => {
        const examData = examDoc.data() as Exam;

        // Only process active exams
        if (examData.isActive !== false) {
          activeExamIds.add(examDoc.id);

          examsList.push({
            ...examData,
            id: examDoc.id,
            createdAt: examData.createdAt instanceof Timestamp ? examData.createdAt.toDate() : examData.createdAt,
            updatedAt: examData.updatedAt instanceof Timestamp ? examData.updatedAt.toDate() : examData.updatedAt,
          });

          if (examData.questions && examData.questions.length > 0) {
            examData.questions.forEach((question) => {
              // Check if question already exists in individual questions
              const existingQuestion = questionsList.find(q => q.id === question.id);
              if (!existingQuestion) {
                questionsList.push({
                  ...question,
                  examId: examDoc.id,
                  examName: examData.name,
                  examType: examData.examType,
                  createdAt: examData.createdAt instanceof Timestamp ? examData.createdAt.toDate() : examData.createdAt,
                  updatedAt: examData.updatedAt instanceof Timestamp ? examData.updatedAt.toDate() : examData.updatedAt,
                });
              }
            });
          }
        }
      });

      // Filter out individual questions that belong to inactive exams
      const filteredQuestionsList = questionsList.filter(question => {
        // If question has an examId, make sure the exam is active
        if (question.examId) {
          return activeExamIds.has(question.examId);
        }
        // If no examId, it's an individual question - keep it
        return true;
      });

      setAvailableExams(examsList);

      setQuestions(filteredQuestionsList);

      // Extract unique exam names for filtering (only from active exams)
      const examNamesSet = new Set<string>();
      filteredQuestionsList
        .filter(q => q.examName)
        .forEach(q => examNamesSet.add(q.examName!));
      const uniqueExamNames = Array.from(examNamesSet);
      setExamNames(uniqueExamNames);

      console.log(`Loaded ${filteredQuestionsList.length} questions from ${examsList.length} active exams`);

    } catch (error) {
      console.error('Error fetching questions:', error);
      toast.error('Failed to fetch questions');
    } finally {
      setLoading(false);
    }
  };

  const fetchExamTypes = async () => {
    try {
      const examTypesSnapshot = await getDocs(collection(db, 'examTypes'));
      const types: string[] = ['Postal Guide', 'Postal Volumes', 'Custom Exam'];

      examTypesSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.name && !types.includes(data.name)) {
          types.push(data.name);
        }
      });

      setExamTypes(types);
    } catch (error) {
      console.error('Error fetching exam types:', error);
    }
  };

  const applyFilters = useCallback(() => {
    let filtered = [...questions];

    if (filters.difficulty) {
      filtered = filtered.filter(q => q.difficulty === filters.difficulty);
    }

    if (filters.examType) {
      filtered = filtered.filter(q => q.examType === filters.examType);
    }

    if (filters.examName) {
      filtered = filtered.filter(q => q.examName === filters.examName);
    }

    if (filters.search) {
      const searchLower = filters.search.toLowerCase();
      filtered = filtered.filter(q =>
        q.question.toLowerCase().includes(searchLower) ||
        q.options.some(option => option.toLowerCase().includes(searchLower))
      );
    }

    setFilteredQuestions(filtered);
    setPage(0); // Reset to first page when filters change
  }, [questions, filters]);

  useEffect(() => {
    applyFilters();
  }, [questions, filters, applyFilters]);

  const handleCreateQuestion = () => {
    setEditingQuestion(null);
    setQuestionForm({
      question: '',
      options: ['', '', '', ''],
      correctAnswer: 0,
      explanation: '',
      difficulty: 'Medium',
      examType: '',
      category: '',
    });
    setOpenDialog(true);
  };

  const handleEditQuestion = (question: Question) => {
    setEditingQuestion(question);
    setQuestionForm(question);
    setOpenDialog(true);
  };

  const handleSaveQuestion = async () => {
    try {
      if (!questionForm.question || questionForm.options?.some(opt => !opt.trim())) {
        toast.error('Please fill in all required fields');
        return;
      }

      // Validate that "None of the above" and "All of the above" are only in the last position
      const specialOptionPatterns = ['none of the above', 'all of the above'];
      const options = questionForm.options || [];

      for (let i = 0; i < options.length - 1; i++) {
        const optionLower = options[i].toLowerCase();
        if (specialOptionPatterns.some(pattern => optionLower.includes(pattern))) {
          toast.error(`"${options[i]}" can only be placed as the last option (Option 4)`);
          return;
        }
      }

      const questionData = {
        ...questionForm,
        updatedAt: new Date(),
        createdAt: editingQuestion ? editingQuestion.createdAt : new Date(),
      };

      if (editingQuestion) {
        // If editing a question that belongs to an exam, update it in the exam
        if (editingQuestion.examId) {
          const examRef = doc(db, 'exams', editingQuestion.examId);
          const examDoc = await getDoc(examRef);

          if (examDoc.exists()) {
            const examData = examDoc.data() as Exam;
            const updatedQuestions = examData.questions.map(q =>
              q.id === editingQuestion.id ? { ...questionData, id: editingQuestion.id } : q
            );

            await updateDoc(examRef, {
              questions: updatedQuestions,
              updatedAt: new Date(),
            });
          }
        } else {
          // Update individual question
          await updateDoc(doc(db, 'questions', editingQuestion.id), questionData);
        }
        toast.success('Question updated successfully');
      } else {
        // Create new question
        if (questionForm.examId) {
          // Add to specific exam
          const examRef = doc(db, 'exams', questionForm.examId);
          const examDoc = await getDoc(examRef);

          if (examDoc.exists()) {
            const examData = examDoc.data() as Exam;
            const newQuestionId = Date.now().toString();
            const newQuestion = { ...questionData, id: newQuestionId };
            const updatedQuestions = [...(examData.questions || []), newQuestion];

            await updateDoc(examRef, {
              questions: updatedQuestions,
              numberOfQuestions: updatedQuestions.length,
              updatedAt: new Date(),
            });

            // Also save to individual questions collection
            await addDoc(collection(db, 'questions'), {
              ...questionData,
              id: newQuestionId,
              examId: questionForm.examId,
              examName: questionForm.examName,
            });
          }
        } else {
          // Create individual question
          await addDoc(collection(db, 'questions'), questionData);
        }
        toast.success('Question created successfully');
      }

      setOpenDialog(false);
      fetchQuestions();
    } catch (error) {
      console.error('Error saving question:', error);
      toast.error('Failed to save question');
    }
  };

  const handleDeleteQuestion = async (questionId: string) => {
    if (!window.confirm('Are you sure you want to delete this question?')) {
      return;
    }

    try {
      const question = questions.find(q => q.id === questionId);

      if (question?.examId) {
        // Delete from exam
        const examRef = doc(db, 'exams', question.examId);
        const examDoc = await getDoc(examRef);

        if (examDoc.exists()) {
          const examData = examDoc.data() as Exam;
          const updatedQuestions = examData.questions.filter(q => q.id !== questionId);

          await updateDoc(examRef, {
            questions: updatedQuestions,
            numberOfQuestions: updatedQuestions.length,
            updatedAt: Timestamp.now(),
          });
        }

        // Also check if this question exists in the individual questions collection and remove it
        try {
          const individualQuestionQuery = query(
            collection(db, 'questions'),
            where('id', '==', questionId)
          );
          const individualQuestionSnapshot = await getDocs(individualQuestionQuery);

          // Delete any matching individual questions
          const deletePromises = individualQuestionSnapshot.docs.map(doc =>
            deleteDoc(doc.ref)
          );
          await Promise.all(deletePromises);

          if (individualQuestionSnapshot.docs.length > 0) {
            console.log(`Removed ${individualQuestionSnapshot.docs.length} individual question(s) with ID ${questionId}`);
          }
        } catch (error) {
          console.warn('Error cleaning up individual questions:', error);
        }
      } else {
        // Delete individual question
        await deleteDoc(doc(db, 'questions', questionId));
      }

      toast.success('Question deleted successfully');
      fetchQuestions();
    } catch (error) {
      console.error('Error deleting question:', error);
      toast.error('Failed to delete question');
    }
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Easy': return 'success';
      case 'Medium': return 'warning';
      case 'Hard': return 'error';
      default: return 'default';
    }
  };

  const cleanupOrphanedQuestions = async () => {
    if (!window.confirm('This will remove questions that belong to deleted exams. Continue?')) {
      return;
    }

    try {
      setLoading(true);

      // Get all active exam IDs
      const activeExamsSnapshot = await getDocs(
        query(collection(db, 'exams'), where('isActive', '==', true))
      );
      const activeExamIds = new Set(activeExamsSnapshot.docs.map(doc => doc.id));

      // Get all individual questions
      const questionsSnapshot = await getDocs(collection(db, 'questions'));

      let orphanedCount = 0;
      const deletePromises: Promise<void>[] = [];

      questionsSnapshot.forEach((doc) => {
        const data = doc.data();

        // If question has an examId but the exam is not active, it's orphaned
        if (data.examId && !activeExamIds.has(data.examId)) {
          orphanedCount++;
          deletePromises.push(deleteDoc(doc.ref));
        }
      });

      if (deletePromises.length > 0) {
        await Promise.all(deletePromises);
        toast.success(`Cleaned up ${orphanedCount} orphaned questions`);
        fetchQuestions();
      } else {
        toast('No orphaned questions found');
      }

    } catch (error) {
      console.error('Error cleaning up orphaned questions:', error);
      toast.error('Failed to cleanup orphaned questions');
    } finally {
      setLoading(false);
    }
  };



  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Button
            variant="outlined"
            startIcon={<ArrowBack />}
            onClick={() => navigate('/dashboard')}
            sx={{ minWidth: 'auto' }}
          >
            Back to Dashboard
          </Button>
          <Typography variant="h4" component="h1">
            Questions Management
          </Typography>
        </Box>
        <Stack direction="row" spacing={2}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={fetchQuestions}
            disabled={loading}
          >
            Refresh
          </Button>
          <Button
            variant="outlined"
            color="warning"
            startIcon={<DeleteIcon />}
            onClick={cleanupOrphanedQuestions}
            disabled={loading}
          >
            Cleanup Orphaned
          </Button>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={handleCreateQuestion}
            sx={{
              background: 'linear-gradient(45deg, #6366F1 30%, #8B5CF6 90%)',
              boxShadow: '0 3px 5px 2px rgba(99, 102, 241, .3)',
            }}
          >
            Add Question
          </Button>
        </Stack>
      </Box>

      {/* Filters */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          <FilterIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
          Filters
        </Typography>
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={2.4}>
            <TextField
              fullWidth
              label="Search Questions"
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
              InputProps={{
                startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
              }}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <FormControl fullWidth>
              <InputLabel>Difficulty</InputLabel>
              <Select
                value={filters.difficulty}
                label="Difficulty"
                onChange={(e) => setFilters({ ...filters, difficulty: e.target.value })}
              >
                <MenuItem value="">All Difficulties</MenuItem>
                <MenuItem value="Easy">🟢 Easy</MenuItem>
                <MenuItem value="Medium">🟡 Medium</MenuItem>
                <MenuItem value="Hard">🔴 Hard</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <FormControl fullWidth>
              <InputLabel>Exam</InputLabel>
              <Select
                value={filters.examName}
                label="Exam"
                onChange={(e) => setFilters({ ...filters, examName: e.target.value })}
              >
                <MenuItem value="">All Exams</MenuItem>
                <MenuItem value="Individual Question">Individual Questions</MenuItem>
                {examNames.map((name) => (
                  <MenuItem key={name} value={name}>
                    {name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <FormControl fullWidth>
              <InputLabel>Exam Type</InputLabel>
              <Select
                value={filters.examType}
                label="Exam Type"
                onChange={(e) => setFilters({ ...filters, examType: e.target.value })}
              >
                <MenuItem value="">All Exam Types</MenuItem>
                {examTypes.map((type) => (
                  <MenuItem key={type} value={type}>
                    {type}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={6} md={2.4}>
            <Button
              fullWidth
              variant="outlined"
              onClick={() => setFilters({ difficulty: '', examType: '', examName: '', search: '' })}
              sx={{ height: '56px' }}
            >
              Clear Filters
            </Button>
          </Grid>
        </Grid>
      </Paper>

      {/* Questions Table */}
      <Paper>
        {loading ? (
          <Box display="flex" justifyContent="center" p={4}>
            <CircularProgress />
          </Box>
        ) : filteredQuestions.length === 0 ? (
          <Box textAlign="center" p={4}>
            <QuestionIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
            <Typography variant="h6" color="text.secondary" gutterBottom>
              {questions.length === 0 ? 'No questions found' : 'No questions match your filters'}
            </Typography>
            <Typography color="text.secondary" mb={3}>
              {questions.length === 0
                ? 'Create your first question to get started'
                : 'Try adjusting your filters or search terms'
              }
            </Typography>
            {questions.length === 0 && (
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={handleCreateQuestion}
              >
                Create First Question
              </Button>
            )}
          </Box>
        ) : (
          <>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Question</TableCell>
                    <TableCell>Difficulty</TableCell>
                    <TableCell>Exam</TableCell>
                    <TableCell>Exam Type</TableCell>
                    <TableCell>Correct Answer</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredQuestions
                    .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                    .map((question) => (
                      <TableRow key={question.id} hover>
                        <TableCell>
                          <Typography variant="subtitle2" sx={{ maxWidth: 300 }}>
                            {question.question.length > 100
                              ? `${question.question.substring(0, 100)}...`
                              : question.question
                            }
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {question.options.length} options
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={question.difficulty}
                            color={getDifficultyColor(question.difficulty) as any}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" fontWeight="medium">
                            {question.examName || 'Individual Question'}
                          </Typography>
                          {question.examId && (
                            <Typography variant="caption" color="text.secondary" display="block">
                              ID: {question.examId.substring(0, 8)}...
                            </Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {question.examType || 'Not specified'}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            Option {question.correctAnswer + 1}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Stack direction="row" spacing={1}>
                            <Tooltip title="Edit Question">
                              <IconButton
                                size="small"
                                onClick={() => handleEditQuestion(question)}
                                color="primary"
                              >
                                <EditIcon />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title="Delete Question">
                              <IconButton
                                size="small"
                                onClick={() => handleDeleteQuestion(question.id)}
                                color="error"
                              >
                                <DeleteIcon />
                              </IconButton>
                            </Tooltip>
                          </Stack>
                        </TableCell>
                      </TableRow>
                    ))}
                </TableBody>
              </Table>
            </TableContainer>
            <TablePagination
              rowsPerPageOptions={[5, 10, 25, 50]}
              component="div"
              count={filteredQuestions.length}
              rowsPerPage={rowsPerPage}
              page={page}
              onPageChange={(_, newPage) => setPage(newPage)}
              onRowsPerPageChange={(event) => {
                setRowsPerPage(parseInt(event.target.value, 10));
                setPage(0);
              }}
            />
          </>
        )}
      </Paper>

      {/* Create/Edit Question Dialog */}
      <Dialog
        open={openDialog}
        onClose={() => setOpenDialog(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          {editingQuestion ? 'Edit Question' : 'Create New Question'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2 }}>
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={3}
                  label="Question"
                  value={questionForm.question}
                  onChange={(e) => setQuestionForm({ ...questionForm, question: e.target.value })}
                  required
                />
              </Grid>

              {questionForm.options?.map((option, index) => (
                <Grid item xs={12} sm={6} key={index}>
                  <TextField
                    fullWidth
                    label={`Option ${index + 1}`}
                    value={option}
                    onChange={(e) => {
                      const newOptions = [...(questionForm.options || [])];
                      newOptions[index] = e.target.value;
                      setQuestionForm({ ...questionForm, options: newOptions });
                    }}
                    required
                  />
                </Grid>
              ))}

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth required>
                  <InputLabel>Correct Answer</InputLabel>
                  <Select
                    value={questionForm.correctAnswer}
                    label="Correct Answer"
                    onChange={(e) => setQuestionForm({ ...questionForm, correctAnswer: e.target.value as number })}
                  >
                    {questionForm.options?.map((option, index) => (
                      <MenuItem key={index} value={index}>
                        Option {index + 1}: {option.substring(0, 30)}{option.length > 30 ? '...' : ''}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth required>
                  <InputLabel>Difficulty Level</InputLabel>
                  <Select
                    value={questionForm.difficulty}
                    label="Difficulty Level"
                    onChange={(e) => setQuestionForm({ ...questionForm, difficulty: e.target.value as 'Easy' | 'Medium' | 'Hard' })}
                  >
                    <MenuItem value="Easy">🟢 Easy</MenuItem>
                    <MenuItem value="Medium">🟡 Medium</MenuItem>
                    <MenuItem value="Hard">🔴 Hard</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Assign to Exam</InputLabel>
                  <Select
                    value={questionForm.examId || ''}
                    label="Assign to Exam"
                    onChange={(e) => {
                      const selectedExam = availableExams.find(exam => exam.id === e.target.value);
                      setQuestionForm({
                        ...questionForm,
                        examId: e.target.value || undefined,
                        examName: selectedExam?.name,
                        examType: selectedExam?.examType || questionForm.examType
                      });
                    }}
                  >
                    <MenuItem value="">Individual Question</MenuItem>
                    {availableExams.map((exam) => (
                      <MenuItem key={exam.id} value={exam.id}>
                        {exam.name} ({exam.examType})
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Exam Type</InputLabel>
                  <Select
                    value={questionForm.examType}
                    label="Exam Type"
                    onChange={(e) => setQuestionForm({ ...questionForm, examType: e.target.value })}
                  >
                    <MenuItem value="">Select Exam Type</MenuItem>
                    {examTypes.map((type) => (
                      <MenuItem key={type} value={type}>
                        {type}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Category"
                  value={questionForm.category}
                  onChange={(e) => setQuestionForm({ ...questionForm, category: e.target.value })}
                />
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={2}
                  label="Explanation (Optional)"
                  value={questionForm.explanation}
                  onChange={(e) => setQuestionForm({ ...questionForm, explanation: e.target.value })}
                />
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleSaveQuestion}
            disabled={!questionForm.question || questionForm.options?.some(opt => !opt.trim())}
          >
            {editingQuestion ? 'Update' : 'Create'} Question
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default QuestionsPage;
