import { collection, addDoc, getDocs, query, orderBy, limit, Timestamp } from 'firebase/firestore';
import { db } from '../config/firebase';

export interface AppUpdateNotification {
  id?: string;
  title: string;
  body: string;
  updateUrl: string;
  imageUrl?: string;
  sentAt?: Timestamp;
  sentBy: string;
  targetAudience: string;
  type: 'app_update';
}

export interface AppUpdateStats {
  totalNotificationsSent: number;
  lastNotificationSent?: Date;
  recentNotifications: AppUpdateNotification[];
}

class AppUpdateService {
  private readonly COLLECTION_NAME = 'app_notifications';

  /**
   * Send app update notification to all users
   */
  async sendAppUpdateNotification(notification: Omit<AppUpdateNotification, 'id' | 'sentAt' | 'type'>): Promise<string> {
    try {
      console.log('📱 Sending app update notification...', notification);

      // Validate required fields
      if (!notification.title || !notification.body || !notification.updateUrl) {
        throw new Error('Title, body, and update URL are required');
      }

      // Validate update URL
      try {
        new URL(notification.updateUrl);
      } catch {
        throw new Error('Invalid update URL format');
      }

      // Prepare FCM message for topic-based sending
      const fcmPayload = {
        topic: 'all_users',
        notification: {
          title: notification.title,
          body: notification.body,
          ...(notification.imageUrl && { image: notification.imageUrl }),
        },
        data: {
          actionType: 'app_update',
          actionUrl: notification.updateUrl,
          timestamp: Date.now().toString(),
        },
      };

      // Send via Firebase Cloud Functions
      console.log('📤 Sending FCM message via Cloud Functions...');

      const functionsUrl = process.env.NODE_ENV === 'development' && process.env.REACT_APP_USE_EMULATOR === 'true'
        ? 'http://127.0.0.1:5001/mcq-quiz-system/us-central1/api'
        : process.env.REACT_APP_FUNCTIONS_URL ||
          'https://us-central1-mcq-quiz-system.cloudfunctions.net/api';

      const response = await fetch(`${functionsUrl}/notifications/send-to-topic`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      });

      if (!response.ok) {
        const errorData = await response.text();
        throw new Error(`Failed to send FCM message: ${response.status} - ${errorData}`);
      }

      const result = await response.json();
      console.log('✅ FCM message sent successfully:', result);

      // Save notification record to Firestore
      const notificationRecord: AppUpdateNotification = {
        ...notification,
        type: 'app_update',
        sentAt: Timestamp.now(),
      };

      const docRef = await addDoc(collection(db, this.COLLECTION_NAME), notificationRecord);
      console.log('✅ Notification record saved to Firestore:', docRef.id);

      return docRef.id;
    } catch (error) {
      console.error('❌ Error sending app update notification:', error);
      throw error;
    }
  }

  /**
   * Get app update notification statistics
   */
  async getAppUpdateStats(): Promise<AppUpdateStats> {
    try {
      console.log('📊 Fetching app update statistics...');

      // Get recent app update notifications
      const q = query(
        collection(db, this.COLLECTION_NAME),
        orderBy('sentAt', 'desc'),
        limit(10)
      );

      const querySnapshot = await getDocs(q);
      const recentNotifications: AppUpdateNotification[] = [];
      let totalCount = 0;
      let lastNotificationDate: Date | undefined;

      querySnapshot.forEach((doc) => {
        const data = doc.data() as AppUpdateNotification;
        if (data.type === 'app_update') {
          const notification = {
            id: doc.id,
            ...data,
          };
          recentNotifications.push(notification);
          totalCount++;

          if (!lastNotificationDate && data.sentAt) {
            lastNotificationDate = data.sentAt.toDate();
          }
        }
      });

      const stats: AppUpdateStats = {
        totalNotificationsSent: totalCount,
        lastNotificationSent: lastNotificationDate,
        recentNotifications,
      };

      console.log('✅ App update stats fetched:', stats);
      return stats;
    } catch (error) {
      console.error('❌ Error fetching app update stats:', error);
      throw error;
    }
  }

  /**
   * Get all app update notifications with pagination
   */
  async getAppUpdateNotifications(limitCount: number = 20): Promise<AppUpdateNotification[]> {
    try {
      console.log(`📋 Fetching ${limitCount} app update notifications...`);

      const q = query(
        collection(db, this.COLLECTION_NAME),
        orderBy('sentAt', 'desc'),
        limit(limitCount)
      );

      const querySnapshot = await getDocs(q);
      const notifications: AppUpdateNotification[] = [];

      querySnapshot.forEach((doc) => {
        const data = doc.data() as AppUpdateNotification;
        if (data.type === 'app_update') {
          notifications.push({
            id: doc.id,
            ...data,
          });
        }
      });

      console.log(`✅ Fetched ${notifications.length} app update notifications`);
      return notifications;
    } catch (error) {
      console.error('❌ Error fetching app update notifications:', error);
      throw error;
    }
  }

  /**
   * Validate app store URL
   */
  validateAppStoreUrl(url: string): { isValid: boolean; platform?: 'android' | 'ios'; error?: string } {
    try {
      const urlObj = new URL(url);
      
      // Check for Google Play Store
      if (urlObj.hostname === 'play.google.com' && urlObj.pathname.includes('/store/apps/details')) {
        return { isValid: true, platform: 'android' };
      }
      
      // Check for Apple App Store
      if (urlObj.hostname === 'apps.apple.com' || urlObj.hostname === 'itunes.apple.com') {
        return { isValid: true, platform: 'ios' };
      }
      
      // Allow other valid URLs (for direct APK downloads, etc.)
      if (urlObj.protocol === 'https:') {
        return { isValid: true };
      }
      
      return { isValid: false, error: 'URL must be HTTPS and preferably from official app stores' };
    } catch {
      return { isValid: false, error: 'Invalid URL format' };
    }
  }

  /**
   * Generate suggested notification content based on app version
   */
  generateUpdateNotificationContent(appVersion: string, platform: 'android' | 'ios' | 'both' = 'both'): {
    title: string;
    body: string;
  } {
    const platformText = platform === 'both' ? '' : platform === 'android' ? ' for Android' : ' for iOS';
    
    return {
      title: `🚀 App Update Available${platformText}!`,
      body: `Version ${appVersion} is now available with new features and improvements. Update now for the best experience!`,
    };
  }
}

export const appUpdateService = new AppUpdateService();
export default appUpdateService;
