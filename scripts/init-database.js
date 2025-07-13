#!/usr/bin/env node

/**
 * MCQ Quiz System - Database Initialization Script
 * This script initializes the Firestore database with sample data
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✓ ${message}`, 'green');
}

function logError(message) {
  log(`✗ ${message}`, 'red');
}

function logInfo(message) {
  log(`ℹ ${message}`, 'blue');
}

function logWarning(message) {
  log(`⚠ ${message}`, 'yellow');
}

// Initialize Firebase Admin
function initializeFirebase() {
  try {
    // Try to find service account key
    const serviceAccountPaths = [
      './firebase-adminsdk.json',
      './serviceAccountKey.json',
      '../firebase/firebase-adminsdk.json'
    ];
    
    let serviceAccountPath = null;
    for (const path of serviceAccountPaths) {
      if (fs.existsSync(path)) {
        serviceAccountPath = path;
        break;
      }
    }
    
    if (serviceAccountPath) {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      logSuccess('Firebase Admin initialized with service account');
    } else {
      // Try to initialize with default credentials
      admin.initializeApp();
      logSuccess('Firebase Admin initialized with default credentials');
    }
    
    return admin.firestore();
  } catch (error) {
    logError('Failed to initialize Firebase Admin');
    logError(error.message);
    process.exit(1);
  }
}

// Sample categories data
const categories = [
  {
    id: 'volumes',
    name: 'Volumes',
    description: 'Volume-based questions for postal calculations and measurements',
    iconUrl: 'volumes_icon.png',
    bannerUrl: 'volumes_banner.jpg',
    color: '#6366F1',
    isActive: true,
    order: 1,
    subCategories: [
      { id: 'basic_volumes', name: 'Basic Volume Calculations', description: 'Fundamental volume problems' },
      { id: 'advanced_volumes', name: 'Advanced Volume Problems', description: 'Complex volume calculations' }
    ]
  },
  {
    id: 'po_guide',
    name: 'PO Guide',
    description: 'Post Office operational guidelines, procedures, and regulations',
    iconUrl: 'po_guide_icon.png',
    bannerUrl: 'po_guide_banner.jpg',
    color: '#8B5CF6',
    isActive: true,
    order: 2,
    subCategories: [
      { id: 'postal_operations', name: 'Postal Operations', description: 'Day-to-day postal operations' },
      { id: 'regulations', name: 'Rules & Regulations', description: 'Postal rules and guidelines' }
    ]
  },
  {
    id: 'general_knowledge',
    name: 'General Knowledge',
    description: 'General awareness, current affairs, and basic knowledge',
    iconUrl: 'gk_icon.png',
    bannerUrl: 'gk_banner.jpg',
    color: '#06B6D4',
    isActive: true,
    order: 3,
    subCategories: [
      { id: 'current_affairs', name: 'Current Affairs', description: 'Recent events and news' },
      { id: 'basic_gk', name: 'Basic GK', description: 'Fundamental general knowledge' }
    ]
  },
  {
    id: 'previous_papers',
    name: 'Previous Year Papers',
    description: 'Previous year question papers and their solutions',
    iconUrl: 'previous_papers_icon.png',
    bannerUrl: 'previous_papers_banner.jpg',
    color: '#10B981',
    isActive: true,
    order: 4,
    subCategories: [
      { id: 'mts_papers', name: 'MTS Papers', description: 'Multi Tasking Staff previous papers' },
      { id: 'postman_papers', name: 'Postman Papers', description: 'Postman previous papers' }
    ]
  }
];

// Sample questions data
const questions = [
  {
    question: 'What is the full form of PIN in PIN Code?',
    options: [
      { id: 'A', text: 'Postal Index Number', isCorrect: true },
      { id: 'B', text: 'Personal Identification Number', isCorrect: false },
      { id: 'C', text: 'Post Information Number', isCorrect: false },
      { id: 'D', text: 'Postal Information Network', isCorrect: false }
    ],
    correctAnswer: 'A',
    explanation: 'PIN stands for Postal Index Number, which is a 6-digit code used to identify postal areas in India.',
    category: 'po_guide',
    subCategory: 'postal_operations',
    examPattern: 'POSTMAN',
    difficulty: 'easy',
    tags: ['postal_code', 'basic'],
    timeLimit: 60,
    isActive: true
  },
  {
    question: 'Who is the current Prime Minister of India?',
    options: [
      { id: 'A', text: 'Narendra Modi', isCorrect: true },
      { id: 'B', text: 'Rahul Gandhi', isCorrect: false },
      { id: 'C', text: 'Amit Shah', isCorrect: false },
      { id: 'D', text: 'Manmohan Singh', isCorrect: false }
    ],
    correctAnswer: 'A',
    explanation: 'Narendra Modi has been serving as the Prime Minister of India since 2014.',
    category: 'general_knowledge',
    subCategory: 'current_affairs',
    examPattern: 'MTS',
    difficulty: 'easy',
    tags: ['politics', 'current_affairs'],
    timeLimit: 45,
    isActive: true
  },
  {
    question: 'Calculate the volume of a cube with side length 5 cm.',
    options: [
      { id: 'A', text: '125 cm³', isCorrect: true },
      { id: 'B', text: '25 cm³', isCorrect: false },
      { id: 'C', text: '75 cm³', isCorrect: false },
      { id: 'D', text: '100 cm³', isCorrect: false }
    ],
    correctAnswer: 'A',
    explanation: 'Volume of a cube = side³ = 5³ = 125 cm³',
    category: 'volumes',
    subCategory: 'basic_volumes',
    examPattern: 'POSTAL_ASSISTANT',
    difficulty: 'medium',
    tags: ['geometry', 'calculation'],
    timeLimit: 90,
    isActive: true
  },
  {
    question: 'What is the capital of France?',
    options: [
      { id: 'A', text: 'London', isCorrect: false },
      { id: 'B', text: 'Berlin', isCorrect: false },
      { id: 'C', text: 'Paris', isCorrect: true },
      { id: 'D', text: 'Madrid', isCorrect: false }
    ],
    correctAnswer: 'C',
    explanation: 'Paris is the capital and largest city of France.',
    category: 'general_knowledge',
    subCategory: 'basic_gk',
    examPattern: 'IPO',
    difficulty: 'easy',
    tags: ['geography', 'world_capitals'],
    timeLimit: 30,
    isActive: true
  },
  {
    question: 'Which year was the Indian Postal Service established?',
    options: [
      { id: 'A', text: '1854', isCorrect: true },
      { id: 'B', text: '1857', isCorrect: false },
      { id: 'C', text: '1860', isCorrect: false },
      { id: 'D', text: '1865', isCorrect: false }
    ],
    correctAnswer: 'A',
    explanation: 'The Indian Postal Service was established in 1854 during British rule.',
    category: 'po_guide',
    subCategory: 'postal_operations',
    examPattern: 'GROUP_B',
    difficulty: 'medium',
    tags: ['postal_history', 'important_dates'],
    timeLimit: 60,
    isActive: true
  }
];

// App settings
const appSettings = [
  {
    id: 'quiz_settings',
    key: 'default_quiz_questions',
    value: 10,
    description: 'Default number of questions in a quiz',
    isPublic: true
  },
  {
    id: 'time_settings',
    key: 'default_question_time',
    value: 60,
    description: 'Default time per question in seconds',
    isPublic: true
  },
  {
    id: 'scoring_settings',
    key: 'correct_answer_points',
    value: 4,
    description: 'Points awarded for correct answer',
    isPublic: true
  },
  {
    id: 'penalty_settings',
    key: 'wrong_answer_penalty',
    value: -1,
    description: 'Points deducted for wrong answer',
    isPublic: true
  }
];

// Add categories to Firestore
async function addCategories(db) {
  logInfo('Adding categories...');
  
  for (const category of categories) {
    try {
      await db.collection('categories').doc(category.id).set({
        ...category,
        questionCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      logSuccess(`Added category: ${category.name}`);
    } catch (error) {
      logError(`Failed to add category ${category.name}: ${error.message}`);
    }
  }
}

// Add questions to Firestore
async function addQuestions(db) {
  logInfo('Adding sample questions...');
  
  for (const question of questions) {
    try {
      await db.collection('questions').add({
        ...question,
        stats: {
          totalAttempts: 0,
          correctAttempts: 0,
          averageTime: 0
        },
        createdBy: 'system',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      logSuccess(`Added question: ${question.question.substring(0, 50)}...`);
      
      // Update category question count
      await db.collection('categories').doc(question.category).update({
        questionCount: admin.firestore.FieldValue.increment(1)
      });
    } catch (error) {
      logError(`Failed to add question: ${error.message}`);
    }
  }
}

// Add app settings
async function addAppSettings(db) {
  logInfo('Adding app settings...');
  
  for (const setting of appSettings) {
    try {
      await db.collection('app_settings').doc(setting.id).set({
        ...setting,
        updatedBy: 'system',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      logSuccess(`Added setting: ${setting.key}`);
    } catch (error) {
      logError(`Failed to add setting ${setting.key}: ${error.message}`);
    }
  }
}

// Create daily challenge
async function createDailyChallenge(db) {
  logInfo('Creating today\'s daily challenge...');
  
  try {
    const today = new Date().toISOString().split('T')[0];
    const challengeId = `challenge_${today}`;
    
    // Get some random question IDs
    const questionsSnapshot = await db.collection('questions').limit(5).get();
    const questionIds = questionsSnapshot.docs.map(doc => doc.id);
    
    if (questionIds.length >= 5) {
      await db.collection('daily_challenges').doc(challengeId).set({
        id: challengeId,
        date: today,
        title: `Daily Challenge - ${new Date().toLocaleDateString('en-US', { weekday: 'long' })}`,
        description: 'Test your knowledge with today\'s mixed challenge',
        questionIds: questionIds.slice(0, 5),
        category: 'mixed',
        difficulty: 'medium',
        timeLimit: 300,
        isActive: true,
        participants: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
      });
      logSuccess('Daily challenge created');
    } else {
      logWarning('Not enough questions to create daily challenge');
    }
  } catch (error) {
    logError(`Failed to create daily challenge: ${error.message}`);
  }
}

// Main initialization function
async function initializeDatabase() {
  log('\n🚀 MCQ Quiz System - Database Initialization', 'cyan');
  log('===========================================', 'cyan');
  
  const db = initializeFirebase();
  
  try {
    await addCategories(db);
    await addQuestions(db);
    await addAppSettings(db);
    await createDailyChallenge(db);
    
    log('\n🎉 Database initialization completed successfully!', 'green');
    log('===============================================', 'green');
    
    logInfo('Next steps:');
    console.log('1. Create an admin user by signing up in the app');
    console.log('2. Update the user role to "master_admin" in Firestore');
    console.log('3. Add more questions using the web admin panel');
    console.log('4. Test the quiz functionality');
    
  } catch (error) {
    logError('Database initialization failed');
    logError(error.message);
    process.exit(1);
  }
}

// Run the initialization
if (require.main === module) {
  initializeDatabase();
}

module.exports = { initializeDatabase };
