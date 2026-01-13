import { collection, doc, setDoc, getDocs } from 'firebase/firestore';
import { db } from '../config/firebase';

export interface TestUser {
  name: string;
  email: string;
  phoneNumber: string;
  officeName: string;
  designation: string;
}

const testUsers: TestUser[] = [
  // Original 8 users
  {
    name: 'John Doe',
    email: 'john.doe@example.com',
    phoneNumber: '+91 9876543210',
    officeName: 'Central Post Office',
    designation: 'GDS'
  },
  {
    name: 'Jane Smith',
    email: 'jane.smith@example.com',
    phoneNumber: '+91 9876543211',
    officeName: 'North Post Office',
    designation: 'MTS'
  },
  {
    name: 'Bob Wilson',
    email: 'bob.wilson@example.com',
    phoneNumber: '+91 9876543212',
    officeName: 'Central Post Office',
    designation: 'Postman'
  },
  {
    name: 'Alice Brown',
    email: 'alice.brown@example.com',
    phoneNumber: '+91 9876543213',
    officeName: 'South Post Office',
    designation: 'Postal Assistant'
  },
  {
    name: 'Charlie Davis',
    email: 'charlie.davis@example.com',
    phoneNumber: '+91 9876543214',
    officeName: 'East Post Office',
    designation: 'Inspector'
  },
  {
    name: 'Diana Miller',
    email: 'diana.miller@example.com',
    phoneNumber: '+91 9876543215',
    officeName: 'West Post Office',
    designation: 'ASP'
  },
  {
    name: 'Frank Johnson',
    email: 'frank.johnson@example.com',
    phoneNumber: '+91 9876543216',
    officeName: 'Central Post Office',
    designation: 'SP'
  },
  {
    name: 'Grace Lee',
    email: 'grace.lee@example.com',
    phoneNumber: '+91 9876543217',
    officeName: 'North Post Office',
    designation: 'GDS'
  },
  // Additional 12 users for more testing
  {
    name: 'Michael Chen',
    email: 'michael.chen@example.com',
    phoneNumber: '+91 9876543218',
    officeName: 'Mumbai Central',
    designation: 'MTS'
  },
  {
    name: 'Sarah Williams',
    email: 'sarah.williams@example.com',
    phoneNumber: '+91 9876543219',
    officeName: 'Delhi GPO',
    designation: 'Postman'
  },
  {
    name: 'David Kumar',
    email: 'david.kumar@example.com',
    phoneNumber: '+91 9876543220',
    officeName: 'Bangalore South',
    designation: 'GDS'
  },
  {
    name: 'Lisa Patel',
    email: 'lisa.patel@example.com',
    phoneNumber: '+91 9876543221',
    officeName: 'Chennai Central',
    designation: 'Postal Assistant'
  },
  {
    name: 'Robert Singh',
    email: 'robert.singh@example.com',
    phoneNumber: '+91 9876543222',
    officeName: 'Kolkata GPO',
    designation: 'Inspector'
  },
  {
    name: 'Emily Sharma',
    email: 'emily.sharma@example.com',
    phoneNumber: '+91 9876543223',
    officeName: 'Hyderabad Central',
    designation: 'ASP'
  },
  {
    name: 'James Gupta',
    email: 'james.gupta@example.com',
    phoneNumber: '+91 9876543224',
    officeName: 'Pune Main',
    designation: 'SP'
  },
  {
    name: 'Maria Rodriguez',
    email: 'maria.rodriguez@example.com',
    phoneNumber: '+91 9876543225',
    officeName: 'Ahmedabad GPO',
    designation: 'GDS'
  },
  {
    name: 'Kevin Joshi',
    email: 'kevin.joshi@example.com',
    phoneNumber: '+91 9876543226',
    officeName: 'Jaipur Central',
    designation: 'MTS'
  },
  {
    name: 'Amanda Verma',
    email: 'amanda.verma@example.com',
    phoneNumber: '+91 9876543227',
    officeName: 'Lucknow GPO',
    designation: 'Postman'
  },
  {
    name: 'Daniel Agarwal',
    email: 'daniel.agarwal@example.com',
    phoneNumber: '+91 9876543228',
    officeName: 'Kanpur Main',
    designation: 'Postal Assistant'
  },
  {
    name: 'Jessica Mishra',
    email: 'jessica.mishra@example.com',
    phoneNumber: '+91 9876543229',
    officeName: 'Indore Central',
    designation: 'Inspector'
  }
];

