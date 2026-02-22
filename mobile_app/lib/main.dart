import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_app_check/firebase_app_check.dart'; // Temporarily disabled
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// Supabase removed - using Firebase Phone Auth only
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider;

import 'core/config/app_config.dart';
import 'core/config/firebase_options.dart';
// Supabase config removed - using Firebase Phone Auth only
// import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/payment_provider.dart';
import 'core/widgets/global_security_wrapper.dart';
import 'core/widgets/screenshot_blocker.dart';
import 'core/services/device_auth_service.dart';
import 'core/services/theme_initialization_service.dart';

// import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/security_service.dart';

void main() async {
  // Set up error handling with enhanced logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint('Exception: ${details.exception}');
    debugPrint('Library: ${details.library}');
    debugPrint('Context: ${details.context}');
    debugPrint('Stack trace: ${details.stack}');
    debugPrint('===================');

    // Try to log to external service in production
    try {
      // You can add Firebase Crashlytics here later
      print('Error logged: ${details.exception}');
    } catch (e) {
      print('Failed to log error: $e');
    }
  };

  // Handle errors outside of Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== PLATFORM ERROR ===');
    debugPrint('Error: $error');
    debugPrint('Stack trace: $stack');
    debugPrint('====================');

    try {
      // You can add Firebase Crashlytics here later
      print('Platform error logged: $error');
    } catch (e) {
      print('Failed to log platform error: $e');
    }
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('Starting MCQ Quiz App...');

    // Initialize theme before anything else to prevent flash
    await ThemeInitializationService.initialize();
    debugPrint('Theme initialization completed');

    // Initialize Firebase (check if already initialized)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');

      // Configure Firebase App Check for phone authentication
      // TEMPORARILY DISABLED - Causing Play Integrity token errors
      // TODO: Re-enable after proper App Check configuration in Firebase Console
      /*
      try {
        await FirebaseAppCheck.instance.activate(
          // Use debug provider for development
          androidProvider: AndroidProvider.debug,
          // For production, use: AndroidProvider.playIntegrity
        );
        debugPrint(
            'Firebase App Check configured successfully with debug provider');
      } catch (appCheckError) {
        debugPrint('App Check configuration failed: $appCheckError');
        // Continue without App Check for now
      }
      */
      debugPrint('App Check temporarily disabled for development');
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('Firebase already initialized, continuing...');
        // Still configure App Check even if Firebase was already initialized
        // TEMPORARILY DISABLED - Causing Play Integrity token errors
        /*
        try {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
          );
          debugPrint(
              'Firebase App Check configured successfully with debug provider');
        } catch (appCheckError) {
          debugPrint('App Check configuration error: $appCheckError');
          // Continue without App Check for now
        }
        */
        debugPrint('App Check temporarily disabled for development');
      } else {
        debugPrint('Firebase initialization error: ${e.message}');
        rethrow;
      }
    }

    // Configure Firestore settings for better real-time updates
    try {
      final firestore = FirebaseFirestore.instance;

      // Configure settings for real-time updates and offline persistence
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('Firestore settings configured with offline persistence');
    } catch (e) {
      debugPrint('Firestore configuration warning: $e');
      // Continue even if configuration fails
    }

    // Initialize FCM service for push notifications
    try {
      await FCMService.initialize();
      // Subscribe to app update notifications
      await FCMService.subscribeToAppUpdates();
      debugPrint('FCM service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM service: $e');
    }

    // Initialize Security service for app protection
    try {
      await SecurityService.initialize();
      debugPrint('Security service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Security service: $e');
    }

    // Start session validation monitoring
    _startSessionValidationMonitoring();

    // Supabase removed - using Firebase Phone Auth + Razorpay only
    // No Supabase initialization needed
    debugPrint('Using Firebase Phone Auth + Razorpay (no Supabase)');

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    debugPrint('Running app...');

    // Optional: Run Firebase Real-time Auth tests in debug mode
    // Uncomment one of the lines below to test Firebase Auth functionality
    // if (kDebugMode) await FirebaseRealtimeAuthTest.runAllTests();
    // if (kDebugMode) await RegistrationTestRunner.runAllTests();

    runApp(
      ProviderScope(
        child: provider.MultiProvider(
          providers: [
            provider.ChangeNotifierProvider(create: (_) => PaymentProvider()),
          ],
          child: const MCQQuizApp(),
        ),
      ),
    );
    debugPrint('App started successfully');
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Run app with error state
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App failed to initialize',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MCQQuizApp extends ConsumerWidget {
  const MCQQuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    // Set router reference in FCMService for notification navigation
    FCMService.setRouter(router);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Router Configuration
      routerConfig: router,

      // Localization
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('hi', 'IN'),
      ],

      // Builder for global configurations
      builder: (context, child) {
        // Note: Pending navigation is now handled directly in FCMService
        // with a delay to ensure the app is ready. We don't need to call
        // executePendingNavigationWithRouter here as it was causing a race
        // condition where the pending navigation was being cleared before
        // the delayed navigation could execute.

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Prevent text scaling
          ),
          child: ScreenshotBlocker(
            enabled: true,
            child: GlobalSecurityWrapper(child: child!),
          ),
        );
      },
    );
  }
}

// Error Widget for better error handling
class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomErrorWidget({
    super.key,
    required this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please restart the app',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Close App',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Start periodic session validation monitoring
void _startSessionValidationMonitoring() {
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    try {
      // This will be handled by the auth provider's session validation
      // The timer ensures regular checks for forced logouts
      debugPrint('🔍 Session validation check triggered');
    } catch (e) {
      debugPrint('❌ Error in session validation monitoring: $e');
    }
  });
}
