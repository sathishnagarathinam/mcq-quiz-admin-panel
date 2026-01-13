#!/usr/bin/env node

/**
 * Script to check what users exist in Firestore admin_users collection
 * Usage: node scripts/check-firestore-users.js
 */

const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

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

async function checkFirestoreUsers() {
  try {
    console.log('🔍 Checking Firestore admin_users collection...');
    console.log('');
    
    const usersRef = collection(db, 'admin_users');
    const snapshot = await getDocs(usersRef);
    
    console.log('📊 Total documents found:', snapshot.size);
    console.log('');
    
    if (snapshot.empty) {
      console.log('❌ No users found in admin_users collection!');
      console.log('');
      console.log('💡 Possible reasons:');
      console.log('   1. No users have registered yet');
      console.log('   2. Firestore rules are blocking access');
      console.log('   3. Collection name mismatch');
      console.log('   4. Firebase project configuration issue');
      console.log('');
      console.log('🔧 Next steps:');
      console.log('   1. Register a new user at: http://localhost:3000/register');
      console.log('   2. Check Firestore rules are deployed');
      console.log('   3. Verify Firebase project configuration');
      return;
    }
    
    console.log('👥 Users found:');
    console.log('================');
    
    snapshot.forEach((doc, index) => {
      const userData = doc.data();
      console.log(`${index + 1}. Document ID: ${doc.id}`);
      console.log(`   Email: ${userData.email || 'N/A'}`);
      console.log(`   Name: ${userData.name || 'N/A'}`);
      console.log(`   Role: ${userData.role || 'N/A'}`);
      console.log(`   Status: ${userData.status || 'N/A'}`);
      console.log(`   Active: ${userData.isActive ? 'Yes' : 'No'}`);
      console.log(`   Created: ${userData.createdAt ? new Date(userData.createdAt.seconds * 1000).toLocaleString() : 'N/A'}`);
      
      if (userData.approvedBy) {
        console.log(`   Approved By: ${userData.approvedBy}`);
        console.log(`   Approved At: ${userData.approvedAt ? new Date(userData.approvedAt.seconds * 1000).toLocaleString() : 'N/A'}`);
      }
      
      console.log('');
    });
    
    // Summary
    const pendingUsers = [];
    const approvedUsers = [];
    const rejectedUsers = [];
    const systemAdmins = [];
    
    snapshot.forEach((doc) => {
      const userData = doc.data();
      if (userData.status === 'pending') {
        pendingUsers.push(userData);
      } else if (userData.status === 'approved') {
        approvedUsers.push(userData);
      } else if (userData.status === 'rejected') {
        rejectedUsers.push(userData);
      }
      
      if (userData.role === 'system_admin') {
        systemAdmins.push(userData);
      }
    });
    
    console.log('📋 Summary:');
    console.log('===========');
    console.log(`🟡 Pending Users: ${pendingUsers.length}`);
    console.log(`🟢 Approved Users: ${approvedUsers.length}`);
    console.log(`🔴 Rejected Users: ${rejectedUsers.length}`);
    console.log(`👑 System Admins: ${systemAdmins.length}`);
    console.log('');
    
    if (pendingUsers.length > 0) {
      console.log('🟡 Pending users that need approval:');
      pendingUsers.forEach((user, index) => {
        console.log(`   ${index + 1}. ${user.name} (${user.email})`);
      });
      console.log('');
    }
    
    if (systemAdmins.length === 0) {
      console.log('⚠️  No system admins found!');
      console.log('💡 Create a system admin with:');
      console.log('   node scripts/create-system-admin.js admin@system.com admin123 "System Administrator"');
      console.log('');
    } else {
      console.log('👑 System admins who can approve users:');
      systemAdmins.forEach((user, index) => {
        console.log(`   ${index + 1}. ${user.name} (${user.email})`);
      });
      console.log('');
    }
    
    console.log('🎯 Next steps:');
    if (pendingUsers.length > 0 && systemAdmins.length > 0) {
      console.log('   1. Login as system admin');
      console.log('   2. Go to User Management');
      console.log('   3. Approve pending users');
    } else if (pendingUsers.length === 0) {
      console.log('   1. Register new users at: http://localhost:3000/register');
      console.log('   2. They will appear as pending for approval');
    } else if (systemAdmins.length === 0) {
      console.log('   1. Create a system admin first');
      console.log('   2. Then approve pending users');
    }
    
  } catch (error) {
    console.error('❌ Error checking Firestore:', error.message);
    
    if (error.code === 'permission-denied') {
      console.log('');
      console.log('🔒 Permission denied - possible causes:');
      console.log('   1. Firestore rules are too restrictive');
      console.log('   2. Authentication required but not provided');
      console.log('   3. Rules not deployed properly');
      console.log('');
      console.log('🔧 Try deploying development rules:');
      console.log('   ./scripts/deploy-firestore-rules.sh dev');
    }
  }
}

// Run the check
checkFirestoreUsers()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });
