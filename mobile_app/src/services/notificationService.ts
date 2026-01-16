import {
  collection,
  doc,
  addDoc,
  updateDoc,
  deleteDoc,
  getDocs,
  getDoc,
  query,
  where,
  orderBy,
  limit,
  Timestamp,
  writeBatch,
} from 'firebase/firestore';
import { db } from '../config/firebase';
import {
  Notification,
  NotificationTarget,
  NotificationContent,
  NotificationRecipient,
  MobileUser,

} from '../types/notification';

export class NotificationService {
  private static readonly NOTIFICATIONS_COLLECTION = 'notifications';
  private static readonly MOBILE_USERS_COLLECTION = 'mobile_users';
  private static readonly NOTIFICATION_RECIPIENTS_COLLECTION = 'notification_recipients';

  // Create a new notification
  static async createNotification(
    content: NotificationContent,
    target: NotificationTarget,
    createdBy: string,
    options: {
      priority?: 'low' | 'normal' | 'high' | 'urgent';
      category?: 'announcement' | 'quiz_update' | 'exam_alert' | 'general' | 'system' | 'test_alert';
      scheduledFor?: Date;
      deliveryMethod?: 'push_only' | 'in_app_only' | 'both';
    } = {}
  ): Promise<string> {
    try {
      console.log('Creating notification with content:', content);
      console.log('Original target:', target);
      console.log('Created by:', createdBy);
      const notificationData: Omit<Notification, 'id'> = {
        title: content.title,
        body: content.body,
        imageUrl: content.imageUrl,
        actionUrl: content.actionUrl,
        actionType: content.actionType,
        testImageUrl: content.testImageUrl,
        target,
        status: 'draft',
        sentCount: 0,
        totalTargets: 0,
        createdBy,
        createdAt: new Date(),
        scheduledFor: options.scheduledFor,
        priority: options.priority || 'normal',
        category: options.category || 'general',
        deliveryMethod: options.deliveryMethod || 'both',
      };

      // Clean the data to remove undefined values (Firestore doesn't accept undefined)
      const cleanedData: any = {
        title: notificationData.title,
        body: notificationData.body,
        status: notificationData.status,
        sentCount: notificationData.sentCount,
        totalTargets: notificationData.totalTargets,
        createdBy: notificationData.createdBy,
        createdAt: Timestamp.fromDate(notificationData.createdAt),
        priority: notificationData.priority,
        category: notificationData.category,
        deliveryMethod: notificationData.deliveryMethod,
      };

      // Clean the target object to remove undefined values
      const cleanedTarget: any = {
        type: target.type,
      };

      // Only add optional target fields if they have values
      if (target.userIds && target.userIds.length > 0) {
        cleanedTarget.userIds = target.userIds;
      }

      if (target.designation && target.designation.trim() !== '') {
        cleanedTarget.designation = target.designation.trim();
      }

      if (target.officeName && target.officeName.trim() !== '') {
        cleanedTarget.officeName = target.officeName.trim();
      }

      cleanedData.target = cleanedTarget;

      console.log('Cleaned target:', cleanedTarget);
      console.log('Final cleaned data:', cleanedData);

      // Only add optional fields if they have values
      if (content.imageUrl && content.imageUrl.trim() !== '') {
        cleanedData.imageUrl = content.imageUrl.trim();
      }

      if (content.actionUrl && content.actionUrl.trim() !== '') {
        cleanedData.actionUrl = content.actionUrl.trim();
      }

      if (content.actionType) {
        cleanedData.actionType = content.actionType;
      }

      if (content.testImageUrl && content.testImageUrl.trim() !== '') {
        cleanedData.testImageUrl = content.testImageUrl.trim();
      }

      if (options.scheduledFor) {
        cleanedData.scheduledFor = Timestamp.fromDate(options.scheduledFor);
      }

      console.log('Cleaned data for Firestore:', cleanedData);

      const docRef = await addDoc(
        collection(db, this.NOTIFICATIONS_COLLECTION),
        cleanedData
      );

      console.log('Notification created successfully with ID:', docRef.id);
      return docRef.id;
    } catch (error) {
      console.error('Error creating notification:', error);
      throw new Error('Failed to create notification');
    }
  }

  // Get target users based on notification target
  static async getTargetUsers(target: NotificationTarget): Promise<MobileUser[]> {
    try {
      console.log('Getting target users for:', target);

      // Use mobile_users collection specifically for mobile notifications
      console.log(`Using mobile_users collection for notification targeting`);
      const usersRef = collection(db, this.MOBILE_USERS_COLLECTION);

      let q;

      switch (target.type) {
        case 'all':
          // Get all active mobile users from mobile_users collection
          q = query(usersRef, where('isActive', '==', true));
          break;
        case 'specific_users':
          if (!target.userIds || target.userIds.length === 0) {
            return [];
          }
          // Firebase 'in' operator supports max 10 items, so we need to batch
          const userBatches = [];
          for (let i = 0; i < target.userIds.length; i += 10) {
            const batch = target.userIds.slice(i, i + 10);
            const batchQuery = query(
              usersRef,
              where('uid', 'in', batch),
              where('isActive', '==', true)
            );
            userBatches.push(batchQuery);
          }
          
          const allUsers: MobileUser[] = [];
          for (const batchQuery of userBatches) {
            const snapshot = await getDocs(batchQuery);
            snapshot.docs.forEach(doc => {
              const userData = doc.data();
              allUsers.push({
                uid: userData.uid || doc.id,
                name: userData.name || '',
                email: userData.email || '',
                phoneNumber: userData.phoneNumber || '',
                officeName: userData.officeName || '',
                designation: userData.designation || '',
                isActive: userData.isActive || true,
                preferences: userData.preferences,
              } as MobileUser);
            });
          }
          return allUsers;
        case 'designation':
          if (!target.designation) {
            return [];
          }
          q = query(
            usersRef,
            where('designation', '==', target.designation),
            where('isActive', '==', true)
          );
          break;
        case 'office':
          if (!target.officeName) {
            return [];
          }
          q = query(
            usersRef,
            where('officeName', '==', target.officeName),
            where('isActive', '==', true)
          );
          break;
        default:
          return [];
      }

      if (q && (target.type === 'all' || target.type === 'designation' || target.type === 'office')) {
        const snapshot = await getDocs(q);
        const users = snapshot.docs.map(doc => {
          const userData = doc.data();
          return {
            uid: userData.uid || doc.id,
            name: userData.name || '',
            email: userData.email || '',
            phoneNumber: userData.phoneNumber || '',
            officeName: userData.officeName || '',
            designation: userData.designation || '',
            isActive: userData.isActive || true,
            preferences: userData.preferences,
            userType: userData.userType,
            role: userData.role,
          } as MobileUser;
        });

        console.log(`Found ${users.length} mobile users from mobile_users collection`);
        return users;
      }

      return [];
    } catch (error) {
      console.error('Error getting target users:', error);
      throw new Error('Failed to get target users');
    }
  }

