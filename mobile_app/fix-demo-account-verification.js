#!/usr/bin/env node

/**
 * Fix Demo Account Email Verification
 * This script marks the demo account email as verified using Firebase Admin SDK
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You'll need to download the service account key from Firebase Console
// and save it as 'serviceAccountKey.json' in the same directory
try {
  const serviceAccount = require('./serviceAccountKey.json');
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'mcq-quiz-system'
  });
  
  console.log('✅ Firebase Admin SDK initialized');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK');
  console.error('Please download the service account key from Firebase Console:');
  console.error('1. Go to Firebase Console > Project Settings > Service Accounts');
  console.error('2. Click "Generate new private key"');
  console.error('3. Save as "serviceAccountKey.json" in mobile_app directory');
  console.error('Error:', error.message);
  process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

// Demo account details
const DEMO_EMAIL = 'googleplay.demo@dakshinpostalacademy.com';

async function fixDemoAccountVerification() {
  console.log('🔧 Fixing demo account email verification...');
  console.log('📧 Demo Email:', DEMO_EMAIL);
  
  try {
    // Get user by email
    const userRecord = await auth.getUserByEmail(DEMO_EMAIL);
    console.log('✅ Found demo account:', userRecord.uid);
    
    // Update user to mark email as verified
    await auth.updateUser(userRecord.uid, {
      emailVerified: true
    });
    
    console.log('✅ Email verification status updated');
    
    // Also update the Firestore document to ensure consistency
    const userDocRef = db.collection('mobile_users').doc(userRecord.uid);
    await userDocRef.update({
      emailVerified: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Firestore document updated');
    
    // Also update users collection for compatibility
    const usersDocRef = db.collection('users').doc(userRecord.uid);
    await usersDocRef.update({
      emailVerified: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Users collection updated');
    
    // Verify the fix
    const updatedUserRecord = await auth.getUser(userRecord.uid);
    console.log('🧪 Verification Status:', updatedUserRecord.emailVerified);
    
    if (updatedUserRecord.emailVerified) {
      console.log('\n🎉 DEMO ACCOUNT FIXED SUCCESSFULLY!');
      console.log('==========================================');
      console.log('📧 Email:', DEMO_EMAIL);
      console.log('🔑 Password: GooglePlay2024!');
      console.log('✅ Email Verified: YES');
      console.log('👤 User ID:', userRecord.uid);
      console.log('==========================================');
      console.log('\n✅ Demo account is now ready for Google Play review!');
      console.log('🧪 Users can now login without email verification screen');
    } else {
      console.log('❌ Failed to verify email status');
    }
    
  } catch (error) {
    console.error('❌ Error fixing demo account:', error.message);
    
    if (error.code === 'auth/user-not-found') {
      console.error('Demo account not found. Please run create-demo-account-direct.js first');
    }
    
    process.exit(1);
  }
}

// Main execution
async function main() {
  try {
    await fixDemoAccountVerification();
  } catch (error) {
    console.error('❌ Script failed:', error);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

main();
