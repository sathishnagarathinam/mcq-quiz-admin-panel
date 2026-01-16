import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle onboarding state and preferences
class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _firstLaunchKey = 'first_launch';
  static const String _appVersionKey = 'app_version';

  /// Check if onboarding has been completed
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_onboardingCompletedKey) ?? false;
    print('🔍 OnboardingService: isOnboardingCompleted() = $completed');
    return completed;
  }

  /// Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Check if this is the first app launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_firstLaunchKey) ?? true;

    if (isFirst) {
      // Mark as not first launch anymore
      await prefs.setBool(_firstLaunchKey, false);
    }

    return isFirst;
  }

  /// Reset onboarding state (for testing or app updates)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, false);
    await prefs.setBool(_firstLaunchKey, true);
  }

  /// Check if onboarding should be shown for app version update
  static Future<bool> shouldShowOnboardingForUpdate(
      String currentVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getString(_appVersionKey);

    if (savedVersion == null || savedVersion != currentVersion) {
      // Save current version
      await prefs.setString(_appVersionKey, currentVersion);

      // Show onboarding for major version updates
      if (savedVersion != null &&
          _isMajorVersionUpdate(savedVersion, currentVersion)) {
        return true;
      }
    }

    return false;
  }

  /// Check if the version update is a major update
  static bool _isMajorVersionUpdate(String oldVersion, String newVersion) {
    try {
      final oldParts = oldVersion.split('.').map(int.parse).toList();
      final newParts = newVersion.split('.').map(int.parse).toList();

      // Compare major version (first number)
      if (oldParts.isNotEmpty && newParts.isNotEmpty) {
        return newParts[0] > oldParts[0];
      }
    } catch (e) {
      // If parsing fails, assume it's a major update
      return true;
    }

    return false;
  }

  /// Get onboarding preferences
  static Future<Map<String, dynamic>> getOnboardingPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'onboarding_completed': prefs.getBool(_onboardingCompletedKey) ?? false,
      'first_launch': prefs.getBool(_firstLaunchKey) ?? true,
      'app_version': prefs.getString(_appVersionKey),
    };
  }

  /// Clear all onboarding data
  static Future<void> clearOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_firstLaunchKey);
    await prefs.remove(_appVersionKey);
  }
}
