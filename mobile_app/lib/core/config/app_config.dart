class AppConfig {
  static const String appName = 'Test Series';
  static const String appTagline = 'Never Ever Give Up';
  static const String appVersion = '1.7.11';
  static const String appBuildNumber = '19';

  // App Store URLs
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.mcqquiz1.app';
  static const String appStoreUrl =
      'https://apps.apple.com/app/mcq-quiz-app/id123456789';

  // Support URLs
  static const String supportEmail = 'support@mcqquiz.com';
  static const String privacyPolicyUrl = 'https://mcqquiz.com/privacy-policy';
  static const String termsOfServiceUrl =
      'https://mcqquiz.com/terms-of-service';
  static const String helpUrl = 'https://mcqquiz.com/help';

  // Firebase Configuration
  static const String firebaseProjectId = 'mcq-quiz-system';
  static const String firebaseStorageBucket = 'mcq-quiz-system.appspot.com';

  // API Configuration
  static const String baseUrl = 'https://api.mcqquiz.com';
  static const String firebaseFunctionsUrl =
      'https://us-central1-mcq-quiz-system.cloudfunctions.net/api';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Quiz Configuration
  static const int defaultQuizQuestions = 10;
  static const int maxQuizQuestions = 50;
  static const int defaultTimePerQuestion = 60; // seconds
  static const int maxQuizTime = 3600; // 1 hour in seconds

  // Security Configuration
  static const bool enableScreenshotProtection = true;
  static const bool enableAppSwitchDetection = true;
  static const bool enableCopyPasteProtection = true;
  static const int maxSecurityViolations = 3;

  // Performance Configuration
  static const int cacheSize = 100; // MB
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxRetryAttempts = 3;

  // UI Configuration
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Pagination
  static const int questionsPerPage = 20;
  static const int resultsPerPage = 10;
  static const int leaderboardPerPage = 50;

  // Notification Configuration
  static const String fcmTopicAllUsers = 'all_users';
  static const String fcmTopicDailyChallenge = 'daily_challenge';
  static const String fcmTopicNewQuizzes = 'new_quizzes';

  // Local Storage Keys
  static const String keyUserToken = 'user_token';
  static const String keyUserPreferences = 'user_preferences';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserMode = 'user_mode';
  static const String keyLanguage = 'language';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyLastSyncTime = 'last_sync_time';

  // Feature Flags
  static const bool enableDarkMode = true;
  static const bool enableLeaderboard = true;
  static const bool enableDailyChallenge = true;
  static const bool enableBookmarks = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // Payment Gateway Configuration
  static const String paymentGateway = 'razorpay';
  static const String razorpayApiUrl =
      'https://api.razorpay.com/v1'; // Razorpay API endpoint
  static const String paymentSuccessRedirectUrl =
      'https://yourapp.com/payment-success';
  static const int quizAccessDurationDays =
      30; // Quiz access valid for 30 days after payment

  // Environment Configuration
  static const bool isDebugMode = true; // Set to false for production
  static const bool enableLogging = true;
  static const bool enablePerformanceMonitoring = true;

  // Social Features
  static const bool enableSharing = true;
  static const bool enableInviteFriends = true;
  static const String shareText =
      'Check out this amazing MCQ Quiz App for Post Office exam preparation!\n\n📱 Get the app: $playStoreUrl';

  // Gamification
  static const Map<String, int> badgeRequirements = {
    'streak_master': 7, // 7 day streak
    'speed_demon': 30, // Answer in under 30 seconds
    'perfectionist': 100, // 100% score
    'knowledge_seeker': 50, // Complete 50 quizzes
    'daily_warrior': 30, // 30 daily challenges
    'category_expert': 20, // 20 quizzes in same category
  };

  // Scoring System
  static const int correctAnswerPoints = 4;
  static const int wrongAnswerPenalty = -1;
  static const int unansweredPoints = 0;
  static const int timeBonusThreshold = 30; // seconds
  static const int timeBonusPoints = 1;

  // Adaptive Quiz Configuration
  static const double easyToMediumThreshold = 0.8; // 80% accuracy
  static const double mediumToHardThreshold = 0.85; // 85% accuracy
  static const double hardToMediumThreshold = 0.5; // 50% accuracy
  static const double mediumToEasyThreshold = 0.4; // 40% accuracy

  // Offline Configuration
  static const int maxOfflineQuizzes = 10;
  static const int maxCachedQuestions = 500;
  static const Duration offlineSyncInterval = Duration(hours: 6);

  // Image Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp'
  ];
  static const double imageCompressionQuality = 0.8;

  // Error Messages
  static const Map<String, String> errorMessages = {
    'network_error': 'Please check your internet connection and try again.',
    'server_error': 'Server error occurred. Please try again later.',
    'auth_error': 'Authentication failed. Please login again.',
    'permission_error': 'Permission denied. Please check app permissions.',
    'storage_error': 'Storage error occurred. Please free up some space.',
    'unknown_error': 'An unexpected error occurred. Please try again.',
  };

  // Success Messages
  static const Map<String, String> successMessages = {
    'quiz_completed': 'Quiz completed successfully!',
    'profile_updated': 'Profile updated successfully!',
    'bookmark_added': 'Question bookmarked successfully!',
    'bookmark_removed': 'Bookmark removed successfully!',
    'settings_saved': 'Settings saved successfully!',
  };
}