  // Send notification to users
  static async sendNotification(notificationId: string): Promise<void> {
    try {
      const notificationRef = doc(db, this.NOTIFICATIONS_COLLECTION, notificationId);
      const notificationDoc = await getDoc(notificationRef);
      
      if (!notificationDoc.exists()) {
        throw new Error('Notification not found');
      }

      const notification = { id: notificationDoc.id, ...notificationDoc.data() } as Notification;
      
      // Get target users
      const targetUsers = await this.getTargetUsers(notification.target);
      
      // Update notification status and target count
      await updateDoc(notificationRef, {
        status: 'sending',
        totalTargets: targetUsers.length,
      });

      // Create notification recipients and send push notifications
      const batch = writeBatch(db);
      const recipientsRef = collection(db, this.NOTIFICATION_RECIPIENTS_COLLECTION);

      let sentCount = 0;
      const pushNotificationPromises: Promise<any>[] = [];

      for (const user of targetUsers) {
        try {
          // Create recipient record
          const recipientData: Omit<NotificationRecipient, 'id'> = {
            userId: user.uid,
            userName: user.name,
            userEmail: user.email,
            designation: user.designation,
            officeName: user.officeName,
            status: 'sent',
            sentAt: new Date(),
          };

          const recipientRef = doc(recipientsRef);

          // Clean recipient data to remove undefined values
          const cleanedRecipientData: any = {
            userId: recipientData.userId,
            userName: recipientData.userName,
            userEmail: recipientData.userEmail,
            designation: recipientData.designation,
            officeName: recipientData.officeName,
            status: recipientData.status,
            notificationId,
            sentAt: Timestamp.fromDate(recipientData.sentAt!),
          };

          // Handle delivery method logic
          const deliveryMethod = notification.deliveryMethod || 'both';

          // Create in-app notification record only if delivery method includes in-app
          if (deliveryMethod === 'in_app_only' || deliveryMethod === 'both') {
            batch.set(recipientRef, cleanedRecipientData);
          }

          // Send push notification only if delivery method includes push
          if (deliveryMethod === 'push_only' || deliveryMethod === 'both') {
            const pushPromise = this.sendPushNotification(user, notification);
            pushNotificationPromises.push(pushPromise);
          }

          sentCount++;
        } catch (error) {
          console.error(`Failed to send notification to user ${user.uid}:`, error);
        }
      }

      // Commit batch and send push notifications
      const promises: Promise<any>[] = [...pushNotificationPromises];

      // Only commit batch if there are in-app notifications to create
      if (notification.deliveryMethod === 'in_app_only' || notification.deliveryMethod === 'both' || !notification.deliveryMethod) {
        promises.unshift(batch.commit());
      }

      await Promise.all(promises);

      // Update notification status
      await updateDoc(notificationRef, {
        status: 'sent',
        sentCount,
        sentAt: Timestamp.fromDate(new Date()),
      });

    } catch (error) {
      console.error('Error sending notification:', error);

      // Update notification status to failed with error details
      try {
        const notificationRef = doc(db, this.NOTIFICATIONS_COLLECTION, notificationId);
        await updateDoc(notificationRef, {
          status: 'failed',
          errorMessage: error instanceof Error ? error.message : String(error),
          failedAt: Timestamp.fromDate(new Date()),
        });
      } catch (updateError) {
        console.error('Error updating notification status to failed:', updateError);
      }

      // Provide more specific error messages
      if (error instanceof Error) {
        if (error.message.includes('permission-denied')) {
          throw new Error('Permission denied: Check your Firestore security rules');
        } else if (error.message.includes('not-found')) {
          throw new Error('Notification not found: The notification may have been deleted');
        } else if (error.message.includes('network')) {
          throw new Error('Network error: Check your internet connection');
        } else {
          throw new Error(`Failed to send notification: ${error.message}`);
        }
      } else {
        throw new Error('Failed to send notification: Unknown error occurred');
      }
    }
  }

