import React, { useState, useEffect, useMemo } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  CardActions,
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
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Divider,
  Alert,
  CircularProgress,
  Avatar,
  Tooltip,
  Tab,
  Tabs,
  InputAdornment,
  FormControlLabel,
  Switch,
  Checkbox,
} from '@mui/material';
import {
  Add as AddIcon,
  Quiz as QuizIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  AccessTime as TimeIcon,
  QuestionAnswer as QuestionIcon,
  Group as GroupIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
  Category as CategoryIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  Clear as ClearIcon,
  TrendingUp as TrendingIcon,
  Star as StarIcon,
  ArrowBack,
  ToggleOn as ToggleOnIcon,
  ToggleOff as ToggleOffIcon,
  NotificationsActive as NotificationsIcon,
} from '@mui/icons-material';
import { collection, addDoc, getDocs, doc, updateDoc, deleteDoc, query, where, Timestamp } from 'firebase/firestore';
import { db } from '../../config/firebase';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';
import { NotificationService } from '../../services/notificationService';
import { useAuth } from '../../contexts/AuthContext';
import ExamAttemptsDialog from '../../components/admin/ExamAttemptsDialog';

interface Question {
  id: string;
  question: string;
  options: string[];
  correctAnswer: number;
  explanation?: string;
  difficulty: 'Easy' | 'Medium' | 'Hard';
  isFree?: boolean; // Mark if this question is part of free questions in freemium model
}

interface ExamType {
  id: string;
  name: string;
  icon: string;
  isDefault: boolean;
  createdAt: Date;
}

interface SuitabilityOption {
  id: string;
  name: string;
  shortName: string;
  color: string;
  isDefault: boolean;
  order: number;
  createdAt: Date;
}

interface Exam {
  id?: string;
  name: string;
  examType: string; // Now supports any custom exam type
  numberOfQuestions: number;
  timeLimit: number; // in minutes
  suitableFor: string[];
  questions: Question[];
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
  totalAttempts?: number;
  isTrending?: boolean;
  trendingPriority?: number;
  price?: number;
  currency?: string;
  isFree?: boolean;
  freeQuestionsLimit?: number; // Number of free questions (0 = fully paid, -1 = fully free, >0 = freemium)
  unlockPrice?: number; // Price to unlock remaining questions in freemium model
  topic?: string; // Topic/subject of the exam
  // Live test scheduling fields
  isLiveTest?: boolean;
  liveTestDescription?: string;
  liveTestStartTime?: Date;
  liveTestEndTime?: Date;
  liveTestBackgroundColor?: string;
  liveTestCardBackgroundColor?: string;
  liveTestIsPaid?: boolean;
  liveTestPrice?: number;
  // Live test notification fields
  liveTestNotificationEnabled?: boolean;
  liveTestNotificationTiming?: 'immediate' | '1hour' | '24hours'; // When to send notification before start time
  // Live test result release fields
  liveTestResultReleaseTime?: Date;
}

// Default suitability options
const defaultSuitabilityOptions: SuitabilityOption[] = [
  { id: 'mts', name: 'Multi Tasking Staff', shortName: 'MTS', color: '#1976d2', isDefault: true, order: 1, createdAt: new Date() },
  { id: 'postman', name: 'Postman', shortName: 'Postman', color: '#388e3c', isDefault: true, order: 2, createdAt: new Date() },
  { id: 'pa', name: 'Postal Assistant', shortName: 'PA', color: '#f57c00', isDefault: true, order: 3, createdAt: new Date() },
  { id: 'ip', name: 'Inspector of Posts', shortName: 'IP', color: '#7b1fa2', isDefault: true, order: 4, createdAt: new Date() },
  { id: 'group-b', name: 'Group B Officers', shortName: 'Group B', color: '#d32f2f', isDefault: true, order: 5, createdAt: new Date() },
];

// Default exam types
const defaultExamTypes: ExamType[] = [
  {
    id: 'postal-guide',
    name: 'Postal Guide',
    icon: '📮',
    isDefault: true,
    createdAt: new Date(),
  },
  {
    id: 'postal-volumes',
    name: 'Postal Volumes',
    icon: '📚',
    isDefault: true,
    createdAt: new Date(),
  },
];

// Helper function to safely convert date to ISO string for datetime-local input
// datetime-local expects local time, not UTC
const safeToISOString = (date: any): string => {
  try {
    if (!date) return '';
    const d = new Date(date);
    if (isNaN(d.getTime())) {
      console.warn('Invalid date:', date);
      // Return current local time in datetime-local format
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      return `${year}-${month}-${day}T${hours}:${minutes}`;
    }
    // Convert to local time format for datetime-local input
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}`;
  } catch (error) {
    console.error('Error converting date to ISO string:', error, date);
    // Return current local time in datetime-local format
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}`;
  }
};

