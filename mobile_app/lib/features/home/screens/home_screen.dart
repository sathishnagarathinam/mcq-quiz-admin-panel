import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/exam_provider.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/models/banner_model.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/email_auth_provider.dart';
import '../../../shared/widgets/promotional_banner.dart';
import '../../../core/providers/banner_provider.dart';
import '../../../core/providers/live_test_provider.dart';
import '../../../core/providers/trending_exam_provider.dart';
import '../../../core/providers/quiz_attempt_provider.dart';
import '../../../core/providers/exam_type_provider.dart';
import '../../../core/providers/user_mode_provider.dart';
import '../../../core/models/quiz_attempt_model.dart';
import '../widgets/purchased_quizzes_section.dart';
import '../../../core/widgets/secure_screen_wrapper.dart';
import '../../../core/models/live_test_model.dart';
import '../../../core/services/security_service.dart';
import '../widgets/analytics_dashboard_widget.dart';
import '../widgets/easy_mode_home_view.dart';

/// Custom clipper for curved edges only (corners)
class CurvedBottomClipper extends CustomClipper<Path> {
  final double offset;

  CurvedBottomClipper({this.offset = 0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = 20.0; // Radius for corner curves

    path.moveTo(0, 0);
    path.lineTo(0, size.height - radius - offset);

    // Left bottom corner curve
    path.quadraticBezierTo(
        0, size.height - offset, radius, size.height - offset);

    // Straight bottom edge
    path.lineTo(size.width - radius, size.height - offset);

    // Right bottom corner curve
    path.quadraticBezierTo(size.width, size.height - offset, size.width,
        size.height - radius - offset);

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Home screen - main dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  PageController? _bannerPageController;

  // State for exam suitability dropdown
  String _selectedSuitability = 'All';

  // Search overlay state
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchSuggestionsTimer;
  final List<String> _searchSuggestions = [
    'try Postal Guide',
    'try Postman',
    'try Postal Volumes'
  ];
  final List<String> _recentSearches = [
    'Postal Guide',
    'MTS Exam',
    'Postman Test',
    'PA Questions',
    'Inspector Quiz'
  ];

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchSuggestionsTimer?.cancel();
    _searchController.dispose();
    _bannerPageController?.dispose();
    super.dispose();
  }

  /// Test screenshot protection functionality (debug only)
  void _testScreenshotProtection(BuildContext context) async {
    try {
      // First enable screenshot protection
      await SecurityService.enableScreenProtection();

      // Wait a moment for the protection to take effect
      await Future.delayed(const Duration(milliseconds: 500));

      // Test if protection is actually active
      final bool isProtected = await SecurityService.testScreenshotProtection();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isProtected
                  ? '🛡️ Screenshot protection is ACTIVE! FLAG_SECURE is set. Try taking a screenshot - it should be blocked.'
                  : '⚠️ Screenshot protection may not be working. FLAG_SECURE is not detected.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: isProtected ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Log detailed information
      if (kDebugMode) {
        print('🧪 Screenshot Protection Test Results:');
        print('  - Protection Active: $isProtected');
        print('  - Platform: ${Platform.operatingSystem}');
        print('  - Device Type: ${Platform.isAndroid ? "Android" : "iOS"}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error testing screenshot protection: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startBannerTimer(int bannerCount) {
    _bannerTimer?.cancel();
    if (bannerCount > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        if (mounted && _bannerPageController != null) {
          final nextIndex = (_currentBannerIndex + 1) % bannerCount;
          _bannerPageController!.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  /// Helper method to get time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailAuthState = ref.watch(emailAuthProvider);
    final user = emailAuthState.user;

    return SecureScreenWrapper(
      enableScreenshotPrevention: true,
      enableScreenRecordingPrevention: true,
      showWarningOnRecording: true,
      customWarningMessage:
          'Screenshots and screen recording are not allowed for security purposes.',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // If search overlay is open, close it instead of exiting app
          if (_isSearchExpanded) {
            setState(() {
              _isSearchExpanded = false;
            });
            _searchController.clear();
            _searchSuggestionsTimer?.cancel();
            return;
          }

          // Show exit confirmation dialog
          final shouldExit = await _showExitConfirmationDialog(context);
          if (shouldExit && context.mounted) {
            // Exit the app properly
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight:
                0, // Hide the app bar but keep it for status bar color
          ),
          body: Stack(
            children: [
              // Main content - conditionally render based on mode
              Consumer(
                builder: (context, ref, child) {
                  final isEasyMode = ref.watch(isEasyModeProvider);

                  return Column(
                    children: [
                      // Fixed header with user info and exam suitability
                      _buildFixedHeader(context, ref, user),

                      // Content based on mode
                      Expanded(
                        child: isEasyMode
                            ? const EasyModeHomeView()
                            : _buildExpertModeContent(context, ref),
                      ),
                    ],
                  );
                },
              ),

              // Search overlay that slides down from notification bar and covers entire app bar
              if (_isSearchExpanded)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFullScreenSearchOverlay(context),
                ),
            ],
          ),
          floatingActionButton: Consumer(
            builder: (context, ref, child) {
              final isEasyMode = ref.watch(isEasyModeProvider);

              // Hide floating action button in easy mode
              if (isEasyMode) return const SizedBox.shrink();

              // In debug mode, show security test button
              if (kDebugMode) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      onPressed: () => _testScreenshotProtection(context),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      heroTag: "securityTest",
                      child: const Icon(Icons.security),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.extended(
                      onPressed: () {
                        // Navigate to quiz list page
                        context.goToQuizList();
                      },
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.quiz),
                      label: Text(
                        'Quick Quizzes',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      elevation: 6,
                      heroTag: "quickQuizzes",
                    ),
                  ],
                );
              }

              return FloatingActionButton.extended(
                onPressed: () {
                  // Navigate to quiz list page
                  context.goToQuizList();
                },
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.quiz),
                label: Text(
                  'Quick Quizzes',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                elevation: 6,
                heroTag: "quickQuizzes",
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  Widget _buildDynamicBanner(WidgetRef ref) {
    print('🔥 HomeScreen: Building dynamic banner...');
    final bannersAsync = ref.watch(bannersProvider);

    return bannersAsync.when(
      data: (banners) {
        print('✅ HomeScreen: Received ${banners.length} banners');
        if (banners.isEmpty) {
          print('⚠️ HomeScreen: No banners found, showing default');
          return const PromotionalBanner(
            title: 'ADMIN SYSTEM READY!',
            subtitle: 'Create banners in web admin to see them here',
            couponCode: 'ADMIN',
            discount: 'LIVE',
          );
        }

        // Filter active banners in memory
        final now = DateTime.now();
        final activeBanners = banners.where((banner) {
          final isInDateRange =
              banner.startDate.isBefore(now) && banner.endDate.isAfter(now);
          return banner.isActive && isInDateRange;
        }).toList();

        if (activeBanners.isEmpty) {
          print('⚠️ HomeScreen: No active banners found, showing default');
          return const PromotionalBanner(
            title: 'NO ACTIVE BANNERS',
            subtitle: 'Create active banners in web admin',
            couponCode: 'ADMIN',
            discount: 'READY',
          );
        }

        // Start auto-changing timer if multiple banners
        _startBannerTimer(activeBanners.length);

        // Show current banner based on index
        final bannerIndex = _currentBannerIndex % activeBanners.length;
        final banner = activeBanners[bannerIndex];
        print(
            '✅ HomeScreen: Showing banner ${bannerIndex + 1}/${activeBanners.length}: ${banner.title}');

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: PromotionalBanner(
            key: ValueKey(banner.id),
            title: banner.title,
            subtitle: banner.subtitle,
            couponCode: banner.couponCode,
            discount: banner.discount,
            primaryColor: _parseColor(banner.primaryColor),
            secondaryColor: _parseColor(banner.secondaryColor),
            icon: _parseIcon(banner.iconName),
            onTap: banner.examId != null
                ? () => _handleBannerTap(banner)
                : banner.targetUrl.isNotEmpty
                    ? () => _handleBannerTap(banner)
                    : null,
          ),
        );
      },
      loading: () {
        print('⏳ HomeScreen: Banner provider loading...');
        return const PromotionalBanner(
          title: 'LOADING...',
          subtitle: 'Please wait',
          couponCode: '',
          discount: '',
        );
      },
      error: (error, stackTrace) {
        print('❌ HomeScreen: Banner provider error: $error');
        return const PromotionalBanner(
          title: 'ERROR LOADING BANNERS',
          subtitle: 'Check Firebase connection',
          couponCode: 'ERROR',
          discount: '',
        );
      },
    );
  }

  Widget _buildDynamicLiveTests(BuildContext context, WidgetRef ref) {
    print('🔥 HomeScreen: Building dynamic live tests...');
    final liveTestsAsync = ref.watch(liveTestsProvider);

    return liveTestsAsync.when(
      data: (liveTests) {
        print('✅ HomeScreen: Received ${liveTests.length} live tests');
        if (liveTests.isEmpty) {
          print('⚠️ HomeScreen: No live tests found');
          return _buildNoLiveTests();
        }

        // Filter upcoming and live tests in memory
        final now = DateTime.now();
        final upcomingTests = liveTests
            .where((test) {
              final isUpcoming =
                  test.status == 'upcoming' && test.startTime.isAfter(now);
              final isLive = test.status == 'live' &&
                  test.startTime.isBefore(now) &&
                  test.endTime.isAfter(now);
              print(
                  '🔥 HomeScreen: Test ${test.title} - status: ${test.status}, isUpcoming: $isUpcoming, isLive: $isLive');
              return test.isActive && (isUpcoming || isLive);
            })
            .take(5)
            .toList();

        if (upcomingTests.isEmpty) {
          print('⚠️ HomeScreen: No upcoming live tests found');
          return _buildNoLiveTests();
        }

        // Show the next upcoming test
        final nextTest = upcomingTests.first;
        print('✅ HomeScreen: Showing live test: ${nextTest.title}');
        return _buildLiveTestCard(nextTest);
      },
      loading: () {
        print('⏳ HomeScreen: Live test provider loading...');
        return _buildLoadingLiveTest();
      },
      error: (error, stackTrace) {
        print('❌ HomeScreen: Live test provider error: $error');
        return _buildNoLiveTests();
      },
    );
  }

  Widget _buildLiveTestCard(LiveTestModel liveTest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Test',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: liveTest.isCurrentlyLive
                          ? Colors.red.withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      liveTest.isCurrentlyLive ? Icons.live_tv : Icons.schedule,
                      color: liveTest.isCurrentlyLive
                          ? Colors.red
                          : AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveTest.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          liveTest.isCurrentlyLive
                              ? 'LIVE NOW - ${liveTest.currentParticipants} participants'
                              : 'Starts ${_formatDateTime(liveTest.startTime)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: liveTest.isCurrentlyLive
                                ? Colors.red
                                : AppTheme.textSecondaryColor,
                            fontWeight: liveTest.isCurrentlyLive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (liveTest.isCurrentlyLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'LIVE',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              if (liveTest.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  liveTest.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods for dynamic content
  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFE91E63); // Default pink color
    }
  }

  IconData _parseIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'lightbulb':
        return Icons.lightbulb;
      case 'star':
        return Icons.star;
      case 'gift':
        return Icons.card_giftcard;
      case 'discount':
        return Icons.local_offer;
      case 'sale':
        return Icons.sell;
      case 'percent':
        return Icons.percent;
      default:
        return Icons.lightbulb;
    }
  }

  void _handleBannerTap(BannerModel banner) {
    print('Banner tapped: ${banner.title}');

    // If banner has an exam linked, navigate to that exam with discount info
    if (banner.examId != null && banner.examId!.isNotEmpty) {
      print('Navigating to exam: ${banner.examId} (${banner.examName})');
      print(
          'Applying discount: ${banner.discount} | Coupon: ${banner.couponCode}');

      // Extract discount percentage from discount string (e.g., "30%" -> 30.0)
      double discountPercentage = 0.0;
      if (banner.discount.isNotEmpty) {
        final discountStr = banner.discount.replaceAll('%', '').trim();
        discountPercentage = double.tryParse(discountStr) ?? 0.0;
      }

      // Navigate with extra data containing discount information
      context.pushNamed(
        AppRoutes.quizInstructions,
        pathParameters: {'quizId': banner.examId!},
        extra: {
          'discountPercentage': discountPercentage,
          'couponCode': banner.couponCode,
          'bannerRoutedFrom': banner.id,
        },
      );
      return;
    }

    // If banner has a target URL, handle URL navigation
    if (banner.targetUrl.isNotEmpty) {
      print('Banner has target URL: ${banner.targetUrl}');
      // TODO: Implement URL handling if needed
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'starting soon';
    }
  }

  Widget _buildNoLiveTests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Test',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.grey.shade400,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No live tests scheduled at the moment',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingLiveTest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Test',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading live tests...'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingExams(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trending Quizzes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => context.goNamed('quiz-list'),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Trending exams list
        SizedBox(
          height: 145,
          child: Consumer(
            builder: (context, ref, child) {
              final trendingExamsAsync = ref.watch(trendingExamsProvider);

              return trendingExamsAsync.when(
                data: (trendingExams) {
                  if (trendingExams.isEmpty) {
                    return Center(
                      child: Text(
                        'No trending exams available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: trendingExams.length,
                    itemBuilder: (context, index) {
                      final exam = trendingExams[index];
                      return _buildTrendingExamCard(exam, index);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading trending exams',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredQuizzes(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quizzes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => context.goNamed('quiz-list'),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filtered quizzes list
        SizedBox(
          height: 180,
          child: Consumer(
            builder: (context, ref, child) {
              final activeExamsAsync = ref.watch(activeExamsStreamProvider);

              return activeExamsAsync.when(
                data: (allExams) {
                  // Filter exams based on selected suitability
                  List<ExamModel> filteredExams;
                  if (_selectedSuitability == 'All') {
                    filteredExams = allExams;
                  } else {
                    filteredExams = allExams.where((exam) {
                      return exam.suitableFor.contains(_selectedSuitability);
                    }).toList();
                  }

                  if (filteredExams.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedSuitability == 'All'
                            ? 'No quizzes available'
                            : 'No quizzes available for $_selectedSuitability',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredExams.length,
                    itemBuilder: (context, index) {
                      final exam = filteredExams[index];
                      return _buildTrendingExamCard(exam, index);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading quizzes',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingExamCard(ExamModel exam, int index) {
    return Consumer(
      builder: (context, ref, child) {
        // Get exam types for dynamic icon lookup
        final examTypes = ref.watch(examTypesListProvider);

        // Get user's last attempt for this exam
        final lastAttemptAsync = ref.watch(userLastAttemptProvider(exam.id));

        // Enhanced color scheme with gradients
        List<Color> gradientColors;
        Color accentColor;
        String iconEmoji;

        switch (exam.examType) {
          case 'Postal guide':
            gradientColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
            accentColor = const Color(0xFF6366F1);
            break;
          case 'Postal Volumes':
            gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
            accentColor = const Color(0xFF10B981);
            break;
          case 'General Knowledge':
            gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
            accentColor = const Color(0xFFEF4444);
            break;
          case 'Current Affairs':
            gradientColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
            accentColor = const Color(0xFFF59E0B);
            break;
          case 'Mathematics':
            gradientColors = [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
            accentColor = const Color(0xFF3B82F6);
            break;
          default:
            gradientColors = [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
            accentColor = const Color(0xFF8B5CF6);
        }

        // Use dynamic icon from exam types
        iconEmoji = ExamTypeUtils.getIconForExamType(exam.examType, examTypes);

        return GestureDetector(
          onTap: () async {
            // Add haptic feedback for better UX
            HapticFeedback.lightImpact();

            // Increment attempt count in background (non-blocking)
            final trendingService = ref.read(trendingExamServiceProvider);
            // Don't await - let it run in background
            trendingService.incrementExamAttempts(exam.id).catchError((error) {
              debugPrint('Error tracking trending exam attempt: $error');
            });

            // Always go to instructions first for both free and paid quizzes
            // The instruction screen will handle payment logic if needed
            context.goToQuizInstructions(exam.id);
          },
          child: Container(
            width: 130,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  gradientColors[0].withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section with icon and price badge
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badges container - show both trending and price info
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Trending badge (if trending)
                            if (exam.isTrending) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade600,
                                      Colors.orange.shade800
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'TRENDING',
                                      style: GoogleFonts.poppins(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Price badge (always show - paid or free)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              margin: EdgeInsets.only(
                                bottom: 2,
                                top: exam.isTrending ? 2 : 0,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: exam.isFree
                                      ? [
                                          Colors.blue.shade600,
                                          Colors.blue.shade800
                                        ]
                                      : [
                                          Colors.green.shade600,
                                          Colors.green.shade800
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                exam.isFree ? 'FREE' : '₹${exam.price.toInt()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Exam icon without background
                        Text(
                          iconEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ],
                    ),

                    // Middle section with exam name
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Exam name
                          Text(
                            exam.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Exam type badge (compact)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              exam.examType,
                              style: GoogleFonts.poppins(
                                fontSize: 7,
                                fontWeight: FontWeight.w500,
                                color: accentColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom section with stats (compact)
                    SizedBox(
                      height: 18,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Questions count
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                size: 9,
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 1),
                              Text(
                                '${exam.numberOfQuestions}',
                                style: GoogleFonts.poppins(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),

                          // Attempt count
                          if (exam.totalAttempts > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 9,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 1),
                                Text(
                                  '${exam.totalAttempts}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w500,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),

                          // Previous attempt time
                          lastAttemptAsync.when(
                            data: (lastAttempt) {
                              if (lastAttempt != null) {
                                final timeAgo =
                                    _getTimeAgo(lastAttempt.attemptedAt);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 9,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 1),
                                    Text(
                                      timeAgo,
                                      style: GoogleFonts.poppins(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveTests(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Test',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.live_tv,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IBPS RRB Officer Prelims Live Test 10',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Test Available From Jun 25 5:30 PM',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Quizzes Taken',
                  '12',
                  Icons.quiz,
                  AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Average Score',
                  '85%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Streak',
                  '7 days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Take Quiz',
                'Start a new quiz',
                Icons.play_arrow,
                AppTheme.primaryColor,
                () => context.goNamed('quiz-list'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'View Results',
                'Check your scores',
                Icons.assessment,
                Colors.blue,
                () => context.goNamed('profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'Mathematics Quiz',
                'Scored 90% • 2 hours ago',
                Icons.calculate,
                Colors.green,
              ),
              const Divider(),
              _buildActivityItem(
                'Science Quiz',
                'Scored 75% • Yesterday',
                Icons.science,
                Colors.blue,
              ),
              const Divider(),
              _buildActivityItem(
                'History Quiz',
                'Scored 85% • 2 days ago',
                Icons.history_edu,
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedQuizzes(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Quizzes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => context.goNamed('quiz-list'),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Analytics Dashboard
        const AnalyticsDashboardWidget(),

        const SizedBox(height: 16),

        // User's Recent Quiz Attempts
        Consumer(
          builder: (context, ref, child) {
            final recentAttemptsAsync =
                ref.watch(userRecentAttemptsProvider(5));

            return recentAttemptsAsync.when(
              data: (attempts) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (attempts.isEmpty) ...[
                      // Hide empty state due to tight height constraints
                      // Just show a simple text message
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No recent quiz attempts',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: 200, // Increased height to accommodate content
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4), // Add padding
                          itemCount: attempts.length,
                          itemBuilder: (context, index) {
                            final attempt = attempts[index];
                            return _buildRecentAttemptCard(
                              attempt,
                              () async {
                                // Always go to instructions first for both free and paid quizzes
                                // The instruction screen will handle payment logic if needed
                                if (context.mounted) {
                                  context.goToQuizInstructions(attempt.examId);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 160,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading exams from Firebase...'),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load quizzes',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Error: ${error.toString()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.errorColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            ref.refresh(featuredExamsStreamProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Add some bottom padding to prevent overflow
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExamCard(ExamModel exam, VoidCallback onTap) {
    return Consumer(
      builder: (context, ref, child) {
        // Get exam types for dynamic icon lookup
        final examTypes = ref.watch(examTypesListProvider);

        // Get user's last attempt for this exam
        final lastAttemptAsync = ref.watch(userLastAttemptProvider(exam.id));

        // Enhanced color scheme with gradients (same as trending cards)
        List<Color> gradientColors;
        Color accentColor;

        switch (exam.examType) {
          case 'Postal guide':
            gradientColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
            accentColor = const Color(0xFF6366F1);
            break;
          case 'Postal Volumes':
            gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
            accentColor = const Color(0xFF10B981);
            break;
          case 'General Knowledge':
            gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
            accentColor = const Color(0xFFEF4444);
            break;
          case 'Current Affairs':
            gradientColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
            accentColor = const Color(0xFFF59E0B);
            break;
          case 'Mathematics':
            gradientColors = [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
            accentColor = const Color(0xFF3B82F6);
            break;
          default:
            gradientColors = [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
            accentColor = const Color(0xFF8B5CF6);
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 160,
            height: 180, // Add fixed height to prevent overflow
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12), // Reduce padding slightly
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  gradientColors[0].withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Use minimum space needed
              children: [
                // Exam type icon and status (consistent with web admin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        ExamTypeUtils.getIconForExamType(
                            exam.examType, examTypes),
                        style: const TextStyle(
                            fontSize: 18), // Slightly smaller for better fit
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: exam.isReady ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exam.isReady ? 'Ready' : 'Draft',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduce spacing

                // Exam name - properly aligned
                Text(
                  exam.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 20, // Slightly smaller font
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    height: 1.2, // Better line height for alignment
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left, // Ensure left alignment
                ),
                const SizedBox(height: 6), // Reduce spacing

                // Exam details
                Row(
                  children: [
                    const Icon(
                      Icons.quiz,
                      size: 12, // Smaller icon
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${exam.questions.length} Questions',
                        style: GoogleFonts.poppins(
                          fontSize: 11, // Smaller font
                          color: AppTheme.textSecondaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3), // Reduce spacing
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12, // Smaller icon
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        exam.formattedDuration,
                        style: GoogleFonts.poppins(
                          fontSize: 11, // Smaller font
                          color: AppTheme.textSecondaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Previous attempt time
                lastAttemptAsync.when(
                  data: (lastAttempt) {
                    if (lastAttempt != null) {
                      final timeAgo = _getTimeAgo(lastAttempt.attemptedAt);
                      return Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history,
                              size: 12,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'Last: $timeAgo',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 6), // Reduce spacing

                // Suitable for tags - use remaining space efficiently
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Wrap(
                      spacing: 3,
                      runSpacing: 2,
                      children: exam.suitableFor.take(2).map((role) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            role,
                            style: GoogleFonts.poppins(
                              fontSize: 9, // Smaller font
                              fontWeight: FontWeight.w500,
                              color: accentColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentAttemptCard(QuizAttemptModel attempt, VoidCallback onTap) {
    return Consumer(
      builder: (context, ref, child) {
        // Get exam types for dynamic icon lookup
        final examTypes = ref.watch(examTypesListProvider);

        // Enhanced color scheme with gradients (same as trending cards)
        List<Color> gradientColors;
        Color accentColor;

        switch (attempt.examType) {
          case 'Postal guide':
            gradientColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
            accentColor = const Color(0xFF6366F1);
            break;
          case 'Postal Volumes':
            gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
            accentColor = const Color(0xFF10B981);
            break;
          case 'General Knowledge':
            gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
            accentColor = const Color(0xFFEF4444);
            break;
          case 'Current Affairs':
            gradientColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
            accentColor = const Color(0xFFF59E0B);
            break;
          case 'Mathematics':
            gradientColors = [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
            accentColor = const Color(0xFF3B82F6);
            break;
          default:
            gradientColors = [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
            accentColor = const Color(0xFF8B5CF6);
        }

        // Get status color
        Color getStatusColor(String status) {
          switch (status) {
            case 'completed':
              return Colors.green;
            case 'in_progress':
              return Colors.orange;
            case 'abandoned':
              return Colors.red;
            default:
              return Colors.grey;
          }
        }

        final statusColor = getStatusColor(attempt.status);
        final icon =
            ExamTypeUtils.getIconForExamType(attempt.examType, examTypes);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  gradientColors[0].withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Use minimum space needed
                children: [
                  // Header with icon and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6), // Reduced padding
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          icon,
                          style:
                              const TextStyle(fontSize: 18), // Slightly smaller
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          attempt.statusDisplayText,
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Reduced spacing

                  // Exam name
                  Flexible(
                    child: Text(
                      attempt.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 13, // Slightly smaller
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3), // Reduced spacing

                  // Exam type
                  Text(
                    attempt.examType,
                    style: GoogleFonts.poppins(
                      fontSize: 9, // Slightly smaller
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced spacing

                  // Score and time info
                  if (attempt.isCompleted && attempt.score != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 11, // Slightly smaller
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3), // Reduced spacing
                        Text(
                          '${attempt.score}/${attempt.totalQuestions}',
                          style: GoogleFonts.poppins(
                            fontSize: 9, // Slightly smaller
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        if (attempt.scorePercentage != null) ...[
                          const SizedBox(width: 6), // Reduced spacing
                          Text(
                            '${attempt.scorePercentage!.toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 9, // Slightly smaller
                              fontWeight: FontWeight.w600,
                              color: attempt.scorePercentage! >= 60
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3), // Reduced spacing
                  ],

                  // Attempt time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 11, // Slightly smaller
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 3), // Reduced spacing
                      Flexible(
                        child: Text(
                          attempt.formattedAttemptDate,
                          style: GoogleFonts.poppins(
                            fontSize: 9, // Slightly smaller
                            color: AppTheme.textSecondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Expert mode content (original home screen content)
  Widget _buildExpertModeContent(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Search bar and banner section only
          _buildScrollableAppBarSection(context, ref),

          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Filtered Quizzes section (based on exam suitability dropdown)
                _buildFilteredQuizzes(context, ref),

                const SizedBox(height: 24),

                // Trending Exams section
                _buildTrendingExams(context, ref),

                const SizedBox(height: 24),

                // Your Purchased Quizzes section
                const PurchasedQuizzesSection(),

                const SizedBox(height: 24),

                // Dynamic Live Test section
                _buildDynamicLiveTests(context, ref),

                const SizedBox(height: 24),

                // Featured Quizzes
                _buildFeaturedQuizzes(context, ref),

                // Add some bottom padding to prevent overflow
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mode toggle switch widget
  Widget _buildModeToggle(WidgetRef ref) {
    final isEasyMode = ref.watch(isEasyModeProvider);
    final userModeNotifier = ref.read(userModeProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => userModeNotifier.setEasyMode(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isEasyMode
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Easy',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isEasyMode
                      ? AppTheme.primaryColor
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 1),
          GestureDetector(
            onTap: () => userModeNotifier.setExpertMode(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: !isEasyMode
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Expert',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: !isEasyMode
                      ? AppTheme.primaryColor
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fixed header with title, user info and exam suitability dropdown
  Widget _buildFixedHeader(BuildContext context, WidgetRef ref, dynamic user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row with mode toggle, title, and logo
              Row(
                children: [
                  // Mode toggle switch (left side) - fixed width container
                  SizedBox(
                    width: 80,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: _buildModeToggle(ref),
                      ),
                    ),
                  ),

                  // Title (center) - properly centered
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DEPARTMENT OF POST',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'MCQ',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // App logo (right side) - fixed width container to balance left side
                  SizedBox(
                    width: 80,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bottom row with dropdown, welcome message and profile
              Row(
                children: [
                  // Exam Suitability Dropdown (left side)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSuitability,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedSuitability = newValue;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 18,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        dropdownColor: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(8),
                        items: const [
                          'All',
                          'MTS',
                          'Postman',
                          'Postal Assistant',
                          'Inspector',
                          'Group B',
                          'Others',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Welcome message and user name (right side)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome back!',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        user?.name ?? user?.email?.split('@').first ?? 'User',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // User profile icon
                  GestureDetector(
                    onTap: () {
                      context.pushNamed('profile');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Scrollable app bar section with search and banner
  Widget _buildScrollableAppBarSection(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.9),
            AppTheme.primaryColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: ClipPath(
        clipper: CurvedBottomClipper(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.8),
                AppTheme.primaryColor.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: Column(
            children: [
              // Search bar
              _buildIntegratedSearchBar(context),

              const SizedBox(height: 16),

              // Banner
              _buildIntegratedBanner(bannersAsync),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern integrated app bar with search and banner - like food delivery app
  Widget _buildModernIntegratedAppBar(
      BuildContext context, WidgetRef ref, dynamic user) {
    final bannersAsync = ref.watch(bannersProvider);

    return SizedBox(
      height:
          550, // MAXIMUM height to ensure Department of Post title is visible
      child: Stack(
        children: [
          // First layer (background) - Darker gradient
          ClipPath(
            clipper: CurvedBottomClipper(offset: 5),
            child: Container(
              height: 550,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                    AppTheme.primaryColor.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          // Second layer (foreground) - Brighter gradient
          ClipPath(
            clipper: CurvedBottomClipper(),
            child: Container(
              height: 545,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.9),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🏛️ DEPARTMENT OF POST MCQ TITLE - MAXIMUM VISIBILITY
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(0, 6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    '🏛️ DEPARTMENT OF POST',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.8),
                                          offset: const Offset(0, 3),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // App logo on the right side
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        offset: const Offset(0, 4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '📝 MCQ',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 3.0,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.8),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Top row with dropdown and user info
                      Row(
                        children: [
                          // Exam Suitability Dropdown (left side) - No background
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSuitability,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedSuitability = newValue;
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                dropdownColor: const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(8),
                                items: const [
                                  'All',
                                  'MTS',
                                  'Postman',
                                  'Postal Assistant',
                                  'Inspector',
                                  'Group B',
                                  'Others',
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // User profile icon
                          GestureDetector(
                            onTap: () {
                              // Navigate to profile or show menu
                              context.pushNamed('profile');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Welcome message and user name (centered) - Compact
                      Text(
                        'Welcome back, ${user?.name ?? user?.email?.split('@').first ?? 'User'}!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Search bar (without overlay here)
                      _buildIntegratedSearchBar(context),

                      const SizedBox(height: 12),

                      // Banner integrated in app bar
                      _buildIntegratedBanner(bannersAsync),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Integrated search bar for app bar - food delivery style
  Widget _buildIntegratedSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSearchExpanded = true;
        });
        // Start the search suggestions timer when overlay opens
        _startSearchSuggestionsTimer();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10), // Reduced from 14 to 10
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.grey.shade400,
                size: 18, // Reduced from 20 to 18
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search for exams & quizzes',
                  style: GoogleFonts.poppins(
                    fontSize: 13, // Reduced from 14 to 13
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.all(6), // Reduced from 8 to 6
                decoration: BoxDecoration(
                  color: Colors.orange.shade500,
                  borderRadius: BorderRadius.circular(6), // Reduced from 8 to 6
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 16, // Reduced from 18 to 16
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full-screen search overlay that slides down from notification bar
  Widget _buildFullScreenSearchOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSearchExpanded = false;
        });
        _searchController.clear();
        _searchSuggestionsTimer?.cancel();
      },
      child: Container(
        color:
            Colors.black.withValues(alpha: 0.3), // Semi-transparent background
        child: Column(
          children: [
            // Search overlay that slides down from notification bar with slow animation
            AnimatedContainer(
              duration: const Duration(
                  milliseconds:
                      600), // Slower animation - increased from 300ms to 600ms
              curve: Curves
                  .easeOutCubic, // Smoother curve for slower drop-down effect
              height: _isSearchExpanded
                  ? 350
                  : 0, // Increased height to accommodate new layout
              child: GestureDetector(
                onTap: () {}, // Prevent tap from propagating to parent
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // Add curved edges at bottom-left and bottom-right
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button above search bar
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSearchExpanded = false;
                                  });
                                  _searchController.clear();
                                  _searchSuggestionsTimer?.cancel();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.grey.shade700,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Search for Quizzes',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Search input field
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: _getCurrentSearchHint(),
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        _performSearch(value.trim());
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade500,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Recent searches section
                          if (_recentSearches.isNotEmpty)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RECENTLY SEARCHED EXAMS',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Recent search chips
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _recentSearches
                                            .take(5)
                                            .map((search) {
                                          return GestureDetector(
                                            onTap: () {
                                              _searchController.text = search;
                                              _performSearch(search);
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.history,
                                                    size: 18,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    search,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade700,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ), // Close AnimatedContainer
            // Spacer to push content down
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }

  /// Get current search hint with rotating suggestions
  String _getCurrentSearchHint() {
    if (_searchSuggestions.isEmpty) return 'Search for exams & quizzes';

    // Start timer when search overlay is expanded
    if (_isSearchExpanded && _searchSuggestionsTimer == null) {
      _startSearchSuggestionsTimer();
    }

    // Return current suggestion based on timer cycles
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final cycleIndex = ((currentTime ~/ 10000) %
        _searchSuggestions.length); // 10 second cycles
    return _searchSuggestions[cycleIndex];
  }

  /// Start timer for rotating search suggestions
  void _startSearchSuggestionsTimer() {
    _searchSuggestionsTimer?.cancel();
    _searchSuggestionsTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _isSearchExpanded) {
        setState(() {
          // Trigger rebuild to update hint text
        });
      } else {
        timer.cancel();
        _searchSuggestionsTimer = null;
      }
    });
  }

  /// Show exit confirmation dialog
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Exit App',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            content: Text(
              'Are you sure you want to exit the app?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Exit',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Perform search functionality
  void _performSearch(String query) {
    // Cancel suggestions timer
    _searchSuggestionsTimer?.cancel();
    _searchSuggestionsTimer = null;

    // Add to recent searches if not already present
    if (!_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
    }

    // Close search overlay
    setState(() {
      _isSearchExpanded = false;
    });

    // Navigate to search results
    context.pushNamed('search', queryParameters: {'q': query});
  }

  /// Create default demo banners when no banners are available
  List<BannerModel> _createDefaultBanners() {
    final now = DateTime.now();
    return [
      BannerModel(
        id: 'default_1',
        title: 'SPECIAL OFFER!',
        subtitle: 'Get 30% discount on premium quizzes',
        couponCode: 'SAVE30',
        discount: '30%',
        primaryColor: '#E91E63',
        secondaryColor: '#9C27B0',
        iconName: 'lightbulb',
        isActive: true,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 30)),
        targetUrl: '',
        examId: null,
        examName: null,
        priority: 1,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
      BannerModel(
        id: 'default_2',
        title: 'NEW QUIZZES ADDED!',
        subtitle: 'Practice with latest exam patterns',
        couponCode: 'NEW',
        discount: 'FREE',
        primaryColor: '#4F46E5',
        secondaryColor: '#7C3AED',
        iconName: 'star',
        isActive: true,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 30)),
        targetUrl: '',
        examId: null,
        examName: null,
        priority: 2,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
    ];
  }

  /// Enhanced banner with swipe functionality and page indicators
  Widget _buildIntegratedBanner(AsyncValue<List<BannerModel>> bannersAsync) {
    return bannersAsync.when(
      data: (banners) {
        // Filter active banners in memory
        final now = DateTime.now();
        final activeBanners = banners.where((banner) {
          final isInDateRange =
              banner.startDate.isBefore(now) && banner.endDate.isAfter(now);
          return banner.isActive && isInDateRange;
        }).toList();

        // If no banners available, create default demo banners
        List<BannerModel> displayBanners;
        if (activeBanners.isEmpty) {
          displayBanners = _createDefaultBanners();
        } else {
          // Ensure we have at least 2 banners for demo (duplicate if only 1)
          displayBanners = activeBanners.length == 1
              ? [activeBanners.first, activeBanners.first]
              : activeBanners;
        }

        // Initialize PageController if not already done
        if (_bannerPageController == null) {
          _bannerPageController = PageController(
            initialPage: _currentBannerIndex % displayBanners.length,
          );
        }

        // Start auto-changing timer
        _startBannerTimer(displayBanners.length);

        return Column(
          children: [
            // Banner PageView with swipe functionality
            SizedBox(
              height: 80,
              child: PageView.builder(
                controller: _bannerPageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                  // Restart timer when user manually swipes
                  _startBannerTimer(displayBanners.length);
                },
                itemCount: displayBanners.length,
                itemBuilder: (context, index) {
                  final banner = displayBanners[index];
                  return GestureDetector(
                    onTap: () => _handleBannerTap(banner),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            _parseColor(banner.primaryColor),
                            _parseColor(banner.secondaryColor),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Banner content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    banner.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    banner.subtitle,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Banner icon
                          Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              _parseIcon(banner.iconName),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page indicators (only show if more than 1 banner)
            if (displayBanners.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  displayBanners.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          (_currentBannerIndex % displayBanners.length) == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