  // Get all notifications
  static async getNotifications(limitCount: number = 50): Promise<Notification[]> {
    try {
      const q = query(
        collection(db, this.NOTIFICATIONS_COLLECTION),
        orderBy('createdAt', 'desc'),
        limit(limitCount)
      );
      
      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
        sentAt: doc.data().sentAt?.toDate(),
        scheduledFor: doc.data().scheduledFor?.toDate(),
      } as Notification));
    } catch (error) {
      console.error('Error getting notifications:', error);
      throw new Error('Failed to get notifications');
    }
  }

  // Get notification by ID
  static async getNotification(id: string): Promise<Notification | null> {
    try {
      const docRef = doc(db, this.NOTIFICATIONS_COLLECTION, id);
      const docSnap = await getDoc(docRef);
      
      if (!docSnap.exists()) {
        return null;
      }

      return {
        id: docSnap.id,
        ...docSnap.data(),
        createdAt: docSnap.data().createdAt?.toDate(),
        sentAt: docSnap.data().sentAt?.toDate(),
        scheduledFor: docSnap.data().scheduledFor?.toDate(),
      } as Notification;
    } catch (error) {
      console.error('Error getting notification:', error);
      throw new Error('Failed to get notification');
    }
  }

  // Delete notification
  static async deleteNotification(id: string): Promise<void> {
    try {
      await deleteDoc(doc(db, this.NOTIFICATIONS_COLLECTION, id));
    } catch (error) {
      console.error('Error deleting notification:', error);
      throw new Error('Failed to delete notification');
    }
  }

  // Get unique designations from mobile_users collection only
  static async getDesignations(): Promise<string[]> {
    try {
      console.log('Getting designations from mobile_users collection...');

      const snapshot = await getDocs(collection(db, this.MOBILE_USERS_COLLECTION));
      console.log(`Found ${snapshot.docs.length} documents in mobile_users collection`);

      const designations = new Set<string>();

      snapshot.docs.forEach(doc => {
        const userData = doc.data();
        const designation = userData.designation;

        if (designation && designation.trim() !== '') {
          designations.add(designation.trim());
        }
      });

      const result = Array.from(designations).sort();
      console.log(`Found designations from mobile users:`, result);
      return result;
    } catch (error) {
      console.error('Error getting designations:', error);
      throw new Error('Failed to get designations: ' + (error instanceof Error ? error.message : String(error)));
    }
  }

  // Get unique office names from mobile_users collection only
  static async getOfficeNames(): Promise<string[]> {
    try {
      console.log('Getting office names from mobile_users collection...');

      const snapshot = await getDocs(collection(db, this.MOBILE_USERS_COLLECTION));
      console.log(`Found ${snapshot.docs.length} documents in mobile_users collection`);

      const officeNames = new Set<string>();

      snapshot.docs.forEach(doc => {
        const userData = doc.data();
        const officeName = userData.officeName;

        if (officeName && officeName.trim() !== '') {
          officeNames.add(officeName.trim());
        }
      });

      const result = Array.from(officeNames).sort();
      console.log(`Found office names from mobile users:`, result);
      return result;
    } catch (error) {
      console.error('Error getting office names:', error);
      throw new Error('Failed to get office names: ' + (error instanceof Error ? error.message : String(error)));
    }
  }

  // Get mobile users from mobile_users collection only
  static async getMobileUsers(): Promise<MobileUser[]> {
    try {
      console.log('Getting mobile users from mobile_users collection...');

      const q = query(
        collection(db, this.MOBILE_USERS_COLLECTION),
        where('isActive', '==', true),
        orderBy('name')
      );

      const snapshot = await getDocs(q);
      console.log(`Found ${snapshot.docs.length} mobile users in mobile_users collection`);

      const users = snapshot.docs.map(doc => {
        const userData = doc.data();
        console.log(`Processing user ${doc.id}:`, {
          name: userData.name,
          email: userData.email,
          designation: userData.designation,
          officeName: userData.officeName
        });

        return {
          uid: userData.uid || doc.id,
          name: userData.name || userData.displayName || 'Unknown User',
          email: userData.email || 'No email',
          phoneNumber: userData.phoneNumber || userData.phone || '',
          officeName: userData.officeName || 'Not specified',
          designation: userData.designation || 'Not specified',
          isActive: userData.isActive !== false,
          preferences: userData.preferences,
          userType: userData.userType,
          role: userData.role,
        } as MobileUser;
      });

      console.log(`Successfully loaded ${users.length} mobile users from mobile_users collection`);
      return users;
    } catch (error) {
      console.error('Error getting mobile users:', error);
      throw new Error('Failed to get mobile users: ' + (error instanceof Error ? error.message : String(error)));
    }
  }

  // Send push notification to individual user
  private static async sendPushNotification(user: MobileUser, notification: Notification): Promise<void> {
    try {
      // Get user's FCM token from Firestore
      const userDoc = await getDoc(doc(db, this.MOBILE_USERS_COLLECTION, user.uid));
      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`📱 No FCM token found for user ${user.uid} (${user.name})`);
        return;
      }

      // Prepare FCM message with proper structure
      // Build notification object - only include image if it exists
      const notificationObj: any = {
        title: notification.title,
        body: notification.body,
      };

      // Only add image if it has a value
      const imageUrl = notification.testImageUrl || notification.imageUrl;
      if (imageUrl) {
        notificationObj.image = imageUrl;
      }

      // Build data object - all values must be strings for FCM
      const dataObj: any = {
        notificationId: notification.id,
        actionType: notification.actionType || 'general',
        actionUrl: notification.actionUrl || '',
        priority: notification.priority || 'normal',
        category: notification.category || 'general',
        deliveryMethod: notification.deliveryMethod || 'both',
      };

      // Only add testImageUrl if it exists
      if (notification.testImageUrl) {
        dataObj.testImageUrl = notification.testImageUrl;
      }

      // Build the complete message object
      const message: any = {
        notification: notificationObj,
        data: dataObj,
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
                title: notification.title,
                body: notification.body,
              },
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      console.log(`📤 Sending push notification to: ${user.name}`);

      // Send FCM message (handles CORS gracefully)
      await this.sendFCMMessage(message);

      console.log(`✅ Push notification processed for ${user.name}`);
    } catch (error) {
      console.error(`❌ Error sending push notification to ${user.uid}:`, error);
      // Don't throw - let the notification creation continue
    }
  }

  // Send FCM message via Firebase Cloud Functions
  private static async sendFCMMessage(message: any): Promise<void> {
    try {
      console.log('Attempting to send FCM message:', message.token?.substring(0, 20) + '...');

      // Check if we should enable real FCM sending
      const enableRealFCM = process.env.REACT_APP_ENABLE_REAL_FCM === 'true';

      if (!enableRealFCM && process.env.NODE_ENV === 'development') {
        console.warn('⚠️ FCM sending skipped in development mode');
        console.log('📱 To enable real FCM, set REACT_APP_ENABLE_REAL_FCM=true in .env');
        console.log('📱 Make sure Firebase Cloud Functions are deployed');

        // Simulate successful sending for development
        await new Promise(resolve => setTimeout(resolve, 500));
        console.log('✅ FCM message simulated successfully');
        return;
      }

      // Send via Firebase Cloud Functions (no CORS issues)
      console.log('📤 Sending FCM message via Cloud Functions...');

      // Get the Cloud Functions URL
      const functionsUrl = process.env.NODE_ENV === 'development' && process.env.REACT_APP_USE_EMULATOR === 'true'
        ? 'http://127.0.0.1:5001/mcq-quiz-system/us-central1/api'  // Local emulator
        : process.env.REACT_APP_FUNCTIONS_URL ||
          'https://us-central1-mcq-quiz-system.cloudfunctions.net/api';  // Production

      const response = await fetch(`${functionsUrl}/notifications/send-fcm`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: message
        }),
      });

      if (!response.ok) {
        let errorText = '';
        try {
          errorText = await response.text();
        } catch (e) {
          errorText = 'Could not read error response';
        }

        console.error('❌ Cloud Functions error:', {
          status: response.status,
          statusText: response.statusText,
          errorText: errorText
        });

        // Try to parse JSON error response
        try {
          const errorJson = JSON.parse(errorText);
          console.error('📋 Parsed error response:', errorJson);
        } catch (e) {
          // Not JSON, that's ok
        }

        throw new Error(`Cloud Functions error: ${response.status} - ${errorText}`);
      }

      const result = await response.json();
      console.log('✅ FCM message sent successfully via Cloud Functions:', result);

    } catch (error) {
      console.error('❌ Error sending FCM message:', error);

      // Don't throw the error to prevent notification creation from failing
      // Just log it and continue with in-app notification
      console.warn('📝 In-app notification will still be created despite FCM failure');
    }
  }
}
