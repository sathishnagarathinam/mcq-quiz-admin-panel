import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/services/onboarding_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Get Comprehensive Test Series Material for Deparment of Post',
      subtitle:
          'Complete The preparation With All Type Of MCQ Series & Unlimited Practice Test Series',
      illustration: 'study_illustration',
      backgroundColor: const Color(0xFF6C63FF),
      gradientColors: [const Color(0xFF6C63FF), const Color(0xFF4ECDC4)],
    ),
    OnboardingPageData(
      title: 'Improve Your Scores',
      subtitle: 'Individual Performance Analysis & Feedback',
      illustration: 'performance_illustration',
      backgroundColor: const Color(0xFF4ECDC4),
      gradientColors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
    ),
    OnboardingPageData(
      title: 'Practice Anytime, Anywhere',
      subtitle: 'Study Synchronized Across Your Mobile app',
      illustration: 'practice_illustration',
      backgroundColor: const Color(0xFF44A08D),
      gradientColors: [const Color(0xFF44A08D), const Color(0xFF093637)],
    ),
    OnboardingPageData(
      title: 'Never Ever Give Up',
      subtitle:
          'Your success journey starts here. Stay motivated and achieve your goals with our comprehensive test series.',
      illustration: 'success_illustration',
      backgroundColor: const Color(0xFF093637),
      gradientColors: [const Color(0xFF093637), const Color(0xFF6C63FF)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    try {
      // Mark onboarding as completed
      await OnboardingService.completeOnboarding();

      // Navigate to email registration since we're using email auth now
      if (mounted) {
        context.go('/auth/email-register');
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      // Still navigate even if there's an error saving the preference
      if (mounted) {
        context.go('/auth/email-register');
      }
    }
  }

  Widget _buildOnboardingPage(OnboardingPageData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradientColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Skip button
              if (_currentPage < _pages.length - 1)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 60),

              // Main content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(140),
                          ),
                          child: _buildIllustration(data.illustration),
                        ),

                        const SizedBox(height: 48),

                        // Title
                        Text(
                          data.title,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          data.subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(String illustration) {
    // Create different illustrations for each page
    switch (illustration) {
      case 'study_illustration':
        return _buildStudyIllustration();
      case 'performance_illustration':
        return _buildPerformanceIllustration();
      case 'practice_illustration':
        return _buildPracticeIllustration();
      case 'success_illustration':
        return _buildSuccessIllustration();
      default:
        return _buildDefaultIllustration();
    }
  }

  Widget _buildStudyIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Books stack
        Positioned(
          bottom: 60,
          left: 80,
          child: Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_book,
              size: 40,
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
        // Student figure
        Positioned(
          bottom: 80,
          right: 60,
          child: Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Chart background
        Positioned(
          child: Container(
            width: 160,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.trending_up,
              size: 60,
              color: Color(0xFF4ECDC4),
            ),
          ),
        ),
        // Person with laptop
        Positioned(
          bottom: 40,
          child: Container(
            width: 100,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.laptop_mac,
              size: 40,
              color: Color(0xFF4ECDC4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Mobile device
        Positioned(
          child: Container(
            width: 120,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.quiz,
                  size: 40,
                  color: Color(0xFF44A08D),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF44A08D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF44A08D).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Person
        Positioned(
          bottom: 20,
          right: 40,
          child: Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              size: 30,
              color: Color(0xFF44A08D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Trophy
        Positioned(
          child: Container(
            width: 140,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SSS Logo
                SvgPicture.asset(
                  'assets/images/sss_logo.svg',
                  width: 60,
                  height: 60,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF093637),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 12),
                const Icon(
                  Icons.emoji_events,
                  size: 40,
                  color: Color(0xFFFFD700),
                ),
              ],
            ),
          ),
        ),
        // Celebration elements
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: 30,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(60),
      ),
      child: const Icon(
        Icons.quiz,
        size: 60,
        color: Color(0xFF6C63FF),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              // Restart animation for new page
              _animationController.reset();
              _animationController.forward();
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildOnboardingPage(_pages[index]);
            },
          ),

          // Bottom navigation overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _pages[_currentPage].backgroundColor.withValues(alpha: 0.1),
                    _pages[_currentPage].backgroundColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Indicator
                    _buildPageIndicator(),

                    const SizedBox(height: 32),

                    // Navigation Buttons
                    Row(
                      children: [
                        // Back Button
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousPage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Back',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        if (_currentPage > 0) const SizedBox(width: 16),

                        // Next/Get Started Button
                        Expanded(
                          flex: _currentPage > 0 ? 2 : 1,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  _pages[_currentPage].backgroundColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 8,
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == _pages.length - 1
                                      ? Icons.rocket_launch
                                      : Icons.arrow_forward,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String illustration;
  final Color backgroundColor;
  final List<Color> gradientColors;

  OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.backgroundColor,
    required this.gradientColors,
  });
}
