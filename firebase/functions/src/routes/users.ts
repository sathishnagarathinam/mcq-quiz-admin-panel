import { Router } from 'express';
import * as admin from 'firebase-admin';

const router = Router();

// Get users with pagination
router.get('/', async (req, res) => {
  try {
    const { limit = 10, offset = 0, role } = req.query;
    
    let query: admin.firestore.Query = admin.firestore().collection('users');

    if (role) {
      query = query.where('role', '==', role);
    }
    
    const snapshot = await query
      .orderBy('createdAt', 'desc')
      .limit(Number(limit))
      .offset(Number(offset))
      .get();
    
    const users = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.status(200).json({
      success: true,
      users,
      total: snapshot.size
    });

  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({
      error: 'Failed to fetch users',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Update user
router.put('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const updateData = {
      ...req.body,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await admin.firestore().collection('users').doc(userId).update(updateData);

    res.status(200).json({
      success: true,
      message: 'User updated successfully'
    });

  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({
      error: 'Failed to update user',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Delete user from Firebase Authentication and Firestore
router.delete('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({
        error: 'User ID is required'
      });
    }

    console.log(`🗑️ Starting deletion process for user: ${userId}`);

    // Delete user from Firebase Authentication
    try {
      await admin.auth().deleteUser(userId);
      console.log(`✓ Deleted user from Firebase Authentication: ${userId}`);
    } catch (authError: any) {
      // If user doesn't exist in Firebase Auth, continue with Firestore deletion
      if (authError.code === 'auth/user-not-found') {
        console.log(`⚠️ User not found in Firebase Authentication: ${userId}`);
      } else {
        throw authError;
      }
    }

    // Delete user document from users collection
    await admin.firestore().collection('users').doc(userId).delete();
    console.log(`✓ Deleted user document from Firestore: ${userId}`);

    // Delete all quiz attempts for this user
    const quizAttemptsRef = admin.firestore().collection('quizAttempts');
    const quizAttemptsQuery = await quizAttemptsRef.where('userId', '==', userId).get();

    for (const docSnapshot of quizAttemptsQuery.docs) {
      await docSnapshot.ref.delete();
    }
    console.log(`✓ Deleted ${quizAttemptsQuery.docs.length} quiz attempts`);

    // Delete all paid orders for this user
    const paidOrdersRef = admin.firestore().collection('paidOrders');
    const paidOrdersQuery = await paidOrdersRef.where('userId', '==', userId).get();

    for (const docSnapshot of paidOrdersQuery.docs) {
      await docSnapshot.ref.delete();
    }
    console.log(`✓ Deleted ${paidOrdersQuery.docs.length} paid orders`);

    // Delete all device registrations for this user
    const deviceRegistrationsRef = admin.firestore().collection('deviceRegistrations');
    const deviceRegistrationsQuery = await deviceRegistrationsRef.where('userId', '==', userId).get();

    for (const docSnapshot of deviceRegistrationsQuery.docs) {
      await docSnapshot.ref.delete();
    }
    console.log(`✓ Deleted ${deviceRegistrationsQuery.docs.length} device registrations`);

    // Delete all notifications for this user
    const notificationsRef = admin.firestore().collection('notifications');
    const notificationsQuery = await notificationsRef.where('userId', '==', userId).get();

    for (const docSnapshot of notificationsQuery.docs) {
      await docSnapshot.ref.delete();
    }
    console.log(`✓ Deleted ${notificationsQuery.docs.length} notifications`);

    // Delete all feedback for this user
    const feedbackRef = admin.firestore().collection('feedback');
    const feedbackQuery = await feedbackRef.where('userId', '==', userId).get();

    for (const docSnapshot of feedbackQuery.docs) {
      await docSnapshot.ref.delete();
    }
    console.log(`✓ Deleted ${feedbackQuery.docs.length} feedback entries`);

    // Delete all user sessions for this user
    const sessionsRef = admin.firestore().collection('userSessions');
    const sessionsQuery = await sessionsRef.where('userId', '==', userId).get();

    for (const docSnapshot of sessionsQuery.docs) {
      await docSnapshot.ref.delete();
    }
    console.log(`✓ Deleted ${sessionsQuery.docs.length} user sessions`);

    // Delete mobile_users document if it exists
    try {
      await admin.firestore().collection('mobile_users').doc(userId).delete();
      console.log(`✓ Deleted mobile_users document: ${userId}`);
    } catch (error) {
      console.log(`⚠️ mobile_users document not found: ${userId}`);
    }

    return res.status(200).json({
      success: true,
      message: 'User and all related data deleted successfully',
      deletedData: {
        user: true,
        quizAttempts: quizAttemptsQuery.docs.length,
        paidOrders: paidOrdersQuery.docs.length,
        deviceRegistrations: deviceRegistrationsQuery.docs.length,
        notifications: notificationsQuery.docs.length,
        feedback: feedbackQuery.docs.length,
        sessions: sessionsQuery.docs.length
      }
    });

  } catch (error) {
    console.error('Error deleting user:', error);
    return res.status(500).json({
      error: 'Failed to delete user',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export const userRoutes = router;
