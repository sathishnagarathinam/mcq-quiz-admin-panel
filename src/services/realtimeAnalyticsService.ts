import { 
  collection, 
  doc, 
  onSnapshot, 
  query, 
  orderBy, 
  limit, 
  where,
  Unsubscribe,
  DocumentSnapshot,
  QuerySnapshot 
} from 'firebase/firestore';
import { db } from '../config/firebase';

export interface UserAnalytics {
  userId: string;
  statistics: {
    totalQuizzesAttempted: number;
    totalQuizzesCompleted: number;
    totalQuestionsAnswered: number;
    totalCorrectAnswers: number;
    totalTimeSpent: number;
    currentStreak: number;
    longestStreak: number;
    lastQuizDate?: Date;
  };
  performance: {
    bestScore: number;
    averageScore: number;
    worstScore: number;
    bestTime: number;
    averageTime: number;
    categoryScores: Record<string, number>;
    recentScores: Array<{ score: number; date: Date; examType: string; timeSpent?: number }>;
  };
  activity: {
    loginCount: number;
    lastLoginDate?: Date;
    sessionsThisWeek: number;
    sessionsThisMonth: number;
    averageSessionDuration: number;
    activityLevel: string;
  };
  progress: {
    currentLevel: string;
    levelProgress: number;
    experiencePoints: number;
    achievements: string[];
    rank: number;
  };
  lastUpdated: Date;
}

export interface PlatformAnalytics {
  registrationStats: {
    totalUsers: number;
    activeUsers: number;
    inactiveUsers: number;
    dailyRegistrations: Record<string, number>;
    weeklyRegistrations: Record<string, number>;
    monthlyRegistrations: Record<string, number>;
    usersByDesignation: Record<string, number>;
    growthRate: number;
  };
  engagementStats: {
    averageSessionDuration: number;
    totalSessions: number;
    sessionsByDay: Record<string, number>;
    engagementByHour: Record<string, number>;
    retentionRate: number;
    averageQuizzesPerUser: number;
    deviceTypes: Record<string, number>;
  };
  quizStats: {
    totalQuizAttempts: number;
    totalQuizCompletions: number;
    popularCategories: Record<string, number>;
    categoryAverageScores: Record<string, number>;
    overallAverageScore: number;
    totalQuestionsAnswered: number;
    averageCompletionTime: number;
    difficultyDistribution: Record<string, number>;
  };
  systemStats: {
    averageResponseTime: number;
    uptime: number;
    totalApiCalls: number;
    errorCounts: Record<string, number>;
    cacheHitRate: number;
    concurrentUsers: number;
    databasePerformance: number;
  };
  lastUpdated: Date;
}

export interface QuizAttempt {
  id: string;
  userId: string;
  examType: string;
  totalQuestions: number;
  correctAnswers: number;
  scorePercentage: number;
  timeSpent: number;
  isCompleted: boolean;
  attemptedAt: Date;
  completedAt?: Date;
}

class RealtimeAnalyticsService {
  private userAnalyticsListeners: Map<string, Unsubscribe> = new Map();
  private platformAnalyticsListener: Unsubscribe | null = null;
  private recentAttemptsListener: Unsubscribe | null = null;
  
  // Cache for performance optimization
  private userAnalyticsCache: Map<string, UserAnalytics> = new Map();
  private platformAnalyticsCache: PlatformAnalytics | null = null;
  private cacheTimestamps: Map<string, Date> = new Map();
  private platformCacheTimestamp: Date | null = null;
  
  // Cache duration (5 minutes)
  private readonly CACHE_DURATION = 5 * 60 * 1000;

  /**
   * Subscribe to user analytics updates
   */
  subscribeToUserAnalytics(
    userId: string,
    callback: (analytics: UserAnalytics | null) => void,
    onError?: (error: Error) => void
  ): Unsubscribe {
    // Cancel existing listener for this user
    this.unsubscribeFromUserAnalytics(userId);

    console.log(`📊 Setting up analytics listener for user: ${userId}`);

    const userAnalyticsRef = doc(db, 'user_analytics', userId);

    const unsubscribe = onSnapshot(
      userAnalyticsRef,
      (snapshot: DocumentSnapshot) => {
        try {
          if (snapshot.exists()) {
            const data = snapshot.data();
            console.log(`📈 Received analytics data for user ${userId}:`, data);

            const analytics = this.parseUserAnalytics(userId, data);

            // Update cache
            this.userAnalyticsCache.set(userId, analytics);
            this.cacheTimestamps.set(userId, new Date());

            console.log(`✅ Parsed analytics for user ${userId}:`, {
              totalQuizzes: analytics.statistics.totalQuizzesCompleted,
              averageScore: analytics.performance.averageScore,
              currentStreak: analytics.statistics.currentStreak
            });

            callback(analytics);
          } else {
            console.log(`⚠️ No analytics data found for user: ${userId}`);
            callback(null);
          }
        } catch (error) {
          console.error('Error processing user analytics:', error);
          onError?.(error as Error);
        }
      },
      (error) => {
        console.error('User analytics listener error:', error);
        onError?.(error as Error);
      }
    );

    this.userAnalyticsListeners.set(userId, unsubscribe);
    return unsubscribe;
  }

