import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/phone_auth_redirect.dart';
import '../../features/auth/screens/email_login_screen.dart';
import '../../features/auth/screens/email_registration_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../providers/email_auth_provider.dart';
import '../providers/quiz_attempt_provider.dart';
import '../providers/user_mode_provider.dart';
import '../theme/app_theme.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/quiz/screens/quiz_list_screen.dart';
import '../../features/quiz/screens/quiz_instruction_screen.dart';
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/quiz/screens/quiz_result_screen.dart';
import '../../features/payment/screens/payment_success_test_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/privacy_policy_screen.dart';
import '../../features/settings/screens/terms_of_service_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/exam/screens/exam_screen.dart';
import '../../features/feedback/screens/feedback_history_screen.dart';
import '../../features/feedback/screens/general_feedback_history_screen.dart';
import '../../features/feedback/screens/add_feedback_screen.dart';
import '../../features/disclaimer/screens/disclaimer_screen.dart';

/// App router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(emailAuthProvider);
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnAuth = state.matchedLocation.startsWith('/auth');
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      final isOnDisclaimer = state.matchedLocation == '/disclaimer';
      final isOnDisclaimerReadonly =
          state.matchedLocation == '/disclaimer-readonly';
      // Allow quiz instructions navigation from notifications even if not authenticated
      final isOnQuizInstructions =
          state.matchedLocation.contains('/instructions');

      // If we're on splash screen, let it handle the navigation
      if (isOnSplash) {
        return null;
      }

      // If we're on disclaimer screens, allow it
      if (isOnDisclaimer || isOnDisclaimerReadonly) {
        return null;
      }

      // If we're on onboarding screen, allow it
      if (isOnOnboarding) {
        return null;
      }

      // Allow quiz instructions navigation from notifications
      if (isOnQuizInstructions) {
        return null;
      }

      // If user is authenticated and trying to access auth pages, redirect to home
      if (authState.isAuthenticated && authState.user != null && isOnAuth) {
        return '/home';
      }

      // If user is not authenticated and trying to access protected pages, redirect to login
      if (!authState.isAuthenticated &&
          !isOnAuth &&
          !isOnSplash &&
          !isOnOnboarding &&
          !isOnDisclaimer &&
          !isOnDisclaimerReadonly &&
          !isOnQuizInstructions) {
        return '/auth/email-login';
      }

      // Allow navigation
      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Disclaimer routes
      GoRoute(
        path: '/disclaimer',
        name: 'disclaimer',
        builder: (context, state) => const DisclaimerScreen(showButtons: true),
      ),
      GoRoute(
        path: '/disclaimer-readonly',
        name: 'disclaimer-readonly',
        builder: (context, state) => const DisclaimerScreen(showButtons: false),
      ),
      // Authentication routes
      // Email Authentication (Primary)
      GoRoute(
        path: '/auth/email-login',
        name: 'email-login',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/auth/email-register',
        name: 'email-registration',
        builder: (context, state) => const EmailRegistrationScreen(),
      ),
      GoRoute(
        path: '/auth/email-verification',
        name: 'email-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),

      // Phone Authentication (Legacy - kept for reference)
      GoRoute(
        path: '/auth/login',
        name: 'phone-login',
        builder: (context, state) => const PhoneAuthRedirectScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'registration',
        builder: (context, state) => const PhoneAuthRedirectScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        name: 'otp-verification',
        builder: (context, state) => const PhoneAuthRedirectScreen(),
      ),
      GoRoute(
        path: '/auth/registration-otp',
        name: 'registration-otp-verification',
        builder: (context, state) => const PhoneAuthRedirectScreen(),
      ),

      // Onboarding route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main app routes
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Home route
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const HomeScreen(),
            ),
          ),

          // Quiz routes
          GoRoute(
            path: '/quiz',
            name: 'quiz-list',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const QuizListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':quizId/instructions',
                name: 'quiz-instructions',
                pageBuilder: (context, state) {
                  final quizId = state.pathParameters['quizId']!;
                  return _buildPageWithTransition(
                    context,
                    state,
                    QuizInstructionScreen(quizId: quizId),
                  );
                },
              ),
              GoRoute(
                path: ':quizId',
                name: 'quiz',
                pageBuilder: (context, state) {
                  final quizId = state.pathParameters['quizId']!;
                  return _buildPageWithTransition(
                    context,
                    state,
                    QuizScreen(quizId: quizId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'result',
                    name: 'quiz-result',
                    pageBuilder: (context, state) {
                      final quizId = state.pathParameters['quizId']!;

                      // Handle both old format (int) and new format (Map)
                      int score = 0;
                      Map<String, dynamic> userAnswers = {};
                      List<dynamic> shuffledQuestions = [];

                      if (state.extra is Map<String, dynamic>) {
                        final extraData = state.extra as Map<String, dynamic>;
                        score = extraData['score'] as int? ?? 0;
                        userAnswers =
                            extraData['userAnswers'] as Map<String, dynamic>? ??
                                {};
                        shuffledQuestions =
                            extraData['shuffledQuestions'] as List<dynamic>? ??
                                [];
                      } else if (state.extra is int) {
                        // Backward compatibility
                        score = state.extra as int;
                      }

                      return _buildPageWithTransition(
                        context,
                        state,
                        QuizResultScreen(
                          quizId: quizId,
                          score: score,
                          userAnswers: userAnswers,
                          shuffledQuestions: shuffledQuestions,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Search route
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              SearchScreen(
                initialQuery: state.uri.queryParameters['q'],
              ),
            ),
          ),

          // Profile route
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const ProfileScreen(),
            ),
          ),

          // Exam route
          GoRoute(
            path: '/exam',
            name: 'exam',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const ExamScreen(),
            ),
          ),

          // Settings route
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const SettingsScreen(),
            ),
          ),

          // Privacy Policy route
          GoRoute(
            path: '/privacy-policy',
            name: 'privacy-policy',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const PrivacyPolicyScreen(),
            ),
          ),

          // Terms of Service route
          GoRoute(
            path: '/terms-of-service',
            name: 'terms-of-service',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const TermsOfServiceScreen(),
            ),
          ),

          // Feedback history route (quiz feedback)
          GoRoute(
            path: '/feedback-history',
            name: 'feedback-history',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const FeedbackHistoryScreen(),
            ),
          ),

          // General feedback history route
          GoRoute(
            path: '/general-feedback-history',
            name: 'general-feedback-history',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const GeneralFeedbackHistoryScreen(),
            ),
          ),

          // Add feedback route
          GoRoute(
            path: '/add-feedback',
            name: 'add-feedback',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const AddFeedbackScreen(),
            ),
          ),

          // Payment success test route
          GoRoute(
            path: '/payment-success-test',
            name: 'payment-success-test',
            pageBuilder: (context, state) {
              final examId = state.uri.queryParameters['examId'] ?? '';
              final transactionId = state.uri.queryParameters['transactionId'];
              final orderId = state.uri.queryParameters['orderId'];

              return _buildPageWithTransition(
                context,
                state,
                PaymentSuccessTestScreen(
                  examId: examId,
                  transactionId: transactionId,
                  orderId: orderId,
                ),
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

/// Main shell widget for bottom navigation
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEasyMode = ref.watch(isEasyModeProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: isEasyMode ? null : const BottomNavBar(),
    );
  }
}

/// Bottom navigation bar
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(currentLocation),
      onTap: (index) => _onTap(context, ref, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz),
          label: 'Quiz',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Exam',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  int _getCurrentIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/quiz')) return 1;
    if (location.startsWith('/exam')) return 2;
    if (location.startsWith('/profile')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, int index) async {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    // Check if user is currently taking a quiz
    final isInQuiz = _isCurrentlyInQuiz(currentLocation);

    if (isInQuiz) {
      // Show warning dialog before navigating away from quiz
      final shouldNavigate = await _showQuizAbandonDialog(context);
      if (!shouldNavigate) return;

      // If user confirms, abandon the quiz attempt
      try {
        final attemptNotifier = ref.read(currentQuizAttemptProvider.notifier);
        await attemptNotifier.abandonAttempt();
      } catch (e) {
        // Log error silently - in production, use proper logging
        debugPrint('Failed to abandon quiz attempt: $e');
      }
    }

    // Check if context is still mounted before navigation
    if (!context.mounted) return;

    // Navigate to selected tab
    switch (index) {
      case 0:
        context.goNamed('home');
        break;
      case 1:
        context.goNamed('quiz-list');
        break;
      case 2:
        context.goNamed('exam');
        break;
      case 3:
        context.goNamed('profile');
        break;
      case 4:
        context.goNamed('settings');
        break;
    }
  }

  bool _isCurrentlyInQuiz(String location) {
    // Check if the current location is a quiz screen (not quiz list or instructions)
    final quizPattern = RegExp(r'^/quiz/[^/]+$');
    return quizPattern.hasMatch(location);
  }

  Future<bool> _showQuizAbandonDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Abandon Quiz?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to leave this quiz? Your progress will be lost.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Continue Quiz',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Abandon',
                  style: GoogleFonts.poppins(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Build page with smooth transition
Page<dynamic> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade transition for smooth page changes
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
  );
}

