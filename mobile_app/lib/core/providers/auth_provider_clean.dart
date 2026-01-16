import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple user model for authentication
class SimpleUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;

  const SimpleUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.isEmailVerified,
  });

  SimpleUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isEmailVerified,
  }) {
    return SimpleUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

/// Simple authentication state
class SimpleAuthState {
  final SimpleUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const SimpleAuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  SimpleAuthState copyWith({
    SimpleUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return SimpleAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Simple Authentication Provider (Clean - No Phone Auth Dependencies)
class SimpleAuthNotifier extends StateNotifier<SimpleAuthState> {
  SimpleAuthNotifier() : super(const SimpleAuthState()) {
    _checkAuthState();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check current authentication state
  void _checkAuthState() {
    final user = _auth.currentUser;
    if (user != null) {
      final simpleUser = SimpleUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        isEmailVerified: user.emailVerified,
      );
      state = state.copyWith(
        user: simpleUser,
        isAuthenticated: true,
      );
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      state = const SimpleAuthState();
      if (kDebugMode) {
        print('DEBUG: ✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Sign out failed: $e');
      }
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get current user
  SimpleUser? get currentUser => state.user;

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated && state.user != null;

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      await _auth.currentUser?.reload();
      _checkAuthState();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to refresh user: $e');
      }
    }
  }

  /// Listen to auth state changes
  void listenToAuthChanges() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        final simpleUser = SimpleUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          isEmailVerified: user.emailVerified,
        );
        state = state.copyWith(
          user: simpleUser,
          isAuthenticated: true,
          error: null,
        );
      } else {
        state = const SimpleAuthState();
      }
    });
  }
}

/// Simple Auth Provider (Clean)
final simpleAuthProvider = StateNotifierProvider<SimpleAuthNotifier, SimpleAuthState>((ref) {
  final notifier = SimpleAuthNotifier();
  notifier.listenToAuthChanges();
  return notifier;
});

/// Legacy auth provider for backward compatibility
/// This is a placeholder that redirects to email auth
final authProvider = Provider<SimpleAuthNotifier>((ref) {
  return ref.read(simpleAuthProvider.notifier);
});
