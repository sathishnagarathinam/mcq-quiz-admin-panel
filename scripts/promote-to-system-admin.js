#!/usr/bin/env node

/**
 * Script to promote an existing user to system admin
 * Usage: node scripts/promote-to-system-admin.js <email>
 */

const { initializeApp } = require('firebase/app');
const { getFirestore, collection, query, where, getDocs, doc, updateDoc } = require('firebase/firestore');

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
const db = getFirestore(app);

async function promoteToSystemAdmin(email) {
  try {
    console.log('🔍 Searching for user with email:', email);
    
    // Find user by email
    const usersRef = collection(db, 'admin_users');
    const q = query(usersRef, where('email', '==', email));
    const querySnapshot = await getDocs(q);
    
    if (querySnapshot.empty) {
      console.log('❌ No user found with email:', email);
      console.log('💡 Make sure the user has registered first at: http://localhost:3000/register');
      return;
    }
    
    // Get the first matching user
    const userDoc = querySnapshot.docs[0];
    const userData = userDoc.data();
    
    console.log('✅ User found:');
    console.log(`   Name: ${userData.name}`);
    console.log(`   Email: ${userData.email}`);
    console.log(`   Current Role: ${userData.role}`);
    console.log(`   Status: ${userData.isActive ? 'Active' : 'Inactive'}`);
    
    // Update user role to system_admin
    const userRef = doc(db, 'admin_users', userDoc.id);
    await updateDoc(userRef, {
      role: 'system_admin',
      isActive: true // Also activate the user
    });
    
    console.log('🎉 User successfully promoted to System Admin!');
    console.log('');
    console.log('📋 Updated Details:');
    console.log(`   Email: ${userData.email}`);
    console.log(`   Name: ${userData.name}`);
    console.log(`   New Role: system_admin`);
    console.log(`   Status: Active`);
    console.log('');
    console.log('🔐 The user can now login and access system admin features at:');
    console.log('   http://localhost:3000/login');
    console.log('');
    console.log('👑 System Admin Features:');
    console.log('   - User Management Dashboard Card');
    console.log('   - Approve/Reject Admin Registrations');
    console.log('   - Edit User Roles and Status');
    console.log('   - Full Admin User Management');
    
  } catch (error) {
    console.error('❌ Error promoting user:', error.message);
    
    if (error.code === 'permission-denied') {
      console.log('💡 Tip: Make sure Firestore rules allow this operation or use development rules.');
    }
  }
}

// Get command line arguments
const args = process.argv.slice(2);

if (args.length !== 1) {
  console.log('❌ Invalid arguments');
  console.log('');
  console.log('Usage: node scripts/promote-to-system-admin.js <email>');
  console.log('');
  console.log('Example:');
  console.log('  node scripts/promote-to-system-admin.js admin@example.com');
  console.log('');
  console.log('📋 This script will:');
  console.log('  1. Find the user by email in admin_users collection');
  console.log('  2. Update their role to "system_admin"');
  console.log('  3. Activate their account');
  console.log('  4. Enable system admin dashboard features');
  console.log('');
  process.exit(1);
}

const [email] = args;

// Validate email
if (!email || !email.includes('@')) {
  console.log('❌ Please provide a valid email address');
  process.exit(1);
}

// Promote the user
promoteToSystemAdmin(email)
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });
