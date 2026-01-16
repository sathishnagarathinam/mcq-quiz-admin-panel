import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';

/// Easy mode home view with 4 main cards
class EasyModeHomeView extends ConsumerStatefulWidget {
  const EasyModeHomeView({super.key});

  @override
  ConsumerState<EasyModeHomeView> createState() => _EasyModeHomeViewState();
}

class _EasyModeHomeViewState extends ConsumerState<EasyModeHomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(),
            const SizedBox(height: 32),

            // Main cards grid
            _buildMainCardsGrid(),

            // Add some bottom padding
            const SizedBox(height: 100),
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
            Colors.blue.withValues(alpha: 0.1),
            Colors.indigo.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
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
                colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home,
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
                  'Easy Mode',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Simple navigation for quick access',
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

  Widget _buildMainCardsGrid() {
    final mainCards = [
      _EasyModeCardData(
        title: 'Quiz',
        subtitle: 'Take practice quizzes',
        icon: Icons.quiz,
        gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
        onTap: () {
          try {
            context.goNamed('quiz-list');
            print('🎯 Easy Mode: Navigating to quiz-list');
          } catch (e) {
            print('❌ Easy Mode: Navigation error to quiz-list: $e');
            // Fallback navigation
            context.go('/quiz');
          }
        },
      ),
      _EasyModeCardData(
        title: 'Exam',
        subtitle: 'Access exam hub',
        icon: Icons.school,
        gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        onTap: () {
          try {
            context.goNamed('exam');
            print('🎯 Easy Mode: Navigating to exam');
          } catch (e) {
            print('❌ Easy Mode: Navigation error to exam: $e');
            // Fallback navigation
            context.go('/exam');
          }
        },
      ),
      _EasyModeCardData(
        title: 'Profile',
        subtitle: 'View your progress',
        icon: Icons.person,
        gradient: [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
        onTap: () {
          try {
            context.goNamed('profile');
            print('🎯 Easy Mode: Navigating to profile');
          } catch (e) {
            print('❌ Easy Mode: Navigation error to profile: $e');
            // Fallback navigation
            context.go('/profile');
          }
        },
      ),
      _EasyModeCardData(
        title: 'Settings',
        subtitle: 'Customize your app',
        icon: Icons.settings,
        gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        onTap: () {
          try {
            context.goNamed('settings');
            print('🎯 Easy Mode: Navigating to settings');
          } catch (e) {
            print('❌ Easy Mode: Navigation error to settings: $e');
            // Fallback navigation
            context.go('/settings');
          }
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: mainCards.length,
      itemBuilder: (context, index) {
        return _buildEasyModeCard(mainCards[index], index);
      },
    );
  }

  Widget _buildEasyModeCard(_EasyModeCardData cardData, int index) {
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
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          cardData.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Subtitle
                        Text(
                          cardData.subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

/// Data class for easy mode cards
class _EasyModeCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  _EasyModeCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}