  /**
   * Subscribe to platform analytics updates
   */
  subscribeToPlatformAnalytics(
    callback: (analytics: PlatformAnalytics | null) => void,
    onError?: (error: Error) => void
  ): Unsubscribe {
    // Cancel existing listener
    this.unsubscribeFromPlatformAnalytics();

    const platformAnalyticsRef = doc(db, 'platform_analytics', 'global');
    
    const unsubscribe = onSnapshot(
      platformAnalyticsRef,
      (snapshot: DocumentSnapshot) => {
        try {
          if (snapshot.exists()) {
            const data = snapshot.data();
            const analytics = this.parsePlatformAnalytics(data);
            
            // Update cache
            this.platformAnalyticsCache = analytics;
            this.platformCacheTimestamp = new Date();
            
            callback(analytics);
          } else {
            callback(null);
          }
        } catch (error) {
          console.error('Error processing platform analytics:', error);
          onError?.(error as Error);
        }
      },
      (error) => {
        console.error('Platform analytics listener error:', error);
        onError?.(error as Error);
      }
    );

    this.platformAnalyticsListener = unsubscribe;
    return unsubscribe;
  }

  /**
   * Subscribe to recent quiz attempts
   */
  subscribeToRecentAttempts(
    callback: (attempts: QuizAttempt[]) => void,
    options: { userId?: string; limit?: number } = {},
    onError?: (error: Error) => void
  ): Unsubscribe {
    // Cancel existing listener
    this.unsubscribeFromRecentAttempts();

    let attemptsQuery = query(
      collection(db, 'quiz_attempts'),
      orderBy('attemptedAt', 'desc'),
      limit(options.limit || 50)
    );

    if (options.userId) {
      attemptsQuery = query(
        collection(db, 'quiz_attempts'),
        where('userId', '==', options.userId),
        orderBy('attemptedAt', 'desc'),
        limit(options.limit || 20)
      );
    }

    const unsubscribe = onSnapshot(
      attemptsQuery,
      (snapshot: QuerySnapshot) => {
        try {
          const attempts = snapshot.docs.map(doc => {
            const data = doc.data();
            return this.parseQuizAttempt(doc.id, data);
          });
          
          callback(attempts);
        } catch (error) {
          console.error('Error processing recent attempts:', error);
          onError?.(error as Error);
        }
      },
      (error) => {
        console.error('Recent attempts listener error:', error);
        onError?.(error as Error);
      }
    );

    this.recentAttemptsListener = unsubscribe;
    return unsubscribe;
  }

  /**
   * Get cached user analytics
   */
  getCachedUserAnalytics(userId: string): UserAnalytics | null {
    if (!this.isUserAnalyticsCacheValid(userId)) {
      return null;
    }
    return this.userAnalyticsCache.get(userId) || null;
  }

  /**
   * Get cached platform analytics
   */
  getCachedPlatformAnalytics(): PlatformAnalytics | null {
    if (!this.isPlatformAnalyticsCacheValid()) {
      return null;
    }
    return this.platformAnalyticsCache;
  }

  /**
   * Unsubscribe from user analytics
   */
  unsubscribeFromUserAnalytics(userId: string): void {
    const unsubscribe = this.userAnalyticsListeners.get(userId);
    if (unsubscribe) {
      unsubscribe();
      this.userAnalyticsListeners.delete(userId);
    }
  }

  /**
   * Unsubscribe from platform analytics
   */
  unsubscribeFromPlatformAnalytics(): void {
    if (this.platformAnalyticsListener) {
      this.platformAnalyticsListener();
      this.platformAnalyticsListener = null;
    }
  }

  /**
   * Unsubscribe from recent attempts
   */
  unsubscribeFromRecentAttempts(): void {
    if (this.recentAttemptsListener) {
      this.recentAttemptsListener();
      this.recentAttemptsListener = null;
    }
  }

  /**
   * Unsubscribe from all listeners
   */
  unsubscribeFromAll(): void {
    // Unsubscribe from all user analytics
    this.userAnalyticsListeners.forEach(unsubscribe => unsubscribe());
    this.userAnalyticsListeners.clear();

    // Unsubscribe from platform analytics
    this.unsubscribeFromPlatformAnalytics();

    // Unsubscribe from recent attempts
    this.unsubscribeFromRecentAttempts();
  }

