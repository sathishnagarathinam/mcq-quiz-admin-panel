#!/usr/bin/env node

/**
 * Script to create a system admin user
 * Usage: node scripts/create-system-admin.js <email> <password> <name>
 */

const { initializeApp } = require('firebase/app');
const { getAuth, createUserWithEmailAndPassword, updateProfile } = require('firebase/auth');
const { getFirestore, doc, setDoc, serverTimestamp } = require('firebase/firestore');

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyDIdFTL8Xl-E02bYB_HnuymfGBRRL6xBqk",
  authDomain: "mcq-quiz-system.firebaseapp.com",
  projectId: "mcq-quiz-system",
  storageBucket: "mcq-quiz-system.firebasestorage.app",
  messagingSenderId: "109048215498",
  appId: "1:109048215498:web:398b38704a2b075fb08133"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

async function createSystemAdmin(email, password, name) {
  try {
    console.log('🔧 Creating system admin user...');
    
    // Create user in Firebase Auth
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;
    
    console.log('✅ User created in Firebase Auth:', user.uid);
    
    // Update user profile
    await updateProfile(user, {
      displayName: name
    });
    
    console.log('✅ User profile updated');
    
    // Create admin user document in Firestore
    const adminUserData = {
      uid: user.uid,
      email: email,
      name: name,
      role: 'system_admin',
      createdAt: serverTimestamp(),
      lastLogin: serverTimestamp(),
      isActive: true,
      status: 'approved', // System admin is auto-approved
      approvedBy: 'system', // Auto-approved by system
      approvedAt: serverTimestamp()
    };
    
    await setDoc(doc(db, 'admin_users', user.uid), adminUserData);
    
    console.log('✅ Admin user document created in Firestore');
    console.log('🎉 System admin user created successfully!');
    console.log('');
    console.log('📋 User Details:');
    console.log(`   Email: ${email}`);
    console.log(`   Name: ${name}`);
    console.log(`   Role: system_admin`);
    console.log(`   UID: ${user.uid}`);
    console.log('');
    console.log('🔐 You can now login with these credentials at:');
    console.log('   http://localhost:3000/login');
    
  } catch (error) {
    console.error('❌ Error creating system admin:', error.message);
    
    if (error.code === 'auth/email-already-in-use') {
      console.log('💡 Tip: This email is already registered. Try a different email or login with existing credentials.');
    } else if (error.code === 'auth/weak-password') {
      console.log('💡 Tip: Password should be at least 6 characters long.');
    } else if (error.code === 'auth/invalid-email') {
      console.log('💡 Tip: Please provide a valid email address.');
    }
  }
}

// Get command line arguments
const args = process.argv.slice(2);

if (args.length !== 3) {
  console.log('❌ Invalid arguments');
  console.log('');
  console.log('Usage: node scripts/create-system-admin.js <email> <password> <name>');
  console.log('');
  console.log('Example:');
  console.log('  node scripts/create-system-admin.js admin@system.com admin123 "System Administrator"');
  console.log('');
  process.exit(1);
}

const [email, password, name] = args;

// Validate inputs
if (!email || !password || !name) {
  console.log('❌ All fields are required: email, password, name');
  process.exit(1);
}

if (password.length < 6) {
  console.log('❌ Password must be at least 6 characters long');
  process.exit(1);
}

// Create the system admin
createSystemAdmin(email, password, name)
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });
