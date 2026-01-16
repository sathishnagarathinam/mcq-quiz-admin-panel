// Shared Constants for MCQ Quiz System

// User Roles
export const USER_ROLES = {
  USER: 'user',
  ADMIN: 'admin',
  MASTER_ADMIN: 'master_admin'
};

// Exam Patterns
export const EXAM_PATTERNS = {
  MTS: 'MTS',
  POSTMAN: 'POSTMAN',
  POSTAL_ASSISTANT: 'POSTAL_ASSISTANT',
  IPO: 'IPO',
  GROUP_B: 'GROUP_B'
};

// Question Difficulties
export const DIFFICULTY_LEVELS = {
  EASY: 'easy',
  MEDIUM: 'medium',
  HARD: 'hard'
};

// Quiz Status
export const QUIZ_STATUS = {
  NOT_STARTED: 'not_started',
  STARTED: 'started',
  PAUSED: 'paused',
  COMPLETED: 'completed',
  ABANDONED: 'abandoned'
};

// Security Event Types
export const SECURITY_EVENTS = {
  SCREENSHOT_ATTEMPT: 'screenshot_attempt',
  APP_SWITCH: 'app_switch',
  SCREEN_LOCK: 'screen_lock',
  COPY_ATTEMPT: 'copy_attempt',
  BACKGROUND_APP: 'background_app'
};

// Default Categories
export const DEFAULT_CATEGORIES = [
  {
    id: 'volumes',
    name: 'Volumes',
    description: 'Volume-based questions for postal calculations',
    color: '#6366F1',
    iconUrl: 'volumes_icon.png'
  },
  {
    id: 'po_guide',
    name: 'PO Guide',
    description: 'Post Office operational guidelines and procedures',
    color: '#8B5CF6',
    iconUrl: 'po_guide_icon.png'
  },
  {
    id: 'general_knowledge',
    name: 'General Knowledge',
    description: 'General awareness and current affairs',
    color: '#06B6D4',
    iconUrl: 'gk_icon.png'
  },
  {
    id: 'previous_papers',
    name: 'Previous Year Papers',
    description: 'Previous year question papers and solutions',
    color: '#10B981',
    iconUrl: 'previous_papers_icon.png'
  }
];

// Time Limits (in seconds)
export const TIME_LIMITS = {
  DEFAULT_QUESTION: 60,
  EASY_QUESTION: 45,
  MEDIUM_QUESTION: 60,
  HARD_QUESTION: 90,
  DAILY_CHALLENGE: 300,
  FULL_QUIZ: 1800 // 30 minutes
};

// Scoring System
export const SCORING = {
  CORRECT_ANSWER: 4,
  WRONG_ANSWER: -1,
  UNANSWERED: 0,
  TIME_BONUS_THRESHOLD: 30, // seconds
  TIME_BONUS_POINTS: 1
};

// Leaderboard Periods
export const LEADERBOARD_PERIODS = {
  DAILY: 'daily',
  WEEKLY: 'weekly',
  MONTHLY: 'monthly',
  ALL_TIME: 'all_time'
};

// Badge Types
export const BADGE_TYPES = {
  STREAK_MASTER: 'streak_master',
  SPEED_DEMON: 'speed_demon',
  PERFECTIONIST: 'perfectionist',
  KNOWLEDGE_SEEKER: 'knowledge_seeker',
  DAILY_WARRIOR: 'daily_warrior',
  CATEGORY_EXPERT: 'category_expert'
};

// Notification Types
export const NOTIFICATION_TYPES = {
  DAILY_CHALLENGE: 'daily_challenge',
  NEW_QUIZ: 'new_quiz',
  ACHIEVEMENT: 'achievement',
  REMINDER: 'reminder',
  SYSTEM: 'system'
};

// App Themes
export const THEMES = {
  LIGHT: 'light',
  DARK: 'dark',
  SYSTEM: 'system'
};

// Languages
export const LANGUAGES = {
  ENGLISH: 'en',
  HINDI: 'hi'
};

// API Endpoints (for web admin)
export const API_ENDPOINTS = {
  USERS: '/api/users',
  QUESTIONS: '/api/questions',
  CATEGORIES: '/api/categories',
  QUIZ_SESSIONS: '/api/quiz-sessions',
  QUIZ_RESULTS: '/api/quiz-results',
  ANALYTICS: '/api/analytics',
  LEADERBOARD: '/api/leaderboard',
  BULK_UPLOAD: '/api/bulk-upload',
  EXPORT: '/api/export'
};

// File Upload Limits
export const UPLOAD_LIMITS = {
  MAX_FILE_SIZE: 5 * 1024 * 1024, // 5MB
  ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/webp'],
  ALLOWED_DOCUMENT_TYPES: ['application/vnd.ms-excel', 'text/csv', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
  MAX_BULK_QUESTIONS: 1000
};

// Validation Rules
export const VALIDATION = {
  MIN_PASSWORD_LENGTH: 8,
  MAX_QUESTION_LENGTH: 500,
  MAX_OPTION_LENGTH: 200,
  MAX_EXPLANATION_LENGTH: 1000,
  MIN_QUIZ_QUESTIONS: 5,
  MAX_QUIZ_QUESTIONS: 50,
  MAX_CATEGORY_NAME_LENGTH: 50
};

// Error Messages
export const ERROR_MESSAGES = {
  NETWORK_ERROR: 'Network error. Please check your connection.',
  UNAUTHORIZED: 'You are not authorized to perform this action.',
  INVALID_CREDENTIALS: 'Invalid email or password.',
  USER_NOT_FOUND: 'User not found.',
  QUIZ_NOT_FOUND: 'Quiz not found.',
  QUESTION_NOT_FOUND: 'Question not found.',
  CATEGORY_NOT_FOUND: 'Category not found.',
  FILE_TOO_LARGE: 'File size exceeds the maximum limit.',
  INVALID_FILE_TYPE: 'Invalid file type.',
  QUIZ_ALREADY_COMPLETED: 'Quiz has already been completed.',
  QUIZ_TIME_EXPIRED: 'Quiz time has expired.',
  SECURITY_VIOLATION: 'Security violation detected. Quiz terminated.'
};

// Success Messages
export const SUCCESS_MESSAGES = {
  QUIZ_COMPLETED: 'Quiz completed successfully!',
  QUESTION_SAVED: 'Question saved successfully!',
  CATEGORY_SAVED: 'Category saved successfully!',
  USER_UPDATED: 'User profile updated successfully!',
  BULK_UPLOAD_SUCCESS: 'Questions uploaded successfully!',
  EXPORT_SUCCESS: 'Data exported successfully!'
};

// Color Palette
export const COLORS = {
  PRIMARY: '#6366F1',
  SECONDARY: '#8B5CF6',
  SUCCESS: '#10B981',
  WARNING: '#F59E0B',
  ERROR: '#EF4444',
  INFO: '#06B6D4',
  LIGHT: '#F8FAFC',
  DARK: '#1E293B',
  GRAY: '#64748B'
};

// Animation Durations (in milliseconds)
export const ANIMATIONS = {
  FAST: 200,
  NORMAL: 300,
  SLOW: 500,
  EXTRA_SLOW: 1000
};

// Local Storage Keys
export const STORAGE_KEYS = {
  USER_TOKEN: 'mcq_user_token',
  USER_PREFERENCES: 'mcq_user_preferences',
  QUIZ_DRAFT: 'mcq_quiz_draft',
  THEME: 'mcq_theme',
  LANGUAGE: 'mcq_language'
};