/// Error screen for routing errors
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({
    super.key,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
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
              'Something went wrong!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.goNamed('home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Route names for easy access
class AppRoutes {
  static const String splash = 'splash';
  static const String phoneLogin = 'phone-login';
  static const String registration = 'registration';
  static const String otpVerification = 'otp-verification';
  static const String registrationOtpVerification =
      'registration-otp-verification';
  static const String onboarding = 'onboarding';
  static const String home = 'home';
  static const String quizList = 'quiz-list';
  static const String quizInstructions = 'quiz-instructions';
  static const String quiz = 'quiz';
  static const String quizResult = 'quiz-result';
  static const String search = 'search';
  static const String exam = 'exam';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String feedbackHistory = 'feedback-history';
  static const String generalFeedbackHistory = 'general-feedback-history';
  static const String addFeedback = 'add-feedback';
  static const String paymentSuccessTest = 'payment-success-test';
}

/// Extension for easy navigation
extension GoRouterExtension on BuildContext {
  /// Navigate to splash screen
  void goToSplash() => goNamed(AppRoutes.splash);

  /// Navigate to phone login
  void goToPhoneLogin() => goNamed(AppRoutes.phoneLogin);

  /// Navigate to registration
  void goToRegistration() => goNamed(AppRoutes.registration);

  /// Navigate to OTP verification
  void goToOtpVerification(Map<String, dynamic> data) => goNamed(
        AppRoutes.otpVerification,
        extra: data,
      );

  /// Navigate to registration OTP verification
  void goToRegistrationOtpVerification(Map<String, dynamic> data) => goNamed(
        AppRoutes.registrationOtpVerification,
        extra: data,
      );

  /// Navigate to onboarding
  void goToOnboarding() => goNamed(AppRoutes.onboarding);

  /// Navigate to home
  void goToHome() => goNamed(AppRoutes.home);

  /// Navigate to quiz list
  void goToQuizList() => goNamed(AppRoutes.quizList);

  /// Navigate to quiz instructions
  void goToQuizInstructions(String quizId) => goNamed(
        AppRoutes.quizInstructions,
        pathParameters: {'quizId': quizId},
      );

  /// Navigate to specific quiz
  void goToQuiz(String quizId) => goNamed(
        AppRoutes.quiz,
        pathParameters: {'quizId': quizId},
      );

  /// Navigate to quiz result
  void goToQuizResult(String quizId, int score,
          [Map<String, dynamic>? userAnswers,
          List<dynamic>? shuffledQuestions]) =>
      goNamed(
        AppRoutes.quizResult,
        pathParameters: {'quizId': quizId},
        extra: {
          'score': score,
          'userAnswers': userAnswers ?? {},
          'shuffledQuestions': shuffledQuestions ?? [],
        },
      );

  /// Navigate to search
  void goToSearch({String? query}) {
    if (query != null) {
      goNamed(AppRoutes.search, queryParameters: {'q': query});
    } else {
      goNamed(AppRoutes.search);
    }
  }

  /// Navigate to exam
  void goToExam() => goNamed(AppRoutes.exam);

  /// Navigate to profile
  void goToProfile() => goNamed(AppRoutes.profile);

  /// Navigate to settings
  void goToSettings() => goNamed(AppRoutes.settings);

  /// Navigate to feedback history (quiz feedback)
  void goToFeedbackHistory() => goNamed(AppRoutes.feedbackHistory);

  /// Navigate to general feedback history
  void goToGeneralFeedbackHistory() =>
      goNamed(AppRoutes.generalFeedbackHistory);

  /// Navigate to add feedback screen
  void goToAddFeedback() => goNamed(AppRoutes.addFeedback);

  /// Navigate to payment success test screen
  void goToPaymentSuccessTest({
    required String examId,
    String? transactionId,
    String? orderId,
  }) {
    final queryParams = <String, String>{
      'examId': examId,
      if (transactionId != null) 'transactionId': transactionId,
      if (orderId != null) 'orderId': orderId,
    };

    goNamed(
      AppRoutes.paymentSuccessTest,
      queryParameters: queryParams,
    );
  }
}
