import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';

import '../../../shared/widgets/custom_snackbar.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to home screen using GoRouter
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // If no previous route, navigate to home using GoRouter
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Appearance
              _buildSection(
                'Appearance',
                [
                  _buildThemeSelector(context, ref, themeMode),
                ],
              ),

              const SizedBox(height: 24),

              // Notifications
              _buildSection(
                'Notifications',
                [
                  _buildSwitchTile(
                    'Push Notifications',
                    'Receive quiz reminders and updates',
                    true,
                    Icons.notifications,
                    (value) {
                      CustomSnackbar.showInfo(
                          context, 'Notification settings updated');
                    },
                  ),
                  _buildSwitchTile(
                    'Email Notifications',
                    'Receive weekly progress reports',
                    false,
                    Icons.email,
                    (value) {
                      CustomSnackbar.showInfo(
                          context, 'Email settings updated');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quiz Settings
              _buildSection(
                'Quiz Settings',
                [
                  _buildSwitchTile(
                    'Auto-submit',
                    'Automatically submit when time runs out',
                    true,
                    Icons.timer,
                    (value) {
                      CustomSnackbar.showInfo(
                          context, 'Auto-submit setting updated');
                    },
                  ),
                  _buildSwitchTile(
                    'Show Explanations',
                    'Display explanations after each question',
                    true,
                    Icons.help_outline,
                    (value) {
                      CustomSnackbar.showInfo(
                          context, 'Explanation setting updated');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // About
              _buildSection(
                'About',
                [
                  _buildTile(
                    'Important Disclaimer',
                    'Not affiliated with government entities',
                    Icons.warning_amber,
                    () {
                      context.push('/disclaimer-readonly');
                    },
                  ),
                  _buildTile(
                    'Privacy Policy',
                    'Read our privacy policy',
                    Icons.privacy_tip,
                    () {
                      context.push('/privacy-policy');
                    },
                  ),
                  _buildTile(
                    'Terms of Service',
                    'Read our terms of service',
                    Icons.description,
                    () {
                      context.push('/terms-of-service');
                    },
                  ),
                  _buildTile(
                    'App Version',
                    '1.5.1',
                    Icons.info,
                    null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Theme',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  context,
                  ref,
                  'Light',
                  Icons.light_mode,
                  ThemeMode.light,
                  themeMode == ThemeMode.light,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  context,
                  ref,
                  'Dark',
                  Icons.dark_mode,
                  ThemeMode.dark,
                  themeMode == ThemeMode.dark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  context,
                  ref,
                  'System',
                  Icons.brightness_auto,
                  ThemeMode.system,
                  themeMode == ThemeMode.system,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    ThemeMode mode,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        final themeNotifier = ref.read(themeModeProvider.notifier);
        switch (mode) {
          case ThemeMode.light:
            themeNotifier.setLightMode();
            break;
          case ThemeMode.dark:
            themeNotifier.setDarkMode();
            break;
          case ThemeMode.system:
            themeNotifier.setSystemMode();
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondaryColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
