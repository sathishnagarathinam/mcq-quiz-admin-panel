import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Alert,
  Button,
} from '@mui/material';
import { ArrowBack } from '@mui/icons-material';
import { collection, addDoc, getDocs, Timestamp, updateDoc, doc } from 'firebase/firestore';
import { db } from '../../config/firebase';
import toast from 'react-hot-toast';
import BulkUploadCard from '../../components/questions/BulkUploadCard';
import { useNavigate } from 'react-router-dom';

interface Question {
  id: string;
  question: string;
  options: string[];
  correctAnswer: number;
  explanation?: string;
  difficulty: 'Easy' | 'Medium' | 'Hard';
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

const BulkUploadPage: React.FC = () => {
  const navigate = useNavigate();
  const [examTypes, setExamTypes] = useState<ExamType[]>(defaultExamTypes);

  useEffect(() => {
    fetchExamTypes();
  }, []);

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

  const handleBulkUploadComplete = async (data: BulkUploadData) => {
    try {
      // Validation
      if (!data.examName || !data.examType || data.suitableFor.length === 0) {
        toast.error('Please fill in all exam configuration fields');
        return;
      }

      if (data.questions.length === 0) {
        toast.error('No questions found to upload');
        return;
      }

      // Check for duplicate exam name
      const existingExams = await getDocs(collection(db, 'exams'));
      const duplicateExam = existingExams.docs.find(doc =>
        doc.data().name.toLowerCase() === data.examName.toLowerCase()
      );

      if (duplicateExam) {
        toast.error(`An exam with the name "${data.examName}" already exists. Please choose a different name.`);
        return;
      }

      // Helper function to remove undefined values from an object (including nested)
      const removeUndefinedFields = <T extends Record<string, unknown>>(obj: T): T => {
        const result = { ...obj };
        Object.keys(result).forEach(key => {
          if (result[key] === undefined) {
            delete result[key];
          }
        });
        return result;
      };

      // Sanitize questions to remove undefined fields (like explanation: undefined)
      const sanitizedQuestions = data.questions.map(question => removeUndefinedFields({
        id: question.id,
        question: question.question,
        options: question.options,
        correctAnswer: question.correctAnswer,
        difficulty: question.difficulty,
        explanation: question.explanation,
        isFree: (question as Question & { isFree?: boolean }).isFree,
      }));

      // Create the exam with questions
      const examData = {
        name: data.examName,
        examType: data.examType,
        numberOfQuestions: data.questions.length,
        timeLimit: data.timeLimit,
        suitableFor: data.suitableFor,
        questions: sanitizedQuestions,
        price: data.isFree ? 0 : data.price,
        currency: data.currency,
        isFree: data.isFree,
        freeQuestionsLimit: data.freeQuestionsLimit ?? -1,
        unlockPrice: data.unlockPrice ?? 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        isActive: true,
      };

      // Remove undefined fields from examData to prevent Firestore errors
      Object.keys(examData).forEach(key =>
        examData[key as keyof typeof examData] === undefined && delete examData[key as keyof typeof examData]
      );

      // Save exam to Firestore
      const examRef = await addDoc(collection(db, 'exams'), examData);

      // Also save each question individually to questions collection
      const questionPromises = data.questions.map(question => {
        const questionData = {
          ...question,
          examId: examRef.id,
          examName: data.examName,
          examType: data.examType,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        };

        // Remove undefined fields to prevent Firestore errors
        Object.keys(questionData).forEach(key =>
          questionData[key as keyof typeof questionData] === undefined && delete questionData[key as keyof typeof questionData]
        );

        return addDoc(collection(db, 'questions'), questionData);
      });

      await Promise.all(questionPromises);

      // Create live test if option is selected
      if (data.createLiveTest && data.liveTestData) {
        try {
          // Update exam document with live test fields
          await updateDoc(doc(db, 'exams', examRef.id), {
            isLiveTest: true,
            liveTestStartTime: Timestamp.fromDate(data.liveTestData.startTime),
            liveTestEndTime: Timestamp.fromDate(data.liveTestData.endTime),
            liveTestIsPaid: false,
            liveTestPrice: 0,
            liveTestBackgroundColor: '#FF6B6B',
          });

          toast.success(
            `🎉 Successfully created exam "${data.examName}" with ${data.questions.length} questions and scheduled live test! ` +
            `The exam is now available in the Categories section and mobile app.`
          );
        } catch (error) {
          console.error('Error scheduling live test:', error);
          toast.success(
            `🎉 Successfully created exam "${data.examName}" with ${data.questions.length} questions! ` +
            `The exam is now available in the Categories section and mobile app. However, failed to schedule live test.`
          );
        }
      } else {
        toast.success(
          `🎉 Successfully created exam "${data.examName}" with ${data.questions.length} questions! ` +
          `The exam is now available in the Categories section and mobile app.`
        );
      }

    } catch (error) {
      console.error('Error creating exam from bulk upload:', error);
      toast.error('Failed to create exam. Please try again.');
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <Button
          variant="outlined"
          startIcon={<ArrowBack />}
          onClick={() => navigate('/dashboard')}
          sx={{ minWidth: 'auto' }}
        >
          Back to Dashboard
        </Button>
        <Typography variant="h4" component="h1">
          Bulk Upload Questions
        </Typography>
      </Box>

      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Upload multiple questions via CSV file and automatically create a new exam with comprehensive configuration options.
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} lg={8}>
          <BulkUploadCard
            onUploadComplete={handleBulkUploadComplete}
            examTypes={examTypes}
          />
        </Grid>

        <Grid item xs={12} lg={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                📋 CSV Format Guide
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Your CSV file should include these columns:
              </Typography>
              <Box component="ul" sx={{ pl: 2, mb: 2 }}>
                <Typography component="li" variant="body2">
                  <strong>question</strong> - The question text
                </Typography>
                <Typography component="li" variant="body2">
                  <strong>option1, option2, option3, option4</strong> - Answer choices
                </Typography>
                <Typography component="li" variant="body2">
                  <strong>correct</strong> - Correct answer number (1-4)
                </Typography>
                <Typography component="li" variant="body2">
                  <strong>difficulty</strong> - Easy, Medium, or Hard (optional)
                </Typography>
                <Typography component="li" variant="body2">
                  <strong>explanation</strong> - Answer explanation (optional)
                </Typography>
              </Box>

              <Alert severity="info" sx={{ mt: 2 }}>
                <Typography variant="body2">
                  <strong>Example CSV format:</strong>
                </Typography>
                <Box component="pre" sx={{ fontSize: '0.75rem', mt: 1, overflow: 'auto' }}>
{`question,option1,option2,option3,option4,correct,difficulty,explanation
"What is 2+2?","3","4","5","6",2,"Easy","Basic arithmetic"
"Capital of India?","Mumbai","Delhi","Kolkata","Chennai",2,"Medium","Delhi is the capital"`}
                </Box>
              </Alert>

              <Alert severity="info" sx={{ mt: 2 }}>
                <Typography variant="body2" fontWeight="bold" gutterBottom>
                  📚 Available Exam Types:
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                  {examTypes.map((type) => (
                    <Box key={type.id} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Typography sx={{ fontSize: '1rem' }}>{type.icon}</Typography>
                      <Typography variant="body2">{type.name}</Typography>
                      {type.isDefault && (
                        <Typography variant="caption" color="primary.main">
                          (Default)
                        </Typography>
                      )}
                    </Box>
                  ))}
                </Box>
              </Alert>

              <Alert severity="success" sx={{ mt: 2 }}>
                <Typography variant="body2">
                  The system will automatically create a new exam with your uploaded questions and the configuration you specify.
                  You can also schedule it as a live test for all users.
                </Typography>
              </Alert>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default BulkUploadPage;