  /**
   * Clear all caches
   */
  clearAllCaches(): void {
    this.userAnalyticsCache.clear();
    this.cacheTimestamps.clear();
    this.platformAnalyticsCache = null;
    this.platformCacheTimestamp = null;
  }

  /**
   * Get cache statistics
   */
  getCacheStats() {
    return {
      userAnalyticsCacheSize: this.userAnalyticsCache.size,
      platformAnalyticsCached: this.platformAnalyticsCache !== null,
      activeListeners: {
        userAnalytics: this.userAnalyticsListeners.size,
        platformAnalytics: this.platformAnalyticsListener !== null,
        recentAttempts: this.recentAttemptsListener !== null,
      },
    };
  }

  // Private helper methods
  private parseUserAnalytics(userId: string, data: any): UserAnalytics {
    return {
      userId,
      statistics: {
        totalQuizzesAttempted: data.statistics?.totalQuizzesAttempted || 0,
        totalQuizzesCompleted: data.statistics?.totalQuizzesCompleted || 0,
        totalQuestionsAnswered: data.statistics?.totalQuestionsAnswered || 0,
        totalCorrectAnswers: data.statistics?.totalCorrectAnswers || 0,
        totalTimeSpent: data.statistics?.totalTimeSpent || 0,
        currentStreak: data.statistics?.currentStreak || 0,
        longestStreak: data.statistics?.longestStreak || 0,
        lastQuizDate: data.statistics?.lastQuizDate?.toDate(),
      },
      performance: {
        bestScore: data.performance?.bestScore || 0,
        averageScore: data.performance?.averageScore || 0,
        worstScore: data.performance?.worstScore || 0,
        bestTime: data.performance?.bestTime || 0,
        averageTime: data.performance?.averageTime || 0,
        categoryScores: data.performance?.categoryScores || {},
        recentScores: (data.performance?.recentScores || []).map((score: any) => ({
          score: score.score,
          date: score.date?.toDate(),
          examType: score.examType,
          timeSpent: score.timeSpent || 0,
        })),
      },
      activity: {
        loginCount: data.activity?.loginCount || 0,
        lastLoginDate: data.activity?.lastLoginDate?.toDate(),
        sessionsThisWeek: data.activity?.sessionsThisWeek || 0,
        sessionsThisMonth: data.activity?.sessionsThisMonth || 0,
        averageSessionDuration: data.activity?.averageSessionDuration || 0,
        activityLevel: data.activity?.activityLevel || 'Inactive',
      },
      progress: {
        currentLevel: data.progress?.currentLevel || 'Beginner',
        levelProgress: data.progress?.levelProgress || 0,
        experiencePoints: data.progress?.experiencePoints || 0,
        achievements: data.progress?.achievements || [],
        rank: data.progress?.rank || 0,
      },
      lastUpdated: data.lastUpdated?.toDate() || new Date(),
    };
  }

  private parsePlatformAnalytics(data: any): PlatformAnalytics {
    return {
      registrationStats: data.registrationStats || {},
      engagementStats: data.engagementStats || {},
      quizStats: data.quizStats || {},
      systemStats: data.systemStats || {},
      lastUpdated: data.lastUpdated?.toDate() || new Date(),
    };
  }

  private parseQuizAttempt(id: string, data: any): QuizAttempt {
    return {
      id,
      userId: data.userId || '',
      examType: data.examType || '',
      totalQuestions: data.totalQuestions || 0,
      correctAnswers: data.correctAnswers || 0,
      scorePercentage: data.scorePercentage || 0,
      timeSpent: data.timeSpent || 0,
      isCompleted: data.isCompleted || false,
      attemptedAt: data.attemptedAt?.toDate() || new Date(),
      completedAt: data.completedAt?.toDate(),
    };
  }

  private isUserAnalyticsCacheValid(userId: string): boolean {
    const analytics = this.userAnalyticsCache.get(userId);
    const timestamp = this.cacheTimestamps.get(userId);
    
    if (!analytics || !timestamp) {
      return false;
    }
    
    return Date.now() - timestamp.getTime() < this.CACHE_DURATION;
  }

  private isPlatformAnalyticsCacheValid(): boolean {
    if (!this.platformAnalyticsCache || !this.platformCacheTimestamp) {
      return false;
    }
    
    return Date.now() - this.platformCacheTimestamp.getTime() < this.CACHE_DURATION;
  }
}

// Export singleton instance
export const realtimeAnalyticsService = new RealtimeAnalyticsService();
