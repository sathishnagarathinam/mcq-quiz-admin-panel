import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/enhanced_notification_service.dart';
import '../../../core/providers/mobile_user_auth_provider.dart';
import '../../../core/widgets/secure_screen_wrapper.dart';
import '../../../shared/widgets/government_source_attribution.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'exam_hub_news_screen.dart';
import 'exam_hub_tips_screen.dart';
import 'exam_hub_papers_screen.dart';
import 'exam_hub_results_screen.dart';
import 'exam_hub_connect_expert_screen.dart';
import 'exam_hub_challenge_friend_screen.dart';
import 'exam_hub_online_classes_screen.dart';

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _unreadNotificationCount = 0;

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
    _animationController.forward();
    _loadNotificationCount();
  }

  void _loadNotificationCount() async {
    final authState = ref.read(mobileUserAuthProvider);
    if (authState.user != null) {
      final count =
          await EnhancedNotificationService.getUnreadNotificationCount(
              authState.user!.uid);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreenWrapper(
      enableScreenshotPrevention: true,
      enableScreenRecordingPrevention: true,
      showWarningOnRecording: true,
      customWarningMessage:
          'Screenshots and screen recording are not allowed in exam section for security purposes.',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Column(
          children: [
            // Modern app bar that covers status bar
            _buildModernAppBar(context),

            // Main content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Government Source Attribution Banner - PROMINENT DISPLAY
                      const ExamContentAttribution(),
                      const SizedBox(height: 16),

                      // Welcome section
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),

                      // Exam cards grid
                      _buildExamCardsGrid(),

                      // Add some bottom padding
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D3B82F6), // 0.3 alpha
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, statusBarHeight + 16, 20, 24),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () {
                // Navigate back to home using GoRouter
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  // If no previous route, navigate to home using GoRouter
                  context.go('/home');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exam Hub',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your complete exam preparation center',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Notification icon with badge
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                )
                    .then((_) {
                  // Refresh notification count when returning
                  _loadNotificationCount();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadNotificationCount > 99
                                ? '99+'
                                : _unreadNotificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.deepOrange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to Excel?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Access all exam preparation resources in one place',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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

  Widget _buildExamCardsGrid() {
    final examCards = [
      _ExamCardData(
        title: 'News',
        subtitle: 'Latest exam updates & notifications',
        icon: Icons.newspaper,
        gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExamHubNewsScreen()),
        ),
      ),
      _ExamCardData(
        title: 'Tips/Shortcuts',
        subtitle: 'Expert tips & time-saving shortcuts',
        icon: Icons.lightbulb_outline,
        gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExamHubTipsScreen()),
        ),
      ),
      _ExamCardData(
        title: 'Connect with Experts',
        subtitle: 'Get guidance from experienced mentors',
        icon: Icons.people_outline,
        gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ExamHubConnectExpertScreen()),
        ),
      ),
      _ExamCardData(
        title: 'Previous Year Papers',
        subtitle: 'Access past exam question papers',
        icon: Icons.history_edu,
        gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExamHubPapersScreen()),
        ),
      ),
      _ExamCardData(
        title: 'Challenge a Friend',
        subtitle: 'Compete with friends in quiz battles',
        icon: Icons.sports_esports,
        gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ExamHubChallengeFriendScreen()),
        ),
      ),
      _ExamCardData(
        title: 'Results',
        subtitle: 'View your exam results & analytics',
        icon: Icons.analytics_outlined,
        gradient: [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExamHubResultsScreen()),
        ),
      ),
      _ExamCardData(
        title: 'Online Classes',
        subtitle: 'Join live classes & recorded sessions',
        icon: Icons.video_library_outlined,
        gradient: [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ExamHubOnlineClassesScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: examCards.length,
      itemBuilder: (context, index) {
        return _buildExamCard(examCards[index], index);
      },
    );
  }

  Widget _buildExamCard(_ExamCardData cardData, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: cardData.onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cardData.gradient,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cardData.gradient.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: cardData.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cardData.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          cardData.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Expanded(
                          child: Text(
                            cardData.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Arrow icon
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExamCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  _ExamCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}
