#!/usr/bin/env node

/**
 * Direct Demo Account Creation Script for Google Play Review
 * This script creates the demo account directly using Firebase Client SDK
 */

const { initializeApp } = require('firebase/app');
const { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword, updateProfile } = require('firebase/auth');
const { getFirestore, doc, setDoc, serverTimestamp, getDoc } = require('firebase/firestore');

// Firebase configuration (from mobile app)
const firebaseConfig = {
  apiKey: "AIzaSyDIdFTL8Xl-E02bYB_HnuymfGBRRL6xBqk",
  authDomain: "mcq-quiz-system.firebaseapp.com",
  projectId: "mcq-quiz-system",
  storageBucket: "mcq-quiz-system.firebasestorage.app",
  messagingSenderId: "109048215498",
  appId: "1:109048215498:web:398b38704a2b075fb08133"
};

// Demo account credentials
const DEMO_ACCOUNT = {
  email: 'googleplay.demo@dakshinpostalacademy.com',
  password: 'GooglePlay2024!',
  name: 'Google Play Reviewer',
  phoneNumber: '+919876543210',
  officeName: 'Demo Post Office',
  designation: 'Inspector'
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

async function createDemoAccount() {
  console.log('🎯 Creating Google Play Demo Account...');
  console.log('📧 Email:', DEMO_ACCOUNT.email);
  console.log('🔑 Password:', DEMO_ACCOUNT.password);
  
  try {
    let user = null;
    
    // First, try to sign in to check if account exists
    try {
      console.log('🔍 Checking if demo account already exists...');
      const signInResult = await signInWithEmailAndPassword(auth, DEMO_ACCOUNT.email, DEMO_ACCOUNT.password);
      user = signInResult.user;
      console.log('✅ Demo account already exists, updating data...');
    } catch (signInError) {
      if (signInError.code === 'auth/user-not-found' || signInError.code === 'auth/wrong-password' || signInError.code === 'auth/invalid-credential') {
        console.log('📝 Demo account not found, creating new account...');
        
        // Create new user
        const createResult = await createUserWithEmailAndPassword(auth, DEMO_ACCOUNT.email, DEMO_ACCOUNT.password);
        user = createResult.user;
        console.log('✅ Created new Firebase Auth user:', user.uid);
        
        // Update profile
        await updateProfile(user, {
          displayName: DEMO_ACCOUNT.name
        });
        console.log('✅ Updated user profile');
      } else {
        throw signInError;
      }
    }

    if (!user) {
      throw new Error('Failed to create or retrieve user');
    }

    // Create comprehensive user document for mobile_users collection
    const userDoc = {
      uid: user.uid,
      email: DEMO_ACCOUNT.email,
      name: DEMO_ACCOUNT.name,
      phoneNumber: DEMO_ACCOUNT.phoneNumber,
      officeName: DEMO_ACCOUNT.officeName,
      designation: DEMO_ACCOUNT.designation,
      userType: 'mobile_user',
      role: 'user',
      isActive: true,
      emailVerified: true,
      profileComplete: true,
      
      // Quiz statistics for demo
      quizzesTaken: 15,
      totalScore: 1250,
      averageScore: 83.3,
      
      // Enhanced stats for better demo experience
      stats: {
        totalQuizzes: 15,
        totalScore: 1250,
        averageScore: 83.3,
        currentStreak: 5,
        longestStreak: 12,
        totalTimeSpent: 7200, // 2 hours in seconds
      },
      
      // User preferences
      preferences: {
        notifications: true,
        darkMode: false,
        language: 'en',
        easyMode: false, // Start in expert mode to show all features
      },
      
      // Device info (demo account bypasses device binding)
      registeredDeviceId: 'demo_device_bypass',
      deviceInfo: { demo: true, type: 'demo_account' },
      isDeviceBound: true,
      
      // FCM token (will be set when user logs in)
      fcmToken: null,
      
      // Timestamps
      createdAt: serverTimestamp(),
      lastLoginAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    // Update mobile_users collection
    await setDoc(doc(db, 'mobile_users', user.uid), userDoc, { merge: true });
    console.log('✅ Created/Updated Firestore document in mobile_users collection');
    
    // Also update users collection for compatibility
    await setDoc(doc(db, 'users', user.uid), userDoc, { merge: true });
    console.log('✅ Created/Updated Firestore document in users collection');

    // Create some sample quiz attempts
    await createSampleQuizAttempts(user.uid);

    console.log('\n🎉 Google Play Demo Account Created Successfully!');
    
  } catch (error) {
    console.error('❌ Error creating demo account:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

async function createSampleQuizAttempts(uid) {
  console.log('📊 Creating sample quiz attempts for demo...');
  
  const sampleAttempts = [
    {
      examId: 'sample_exam_1',
      examTitle: 'Postal Rules and Regulations',
      score: 85,
      totalQuestions: 20,
      correctAnswers: 17,
      timeSpent: 1200, // 20 minutes
      completedAt: new Date(Date.now() - 86400000), // 1 day ago
    },
    {
      examId: 'sample_exam_2', 
      examTitle: 'General Knowledge',
      score: 90,
      totalQuestions: 25,
      correctAnswers: 22,
      timeSpent: 1500, // 25 minutes
      completedAt: new Date(Date.now() - 172800000), // 2 days ago
    },
    {
      examId: 'sample_exam_3',
      examTitle: 'Mathematics',
      score: 75,
      totalQuestions: 30,
      correctAnswers: 22,
      timeSpent: 1800, // 30 minutes
      completedAt: new Date(Date.now() - 259200000), // 3 days ago
    }
  ];

  for (let i = 0; i < sampleAttempts.length; i++) {
    const attempt = sampleAttempts[i];
    const attemptDoc = {
      userId: uid,
      ...attempt,
      createdAt: serverTimestamp(),
    };
    
    await setDoc(doc(db, 'quiz_attempts', `demo_attempt_${i + 1}`), attemptDoc);
  }
  
  console.log(`✅ Created ${sampleAttempts.length} sample quiz attempts`);
}

async function testDemoAccount() {
  console.log('\n🧪 Testing demo account login...');
  
  try {
    const signInResult = await signInWithEmailAndPassword(auth, DEMO_ACCOUNT.email, DEMO_ACCOUNT.password);
    console.log('✅ Demo account login test successful!');
    console.log('👤 User ID:', signInResult.user.uid);
    console.log('📧 Email:', signInResult.user.email);
    console.log('👤 Display Name:', signInResult.user.displayName);
    
    // Check if Firestore document exists
    const userDocRef = doc(db, 'mobile_users', signInResult.user.uid);
    const userDocSnap = await getDoc(userDocRef);
    
    if (userDocSnap.exists()) {
      console.log('✅ Firestore document exists');
      const userData = userDocSnap.data();
      console.log('📊 Quiz Stats:', {
        quizzesTaken: userData.quizzesTaken,
        totalScore: userData.totalScore,
        averageScore: userData.averageScore
      });
    } else {
      console.log('❌ Firestore document missing');
    }
    
  } catch (error) {
    console.error('❌ Demo account login test failed:', error.message);
    throw error;
  }
}

// Main execution
async function main() {
  try {
    await createDemoAccount();
    await testDemoAccount();
    
    console.log('\n🎯 GOOGLE PLAY DEMO ACCOUNT READY!');
    console.log('==========================================');
    console.log(`📧 Email: ${DEMO_ACCOUNT.email}`);
    console.log(`🔑 Password: ${DEMO_ACCOUNT.password}`);
    console.log(`👤 Name: ${DEMO_ACCOUNT.name}`);
    console.log(`📱 Phone: ${DEMO_ACCOUNT.phoneNumber}`);
    console.log(`🏢 Office: ${DEMO_ACCOUNT.officeName}`);
    console.log(`💼 Designation: ${DEMO_ACCOUNT.designation}`);
    console.log('==========================================');
    console.log('\n✅ Account is ready for Google Play review!');
    console.log('📝 Copy these credentials to Google Play Console');
    console.log('🧪 Login tested and verified working!');
    
  } catch (error) {
    console.error('❌ Script failed:', error);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

main();
