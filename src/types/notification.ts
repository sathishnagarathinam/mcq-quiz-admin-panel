export interface NotificationTarget {
  type: 'all' | 'specific_users' | 'designation' | 'office';
  userIds?: string[];
  designation?: string;
  officeName?: string;
}

export interface NotificationContent {
  title: string;
  body: string;
  imageUrl?: string;
  actionUrl?: string;
  actionType?: 'quiz' | 'exam' | 'news' | 'general' | 'test';
  testImageUrl?: string; // For test-related notifications with image links
  quizId?: string; // Quiz ID for direct navigation
}

export interface Notification {
  id: string;
  title: string;
  body: string;
  imageUrl?: string;
  actionUrl?: string;
  actionType?: 'quiz' | 'exam' | 'news' | 'general' | 'test';
  testImageUrl?: string; // For test-related notifications with image links
  quizId?: string; // Quiz ID for direct navigation
  target: NotificationTarget;
  status: 'draft' | 'sending' | 'sent' | 'failed';
  sentCount: number;
  totalTargets: number;
  createdBy: string;
  createdAt: Date;
  sentAt?: Date;
  scheduledFor?: Date;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  category: 'announcement' | 'quiz_update' | 'exam_alert' | 'general' | 'system' | 'test_alert';
  deliveryMethod: 'push_only' | 'in_app_only' | 'both'; // New delivery method options
}

export interface NotificationRecipient {
  userId: string;
  userName: string;
  userEmail: string;
  designation: string;
  officeName: string;
  status: 'pending' | 'sent' | 'delivered' | 'read' | 'failed';
  sentAt?: Date;
  deliveredAt?: Date;
  readAt?: Date;
  errorMessage?: string;
}

export interface NotificationStats {
  totalSent: number;
  totalDelivered: number;
  totalRead: number;
  totalFailed: number;
  deliveryRate: number;
  readRate: number;
}

export interface MobileUser {
  uid: string;
  name: string;
  email: string;
  phoneNumber: string;
  officeName: string;
  designation: string;
  isActive: boolean;
  userType?: string; // 'mobile_user' for mobile app users
  role?: string; // 'user' for regular users, 'admin' for admin users
  preferences?: {
    notifications?: boolean;
  };
}

export interface NotificationTemplate {
  id: string;
  name: string;
  title: string;
  body: string;
  category: string;
  isActive: boolean;
  createdBy: string;
  createdAt: Date;
}
