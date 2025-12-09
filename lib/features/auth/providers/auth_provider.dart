import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_pal/features/auth/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth state model
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool hasSeenOnboarding;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.hasSeenOnboarding = false,
  });

  bool get isSignedIn => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? hasSeenOnboarding,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}

/// AuthService provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Auth Notifier using modern Riverpod syntax
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;
  static const _onboardingKey = 'has_seen_onboarding';

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    _loadOnboardingState();
    
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen((user) {
      state = state.copyWith(
        user: user,
        isLoading: false,
        clearUser: user == null,
        clearError: true,
      );
    });

    ref.onDispose(() => _authSubscription?.cancel());

    return AuthState(user: _authService.currentUser, isLoading: false);
  }

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_onboardingKey) ?? false;
    state = state.copyWith(hasSeenOnboarding: seen);
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    state = state.copyWith(hasSeenOnboarding: true);
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _authService.signInWithEmailAndPassword(email: email, password: password);
    if (result.success) {
      state = state.copyWith(user: result.user, isLoading: false, hasSeenOnboarding: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    if (result.success) {
      state = state.copyWith(user: result.user, isLoading: false, hasSeenOnboarding: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _authService.signInWithGoogle();
    if (result.success) {
      state = state.copyWith(user: result.user, isLoading: false, hasSeenOnboarding: true);
      return true;
    } else {
      // Only show error if not cancelled
      if (result.errorMessage != 'Sign in cancelled by user') {
        state = state.copyWith(isLoading: false, error: result.errorMessage);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _authService.signInAnonymously();
    if (result.success) {
      state = state.copyWith(user: result.user, isLoading: false, hasSeenOnboarding: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = state.copyWith(isLoading: false, clearUser: true);
  }

  Future<bool> sendPasswordReset({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _authService.sendPasswordResetEmail(email: email);
    state = state.copyWith(isLoading: false, error: result.success ? null : result.errorMessage);
    return result.success;
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Main auth provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

/// Convenience providers
final isSignedInProvider = Provider<bool>((ref) => ref.watch(authProvider).isSignedIn);
final currentUserProvider = Provider<User?>((ref) => ref.watch(authProvider).user);

