import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      state = state.copyWith(isAuthenticated: isAuthenticated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.login(email, password);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response['user'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw e;
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.register(email, password, name);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response['user'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw e;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
} 