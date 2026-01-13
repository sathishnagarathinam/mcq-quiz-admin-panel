import { Timestamp } from 'firebase/firestore';

// Base interface for all exam hub items
export interface BaseExamHubItem {
  id: string;
  title: string;
  description: string;
  content?: string; // Optional rich text content
  isActive: boolean;
  priority: number; // For ordering items
  createdBy: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  tags: string[];
  viewCount: number;
  downloadCount?: number; // For items with downloadable content
}

// File attachment interface
export interface FileAttachment {
  id: string;
  name: string;
  originalName: string;
  url: string;
  size: number;
  type: string; // MIME type
  uploadedAt: Timestamp;
}

// News interface
export interface ExamHubNews extends BaseExamHubItem {
  category: 'general' | 'exam_notification' | 'result_announcement' | 'important_update';
  publishDate: Timestamp;
  expiryDate?: Timestamp; // Optional expiry for time-sensitive news
  imageUrl?: string; // Optional featured image
  attachments: FileAttachment[]; // PDF attachments
  isBreaking: boolean; // For urgent/breaking news
  targetAudience: string[]; // e.g., ['MTS', 'POSTMAN', 'ALL']
}

// Tips and Shortcuts interface
export interface ExamHubTips extends BaseExamHubItem {
  category: 'study_tips' | 'exam_strategy' | 'time_management' | 'shortcuts' | 'memory_techniques';
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  estimatedReadTime: number; // in minutes
  attachments: FileAttachment[]; // PDF guides, cheat sheets
  relatedExamTypes: string[]; // e.g., ['MTS', 'POSTMAN', 'IPO']
  isVideoContent: boolean;
  videoUrl?: string; // Optional video link
}

// Previous Year Papers interface
export interface ExamHubPapers extends BaseExamHubItem {
  examType: 'MTS' | 'POSTMAN' | 'POSTAL_ASSISTANT' | 'IPO' | 'GROUP_B' | 'OTHER';
  examYear: number;
  examDate: Timestamp;
  paperType: 'question_paper' | 'answer_key' | 'solution' | 'analysis';
  subject?: string; // Optional subject classification
  duration: number; // Exam duration in minutes
  totalMarks: number;
  totalQuestions: number;
  attachments: FileAttachment[]; // PDF files
  language: string[]; // e.g., ['English', 'Hindi']
  isOfficial: boolean; // Official vs unofficial papers
}

// Results interface
export interface ExamHubResults extends BaseExamHubItem {
  examType: 'MTS' | 'POSTMAN' | 'POSTAL_ASSISTANT' | 'IPO' | 'GROUP_B' | 'OTHER';
  examYear: number;
  resultType: 'final_result' | 'merit_list' | 'cutoff_marks' | 'answer_key' | 'provisional_result';
  publishDate: Timestamp;
  examDate: Timestamp;
  totalCandidates?: number;
  selectedCandidates?: number;
  cutoffMarks?: {
    general: number;
    obc: number;
    sc: number;
    st: number;
    pwd: number;
  };
  attachments: FileAttachment[]; // PDF result files
  isOfficial: boolean;
  resultUrl?: string; // External result link
}

// Form data interfaces for creating/editing
export interface NewsFormData {
  title: string;
  description: string;
  content: string;
  category: ExamHubNews['category'];
  publishDate: Date;
  expiryDate?: Date;
  isBreaking: boolean;
  targetAudience: string[];
  tags: string[];
  priority: number;
  isActive: boolean;
}

export interface TipsFormData {
  title: string;
  description: string;
  content: string;
  category: ExamHubTips['category'];
  difficulty: ExamHubTips['difficulty'];
  estimatedReadTime: number;
  relatedExamTypes: string[];
  isVideoContent: boolean;
  videoUrl?: string;
  tags: string[];
  priority: number;
  isActive: boolean;
}

export interface PapersFormData {
  title: string;
  description: string;
  examType: ExamHubPapers['examType'];
  examYear: number;
  examDate: Date;
  paperType: ExamHubPapers['paperType'];
  subject?: string;
  duration: number;
  totalMarks: number;
  totalQuestions: number;
  language: string[];
  isOfficial: boolean;
  tags: string[];
  priority: number;
  isActive: boolean;
}

export interface ResultsFormData {
  title: string;
  description: string;
  examType: ExamHubResults['examType'];
  examYear: number;
  resultType: ExamHubResults['resultType'];
  publishDate: Date;
  examDate: Date;
  totalCandidates?: number;
  selectedCandidates?: number;
  cutoffMarks?: ExamHubResults['cutoffMarks'];
  isOfficial: boolean;
  resultUrl?: string;
  tags: string[];
  priority: number;
  isActive: boolean;
}

// Upload progress interface
export interface UploadProgress {
  fileName: string;
  progress: number;
  status: 'preparing' | 'compressing' | 'uploading' | 'completed' | 'error';
  error?: string;
}

// Filter and search interfaces
export interface ExamHubFilters {
  category?: string;
  examType?: string;
  year?: number;
  isActive?: boolean;
  tags?: string[];
  dateRange?: {
    start: Date;
    end: Date;
  };
}

export interface ExamHubSearchParams {
  query?: string;
  filters?: ExamHubFilters;
  sortBy?: 'createdAt' | 'updatedAt' | 'priority' | 'viewCount' | 'publishDate' | 'examDate';
  sortOrder?: 'asc' | 'desc';
  limit?: number;
  offset?: number;
}

// Constants for dropdowns and validation
export const EXAM_TYPES = [
  'MTS',
  'POSTMAN', 
  'POSTAL_ASSISTANT',
  'IPO',
  'GROUP_B',
  'OTHER'
] as const;

export const NEWS_CATEGORIES = [
  'general',
  'exam_notification',
  'result_announcement',
  'important_update'
] as const;

export const TIPS_CATEGORIES = [
  'study_tips',
  'exam_strategy',
  'time_management',
  'shortcuts',
  'memory_techniques'
] as const;

export const PAPER_TYPES = [
  'question_paper',
  'answer_key',
  'solution',
  'analysis'
] as const;

export const RESULT_TYPES = [
  'final_result',
  'merit_list',
  'cutoff_marks',
  'answer_key',
  'provisional_result'
] as const;

export const DIFFICULTY_LEVELS = [
  'beginner',
  'intermediate',
  'advanced'
] as const;

export const LANGUAGES = [
  'English',
  'Hindi',
  'Bengali',
  'Tamil',
  'Telugu',
  'Marathi',
  'Gujarati',
  'Kannada',
  'Malayalam',
  'Punjabi',
  'Urdu'
] as const;
