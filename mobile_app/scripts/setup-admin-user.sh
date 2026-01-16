#!/bin/bash

# MCQ Quiz System - Admin User Setup Script
# This script helps you create and configure admin users

set -e

echo "👤 MCQ Quiz System - Admin User Setup"
echo "====================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if Firebase CLI is installed
check_firebase_cli() {
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed"
        echo "Please install it using: npm install -g firebase-tools"
        exit 1
    fi
    print_status "Firebase CLI is installed"
}

# Check if user is logged in to Firebase
check_firebase_login() {
    if ! firebase projects:list &> /dev/null; then
        print_warning "You are not logged in to Firebase"
        echo "Please run: firebase login"
        read -p "Press Enter after logging in..."
    fi
    print_status "Firebase authentication verified"
}

# Create admin user script
create_admin_user_script() {
    echo ""
    echo "📝 Creating Admin User Script"
    echo "============================"
    
    cat > scripts/create-admin-user.js << 'EOF'
#!/usr/bin/env node

/**
 * Create Admin User Script
 * This script creates an admin user in the system
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin
function initializeFirebase() {
  try {
    admin.initializeApp();
    return admin.firestore();
  } catch (error) {
    console.error('Failed to initialize Firebase:', error.message);
    process.exit(1);
  }
}

// Create readline interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function createAdminUser() {
  console.log('🔧 Admin User Creation Tool');
  console.log('===========================\n');
  
  const db = initializeFirebase();
  
  try {
    // Get user details
    const phoneNumber = await question('Enter admin phone number (with country code, e.g., +919876543210): ');
    const displayName = await question('Enter admin display name: ');
    const email = await question('Enter admin email (optional): ');
    const role = await question('Enter role (admin/master_admin) [master_admin]: ') || 'master_admin';
    
    // Validate role
    if (!['admin', 'master_admin'].includes(role)) {
      console.error('Invalid role. Must be "admin" or "master_admin"');
      process.exit(1);
    }
    
    // Create user in Authentication
    console.log('\n📱 Creating user in Firebase Authentication...');
    
    const userRecord = await admin.auth().createUser({
      phoneNumber: phoneNumber,
      displayName: displayName,
      email: email || undefined,
      disabled: false
    });
    
    console.log('✓ User created in Authentication with UID:', userRecord.uid);
    
    // Create user document in Firestore
    console.log('📊 Creating user document in Firestore...');
    
    const userDoc = {
      uid: userRecord.uid,
      email: email || null,
      phoneNumber: phoneNumber,
      displayName: displayName,
      role: role,
      isActive: true,
      stats: {
        totalQuizzes: 0,
        totalScore: 0,
        averageScore: 0,
        currentStreak: 0,
        longestStreak: 0,
        totalTimeSpent: 0
      },
      preferences: {
        darkMode: false,
        notifications: true,
        language: 'en'
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await db.collection('users').doc(userRecord.uid).set(userDoc);
    console.log('✓ User document created in Firestore');
    
    // Add to leaderboard if needed
    if (role === 'admin' || role === 'master_admin') {
      console.log('🏆 Adding to leaderboard...');
      
      await db.collection('leaderboard').doc(userRecord.uid).set({
        userId: userRecord.uid,
        userName: displayName,
        profileImageUrl: null,
        totalScore: 0,
        totalQuizzes: 0,
        averageScore: 0,
        rank: 0,
        badges: ['admin'],
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        period: 'all_time'
      });
      
      console.log('✓ Added to leaderboard');
    }
    
    console.log('\n🎉 Admin user created successfully!');
    console.log('==================================');
    console.log(`User ID: ${userRecord.uid}`);
    console.log(`Phone: ${phoneNumber}`);
    console.log(`Name: ${displayName}`);
    console.log(`Role: ${role}`);
    console.log(`Email: ${email || 'Not provided'}`);
    
    console.log('\n📱 The user can now login using the mobile app or web admin panel');
    
  } catch (error) {
    console.error('Error creating admin user:', error.message);
    process.exit(1);
  } finally {
    rl.close();
  }
}

createAdminUser();
EOF
    
    print_status "Admin user creation script created"
}

# Update existing user to admin
update_user_to_admin() {
    echo ""
    echo "🔄 Update Existing User to Admin"
    echo "==============================="
    
    cat > scripts/update-user-role.js << 'EOF'
#!/usr/bin/env node

/**
 * Update User Role Script
 * This script updates an existing user's role to admin
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin
function initializeFirebase() {
  try {
    admin.initializeApp();
    return admin.firestore();
  } catch (error) {
    console.error('Failed to initialize Firebase:', error.message);
    process.exit(1);
  }
}

// Create readline interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function updateUserRole() {
  console.log('🔧 User Role Update Tool');
  console.log('========================\n');
  
  const db = initializeFirebase();
  
  try {
    // Get user identifier
    const identifier = await question('Enter user phone number or email: ');
    const newRole = await question('Enter new role (user/admin/master_admin): ');
    
    // Validate role
    if (!['user', 'admin', 'master_admin'].includes(newRole)) {
      console.error('Invalid role. Must be "user", "admin", or "master_admin"');
      process.exit(1);
    }
    
    // Find user by phone or email
    console.log('\n🔍 Finding user...');
    
    let userRecord;
    try {
      if (identifier.includes('@')) {
        userRecord = await admin.auth().getUserByEmail(identifier);
      } else {
        userRecord = await admin.auth().getUserByPhoneNumber(identifier);
      }
    } catch (error) {
      console.error('User not found in Authentication:', error.message);
      process.exit(1);
    }
    
    console.log('✓ User found:', userRecord.uid);
    
    // Update user document in Firestore
    console.log('📊 Updating user role in Firestore...');
    
    const userRef = db.collection('users').doc(userRecord.uid);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      console.error('User document not found in Firestore');
      process.exit(1);
    }
    
    await userRef.update({
      role: newRole,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✓ User role updated in Firestore');
    
    // Update leaderboard if needed
    if (newRole === 'admin' || newRole === 'master_admin') {
      console.log('🏆 Updating leaderboard...');
      
      const leaderboardRef = db.collection('leaderboard').doc(userRecord.uid);
      const leaderboardDoc = await leaderboardRef.get();
      
      if (leaderboardDoc.exists) {
        await leaderboardRef.update({
          badges: admin.firestore.FieldValue.arrayUnion('admin'),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
      } else {
        const userData = userDoc.data();
        await leaderboardRef.set({
          userId: userRecord.uid,
          userName: userData.displayName || 'Admin User',
          profileImageUrl: userData.profileImageUrl || null,
          totalScore: userData.stats?.totalScore || 0,
          totalQuizzes: userData.stats?.totalQuizzes || 0,
          averageScore: userData.stats?.averageScore || 0,
          rank: 0,
          badges: ['admin'],
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          period: 'all_time'
        });
      }
      
      console.log('✓ Leaderboard updated');
    }
    
    console.log('\n🎉 User role updated successfully!');
    console.log('=================================');
    console.log(`User ID: ${userRecord.uid}`);
    console.log(`Phone: ${userRecord.phoneNumber || 'Not set'}`);
    console.log(`Email: ${userRecord.email || 'Not set'}`);
    console.log(`New Role: ${newRole}`);
    
  } catch (error) {
    console.error('Error updating user role:', error.message);
    process.exit(1);
  } finally {
    rl.close();
  }
}

updateUserRole();
EOF
    
    print_status "User role update script created"
}

# List all admin users
list_admin_users() {
    echo ""
    echo "📋 List Admin Users Script"
    echo "========================="
    
    cat > scripts/list-admin-users.js << 'EOF'
#!/usr/bin/env node

/**
 * List Admin Users Script
 * This script lists all admin users in the system
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
function initializeFirebase() {
  try {
    admin.initializeApp();
    return admin.firestore();
  } catch (error) {
    console.error('Failed to initialize Firebase:', error.message);
    process.exit(1);
  }
}

async function listAdminUsers() {
  console.log('👥 Admin Users List');
  console.log('==================\n');
  
  const db = initializeFirebase();
  
  try {
    // Get all admin users
    const adminUsersSnapshot = await db.collection('users')
      .where('role', 'in', ['admin', 'master_admin'])
      .get();
    
    if (adminUsersSnapshot.empty) {
      console.log('No admin users found.');
      return;
    }
    
    console.log(`Found ${adminUsersSnapshot.size} admin user(s):\n`);
    
    adminUsersSnapshot.forEach((doc, index) => {
      const user = doc.data();
      console.log(`${index + 1}. ${user.displayName || 'Unnamed User'}`);
      console.log(`   UID: ${doc.id}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Phone: ${user.phoneNumber || 'Not set'}`);
      console.log(`   Email: ${user.email || 'Not set'}`);
      console.log(`   Active: ${user.isActive ? 'Yes' : 'No'}`);
      console.log(`   Created: ${user.createdAt?.toDate?.() || 'Unknown'}`);
      console.log('');
    });
    
  } catch (error) {
    console.error('Error listing admin users:', error.message);
    process.exit(1);
  }
}

listAdminUsers();
EOF
    
    print_status "List admin users script created"
}

# Make scripts executable
make_scripts_executable() {
    echo ""
    echo "🔧 Making Scripts Executable"
    echo "============================"
    
    chmod +x scripts/create-admin-user.js
    chmod +x scripts/update-user-role.js
    chmod +x scripts/list-admin-users.js
    
    print_status "Scripts are now executable"
}

# Main setup function
main() {
    echo "Setting up admin user management tools..."
    echo ""
    
    check_firebase_cli
    check_firebase_login
    create_admin_user_script
    update_user_to_admin
    list_admin_users
    make_scripts_executable
    
    echo ""
    echo "🎉 Admin User Setup Complete!"
    echo "============================"
    print_status "Admin user management tools are ready"
    echo ""
    print_info "Available scripts:"
    echo "1. scripts/create-admin-user.js - Create new admin user"
    echo "2. scripts/update-user-role.js - Update existing user role"
    echo "3. scripts/list-admin-users.js - List all admin users"
    echo ""
    print_info "Usage examples:"
    echo "node scripts/create-admin-user.js"
    echo "node scripts/update-user-role.js"
    echo "node scripts/list-admin-users.js"
    echo ""
    print_warning "Remember to:"
    echo "- Keep your Firebase service account key secure"
    echo "- Test admin access after creating users"
    echo "- Regularly review admin user permissions"
    echo ""
}

# Run main function
main
