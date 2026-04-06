import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/exceptions.dart';
import '../../../core/network/token_manager.dart';
import '../../../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Auth state
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final UserModel? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  // Convenience getters consumed by existing UI
  String? get userName => user?.username ?? user?.userId;
  String? get email => user?.email;
  String? get userId => user?.userId;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    UserModel? user,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage,
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AuthNotifier
// ─────────────────────────────────────────────────────────────────────────────

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  final _api = ApiClient();

  @override
  AuthState build() => const AuthState();

  // ── Register ────────────────────────────────────────────────────────────
  // Only requires password. Backend generates the userId (bock1, bock2, etc.)
  // Returns the generated userId on success, null on failure.

  Future<String?> register({
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final data = await _api.post('/user/register', {
        'password': password,
      });

      final token = _extractToken(data);
      if (token != null) await TokenManager.saveToken(token);

      // Extract the generated userId from response
      String? generatedUserId;
      if (data is Map) {
        generatedUserId = data['data']?['userId']?.toString() ??
            data['data']?['user']?['userId']?.toString();
      }

      final user = _extractUser(data) ??
          UserModel(
            id: '',
            userId: generatedUserId,
          );

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return generatedUserId;
    } on ValidationException catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: e.message, clearUser: false);
      return null;
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      return null;
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────
  // Accepts userId + password (no email)

  Future<void> login({
    required String userId,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final data = await _api.post('/user/login', {
        'userId': userId.toLowerCase().trim(),
        'password': password,
      });

      final token = _extractToken(data);
      if (token != null) await TokenManager.saveToken(token);

      // Prefer embedded user object; fallback to profile fetch
      UserModel? user = _extractUser(data);
      if (user == null) {
        user = await _fetchProfile();
      }

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on ValidationException {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Invalid credentials. Please try again.');
    } on UnauthorizedException {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Invalid User ID or password.');
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    }
  }

  // ── Auto-login (called from splash) ────────────────────────────────────

  Future<void> autoLogin() async {
    final hasToken = await TokenManager.isLoggedIn();
    if (!hasToken) return;

    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _fetchProfile();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on UnauthorizedException {
      // Token expired — silently log out
      await _clearSession();
    } on AppException {
      // Network issue etc. — reset to initial so user can log in manually
      state = const AuthState();
    }
  }

  // ── Get Profile ─────────────────────────────────────────────────────────

  Future<UserModel> _fetchProfile() async {
    final response = await _api.get('/user/profile', auth: true);
    
    // The backend returns: { success: true, data: { ...user fields } }
    Map<String, dynamic> body = response is Map ? response as Map<String, dynamic> : {};
    
    if (body.containsKey('data')) {
      final data = body['data'];
      if (data is Map) {
         body = data as Map<String, dynamic>;
      }
    } else if (body.containsKey('user')) {
      final userMap = body['user'];
      if (userMap is Map) {
         body = userMap as Map<String, dynamic>;
      }
    }
    
    return UserModel.fromJson(body);
  }

  // ── Update Profile ───────────────────────────────────────────────────────

  Future<bool> updateProfile({
    required String username,
    required String phone,
  }) async {
    try {
      final data = await _api.put(
        '/user/profile',
        {'username': username, 'phone': phone},
        auth: true,
      );
      final updatedUser =
          _extractUser(data) ?? state.user?.copyWith(username: username, phone: phone);
      state = state.copyWith(user: updatedUser);
      return true;
    } on UnauthorizedException {
      await _handleTokenExpiry();
      return false;
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      return false;
    }
  }

  // ── Change Password ──────────────────────────────────────────────────────

  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _api.put(
        '/user/change-password',
        {'oldPassword': oldPassword, 'newPassword': newPassword},
        auth: true,
      );
      return null; // null = success
    } on ValidationException catch (e) {
      return e.message;
    } on UnauthorizedException {
      await _handleTokenExpiry();
      return 'Session expired. Please log in again.';
    } on AppException catch (e) {
      return e.message;
    }
  }

  // ── Forgot Password ──────────────────────────────────────────────────────

  Future<String?> forgotPassword(String email) async {
    // Mock implementation as no backend endpoint was provided
    await Future.delayed(const Duration(seconds: 1));
    return null; // success
  }

  // ── Delete Account ───────────────────────────────────────────────────────

  Future<bool> deleteAccount() async {
    try {
      await _api.delete('/user/delete', auth: true);
      await _clearSession();
      return true;
    } on UnauthorizedException {
      await _handleTokenExpiry();
      return false;
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _clearSession();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _clearSession() async {
    await TokenManager.clearToken();
    state = const AuthState();
  }

  Future<void> _handleTokenExpiry() async {
    await _clearSession();
    state = state.copyWith(
      status: AuthStatus.error,
      errorMessage: 'Session expired. Please log in again.',
    );
  }

  String? _extractToken(dynamic body) {
    if (body is Map) {
      final data = body['data'];
      if (data is Map) {
        return (data['token'] ?? data['accessToken'])?.toString();
      }
      return (body['token'] ?? body['accessToken'])?.toString();
    }
    return null;
  }

  UserModel? _extractUser(dynamic body) {
    if (body is Map) {
      final data = body['data'];
      if (data is Map) {
        final userMap = data['user'] ?? data;
        if (userMap is Map && userMap.containsKey('id')) {
          return UserModel.fromJson(userMap as Map<String, dynamic>);
        }
      }
      
      final userMap = body['user'] ?? body;
      if (userMap is Map && userMap.containsKey('id')) {
        return UserModel.fromJson(userMap as Map<String, dynamic>);
      }
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Remember-me toggle (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

final rememberMeProvider =
    NotifierProvider<RememberMeNotifier, bool>(RememberMeNotifier.new);

class RememberMeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}
