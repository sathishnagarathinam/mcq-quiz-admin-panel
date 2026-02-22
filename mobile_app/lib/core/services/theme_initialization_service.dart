import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle theme initialization before app starts
class ThemeInitializationService {
  static const String _themeKey = 'theme_mode';
  static ThemeMode? _initialThemeMode;

  /// Initialize theme mode synchronously before app starts
  static Future<void> initialize() async {
    try {
      debugPrint('🎨 ThemeInitializationService: Initializing theme...');
      
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);

      if (themeIndex != null && 
          themeIndex >= 0 && 
          themeIndex < ThemeMode.values.length) {
        _initialThemeMode = ThemeMode.values[themeIndex];
        debugPrint('🎨 Theme loaded from preferences: $_initialThemeMode');
      } else {
        // If no saved preference, default to light mode
        _initialThemeMode = ThemeMode.light;
        debugPrint('🎨 No saved theme preference, defaulting to light mode');
      }
    } catch (e) {
      // If loading fails, default to light theme
      debugPrint('🎨 Error loading theme mode: $e');
      _initialThemeMode = ThemeMode.light;
    }
  }

  /// Get the initial theme mode (must call initialize() first)
  static ThemeMode get initialThemeMode {
    return _initialThemeMode ?? ThemeMode.light;
  }

  /// Check if theme has been initialized
  static bool get isInitialized {
    return _initialThemeMode != null;
  }

  /// Save theme mode to shared preferences
  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
      _initialThemeMode = themeMode;
      debugPrint('🎨 Theme saved to preferences: $themeMode');
    } catch (e) {
      debugPrint('🎨 Error saving theme mode: $e');
    }
  }

  /// Reset theme to default light mode
  static Future<void> resetToLightMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      _initialThemeMode = ThemeMode.light;
      debugPrint('🎨 Theme reset to light mode');
    } catch (e) {
      debugPrint('🎨 Error resetting theme mode: $e');
      _initialThemeMode = ThemeMode.light;
    }
  }
}
