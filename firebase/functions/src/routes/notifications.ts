import { Router } from 'express';
import * as admin from 'firebase-admin';

const router = Router();

// Interface for FCM message
interface FCMMessage {
  notification: {
    title: string;
    body: string;
    image?: string;
  };
  data: {
    notificationId: string;
    actionType: string;
    actionUrl: string;
    priority: string;
    category: string;
  };
  token: string;
  android?: {
    notification: {
      icon: string;
      color: string;
      sound: string;
      channelId: string;
    };
    priority: 'high' | 'normal';
  };
  apns?: {
    payload: {
      aps: {
        alert: {
          title: string;
          body: string;
        };
        badge: number;
        sound: string;
      };
    };
  };
}

// Send FCM notification
router.post('/send-fcm', async (req, res) => {
  try {
    const { message }: { message: FCMMessage } = req.body;

    if (!message || !message.token) {
      return res.status(400).json({
        error: 'Invalid message format or missing token'
      });
    }

    // Send the message using Firebase Admin SDK
    const response = await admin.messaging().send(message);

    console.log('Successfully sent FCM message:', response);

    return res.status(200).json({
      success: true,
      messageId: response
    });

  } catch (error) {
    console.error('Error sending FCM message:', error);
    
    // Handle specific FCM errors
    if (error instanceof Error) {
      if (error.message.includes('registration-token-not-registered')) {
        return res.status(400).json({
          error: 'Invalid or expired FCM token',
          code: 'INVALID_TOKEN'
        });
      }
      
      if (error.message.includes('invalid-argument')) {
        return res.status(400).json({
          error: 'Invalid message format',
          code: 'INVALID_MESSAGE'
        });
      }
    }

    return res.status(500).json({
      error: 'Failed to send FCM message',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Send bulk FCM notifications
router.post('/send-bulk-fcm', async (req, res) => {
  try {
    const { messages }: { messages: FCMMessage[] } = req.body;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({
        error: 'Invalid messages format or empty array'
      });
    }

    // Send messages in batches of 500 (FCM limit)
    const batchSize = 500;
    const results = [];
    
    for (let i = 0; i < messages.length; i += batchSize) {
      const batch = messages.slice(i, i + batchSize);
      
      try {
        const batchResponse = await admin.messaging().sendAll(batch);
        results.push(batchResponse);
        
        console.log(`Batch ${Math.floor(i / batchSize) + 1} sent:`, {
          successCount: batchResponse.successCount,
          failureCount: batchResponse.failureCount
        });
      } catch (batchError) {
        console.error(`Error sending batch ${Math.floor(i / batchSize) + 1}:`, batchError);
        results.push({
          successCount: 0,
          failureCount: batch.length,
          responses: batch.map(() => ({ success: false, error: batchError }))
        });
      }
    }

    // Aggregate results
    const totalSuccess = results.reduce((sum, result) => sum + result.successCount, 0);
    const totalFailure = results.reduce((sum, result) => sum + result.failureCount, 0);

    return res.status(200).json({
      success: true,
      totalMessages: messages.length,
      successCount: totalSuccess,
      failureCount: totalFailure,
      results: results
    });

  } catch (error) {
    console.error('Error sending bulk FCM messages:', error);
    return res.status(500).json({
      error: 'Failed to send bulk FCM messages',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Send notification to topic
router.post('/send-to-topic', async (req, res) => {
  try {
    const { topic, notification, data } = req.body;

    if (!topic || !notification) {
      return res.status(400).json({
        error: 'Topic and notification are required'
      });
    }

    const message = {
      notification,
      data: data || {},
      topic: topic,
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#1976D2',
          sound: 'default',
          channelId: 'mcq_notifications',
        },
        priority: 'high' as const,
      },
      apns: {
        payload: {
          aps: {
            alert: notification,
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    const response = await admin.messaging().send(message);

    console.log('Successfully sent topic message:', response);

    return res.status(200).json({
      success: true,
      messageId: response
    });

  } catch (error) {
    console.error('Error sending topic message:', error);
    return res.status(500).json({
      error: 'Failed to send topic message',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Subscribe user to topic
router.post('/subscribe-to-topic', async (req, res) => {
  try {
    const { tokens, topic } = req.body;

    if (!tokens || !topic) {
      return res.status(400).json({
        error: 'Tokens and topic are required'
      });
    }

    const tokensArray = Array.isArray(tokens) ? tokens : [tokens];
    const response = await admin.messaging().subscribeToTopic(tokensArray, topic);

    console.log('Successfully subscribed to topic:', response);

    return res.status(200).json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      errors: response.errors
    });

  } catch (error) {
    console.error('Error subscribing to topic:', error);
    return res.status(500).json({
      error: 'Failed to subscribe to topic',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Unsubscribe user from topic
router.post('/unsubscribe-from-topic', async (req, res) => {
  try {
    const { tokens, topic } = req.body;

    if (!tokens || !topic) {
      return res.status(400).json({
        error: 'Tokens and topic are required'
      });
    }

    const tokensArray = Array.isArray(tokens) ? tokens : [tokens];
    const response = await admin.messaging().unsubscribeFromTopic(tokensArray, topic);

    console.log('Successfully unsubscribed from topic:', response);

    return res.status(200).json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      errors: response.errors
    });

  } catch (error) {
    console.error('Error unsubscribing from topic:', error);
    return res.status(500).json({
      error: 'Failed to unsubscribe from topic',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export { router as notificationRoutes };