const CategoriesPage: React.FC = () => {
  const navigate = useNavigate();
  const { user, adminUser } = useAuth();
  const [exams, setExams] = useState<Exam[]>([]);
  const [examTypes, setExamTypes] = useState<ExamType[]>(defaultExamTypes);
  const [loading, setLoading] = useState(true);
  const [tabValue, setTabValue] = useState(0);

  // Notification dialog states
  const [openNotificationDialog, setOpenNotificationDialog] = useState(false);
  const [selectedExamForNotification, setSelectedExamForNotification] = useState<Exam | null>(null);
  const [notificationForm, setNotificationForm] = useState({
    title: '',
    body: '',
  });
  const [sendingNotification, setSendingNotification] = useState(false);

  // Exam attempts dialog states
  const [openAttemptsDialog, setOpenAttemptsDialog] = useState(false);
  const [selectedExamForAttempts, setSelectedExamForAttempts] = useState<Exam | null>(null);

  // Search and filter states
  const [searchQuery, setSearchQuery] = useState('');
  const [filterExamType, setFilterExamType] = useState('');
  const [filterSuitability, setFilterSuitability] = useState('');
  const [filterStatus, setFilterStatus] = useState('');

  // Exam management states
  const [openDialog, setOpenDialog] = useState(false);
  const [editingExam, setEditingExam] = useState<Exam | null>(null);
  const [openQuestionDialog, setOpenQuestionDialog] = useState(false);
  const [currentExam, setCurrentExam] = useState<Exam | null>(null);
  const [questionFilter, setQuestionFilter] = useState<string>(''); // Filter for questions by difficulty
  const [freeQuestionsSelection, setFreeQuestionsSelection] = useState<Set<string>>(new Set()); // Track which questions are marked as free

  // Exam type management states
  const [openExamTypeDialog, setOpenExamTypeDialog] = useState(false);
  const [editingExamType, setEditingExamType] = useState<ExamType | null>(null);
  const [examTypeForm, setExamTypeForm] = useState({
    name: '',
    icon: '📝',
  });

  // Suitability options management states
  const [suitabilityOptions, setSuitabilityOptions] = useState<SuitabilityOption[]>(defaultSuitabilityOptions);
  const [openSuitabilityDialog, setOpenSuitabilityDialog] = useState(false);
  const [editingSuitabilityOption, setEditingSuitabilityOption] = useState<SuitabilityOption | null>(null);
  const [suitabilityForm, setSuitabilityForm] = useState({
    name: '',
    shortName: '',
    color: '#1976d2',
  });

  // Form states
  const [examForm, setExamForm] = useState<Partial<Exam>>({
    name: '',
    examType: 'Postal Guide',
    numberOfQuestions: 10,
    timeLimit: 30,
    suitableFor: [],
    questions: [],
    isActive: true,
    totalAttempts: 0,
    isTrending: false,
    trendingPriority: 0,
    price: 0,
    currency: 'INR',
    isFree: true,
    freeQuestionsLimit: -1,
    unlockPrice: 0,
    topic: '',
    // Live test scheduling fields
    isLiveTest: false,
    liveTestDescription: '',
    liveTestStartTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
    liveTestEndTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
    liveTestBackgroundColor: '#FF6B6B',
    liveTestCardBackgroundColor: '#FFFFFF',
    liveTestIsPaid: false,
    liveTestPrice: 0,
    // Live test notification fields
    liveTestNotificationEnabled: false,
    liveTestNotificationTiming: '24hours' as 'immediate' | '1hour' | '24hours',
    // Live test result release fields
    liveTestResultReleaseTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
  });

  // Live test form state
  const [createLiveTest, setCreateLiveTest] = useState(false);
  const [liveTestForm, setLiveTestForm] = useState({
    title: '',
    description: '',
    startTime: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
    endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000), // Tomorrow + 2 hours
    durationMinutes: 60,
    maxParticipants: 1000,
    instructorName: '',
    difficulty: 'medium' as 'easy' | 'medium' | 'hard',
    passingScore: 60,
    showResults: true,
  });

  const [questionForm, setQuestionForm] = useState<Partial<Question>>({
    question: '',
    options: ['', '', '', ''],
    correctAnswer: 0,
    explanation: '',
    difficulty: 'Medium',
  });

  useEffect(() => {
    fetchExams();
    fetchExamTypes();
    fetchSuitabilityOptions();
  }, []);

  // Filtered exams based on search and filters
  const filteredExams = useMemo(() => {
    const filtered = exams.filter((exam) => {
      // Search filter
      const matchesSearch = searchQuery === '' ||
        exam.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        exam.examType.toLowerCase().includes(searchQuery.toLowerCase()) ||
        exam.suitableFor.some(role => role.toLowerCase().includes(searchQuery.toLowerCase()));

      // Exam type filter
      const matchesExamType = filterExamType === '' || exam.examType === filterExamType;

      // Suitability filter
      const matchesSuitability = filterSuitability === '' ||
        exam.suitableFor.includes(filterSuitability);

      // Status filter
      const matchesStatus = filterStatus === '' ||
        (filterStatus === 'active' && exam.isActive) ||
        (filterStatus === 'inactive' && !exam.isActive) ||
        (filterStatus === 'ready' && exam.questions && exam.questions.length > 0) ||
        (filterStatus === 'draft' && (!exam.questions || exam.questions.length === 0));

      return matchesSearch && matchesExamType && matchesSuitability && matchesStatus;
    });

    // Sort by creation date (latest first)
    return filtered.sort((a, b) => {
      const dateA = a.createdAt instanceof Date ? a.createdAt : new Date(a.createdAt);
      const dateB = b.createdAt instanceof Date ? b.createdAt : new Date(b.createdAt);
      return dateB.getTime() - dateA.getTime();
    });
  }, [exams, searchQuery, filterExamType, filterSuitability, filterStatus]);

  // Clear all filters
  const clearFilters = () => {
    setSearchQuery('');
    setFilterExamType('');
    setFilterSuitability('');
    setFilterStatus('');
  };

  const fetchExams = async () => {
    try {
      setLoading(true);
      const querySnapshot = await getDocs(collection(db, 'exams'));
      const examsList: Exam[] = [];

      // Fetch all exams first
      querySnapshot.forEach((doc) => {
        const data = doc.data();

        // Convert Firestore Timestamps to JavaScript Date objects
        const exam: Exam = {
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate?.() || new Date(data.createdAt),
          updatedAt: data.updatedAt?.toDate?.() || new Date(data.updatedAt),
          // Convert live test date fields
          liveTestStartTime: data.liveTestStartTime?.toDate?.() || (data.liveTestStartTime ? new Date(data.liveTestStartTime) : undefined),
          liveTestEndTime: data.liveTestEndTime?.toDate?.() || (data.liveTestEndTime ? new Date(data.liveTestEndTime) : undefined),
          liveTestResultReleaseTime: data.liveTestResultReleaseTime?.toDate?.() || (data.liveTestResultReleaseTime ? new Date(data.liveTestResultReleaseTime) : undefined),
        } as Exam;

        examsList.push(exam);
      });

      // Calculate totalAttempts for each exam from quiz_attempts collection
      const examsWithAttempts = await Promise.all(
        examsList.map(async (exam) => {
          try {
            // Query quiz_attempts for this exam
            const attemptsQuery = query(
              collection(db, 'quiz_attempts'),
              where('examId', '==', exam.id)
            );
            const attemptsSnapshot = await getDocs(attemptsQuery);

            return {
              ...exam,
              totalAttempts: attemptsSnapshot.size,
            };
          } catch (error) {
            console.warn(`Error fetching attempts for exam ${exam.id}:`, error);
            return exam;
          }
        })
      );

      setExams(examsWithAttempts);
    } catch (error) {
      console.error('Error fetching exams:', error);
      toast.error('Failed to fetch exams');
    } finally {
      setLoading(false);
    }
  };

  const fetchExamTypes = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, 'examTypes'));
      const customTypes: ExamType[] = [];
      querySnapshot.forEach((doc) => {
        customTypes.push({ id: doc.id, ...doc.data() } as ExamType);
      });
      // Combine default types with custom types
      setExamTypes([...defaultExamTypes, ...customTypes]);
    } catch (error) {
      console.error('Error fetching exam types:', error);
      // Continue with default types only
    }
  };

  // Exam Type Management Functions
  const handleCreateExamType = () => {
    setEditingExamType(null);
    setExamTypeForm({
      name: '',
      icon: '📝',
    });
    setOpenExamTypeDialog(true);
  };

  const handleEditExamType = (examType: ExamType) => {
    if (examType.isDefault) {
      toast.error('Cannot edit default exam types');
      return;
    }
    setEditingExamType(examType);
    setExamTypeForm({
      name: examType.name,
      icon: examType.icon,
    });
    setOpenExamTypeDialog(true);
  };

  const handleSaveExamType = async () => {
    try {
      if (!examTypeForm.name.trim()) {
        toast.error('Please enter an exam type name');
        return;
      }

      const examTypeData = {
        name: examTypeForm.name.trim(),
        icon: examTypeForm.icon,
        isDefault: false,
        createdAt: editingExamType ? editingExamType.createdAt : Timestamp.now(),
        updatedAt: Timestamp.now(),
      };

      if (editingExamType) {
        await updateDoc(doc(db, 'examTypes', editingExamType.id), examTypeData);
        toast.success('Exam type updated successfully');
      } else {
        await addDoc(collection(db, 'examTypes'), examTypeData);
        toast.success('Exam type created successfully');
      }

      setOpenExamTypeDialog(false);
      fetchExamTypes();
    } catch (error) {
      console.error('Error saving exam type:', error);
      toast.error('Failed to save exam type');
    }
  };

  const handleDeleteExamType = async (examTypeId: string) => {
    const examType = examTypes.find(et => et.id === examTypeId);
    if (examType?.isDefault) {
      toast.error('Cannot delete default exam types');
      return;
    }

    if (window.confirm('Are you sure you want to delete this exam type? This will affect existing exams using this type.')) {
      try {
        await deleteDoc(doc(db, 'examTypes', examTypeId));
        toast.success('Exam type deleted successfully');
        fetchExamTypes();
      } catch (error) {
        console.error('Error deleting exam type:', error);
        toast.error('Failed to delete exam type');
      }
    }
  };

  // Suitability Options Management Functions
  const fetchSuitabilityOptions = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, 'suitabilityOptions'));
      const customOptions: SuitabilityOption[] = [];
      querySnapshot.forEach((doc) => {
        const data = doc.data();
        customOptions.push({
          id: doc.id,
          name: data.name,
          shortName: data.shortName,
          color: data.color,
          isDefault: false,
          order: data.order || 100,
          createdAt: data.createdAt?.toDate?.() || new Date(),
        });
      });
      // Combine default options with custom options, sorted by order
      const allOptions = [...defaultSuitabilityOptions, ...customOptions].sort((a, b) => a.order - b.order);
      setSuitabilityOptions(allOptions);
    } catch (error) {
      console.error('Error fetching suitability options:', error);
      // Continue with default options only
    }
  };

  const handleCreateSuitabilityOption = () => {
    setEditingSuitabilityOption(null);
    setSuitabilityForm({
      name: '',
      shortName: '',
      color: '#1976d2',
    });
    setOpenSuitabilityDialog(true);
  };

  const handleEditSuitabilityOption = (option: SuitabilityOption) => {
    if (option.isDefault) {
      toast.error('Cannot edit default suitability options');
      return;
    }
    setEditingSuitabilityOption(option);
    setSuitabilityForm({
      name: option.name,
      shortName: option.shortName,
      color: option.color,
    });
    setOpenSuitabilityDialog(true);
  };

  const handleSaveSuitabilityOption = async () => {
    try {
      if (!suitabilityForm.name.trim() || !suitabilityForm.shortName.trim()) {
        toast.error('Please fill in all required fields');
        return;
      }

      const maxOrder = Math.max(...suitabilityOptions.map(o => o.order), 0);
      const optionData = {
        name: suitabilityForm.name.trim(),
        shortName: suitabilityForm.shortName.trim(),
        color: suitabilityForm.color,
        isDefault: false,
        order: editingSuitabilityOption ? editingSuitabilityOption.order : maxOrder + 1,
        createdAt: editingSuitabilityOption ? editingSuitabilityOption.createdAt : Timestamp.now(),
        updatedAt: Timestamp.now(),
      };

      if (editingSuitabilityOption) {
        await updateDoc(doc(db, 'suitabilityOptions', editingSuitabilityOption.id), optionData);
        toast.success('Suitability option updated successfully');
      } else {
        await addDoc(collection(db, 'suitabilityOptions'), optionData);
        toast.success('Suitability option created successfully');
      }

      setOpenSuitabilityDialog(false);
      fetchSuitabilityOptions();
    } catch (error) {
      console.error('Error saving suitability option:', error);
      toast.error('Failed to save suitability option');
    }
  };

  const handleDeleteSuitabilityOption = async (optionId: string) => {
    const option = suitabilityOptions.find(o => o.id === optionId);
    if (option?.isDefault) {
      toast.error('Cannot delete default suitability options');
      return;
    }

    if (window.confirm('Are you sure you want to delete this suitability option? This will affect existing exams using this option.')) {
      try {
        await deleteDoc(doc(db, 'suitabilityOptions', optionId));
        toast.success('Suitability option deleted successfully');
        fetchSuitabilityOptions();
      } catch (error) {
        console.error('Error deleting suitability option:', error);
        toast.error('Failed to delete suitability option');
      }
    }
  };

  // Exam Management Functions
  const handleCreateExam = () => {
    setEditingExam(null);
    setExamForm({
      name: '',
      examType: examTypes[0]?.name || 'Postal Guide',
      numberOfQuestions: 10,
      timeLimit: 30,
      suitableFor: [],
      questions: [],
      isActive: true,
      totalAttempts: 0,
      isTrending: false,
      trendingPriority: 0,
      price: 0,
      currency: 'INR',
      isFree: true,
      freeQuestionsLimit: -1,
      unlockPrice: 0,
      topic: '',
    });

    // Reset live test form
    setCreateLiveTest(false);
    setLiveTestForm({
      title: '',
      description: '',
      startTime: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
      endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000), // Tomorrow + 2 hours
      durationMinutes: 60,
      maxParticipants: 1000,
      instructorName: '',
      difficulty: 'medium' as 'easy' | 'medium' | 'hard',
      passingScore: 60,
      showResults: true,
    });

    setOpenDialog(true);
  };

  const handleEditExam = (exam: Exam) => {
    setEditingExam(exam);

    // Debug logging
    console.log('🔵 handleEditExam - exam.isLiveTest:', exam.isLiveTest);
    console.log('🔵 handleEditExam - exam.liveTestStartTime:', exam.liveTestStartTime, typeof exam.liveTestStartTime);
    console.log('🔵 handleEditExam - exam.liveTestEndTime:', exam.liveTestEndTime, typeof exam.liveTestEndTime);
    console.log('🔵 handleEditExam - exam.liveTestResultReleaseTime:', exam.liveTestResultReleaseTime, typeof exam.liveTestResultReleaseTime);

    setExamForm({
      ...exam,
      // Ensure live test fields are initialized
      isLiveTest: exam.isLiveTest || false,
      liveTestDescription: exam.liveTestDescription || '',
      liveTestStartTime: exam.liveTestStartTime || new Date(Date.now() + 24 * 60 * 60 * 1000),
      liveTestEndTime: exam.liveTestEndTime || new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      liveTestBackgroundColor: exam.liveTestBackgroundColor || '#FF6B6B',
      liveTestCardBackgroundColor: exam.liveTestCardBackgroundColor || '#FFFFFF',
      liveTestIsPaid: exam.liveTestIsPaid || false,
      liveTestPrice: exam.liveTestPrice || 0,
      // Live test notification fields
      liveTestNotificationEnabled: exam.liveTestNotificationEnabled || false,
      liveTestNotificationTiming: exam.liveTestNotificationTiming || '24hours',
      // Live test result release fields
      liveTestResultReleaseTime: exam.liveTestResultReleaseTime || new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
    });
    setOpenDialog(true);
  };

  const handleSaveExam = async () => {
    try {
      if (!examForm.name || !examForm.examType || examForm.suitableFor?.length === 0) {
        toast.error('Please fill in all required fields');
        return;
      }

      // Debug logging
      console.log('🔴 handleSaveExam - examForm.isLiveTest:', examForm.isLiveTest);
      console.log('🔴 handleSaveExam - examForm.liveTestStartTime:', examForm.liveTestStartTime);
      console.log('🔴 handleSaveExam - examForm.liveTestEndTime:', examForm.liveTestEndTime);
      console.log('🔴 handleSaveExam - createLiveTest:', createLiveTest);
      console.log('🔴 handleSaveExam - editingExam:', editingExam?.id);

      // For new exams, sync createLiveTest state to examForm.isLiveTest
      const isLiveTestEnabled = editingExam ? examForm.isLiveTest : createLiveTest;

      // If live test is marked as paid, sync the price to exam's price field
      const finalExamData = {
        ...examForm,
        isLiveTest: isLiveTestEnabled,
        updatedAt: Timestamp.now(),
        createdAt: editingExam ? editingExam.createdAt : Timestamp.now(),
      };

      console.log('🔴 finalExamData.isLiveTest:', finalExamData.isLiveTest);
      console.log('🔴 finalExamData keys:', Object.keys(finalExamData));

      // If live test is paid, update exam's price and isFree fields
      if (isLiveTestEnabled && examForm.liveTestIsPaid && examForm.liveTestPrice) {
        finalExamData.price = examForm.liveTestPrice;
        finalExamData.isFree = false;
      }

      let examRef;
      if (editingExam) {
        await updateDoc(doc(db, 'exams', editingExam.id!), finalExamData);
        examRef = { id: editingExam.id };
        toast.success('Exam updated successfully');
      } else {
        examRef = await addDoc(collection(db, 'exams'), finalExamData);
        toast.success('Exam created successfully');
      }

      // Live test data is now stored directly in the exam document
      // No need to create/update separate live_tests collection

      setOpenDialog(false);
      fetchExams();
    } catch (error) {
      console.error('Error saving exam:', error);
      toast.error('Failed to save exam');
    }
  };

  const handleDeleteExam = async (examId: string) => {
    if (window.confirm('Are you sure you want to delete this exam?')) {
      try {
        await deleteDoc(doc(db, 'exams', examId));
        toast.success('Exam deleted successfully');
        fetchExams();
      } catch (error) {
        console.error('Error deleting exam:', error);
        toast.error('Failed to delete exam');
      }
    }
  };

  const handleManageQuestions = (exam: Exam) => {
    setCurrentExam(exam);
    // Initialize free questions selection from existing questions
    const freeQuestionIds = new Set<string>();
    exam.questions?.forEach(q => {
      if (q.isFree) {
        freeQuestionIds.add(q.id);
      }
    });
    setFreeQuestionsSelection(freeQuestionIds);
    setOpenQuestionDialog(true);
  };

  const handleAddQuestion = () => {
    if (!questionForm.question || questionForm.options?.some(opt => !opt.trim())) {
      toast.error('Please fill in all question fields');
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

    const newQuestion: Question = {
      id: Date.now().toString(),
      question: questionForm.question!,
      options: questionForm.options!,
      correctAnswer: questionForm.correctAnswer!,
      explanation: questionForm.explanation,
      difficulty: questionForm.difficulty || 'Medium',
    };

    if (currentExam) {
      const updatedQuestions = [...(currentExam.questions || []), newQuestion];
      setCurrentExam({ ...currentExam, questions: updatedQuestions });

      // Reset form
      setQuestionForm({
        question: '',
        options: ['', '', '', ''],
        correctAnswer: 0,
        explanation: '',
        difficulty: 'Medium',
      });
    }
  };

  const handleSaveQuestions = async () => {
    if (currentExam && currentExam.id) {
      try {
        // Update questions with isFree flag based on selection
        const updatedQuestions = currentExam.questions.map(q => ({
          ...q,
          isFree: freeQuestionsSelection.has(q.id),
        }));

        // Save questions to exam
        await updateDoc(doc(db, 'exams', currentExam.id), {
          questions: updatedQuestions,
          numberOfQuestions: updatedQuestions.length,
          updatedAt: Timestamp.now(),
        });

        // Also save each question individually to questions collection
        for (const question of updatedQuestions) {
          const questionData = {
            ...question,
            examId: currentExam.id,
            examName: currentExam.name,
            examType: currentExam.examType,
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          };

          // Check if question already exists in individual collection
          try {
            const existingQuestionDoc = await getDocs(
              query(collection(db, 'questions'), where('id', '==', question.id))
            );

            if (existingQuestionDoc.empty) {
              // Create new individual question
              await addDoc(collection(db, 'questions'), questionData);
            } else {
              // Update existing individual question
              const docId = existingQuestionDoc.docs[0].id;
              await updateDoc(doc(db, 'questions', docId), questionData);
            }
          } catch (error) {
            console.warn('Error syncing individual question:', error);
          }
        }

        toast.success('Questions saved successfully');
        setOpenQuestionDialog(false);
        fetchExams();
      } catch (error) {
        console.error('Error saving questions:', error);
        toast.error('Failed to save questions');
      }
    }
  };

  const handleToggleTrending = async (exam: Exam) => {
    if (!exam.id) return;

    try {
      const newTrendingStatus = !exam.isTrending;
      const newPriority = newTrendingStatus ? 1 : 0;

      await updateDoc(doc(db, 'exams', exam.id), {
        isTrending: newTrendingStatus,
        trendingPriority: newPriority,
        updatedAt: Timestamp.now(),
      });

      toast.success(
        newTrendingStatus
          ? 'Exam added to trending'
          : 'Exam removed from trending'
      );
      fetchExams();
    } catch (error) {
      console.error('Error updating trending status:', error);
      toast.error('Failed to update trending status');
    }
  };

  const handleToggleActive = async (exam: Exam) => {
    if (!exam.id) return;

    try {
      const newActiveStatus = !exam.isActive;

      await updateDoc(doc(db, 'exams', exam.id), {
        isActive: newActiveStatus,
        updatedAt: Timestamp.now(),
      });

      toast.success(
        newActiveStatus
          ? 'Exam enabled successfully'
          : 'Exam disabled successfully'
      );
      fetchExams();
    } catch (error) {
      console.error('Error toggling active status:', error);
      toast.error('Failed to update exam status');
    }
  };

  const handleOpenNotificationDialog = (exam: Exam) => {
    setSelectedExamForNotification(exam);
    setNotificationForm({
      title: `New Test: ${exam.name}`,
      body: `A new test "${exam.name}" is now available. Test it now!`,
    });
    setOpenNotificationDialog(true);
  };

  const handleCloseNotificationDialog = () => {
    setOpenNotificationDialog(false);
    setSelectedExamForNotification(null);
    setNotificationForm({
      title: '',
      body: '',
    });
  };

  const handleSendNotification = async () => {
    if (!selectedExamForNotification || !selectedExamForNotification.id || !user) {
      toast.error('Missing required information');
      return;
    }

    if (!notificationForm.title.trim() || !notificationForm.body.trim()) {
      toast.error('Please fill in both title and body');
      return;
    }

    setSendingNotification(true);
    try {
      // Create notification with all users as target
      const notificationId = await NotificationService.createNotification(
        {
          title: notificationForm.title,
          body: notificationForm.body,
          imageUrl: '',
          actionUrl: `/quiz/${selectedExamForNotification.id}/instructions`,
          actionType: 'quiz',
          testImageUrl: '',
          quizId: selectedExamForNotification.id, // Include quiz ID for direct navigation
        },
        {
          type: 'all', // Send to all users
        },
        user.uid,
        {
          priority: 'high',
          category: 'test_alert',
          deliveryMethod: 'push_only', // Send as push notification
        }
      );

      // Send the notification
      await NotificationService.sendNotification(notificationId);

      toast.success(`Notification sent to all users about "${selectedExamForNotification.name}"`);
      handleCloseNotificationDialog();
    } catch (error) {
      console.error('Error sending notification:', error);
      toast.error('Failed to send notification');
    } finally {
      setSendingNotification(false);
    }
  };

  const getExamTypeIcon = (examType: string) => {
    const type = examTypes.find(et => et.name === examType);
    return type?.icon || '📝';
  };

  const getSuitabilityColor = (role: string) => {
    const option = suitabilityOptions.find(o => o.shortName === role);
    return option?.color || '#757575';
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
            Category Management
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={tabValue === 0 ? handleCreateExam : tabValue === 1 ? handleCreateExamType : handleCreateSuitabilityOption}
          sx={{
            background: 'linear-gradient(45deg, #6366F1 30%, #8B5CF6 90%)',
            boxShadow: '0 3px 5px 2px rgba(99, 102, 241, .3)',
          }}
        >
          {tabValue === 0 ? 'Create New Exam' : tabValue === 1 ? 'Create Exam Type' : 'Create Suitability Option'}
        </Button>
      </Box>

      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)}>
          <Tab
            label="Exam Management"
            icon={<QuizIcon />}
            iconPosition="start"
          />
          <Tab
            label="Exam Types"
            icon={<CategoryIcon />}
            iconPosition="start"
          />
          <Tab
            label="Suitability Options"
            icon={<FilterIcon />}
            iconPosition="start"
          />
        </Tabs>
      </Box>

      {/* Tab Content */}
      {tabValue === 0 ? (
        // Exam Management Tab
        <>
          {/* Search and Filter Bar */}
          <Paper sx={{ p: 3, mb: 3 }}>
            <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
              <FilterIcon sx={{ mr: 1 }} />
              Search & Filters
            </Typography>
            <Grid container spacing={3}>
              {/* Search Field */}
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label="Search Exams"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search by name, type, or suitability..."
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <SearchIcon />
                      </InputAdornment>
                    ),
                    endAdornment: searchQuery && (
                      <InputAdornment position="end">
                        <IconButton
                          size="small"
                          onClick={() => setSearchQuery('')}
                          edge="end"
                        >
                          <ClearIcon />
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                />
              </Grid>

              {/* Exam Type Filter */}
              <Grid item xs={12} sm={6} md={2}>
                <FormControl fullWidth>
                  <InputLabel>Exam Type</InputLabel>
                  <Select
                    value={filterExamType}
                    label="Exam Type"
                    onChange={(e) => setFilterExamType(e.target.value)}
                  >
                    <MenuItem value="">All Types</MenuItem>
                    {examTypes.map((type) => (
                      <MenuItem key={type.id} value={type.name}>
                        {type.icon} {type.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              {/* Suitability Filter */}
              <Grid item xs={12} sm={6} md={2}>
                <FormControl fullWidth>
                  <InputLabel>Suitability</InputLabel>
                  <Select
                    value={filterSuitability}
                    label="Suitability"
                    onChange={(e) => setFilterSuitability(e.target.value)}
                  >
                    <MenuItem value="">All Roles</MenuItem>
                    {suitabilityOptions.map((option) => (
                      <MenuItem key={option.id} value={option.shortName}>
                        {option.shortName} - {option.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              {/* Status Filter */}
              <Grid item xs={12} sm={6} md={2}>
                <FormControl fullWidth>
                  <InputLabel>Status</InputLabel>
                  <Select
                    value={filterStatus}
                    label="Status"
                    onChange={(e) => setFilterStatus(e.target.value)}
                  >
                    <MenuItem value="">All Status</MenuItem>
                    <MenuItem value="active">🟢 Active</MenuItem>
                    <MenuItem value="inactive">🔴 Inactive</MenuItem>
                    <MenuItem value="ready">✅ Ready (Has Questions)</MenuItem>
                    <MenuItem value="draft">📝 Draft (No Questions)</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              {/* Clear Filters Button */}
              <Grid item xs={12} sm={6} md={2}>
                <Button
                  fullWidth
                  variant="outlined"
                  onClick={clearFilters}
                  startIcon={<ClearIcon />}
                  sx={{ height: '56px' }}
                  disabled={!searchQuery && !filterExamType && !filterSuitability && !filterStatus}
                >
                  Clear Filters
                </Button>
              </Grid>
            </Grid>

            {/* Filter Summary */}
            {(searchQuery || filterExamType || filterSuitability || filterStatus) && (
              <Box sx={{ mt: 2, pt: 2, borderTop: 1, borderColor: 'divider' }}>
                <Typography variant="body2" color="text.secondary">
                  Showing {filteredExams.length} of {exams.length} exams
                  {searchQuery && ` matching "${searchQuery}"`}
                  {filterExamType && ` • Type: ${filterExamType}`}
                  {filterSuitability && ` • Suitable for: ${filterSuitability}`}
                  {filterStatus && ` • Status: ${filterStatus}`}
                </Typography>
              </Box>
            )}
          </Paper>

          {exams.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: 'center' }}>
              <QuizIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h6" color="text.secondary" gutterBottom>
                No exams created yet
              </Typography>
              <Typography color="text.secondary" mb={3}>
                Create your first exam to get started with the quiz system
              </Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={handleCreateExam}
              >
                Create First Exam
              </Button>
            </Paper>
          ) : filteredExams.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: 'center' }}>
              <SearchIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h6" color="text.secondary" gutterBottom>
                No exams match your search criteria
              </Typography>
              <Typography color="text.secondary" mb={3}>
                Try adjusting your search terms or filters to find exams
              </Typography>
              <Button
                variant="outlined"
                onClick={clearFilters}
                startIcon={<ClearIcon />}
              >
                Clear All Filters
              </Button>
            </Paper>
          ) : (
        <Grid container spacing={3}>
          {filteredExams.map((exam) => (
            <Grid item xs={12} sm={6} md={4} key={exam.id}>
              <Card
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'all 0.3s ease-in-out',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: 4,
                  },
                }}
              >
                <CardContent sx={{ flexGrow: 1 }}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <Avatar
                      sx={{
                        bgcolor: 'primary.main',
                        mr: 2,
                        fontSize: '1.5rem',
                      }}
                    >
                      {getExamTypeIcon(exam.examType)}
                    </Avatar>
                    <Box>
                      <Typography variant="h6" component="h3" noWrap>
                        {exam.name}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {exam.examType}
                      </Typography>
                    </Box>
                  </Box>

                  <Box mb={2}>
                    <Box display="flex" alignItems="center" mb={1}>
                      <QuestionIcon sx={{ fontSize: 16, mr: 1, color: 'text.secondary' }} />
                      <Typography variant="body2">
                        {exam.questions?.length || 0} / {exam.numberOfQuestions} Questions
                      </Typography>
                    </Box>
                    <Box display="flex" alignItems="center" mb={1}>
                      <TimeIcon sx={{ fontSize: 16, mr: 1, color: 'text.secondary' }} />
                      <Typography variant="body2">
                        {exam.timeLimit} minutes
                      </Typography>
                    </Box>
                    <Box display="flex" alignItems="center">
                      <GroupIcon sx={{ fontSize: 16, mr: 1, color: 'text.secondary' }} />
                      <Typography variant="body2">
                        Suitable for: {exam.suitableFor?.join(', ')}
                      </Typography>
                    </Box>
                  </Box>

                  <Box mb={2}>
                    {exam.suitableFor?.map((role) => (
                      <Chip
                        key={role}
                        label={role}
                        size="small"
                        sx={{
                          mr: 0.5,
                          mb: 0.5,
                          bgcolor: getSuitabilityColor(role),
                          color: 'white',
                          fontSize: '0.75rem',
                        }}
                      />
                    ))}
                  </Box>

                  <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                    <Chip
                      label={exam.isActive ? 'Active' : 'Inactive'}
                      color={exam.isActive ? 'success' : 'default'}
                      size="small"
                    />
                    <Typography variant="caption" color="text.secondary">
                      {exam.questions?.length || 0} questions added
                    </Typography>
                  </Box>

                  {/* Trending and Attempts Info */}
                  <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                    <Box display="flex" alignItems="center" gap={1}>
                      {exam.isTrending && (
                        <Chip
                          icon={<TrendingIcon />}
                          label={`Trending #${exam.trendingPriority || 1}`}
                          color="warning"
                          size="small"
                          sx={{ fontSize: '0.7rem' }}
                        />
                      )}
                      {(exam.totalAttempts || 0) > 0 && (
                        adminUser?.role === 'user' ? (
                          // For 'user' role: display only, no click
                          <Chip
                            label={`${exam.totalAttempts} attempts`}
                            variant="outlined"
                            size="small"
                            sx={{ fontSize: '0.7rem' }}
                          />
                        ) : (
                          // For other roles: clickable with tooltip
                          <Tooltip title="Click to view user attempts">
                            <Chip
                              label={`${exam.totalAttempts} attempts`}
                              variant="outlined"
                              size="small"
                              onClick={() => {
                                setSelectedExamForAttempts(exam);
                                setOpenAttemptsDialog(true);
                              }}
                              sx={{
                                fontSize: '0.7rem',
                                cursor: 'pointer',
                                '&:hover': {
                                  backgroundColor: 'action.hover',
                                }
                              }}
                            />
                          </Tooltip>
                        )
                      )}
                    </Box>
                  </Box>

                  {/* Pricing and Freemium Info */}
                  <Box sx={{ p: 1, backgroundColor: '#f5f5f5', borderRadius: 1, mb: 1 }}>
                    {exam.isFree ? (
                      <Typography variant="caption" color="success.main" sx={{ fontWeight: 'bold' }}>
                        ✓ Free Quiz
                      </Typography>
                    ) : (exam.freeQuestionsLimit ?? -1) > 0 ? (
                      <Box>
                        <Typography variant="caption" sx={{ fontWeight: 'bold', color: '#ff9800' }}>
                          🎯 Freemium: {exam.freeQuestionsLimit} free questions
                        </Typography>
                        <Typography variant="caption" display="block" color="text.secondary">
                          Unlock price: ₹{exam.unlockPrice || 0}
                        </Typography>
                      </Box>
                    ) : (
                      <Typography variant="caption" color="error.main" sx={{ fontWeight: 'bold' }}>
                        💰 Paid: ₹{exam.price || 0}
                      </Typography>
                    )}
                  </Box>
                </CardContent>

                <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                  <Box>
                    <Tooltip title="Manage Questions">
                      <IconButton
                        size="small"
                        onClick={() => handleManageQuestions(exam)}
                        color="primary"
                      >
                        <QuestionIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Edit Exam">
                      <IconButton
                        size="small"
                        onClick={() => handleEditExam(exam)}
                        color="primary"
                      >
                        <EditIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title={exam.isTrending ? "Remove from Trending" : "Add to Trending"}>
                      <IconButton
                        size="small"
                        onClick={() => handleToggleTrending(exam)}
                        color={exam.isTrending ? "warning" : "default"}
                      >
                        <StarIcon />
                      </IconButton>
                    </Tooltip>
                  </Box>
                  <Box display="flex" gap={1}>
                    <Tooltip title="Send Notification">
                      <IconButton
                        size="small"
                        onClick={() => handleOpenNotificationDialog(exam)}
                        color="info"
                      >
                        <NotificationsIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title={exam.isActive ? "Disable Exam" : "Enable Exam"}>
                      <IconButton
                        size="small"
                        onClick={() => handleToggleActive(exam)}
                        color={exam.isActive ? "success" : "warning"}
                      >
                        {exam.isActive ? <ToggleOnIcon /> : <ToggleOffIcon />}
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Delete Exam">
                      <IconButton
                        size="small"
                        onClick={() => handleDeleteExam(exam.id!)}
                        color="error"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Tooltip>
                  </Box>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
          )}
        </>
      ) : tabValue === 1 ? (
        // Exam Types Management Tab
        <Grid container spacing={3}>
          {examTypes.map((examType) => (
            <Grid item xs={12} sm={6} md={4} key={examType.id}>
              <Card
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'all 0.3s ease-in-out',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: 4,
                  },
                }}
              >
                <CardContent sx={{ flexGrow: 1 }}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <Avatar
                      sx={{
                        bgcolor: examType.isDefault ? 'primary.main' : 'secondary.main',
                        mr: 2,
                        fontSize: '1.5rem',
                      }}
                    >
                      {examType.icon}
                    </Avatar>
                    <Box>
                      <Typography variant="h6" component="h3">
                        {examType.name}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {examType.isDefault ? 'Default Type' : 'Custom Type'}
                      </Typography>
                    </Box>
                  </Box>

                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Chip
                      label={examType.isDefault ? 'System Default' : 'Custom'}
                      color={examType.isDefault ? 'primary' : 'secondary'}
                      size="small"
                    />
                    <Typography variant="caption" color="text.secondary">
                      {exams.filter(exam => exam.examType === examType.name).length} exams
                    </Typography>
                  </Box>
                </CardContent>

                <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                  <Box>
                    {!examType.isDefault && (
                      <Tooltip title="Edit Exam Type">
                        <IconButton
                          size="small"
                          onClick={() => handleEditExamType(examType)}
                          color="primary"
                        >
                          <EditIcon />
                        </IconButton>
                      </Tooltip>
                    )}
                  </Box>
                  {!examType.isDefault && (
                    <Tooltip title="Delete Exam Type">
                      <IconButton
                        size="small"
                        onClick={() => handleDeleteExamType(examType.id)}
                        color="error"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Tooltip>
                  )}
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
      ) : tabValue === 2 ? (
        // Suitability Options Management Tab
        <Grid container spacing={3}>
          {suitabilityOptions.map((option) => (
            <Grid item xs={12} sm={6} md={4} key={option.id}>
              <Card
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'all 0.3s ease-in-out',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: 4,
                  },
                }}
              >
                <CardContent sx={{ flexGrow: 1 }}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <Avatar
                      sx={{
                        bgcolor: option.color,
                        mr: 2,
                        fontSize: '0.9rem',
                        fontWeight: 'bold',
                      }}
                    >
                      {option.shortName.substring(0, 2)}
                    </Avatar>
                    <Box>
                      <Typography variant="h6" component="h3">
                        {option.name}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Short: {option.shortName}
                      </Typography>
                    </Box>
                  </Box>

                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Chip
                      label={option.isDefault ? 'System Default' : 'Custom'}
                      color={option.isDefault ? 'primary' : 'secondary'}
                      size="small"
                    />
                    <Box
                      sx={{
                        width: 24,
                        height: 24,
                        borderRadius: '50%',
                        bgcolor: option.color,
                        border: '2px solid #e0e0e0',
                      }}
                    />
                  </Box>
                </CardContent>

                <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                  <Box>
                    {!option.isDefault && (
                      <Tooltip title="Edit Suitability Option">
                        <IconButton
                          size="small"
                          onClick={() => handleEditSuitabilityOption(option)}
                          color="primary"
                        >
                          <EditIcon />
                        </IconButton>
                      </Tooltip>
                    )}
                  </Box>
                  {!option.isDefault && (
                    <Tooltip title="Delete Suitability Option">
                      <IconButton
                        size="small"
                        onClick={() => handleDeleteSuitabilityOption(option.id)}
                        color="error"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Tooltip>
                  )}
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
      ) : null}

      {/* Create/Edit Exam Dialog */}
      <Dialog
        open={openDialog}
        onClose={() => setOpenDialog(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          {editingExam ? 'Edit Exam' : 'Create New Exam'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2 }}>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Exam Type</InputLabel>
                  <Select
                    value={examForm.examType}
                    label="Exam Type"
                    onChange={(e) => setExamForm({ ...examForm, examType: e.target.value })}
                  >
                    {examTypes.map((examType) => (
                      <MenuItem key={examType.id} value={examType.name}>
                        {examType.icon} {examType.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Exam Name"
                  value={examForm.name}
                  onChange={(e) => setExamForm({ ...examForm, name: e.target.value })}
                  placeholder={`Enter ${examForm.examType} exam name`}
                  required
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Topic"
                  value={examForm.topic || ''}
                  onChange={(e) => setExamForm({ ...examForm, topic: e.target.value })}
                  placeholder="Enter exam topic (e.g., Mathematics, Science)"
                  helperText="Optional: Topic will be displayed on the quiz instruction page"
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  type="number"
                  label="Number of Questions"
                  value={examForm.numberOfQuestions}
                  onChange={(e) => setExamForm({ ...examForm, numberOfQuestions: parseInt(e.target.value) })}
                  inputProps={{ min: 1, max: 100 }}
                  required
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  type="number"
                  label="Time Limit (minutes)"
                  value={examForm.timeLimit}
                  onChange={(e) => setExamForm({ ...examForm, timeLimit: parseInt(e.target.value) })}
                  inputProps={{ min: 5, max: 180 }}
                  required
                />
              </Grid>

              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Exam Suitable For</InputLabel>
                  <Select
                    multiple
                    value={examForm.suitableFor || []}
                    label="Exam Suitable For"
                    onChange={(e) => setExamForm({ ...examForm, suitableFor: e.target.value as string[] })}
                    renderValue={(selected) => (
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {(selected as string[]).map((value) => (
                          <Chip
                            key={value}
                            label={value}
                            size="small"
                            sx={{
                              bgcolor: getSuitabilityColor(value),
                              color: 'white',
                            }}
                          />
                        ))}
                      </Box>
                    )}
                  >
                    {suitabilityOptions.map((option) => (
                      <MenuItem key={option.id} value={option.shortName}>
                        <Box display="flex" alignItems="center">
                          <Chip
                            label={option.shortName}
                            size="small"
                            sx={{
                              bgcolor: option.color,
                              color: 'white',
                              mr: 1,
                            }}
                          />
                          {option.name}
                        </Box>
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
                        checked={examForm.isFree || false}
                        onChange={(e) => setExamForm({ ...examForm, isFree: e.target.checked, price: e.target.checked ? 0 : examForm.price || 0 })}
                        color="primary"
                      />
                    }
                    label={
                      <Box>
                        <Typography variant="subtitle2" fontWeight="bold">
                          💰 Pricing Configuration
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {examForm.isFree ? 'This exam will be free for all users' : 'This exam requires payment to access'}
                        </Typography>
                      </Box>
                    }
                  />

                  {!examForm.isFree && (
                    <Box sx={{ mt: 2 }}>
                      <Grid container spacing={2}>
                        <Grid item xs={12} sm={6}>
                          <TextField
                            fullWidth
                            type="number"
                            label="Price"
                            value={examForm.price || 0}
                            onChange={(e) => setExamForm({ ...examForm, price: parseFloat(e.target.value) || 0 })}
                            inputProps={{ min: 0, step: 0.01 }}
                            size="small"
                            required={!examForm.isFree}
                          />
                        </Grid>
                        <Grid item xs={12} sm={6}>
                          <FormControl fullWidth size="small">
                            <InputLabel>Currency</InputLabel>
                            <Select
                              value={examForm.currency || 'INR'}
                              label="Currency"
                              onChange={(e) => setExamForm({ ...examForm, currency: e.target.value })}
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
                        value={examForm.freeQuestionsLimit ?? -1}
                        onChange={(e) => setExamForm({ ...examForm, freeQuestionsLimit: parseInt(e.target.value) })}
                        inputProps={{ min: -1 }}
                        size="small"
                        helperText="0 = Fully Paid | -1 = Fully Free | >0 = Freemium (e.g., 5)"
                      />
                    </Grid>

                    {(examForm.freeQuestionsLimit ?? -1) > 0 && (
                      <Grid item xs={12} sm={6}>
                        <TextField
                          fullWidth
                          type="number"
                          label="Unlock Price"
                          value={examForm.unlockPrice ?? 0}
                          onChange={(e) => setExamForm({ ...examForm, unlockPrice: parseFloat(e.target.value) || 0 })}
                          inputProps={{ min: 0, step: 0.01 }}
                          size="small"
                          helperText="Price to unlock remaining questions"
                        />
                      </Grid>
                    )}
                  </Grid>

                  {(examForm.freeQuestionsLimit ?? -1) > 0 && (
                    <Box sx={{ mt: 2, p: 1.5, backgroundColor: '#e3f2fd', borderRadius: 1 }}>
                      <Typography variant="caption" color="primary">
                        ℹ️ Users can attempt {examForm.freeQuestionsLimit} questions for free, then pay ₹{examForm.unlockPrice || 0} to unlock the remaining {Math.max(0, (examForm.numberOfQuestions || 0) - (examForm.freeQuestionsLimit || 0))} questions.
                      </Typography>
                    </Box>
                  )}
                </Box>
              </Grid>

              {/* Live Test Option - Show for both new and existing exams */}
              <Grid item xs={12}>
                <Box sx={{ p: 2, border: '1px solid #e0e0e0', borderRadius: 1, backgroundColor: '#f8f9fa' }}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={editingExam ? (examForm.isLiveTest || false) : createLiveTest}
                        onChange={(e) => {
                          if (editingExam) {
                            setExamForm({ ...examForm, isLiveTest: e.target.checked });
                          } else {
                            setCreateLiveTest(e.target.checked);
                          }
                        }}
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

                    {((editingExam && examForm.isLiveTest) || (!editingExam && createLiveTest)) && (
                      <Box sx={{ mt: 2 }}>
                        <Grid container spacing={2}>
                          <Grid item xs={12} sm={6}>
                            <TextField
                              fullWidth
                              label="Live Test Title"
                              value={editingExam ? (examForm.name || '') : liveTestForm.title}
                              onChange={(e) => {
                                if (editingExam) {
                                  setExamForm({ ...examForm, name: e.target.value });
                                } else {
                                  setLiveTestForm({ ...liveTestForm, title: e.target.value });
                                }
                              }}
                              placeholder={examForm.name || 'Enter title'}
                              size="small"
                            />
                          </Grid>
                          <Grid item xs={12} sm={6}>
                            <TextField
                              fullWidth
                              label="Instructor Name"
                              value={editingExam ? '' : liveTestForm.instructorName}
                              onChange={(e) => {
                                if (!editingExam) {
                                  setLiveTestForm({ ...liveTestForm, instructorName: e.target.value });
                                }
                              }}
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
                              value={editingExam ? (examForm.liveTestDescription || '') : liveTestForm.description}
                              onChange={(e) => {
                                if (editingExam) {
                                  setExamForm({ ...examForm, liveTestDescription: e.target.value });
                                } else {
                                  setLiveTestForm({ ...liveTestForm, description: e.target.value });
                                }
                              }}
                              placeholder={`Live test for ${examForm.name || 'this exam'}`}
                              size="small"
                            />
                          </Grid>
                          <Grid item xs={12} sm={6}>
                            <TextField
                              fullWidth
                              type="datetime-local"
                              label="Start Time"
                              value={editingExam
                                ? safeToISOString(examForm.liveTestStartTime)
                                : safeToISOString(liveTestForm.startTime)}
                              onChange={(e) => {
                                if (editingExam) {
                                  setExamForm({ ...examForm, liveTestStartTime: new Date(e.target.value) });
                                } else {
                                  setLiveTestForm({ ...liveTestForm, startTime: new Date(e.target.value) });
                                }
                              }}
                              size="small"
                              InputLabelProps={{ shrink: true }}
                            />
                          </Grid>
                          <Grid item xs={12} sm={6}>
                            <TextField
                              fullWidth
                              type="datetime-local"
                              label="End Time"
                              value={editingExam
                                ? safeToISOString(examForm.liveTestEndTime)
                                : safeToISOString(liveTestForm.endTime)}
                              onChange={(e) => {
                                if (editingExam) {
                                  setExamForm({ ...examForm, liveTestEndTime: new Date(e.target.value) });
                                } else {
                                  setLiveTestForm({ ...liveTestForm, endTime: new Date(e.target.value) });
                                }
                              }}
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

                          {/* Banner Background Color */}
                          <Grid item xs={12} sm={6}>
                            <TextField
                              fullWidth
                              label="Banner Background Color"
                              type="color"
                              value={editingExam ? (examForm.liveTestBackgroundColor || '#FF6B6B') : '#FF6B6B'}
                              onChange={(e) => {
                                if (editingExam) {
                                  setExamForm({ ...examForm, liveTestBackgroundColor: e.target.value });
                                }
                              }}
                              InputLabelProps={{ shrink: true }}
                              size="small"
                            />
                          </Grid>

                          {/* Card Background Color */}
                          <Grid item xs={12} sm={6}>
                            <TextField
                              fullWidth
                              label="Card Background Color"
                              type="color"
                              value={editingExam ? (examForm.liveTestCardBackgroundColor || '#FFFFFF') : '#FFFFFF'}
                              onChange={(e) => {
                                if (editingExam) {
                                  setExamForm({ ...examForm, liveTestCardBackgroundColor: e.target.value });
                                }
                              }}
                              InputLabelProps={{ shrink: true }}
                              size="small"
                            />
                          </Grid>

                          {/* Paid Test Configuration */}
                          <Grid item xs={12} sm={6}>
                            <FormControlLabel
                              control={
                                <Switch
                                  checked={editingExam ? (examForm.liveTestIsPaid || false) : false}
                                  onChange={(e) => {
                                    if (editingExam) {
                                      setExamForm({ ...examForm, liveTestIsPaid: e.target.checked });
                                    }
                                  }}
                                  color="primary"
                                />
                              }
                              label="Paid Test"
                            />
                          </Grid>

                          {/* Price Field - Show only when test is paid */}
                          {(editingExam && examForm.liveTestIsPaid) && (
                            <Grid item xs={12} sm={6}>
                              <TextField
                                fullWidth
                                type="number"
                                label="Price (₹)"
                                value={examForm.liveTestPrice || 0}
                                onChange={(e) => setExamForm({ ...examForm, liveTestPrice: parseFloat(e.target.value) || 0 })}
                                inputProps={{ step: '0.01', min: '0' }}
                                size="small"
                              />
                            </Grid>
                          )}

                          {/* Notification Configuration */}
                          <Grid item xs={12}>
                            <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
                              📢 Notification Settings
                            </Typography>
                          </Grid>

                          <Grid item xs={12} sm={6}>
                            <FormControlLabel
                              control={
                                <Switch
                                  checked={editingExam ? (examForm.liveTestNotificationEnabled || false) : false}
                                  onChange={(e) => {
                                    if (editingExam) {
                                      setExamForm({ ...examForm, liveTestNotificationEnabled: e.target.checked });
                                    }
                                  }}
                                  color="primary"
                                />
                              }
                              label="Send Notification"
                            />
                          </Grid>

                          {/* Notification Timing - Show only when notifications are enabled */}
                          {(editingExam && examForm.liveTestNotificationEnabled) && (
                            <Grid item xs={12} sm={6}>
                              <FormControl fullWidth size="small">
                                <InputLabel>Notification Timing</InputLabel>
                                <Select
                                  value={examForm.liveTestNotificationTiming || '24hours'}
                                  onChange={(e) => setExamForm({ ...examForm, liveTestNotificationTiming: e.target.value as 'immediate' | '1hour' | '24hours' })}
                                  label="Notification Timing"
                                >
                                  <MenuItem value="immediate">Immediately upon scheduling</MenuItem>
                                  <MenuItem value="1hour">1 hour before start time</MenuItem>
                                  <MenuItem value="24hours">24 hours before start time</MenuItem>
                                </Select>
                              </FormControl>
                            </Grid>
                          )}

                          {/* Result Release Configuration */}
                          <Grid item xs={12}>
                            <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, mt: 2 }}>
                              📊 Result Release Settings
                            </Typography>
                          </Grid>

                          <Grid item xs={12}>
                            <TextField
                              fullWidth
                              type="datetime-local"
                              label="Result Release Time"
                              value={editingExam
                                ? safeToISOString(examForm.liveTestResultReleaseTime)
                                : safeToISOString(new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000))}
                              onChange={(e) => {
                                if (editingExam) {
                                  setExamForm({ ...examForm, liveTestResultReleaseTime: new Date(e.target.value) });
                                }
                              }}
                              size="small"
                              InputLabelProps={{ shrink: true }}
                              helperText="Results will be hidden until this time. Users who attended can view results after this time."
                            />
                          </Grid>
                        </Grid>
                      </Box>
                    )}
                  </Box>
                </Grid>

              <Grid item xs={12}>
                <Alert severity="info">
                  <Typography variant="body2">
                    After creating the exam, you can add questions using the "Manage Questions" button.
                    The exam will appear in the mobile app's featured quizzes once questions are added.
                  </Typography>
                </Alert>
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)} startIcon={<CancelIcon />}>
            Cancel
          </Button>
          <Button
            onClick={handleSaveExam}
            variant="contained"
            startIcon={<SaveIcon />}
          >
            {editingExam ? 'Update Exam' : 'Create Exam'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Question Management Dialog */}
      <Dialog
        open={openQuestionDialog}
        onClose={() => setOpenQuestionDialog(false)}
        maxWidth="lg"
        fullWidth
      >
        <DialogTitle>
          Manage Questions - {currentExam?.name}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2 }}>
            <Grid container spacing={3}>
              {/* Add New Question Form */}
              <Grid item xs={12} md={6}>
                <Paper sx={{ p: 3, mb: 3 }}>
                  <Typography variant="h6" gutterBottom>
                    Add New Question
                  </Typography>

                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    label="Question"
                    value={questionForm.question}
                    onChange={(e) => setQuestionForm({ ...questionForm, question: e.target.value })}
                    sx={{ mb: 2 }}
                  />

                  {questionForm.options?.map((option, index) => (
                    <TextField
                      key={index}
                      fullWidth
                      label={`Option ${index + 1}`}
                      value={option}
                      onChange={(e) => {
                        const newOptions = [...(questionForm.options || [])];
                        newOptions[index] = e.target.value;
                        setQuestionForm({ ...questionForm, options: newOptions });
                      }}
                      sx={{ mb: 2 }}
                    />
                  ))}

                  <FormControl fullWidth sx={{ mb: 2 }}>
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

                  <TextField
                    fullWidth
                    multiline
                    rows={2}
                    label="Explanation (Optional)"
                    value={questionForm.explanation}
                    onChange={(e) => setQuestionForm({ ...questionForm, explanation: e.target.value })}
                    sx={{ mb: 2 }}
                  />

                  <FormControl fullWidth sx={{ mb: 2 }}>
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

                  <Button
                    fullWidth
                    variant="contained"
                    onClick={handleAddQuestion}
                    startIcon={<AddIcon />}
                  >
                    Add Question
                  </Button>
                </Paper>
              </Grid>

              {/* Questions List */}
              <Grid item xs={12} md={6}>
                <Paper sx={{ p: 3 }}>
                  <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                    <Box>
                      <Typography variant="h6">
                        Questions ({currentExam?.questions?.length || 0})
                      </Typography>
                      {examForm.freeQuestionsLimit && examForm.freeQuestionsLimit > 0 && (
                        <Box>
                          <Typography
                            variant="caption"
                            sx={{
                              display: 'block',
                              mt: 0.5,
                              color: freeQuestionsSelection.size === examForm.freeQuestionsLimit ? 'success.main' : 'warning.main',
                              fontWeight: 'bold'
                            }}
                          >
                            {freeQuestionsSelection.size === examForm.freeQuestionsLimit
                              ? `✓ ${freeQuestionsSelection.size}/${examForm.freeQuestionsLimit} free questions selected`
                              : `⚠️ Select ${examForm.freeQuestionsLimit} questions as free (${freeQuestionsSelection.size} selected)`
                            }
                          </Typography>
                        </Box>
                      )}
                    </Box>
                    <FormControl size="small" sx={{ minWidth: 120 }}>
                      <InputLabel>Filter</InputLabel>
                      <Select
                        value={questionFilter}
                        label="Filter"
                        onChange={(e) => setQuestionFilter(e.target.value)}
                      >
                        <MenuItem value="">All</MenuItem>
                        <MenuItem value="Easy">🟢 Easy</MenuItem>
                        <MenuItem value="Medium">🟡 Medium</MenuItem>
                        <MenuItem value="Hard">🔴 Hard</MenuItem>
                      </Select>
                    </FormControl>
                  </Box>

                  {currentExam?.questions?.length === 0 ? (
                    <Box textAlign="center" py={4}>
                      <QuestionIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
                      <Typography color="text.secondary">
                        No questions added yet
                      </Typography>
                    </Box>
                  ) : (
                    <List sx={{ maxHeight: 400, overflow: 'auto' }}>
                      {currentExam?.questions
                        ?.filter(question => !questionFilter || (question.difficulty || 'Medium') === questionFilter)
                        ?.map((question, index) => (
                        <React.Fragment key={question.id}>
                          <ListItem alignItems="flex-start">
                            {examForm.freeQuestionsLimit && examForm.freeQuestionsLimit > 0 && (
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
                                sx={{ mr: 1 }}
                              />
                            )}
                            <ListItemText
                              primary={
                                <Box display="flex" justifyContent="space-between" alignItems="center">
                                  <Typography variant="subtitle2">
                                    Q{index + 1}: {question.question}
                                  </Typography>
                                  <Box display="flex" gap={1} alignItems="center">
                                    {freeQuestionsSelection.has(question.id) && (
                                      <Chip
                                        label="FREE"
                                        size="small"
                                        color="success"
                                        variant="outlined"
                                      />
                                    )}
                                    <Chip
                                      label={question.difficulty || 'Medium'}
                                      size="small"
                                      color={
                                        (question.difficulty || 'Medium') === 'Easy' ? 'success' :
                                        (question.difficulty || 'Medium') === 'Medium' ? 'warning' : 'error'
                                      }
                                    />
                                  </Box>
                                </Box>
                              }
                              secondary={
                                <Box>
                                  {question.options.map((option, optIndex) => (
                                    <Typography
                                      key={optIndex}
                                      variant="body2"
                                      color={optIndex === question.correctAnswer ? 'success.main' : 'text.secondary'}
                                      sx={{ fontWeight: optIndex === question.correctAnswer ? 'bold' : 'normal' }}
                                    >
                                      {optIndex + 1}. {option}
                                      {optIndex === question.correctAnswer && ' ✓'}
                                    </Typography>
                                  ))}
                                  {question.explanation && (
                                    <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                                      Explanation: {question.explanation}
                                    </Typography>
                                  )}
                                </Box>
                              }
                            />
                            <ListItemSecondaryAction>
                              <IconButton
                                edge="end"
                                onClick={() => {
                                  if (currentExam) {
                                    const updatedQuestions = currentExam.questions.filter(q => q.id !== question.id);
                                    setCurrentExam({ ...currentExam, questions: updatedQuestions });
                                  }
                                }}
                                color="error"
                                size="small"
                              >
                                <DeleteIcon />
                              </IconButton>
                            </ListItemSecondaryAction>
                          </ListItem>
                          {index < (currentExam?.questions?.length || 0) - 1 && <Divider />}
                        </React.Fragment>
                      ))}
                    </List>
                  )}
                </Paper>
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenQuestionDialog(false)} startIcon={<CancelIcon />}>
            Cancel
          </Button>
          <Tooltip
            title={
              examForm.freeQuestionsLimit && examForm.freeQuestionsLimit > 0
                ? freeQuestionsSelection.size !== examForm.freeQuestionsLimit
                  ? `Please select exactly ${examForm.freeQuestionsLimit} questions as free`
                  : ''
                : ''
            }
          >
            <span>
              <Button
                onClick={handleSaveQuestions}
                variant="contained"
                startIcon={<SaveIcon />}
                disabled={
                  !currentExam?.questions?.length ||
                  (examForm.freeQuestionsLimit && examForm.freeQuestionsLimit > 0
                    ? freeQuestionsSelection.size !== examForm.freeQuestionsLimit
                    : false)
                }
              >
                Save Questions
              </Button>
            </span>
          </Tooltip>
        </DialogActions>
      </Dialog>

      {/* Exam Type Create/Edit Dialog */}
      <Dialog
        open={openExamTypeDialog}
        onClose={() => setOpenExamTypeDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          {editingExamType ? 'Edit Exam Type' : 'Create New Exam Type'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2 }}>
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Exam Type Name"
                  value={examTypeForm.name}
                  onChange={(e) => setExamTypeForm({ ...examTypeForm, name: e.target.value })}
                  placeholder="e.g., Railway Exam, Banking Exam, etc."
                  required
                />
              </Grid>

              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Icon</InputLabel>
                  <Select
                    value={examTypeForm.icon}
                    label="Icon"
                    onChange={(e) => setExamTypeForm({ ...examTypeForm, icon: e.target.value })}
                  >
                    <MenuItem value="📝">📝 General</MenuItem>
                    <MenuItem value="📮">📮 Postal</MenuItem>
                    <MenuItem value="📚">📚 Books/Study</MenuItem>
                    <MenuItem value="🚂">🚂 Railway</MenuItem>
                    <MenuItem value="🏦">🏦 Banking</MenuItem>
                    <MenuItem value="👮">👮 Police</MenuItem>
                    <MenuItem value="⚖️">⚖️ Legal</MenuItem>
                    <MenuItem value="🏥">🏥 Medical</MenuItem>
                    <MenuItem value="🎓">🎓 Academic</MenuItem>
                    <MenuItem value="💼">💼 Corporate</MenuItem>
                    <MenuItem value="🔬">🔬 Science</MenuItem>
                    <MenuItem value="💻">💻 Technology</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <Alert severity="info">
                  <Typography variant="body2">
                    Custom exam types allow you to create specialized categories for different types of exams.
                    Once created, this type will be available when creating new exams.
                  </Typography>
                </Alert>
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenExamTypeDialog(false)} startIcon={<CancelIcon />}>
            Cancel
          </Button>
          <Button
            onClick={handleSaveExamType}
            variant="contained"
            startIcon={<SaveIcon />}
          >
            {editingExamType ? 'Update Type' : 'Create Type'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Suitability Option Create/Edit Dialog */}
      <Dialog
        open={openSuitabilityDialog}
        onClose={() => setOpenSuitabilityDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          {editingSuitabilityOption ? 'Edit Suitability Option' : 'Create New Suitability Option'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2 }}>
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Full Name"
                  value={suitabilityForm.name}
                  onChange={(e) => setSuitabilityForm({ ...suitabilityForm, name: e.target.value })}
                  placeholder="e.g., Multi Tasking Staff, Postal Assistant, etc."
                  required
                />
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Short Name"
                  value={suitabilityForm.shortName}
                  onChange={(e) => setSuitabilityForm({ ...suitabilityForm, shortName: e.target.value })}
                  placeholder="e.g., MTS, PA, IP, etc."
                  required
                  helperText="This will be displayed in dropdowns and chips"
                />
              </Grid>

              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Color</InputLabel>
                  <Select
                    value={suitabilityForm.color}
                    label="Color"
                    onChange={(e) => setSuitabilityForm({ ...suitabilityForm, color: e.target.value })}
                  >
                    <MenuItem value="#1976d2">
                      <Box display="flex" alignItems="center">
                        <Box sx={{ width: 20, height: 20, borderRadius: '50%', bgcolor: '#1976d2', mr: 1 }} />
                        Blue
                      </Box>
                    </MenuItem>
                    <MenuItem value="#388e3c">
                      <Box display="flex" alignItems="center">
                        <Box sx={{ width: 20, height: 20, borderRadius: '50%', bgcolor: '#388e3c', mr: 1 }} />
                        Green
                      </Box>
                    </MenuItem>
                    <MenuItem value="#f57c00">
                      <Box display="flex" alignItems="center">
                        <Box sx={{ width: 20, height: 20, borderRadius: '50%', bgcolor: '#f57c00', mr: 1 }} />
                        Orange
                      </Box>
                    </MenuItem>
                    <MenuItem value="#7b1fa2">
                      <Box display="flex" alignItems="center">
                        <Box sx={{ width: 20, height: 20, borderRadius: '50%', bgcolor: '#7b1fa2', mr: 1 }} />
                        Purple
                      </Box>
                    </MenuItem>
                    <MenuItem value="#d32f2f">
                      <Box display="flex" alignItems="center">
                        <Box sx={{ width: 20, height: 20, borderRadius: '50%', bgcolor: '#d32f2f', mr: 1 }} />
                        Red
                      </Box>
                    </MenuItem>
                    <MenuItem value="#0288d1">
                      <Box display="flex" alignItems="center">
                        <Box sx={{ width: 20, height: 20, borderRadius: '50%', bgcolor: '#0288d1', mr: 1 }} />
                        Light Blue
                      </Box>
                    </MenuItem>
                    <MenuItem value="#00796b">
                      <Box display="flex" alignItems="center">
                        <Box sx={{ width: 20, height: 20, borderRadius: '50%', bgcolor: '#00796b', mr: 1 }} />
                        Teal
                      </Box>
                    </MenuItem>
                    <MenuItem value="#5d4037">
                      <Box display="flex" alignItems="center">
                        <Box sx={{ width: 20, height: 20, borderRadius: '50%', bgcolor: '#5d4037', mr: 1 }} />
                        Brown
                      </Box>
                    </MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <Alert severity="info">
                  <Typography variant="body2">
                    Suitability options help categorize exams by the target audience (e.g., MTS, Postman, PA).
                    These options will appear in dropdown filters in both web admin and mobile app.
                  </Typography>
                </Alert>
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenSuitabilityDialog(false)} startIcon={<CancelIcon />}>
            Cancel
          </Button>
          <Button
            onClick={handleSaveSuitabilityOption}
            variant="contained"
            startIcon={<SaveIcon />}
          >
            {editingSuitabilityOption ? 'Update Option' : 'Create Option'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Send Notification Dialog */}
      <Dialog
        open={openNotificationDialog}
        onClose={handleCloseNotificationDialog}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          Send Notification - {selectedExamForNotification?.name}
        </DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <TextField
              fullWidth
              label="Notification Title"
              value={notificationForm.title}
              onChange={(e) =>
                setNotificationForm({ ...notificationForm, title: e.target.value })
              }
              placeholder="e.g., New Test: SSC CGL 2024"
              multiline
              rows={2}
            />
            <TextField
              fullWidth
              label="Notification Body"
              value={notificationForm.body}
              onChange={(e) =>
                setNotificationForm({ ...notificationForm, body: e.target.value })
              }
              placeholder="e.g., A new test is now available. Test it now!"
              multiline
              rows={3}
            />
            <Alert severity="info">
              <Typography variant="body2">
                This notification will be sent to <strong>all users</strong> with a direct link to the quiz instruction page.
              </Typography>
            </Alert>
            <Alert severity="success">
              <Typography variant="body2">
                When users tap the notification, they will be taken directly to the quiz instruction page where they can start the test.
              </Typography>
            </Alert>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={handleCloseNotificationDialog}
            disabled={sendingNotification}
          >
            Cancel
          </Button>
          <Button
            onClick={handleSendNotification}
            variant="contained"
            color="primary"
            disabled={sendingNotification}
            startIcon={sendingNotification ? <CircularProgress size={20} /> : <NotificationsIcon />}
          >
            {sendingNotification ? 'Sending...' : 'Send Notification'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Exam Attempts Dialog */}
      <ExamAttemptsDialog
        open={openAttemptsDialog}
        examId={selectedExamForAttempts?.id || ''}
        examName={selectedExamForAttempts?.name || ''}
        onClose={() => {
          setOpenAttemptsDialog(false);
          setSelectedExamForAttempts(null);
        }}
      />
    </Box>
  );
};

export default CategoriesPage;