export const createTestUsers = async (): Promise<{ success: boolean; message: string; details: string[] }> => {
  const results: string[] = [];
  let successCount = 0;
  let errorCount = 0;

  try {
    results.push('🚀 Starting test user creation...');

    // Use mobile_users collection specifically for mobile notifications
    const collectionNames = ['mobile_users'];
    
    for (const collectionName of collectionNames) {
      try {
        results.push(`\n📁 Trying collection: ${collectionName}`);
        
        for (const userData of testUsers) {
          try {
            const userDoc = {
              uid: `test-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
              name: userData.name,
              email: userData.email,
              phoneNumber: userData.phoneNumber,
              officeName: userData.officeName,
              designation: userData.designation,
              userType: 'mobile_user', // Explicitly mark as mobile user
              role: 'user', // User role (not admin)
              isActive: true,
              emailVerified: true,
              profileComplete: true,
              quizzesTaken: Math.floor(Math.random() * 10),
              totalScore: Math.floor(Math.random() * 1000),
              averageScore: Math.floor(Math.random() * 100),
              stats: {
                totalQuizzes: Math.floor(Math.random() * 10),
                totalScore: Math.floor(Math.random() * 1000),
                averageScore: Math.floor(Math.random() * 100),
                currentStreak: Math.floor(Math.random() * 5),
                longestStreak: Math.floor(Math.random() * 10),
                totalTimeSpent: Math.floor(Math.random() * 10000),
              },
              preferences: {
                notifications: true,
                darkMode: false,
                language: 'en',
              },
              createdAt: new Date(),
              lastLoginAt: new Date(),
              updatedAt: new Date(),
            };

            // Use the generated UID as document ID
            await setDoc(doc(db, collectionName, userDoc.uid), userDoc);
            
            results.push(`✅ Created user: ${userData.name} (${userData.designation}) in ${collectionName}`);
            successCount++;
          } catch (userError) {
            results.push(`❌ Failed to create user ${userData.name}: ${userError}`);
            errorCount++;
          }
        }

        // If we successfully created users in this collection, break
        if (successCount > 0) {
          results.push(`\n🎉 Successfully created ${successCount} users in ${collectionName} collection!`);
          break;
        }
      } catch (collectionError) {
        results.push(`❌ Error with collection ${collectionName}: ${collectionError}`);
        continue;
      }
    }

    if (successCount === 0) {
      return {
        success: false,
        message: 'Failed to create any test users',
        details: results
      };
    }

    return {
      success: true,
      message: `Successfully created ${successCount} test users${errorCount > 0 ? ` (${errorCount} failed)` : ''}`,
      details: results
    };

  } catch (error) {
    results.push(`❌ Critical error: ${error}`);
    return {
      success: false,
      message: 'Critical error during user creation',
      details: results
    };
  }
};

export const checkExistingUsers = async (): Promise<{ collectionName: string; count: number; users: any[] }[]> => {
  const results: { collectionName: string; count: number; users: any[] }[] = [];
  const collectionNames = ['mobile_users']; // Only check mobile_users collection

  for (const collectionName of collectionNames) {
    try {
      const snapshot = await getDocs(collection(db, collectionName));
      const users = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      results.push({
        collectionName,
        count: snapshot.docs.length,
        users: users.slice(0, 3) // Only return first 3 for preview
      });
    } catch (error) {
      results.push({
        collectionName,
        count: -1,
        users: []
      });
    }
  }

  return results;
};
