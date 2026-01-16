import { collection, getDocs, doc, updateDoc } from 'firebase/firestore';
import { db } from '../config/firebase';

/**
 * Utility to manually add FCM token field to existing users
 * This is a one-time operation to prepare existing users for push notifications
 */

export const addFCMTokenFieldToUsers = async (): Promise<{ success: boolean; message: string; details: any }> => {
  try {
    console.log('Starting FCM token field addition for existing users...');
    
    // Get all users from mobile_users collection
    const usersRef = collection(db, 'mobile_users');
    const snapshot = await getDocs(usersRef);
    
    console.log(`Found ${snapshot.docs.length} users in mobile_users collection`);
    
    let updatedCount = 0;
    let skippedCount = 0;
    const errors: string[] = [];
    
    for (const userDoc of snapshot.docs) {
      try {
        const userData = userDoc.data();
        
        // Check if user already has fcmToken field
        if (userData.fcmToken !== undefined) {
          console.log(`User ${userDoc.id} already has fcmToken field, skipping`);
          skippedCount++;
          continue;
        }
        
        // Add fcmToken field (initially null, will be populated when user logs in)
        await updateDoc(doc(db, 'mobile_users', userDoc.id), {
          fcmToken: null,
          lastTokenUpdate: null,
        });
        
        console.log(`Added fcmToken field to user ${userDoc.id} (${userData.name})`);
        updatedCount++;
        
      } catch (error) {
        const errorMsg = `Failed to update user ${userDoc.id}: ${error}`;
        console.error(errorMsg);
        errors.push(errorMsg);
      }
    }
    
    const result = {
      success: true,
      message: `FCM token fields added successfully. Updated: ${updatedCount}, Skipped: ${skippedCount}, Errors: ${errors.length}`,
      details: {
        totalUsers: snapshot.docs.length,
        updatedCount,
        skippedCount,
        errorCount: errors.length,
        errors: errors.slice(0, 5), // Show first 5 errors only
      }
    };
    
    console.log('FCM token field addition completed:', result);
    return result;
    
  } catch (error) {
    const errorMsg = `Failed to add FCM token fields: ${error}`;
    console.error(errorMsg);
    return {
      success: false,
      message: errorMsg,
      details: { error: String(error) }
    };
  }
};

/**
 * Check FCM token status for all users
 */
export const checkFCMTokenStatus = async (): Promise<{ success: boolean; message: string; details: any }> => {
  try {
    console.log('Checking FCM token status for all users...');
    
    const usersRef = collection(db, 'mobile_users');
    const snapshot = await getDocs(usersRef);
    
    let usersWithTokens = 0;
    let usersWithoutTokens = 0;
    let usersWithNullTokens = 0;
    const sampleUsersWithTokens: any[] = [];
    const sampleUsersWithoutTokens: any[] = [];
    
    snapshot.docs.forEach(userDoc => {
      const userData = userDoc.data();
      const userInfo = {
        id: userDoc.id,
        name: userData.name,
        email: userData.email,
        hasTokenField: 'fcmToken' in userData,
        tokenValue: userData.fcmToken,
        lastTokenUpdate: userData.lastTokenUpdate,
      };
      
      if (!('fcmToken' in userData)) {
        usersWithoutTokens++;
        if (sampleUsersWithoutTokens.length < 3) {
          sampleUsersWithoutTokens.push(userInfo);
        }
      } else if (userData.fcmToken === null || userData.fcmToken === undefined) {
        usersWithNullTokens++;
        if (sampleUsersWithoutTokens.length < 3) {
          sampleUsersWithoutTokens.push(userInfo);
        }
      } else {
        usersWithTokens++;
        if (sampleUsersWithTokens.length < 3) {
          sampleUsersWithTokens.push({
            ...userInfo,
            tokenPreview: userData.fcmToken.substring(0, 20) + '...'
          });
        }
      }
    });
    
    const result = {
      success: true,
      message: `FCM token status check completed. Total users: ${snapshot.docs.length}`,
      details: {
        totalUsers: snapshot.docs.length,
        usersWithTokens,
        usersWithNullTokens,
        usersWithoutTokens,
        sampleUsersWithTokens,
        sampleUsersWithoutTokens,
      }
    };
    
    console.log('FCM token status check completed:', result);
    return result;
    
  } catch (error) {
    const errorMsg = `Failed to check FCM token status: ${error}`;
    console.error(errorMsg);
    return {
      success: false,
      message: errorMsg,
      details: { error: String(error) }
    };
  }
};

/**
 * Simulate FCM tokens for test users (for testing purposes)
 */
export const addTestFCMTokens = async (): Promise<{ success: boolean; message: string; details: any }> => {
  try {
    console.log('Adding test FCM tokens to users...');
    
    const usersRef = collection(db, 'mobile_users');
    const snapshot = await getDocs(usersRef);
    
    let updatedCount = 0;
    const errors: string[] = [];
    
    for (const userDoc of snapshot.docs) {
      try {
        const userData = userDoc.data();
        
        // Generate a fake FCM token for testing
        const testToken = `test_fcm_token_${userDoc.id}_${Date.now()}`;
        
        await updateDoc(doc(db, 'mobile_users', userDoc.id), {
          fcmToken: testToken,
          lastTokenUpdate: new Date(),
        });
        
        console.log(`Added test FCM token to user ${userDoc.id} (${userData.name})`);
        updatedCount++;
        
      } catch (error) {
        const errorMsg = `Failed to add test token to user ${userDoc.id}: ${error}`;
        console.error(errorMsg);
        errors.push(errorMsg);
      }
    }
    
    const result = {
      success: true,
      message: `Test FCM tokens added successfully. Updated: ${updatedCount}, Errors: ${errors.length}`,
      details: {
        totalUsers: snapshot.docs.length,
        updatedCount,
        errorCount: errors.length,
        errors: errors.slice(0, 5),
      }
    };
    
    console.log('Test FCM token addition completed:', result);
    return result;
    
  } catch (error) {
    const errorMsg = `Failed to add test FCM tokens: ${error}`;
    console.error(errorMsg);
    return {
      success: false,
      message: errorMsg,
      details: { error: String(error) }
    };
  }
};
