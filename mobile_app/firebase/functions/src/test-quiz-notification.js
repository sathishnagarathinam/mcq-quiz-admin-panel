/**
 * Test function for sending quiz notifications
 * This demonstrates how to send FCM notifications with quiz links
 */

const admin = require('firebase-admin');

/**
 * Send a test quiz notification
 * @param {string} quizId - The quiz document ID from Firestore
 * @param {string} quizTitle - The quiz title for notification
 * @param {string} quizDescription - Brief description of the quiz
 * @param {string} target - Target audience ('all_users', 'ssc_students', etc.)
 * @param {Object} quizMetadata - Additional quiz information
 */
async function sendTestQuizNotification(
  quizId,
  quizTitle,
  quizDescription,
  target = 'all_users',
  quizMetadata = {}
) {
  try {
    console.log(`📤 Sending test quiz notification for: ${quizTitle}`);

    // Verify quiz exists in Firestore
    const quizDoc = await admin.firestore()
      .collection('exams')
      .doc(quizId)
      .get();

    if (!quizDoc.exists) {
      throw new Error(`Quiz not found: ${quizId}`);
    }

    const quizData = quizDoc.data();
    console.log(`✅ Quiz found: ${quizData.name}`);

    // Generate quiz link
    const actionUrl = `/quiz/${quizId}/instructions`;

    // Prepare FCM message
    const message = {
      notification: {
        title: `🎯 ${quizTitle}`,
        body: quizDescription,
        image: quizMetadata.imageUrl || undefined
      },
      data: {
        // Required fields for quiz navigation
        actionType: 'quiz',
        actionUrl: actionUrl,
        quizId: quizId,
        category: 'quiz_update',
        priority: 'high',
        
        // Optional quiz metadata (all values must be strings)
        examType: quizData.examType || '',
        subject: quizMetadata.subject || '',
        numberOfQuestions: quizData.numberOfQuestions?.toString() || '0',
        timeLimit: quizData.timeLimit?.toString() || '0',
        difficultyLevel: quizData.difficultyLevel || '',
        isFree: quizData.isFree?.toString() || 'false',
        price: quizData.price?.toString() || '0'
      },
      topic: target,
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#1976D2',
          sound: 'default',
          channelId: 'mcq_notifications',
        },
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: `🎯 ${quizTitle}`,
              body: quizDescription
            },
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    // Send the notification
    const response = await admin.messaging().send(message);
    
    console.log('✅ Quiz notification sent successfully!');
    console.log(`📊 Message ID: ${response}`);
    console.log(`🔗 Quiz Link: ${actionUrl}`);
    
    return {
      success: true,
      messageId: response,
      quizLink: actionUrl,
      quizData: {
        id: quizId,
        name: quizData.name,
        examType: quizData.examType,
        isFree: quizData.isFree,
        price: quizData.price
      }
    };

  } catch (error) {
    console.error('❌ Error sending quiz notification:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Send quiz notification to specific user
 * @param {string} userId - Target user ID
 * @param {string} quizId - Quiz document ID
 * @param {string} quizTitle - Quiz title
 * @param {string} quizDescription - Quiz description
 */
async function sendQuizNotificationToUser(userId, quizId, quizTitle, quizDescription) {
  try {
    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('mobile_users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      throw new Error(`User not found: ${userId}`);
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      throw new Error(`User has no FCM token: ${userId}`);
    }

    // Get quiz data
    const quizDoc = await admin.firestore()
      .collection('exams')
      .doc(quizId)
      .get();

    if (!quizDoc.exists) {
      throw new Error(`Quiz not found: ${quizId}`);
    }

    const quizData = quizDoc.data();
    const actionUrl = `/quiz/${quizId}/instructions`;

    // Prepare message for specific user
    const message = {
      notification: {
        title: `🎯 ${quizTitle}`,
        body: quizDescription
      },
      data: {
        actionType: 'quiz',
        actionUrl: actionUrl,
        quizId: quizId,
        category: 'quiz_update',
        priority: 'high',
        examType: quizData.examType || '',
        numberOfQuestions: quizData.numberOfQuestions?.toString() || '0',
        timeLimit: quizData.timeLimit?.toString() || '0'
      },
      token: fcmToken,
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#1976D2',
          sound: 'default',
          channelId: 'mcq_notifications',
        },
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: `🎯 ${quizTitle}`,
              body: quizDescription
            },
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    
    console.log(`✅ Quiz notification sent to user: ${userData.name}`);
    console.log(`📊 Message ID: ${response}`);
    
    return {
      success: true,
      messageId: response,
      userId: userId,
      userName: userData.name
    };

  } catch (error) {
    console.error('❌ Error sending quiz notification to user:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Example usage and test cases
 */
async function runQuizNotificationTests() {
  console.log('🧪 Running quiz notification tests...\n');

  // Test 1: Send to all users
  console.log('📋 Test 1: Send quiz notification to all users');
  const result1 = await sendTestQuizNotification(
    'ssc_cgl_quantitative_2024',
    'SSC CGL Quantitative Aptitude',
    '50 questions • 60 minutes • Practice now!',
    'all_users',
    {
      subject: 'Quantitative Aptitude',
      imageUrl: 'https://example.com/ssc-banner.jpg'
    }
  );
  console.log('Result:', result1);
  console.log('');

  // Test 2: Send to specific topic
  console.log('📋 Test 2: Send banking quiz to banking students');
  const result2 = await sendTestQuizNotification(
    'ibps_po_reasoning_2024',
    'IBPS PO Reasoning',
    'Logical reasoning questions for banking exam',
    'banking_students',
    {
      subject: 'Reasoning'
    }
  );
  console.log('Result:', result2);
  console.log('');

  // Test 3: Send to specific user (replace with actual user ID)
  console.log('📋 Test 3: Send quiz notification to specific user');
  const result3 = await sendQuizNotificationToUser(
    'USER_ID_HERE', // Replace with actual user ID
    'post_office_gk_2024',
    'Post Office General Knowledge',
    'Test your GK preparation for Post Office exam'
  );
  console.log('Result:', result3);
  console.log('');

  console.log('🎉 Quiz notification tests completed!');
}

module.exports = {
  sendTestQuizNotification,
  sendQuizNotificationToUser,
  runQuizNotificationTests
};

// Uncomment to run tests
// runQuizNotificationTests();
