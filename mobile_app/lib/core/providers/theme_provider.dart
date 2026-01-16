import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_initialization_service.dart';

/// Provider for managing theme mode state with proper initialization
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Provider for checking if current theme is dark
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.dark;
});

/// Provider for getting current theme colors based on theme mode
final currentThemeColorsProvider = Provider<ThemeData>((ref) {
  final isDark = ref.watch(isDarkModeProvider);
  return isDark ? ThemeData.dark() : ThemeData.light();
});

/// Notifier class for managing theme mode state
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeInitializationService.initialThemeMode) {
    debugPrint(
        '🎨 ThemeModeNotifier initialized with: ${ThemeInitializationService.initialThemeMode}');
  }

  /// Set theme mode to light
  Future<void> setLightMode() async {
    state = ThemeMode.light;
    await ThemeInitializationService.saveThemeMode(ThemeMode.light);
  }

  /// Set theme mode to dark
  Future<void> setDarkMode() async {
    state = ThemeMode.dark;
    await ThemeInitializationService.saveThemeMode(ThemeMode.dark);
  }

  /// Set theme mode to system
  Future<void> setSystemMode() async {
    state = ThemeMode.system;
    await ThemeInitializationService.saveThemeMode(ThemeMode.system);
  }

  /// Reset theme to default light mode and clear saved preferences
  Future<void> resetToLightMode() async {
    state = ThemeMode.light;
    await ThemeInitializationService.resetToLightMode();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    switch (state) {
      case ThemeMode.light:
        await setDarkMode();
        break;
      case ThemeMode.dark:
        await setLightMode();
        break;
      case ThemeMode.system:
        // For system mode, toggle to light mode
        await setLightMode();
        break;
    }
  }

  /// Get theme mode as string for display
  String get themeModeString {
    switch (state) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Check if current theme is light
  bool get isLightMode => state == ThemeMode.light;

  /// Check if current theme is dark
  bool get isDarkMode => state == ThemeMode.dark;

  /// Check if current theme is system
  bool get isSystemMode => state == ThemeMode.system;
}

/// Extension for theme mode utilities
extension ThemeModeExtension on ThemeMode {
  /// Get icon for theme mode
  IconData get icon {
    switch (this) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Get display name for theme mode
  String get displayName {
    switch (this) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  /// Get description for theme mode
  String get description {
    switch (this) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system settings';
    }
  }
}
