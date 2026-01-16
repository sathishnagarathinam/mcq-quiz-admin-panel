import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Enum for user interface modes
enum UserMode {
  easy,
  expert,
}

/// Extension for UserMode to handle string conversion
extension UserModeExtension on UserMode {
  String get name {
    switch (this) {
      case UserMode.easy:
        return 'easy';
      case UserMode.expert:
        return 'expert';
    }
  }

  static UserMode fromString(String value) {
    switch (value) {
      case 'easy':
        return UserMode.easy;
      case 'expert':
        return UserMode.expert;
      default:
        return UserMode.expert; // Default to expert mode
    }
  }
}

/// Service for managing user mode persistence
class UserModeService {
  static const String _defaultMode = 'expert';

  /// Load user mode from SharedPreferences
  static Future<UserMode> loadUserMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(AppConfig.keyUserMode) ?? _defaultMode;
      return UserModeExtension.fromString(modeString);
    } catch (e) {
      print('Error loading user mode: $e');
      return UserMode.expert; // Default fallback
    }
  }

  /// Save user mode to SharedPreferences
  static Future<void> saveUserMode(UserMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.keyUserMode, mode.name);
      print('User mode saved: ${mode.name}');
    } catch (e) {
      print('Error saving user mode: $e');
    }
  }

  /// Reset user mode to default (expert)
  static Future<void> resetUserMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.keyUserMode);
      print('User mode reset to default');
    } catch (e) {
      print('Error resetting user mode: $e');
    }
  }
}

/// Notifier class for managing user mode state
class UserModeNotifier extends StateNotifier<UserMode> {
  UserModeNotifier() : super(UserMode.expert) {
    _loadInitialMode();
  }

  /// Load initial mode from storage
  Future<void> _loadInitialMode() async {
    final mode = await UserModeService.loadUserMode();
    state = mode;
    print('🎯 UserModeNotifier initialized with: ${mode.name}');
  }

  /// Set mode to easy
  Future<void> setEasyMode() async {
    state = UserMode.easy;
    await UserModeService.saveUserMode(UserMode.easy);
    print('🎯 User mode set to: easy');
  }

  /// Set mode to expert
  Future<void> setExpertMode() async {
    state = UserMode.expert;
    await UserModeService.saveUserMode(UserMode.expert);
    print('🎯 User mode set to: expert');
  }

  /// Toggle between easy and expert mode
  Future<void> toggleMode() async {
    switch (state) {
      case UserMode.easy:
        await setExpertMode();
        break;
      case UserMode.expert:
        await setEasyMode();
        break;
    }
  }

  /// Reset to default mode (expert)
  Future<void> resetToExpertMode() async {
    state = UserMode.expert;
    await UserModeService.resetUserMode();
    print('🎯 User mode reset to: expert');
  }

  /// Get mode as string for display
  String get modeString {
    switch (state) {
      case UserMode.easy:
        return 'Easy';
      case UserMode.expert:
        return 'Expert';
    }
  }

  /// Check if current mode is easy
  bool get isEasyMode => state == UserMode.easy;

  /// Check if current mode is expert
  bool get isExpertMode => state == UserMode.expert;
}

/// Provider for managing user mode state with persistence
final userModeProvider = StateNotifierProvider<UserModeNotifier, UserMode>(
  (ref) => UserModeNotifier(),
);

/// Provider for checking if current mode is easy
final isEasyModeProvider = Provider<bool>((ref) {
  final userMode = ref.watch(userModeProvider);
  return userMode == UserMode.easy;
});

/// Provider for checking if current mode is expert
final isExpertModeProvider = Provider<bool>((ref) {
  final userMode = ref.watch(userModeProvider);
  return userMode == UserMode.expert;
});

/// Provider for getting mode as display string
final userModeStringProvider = Provider<String>((ref) {
  final notifier = ref.watch(userModeProvider.notifier);
  return notifier.modeString;
});
