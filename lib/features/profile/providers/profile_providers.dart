import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_providers.dart';

// ══════════════════════════════════════════════
// THEME MODE (persisted via SharedPreferences)
// ══════════════════════════════════════════════

const _kThemeKey = 'app_theme_mode';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Kick off async load; start with system default
    _loadFromPrefs();
    return ThemeMode.system;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemeKey);
      if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'light') {
        state = ThemeMode.light;
      }
    } catch (_) {
      // Keep system default on error
    }
  }

  Future<void> _saveToPrefs(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kThemeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  void set(ThemeMode mode) {
    state = mode;
    _saveToPrefs(mode);
  }

  void toggle() {
    final next =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    _saveToPrefs(next);
  }

  bool get isDark => state == ThemeMode.dark;
}

// ══════════════════════════════════════════════
// PROFILE EDIT STATE  (wired to real API)
// ══════════════════════════════════════════════

class ProfileEditState {
  final String username;
  final String phone;
  final bool isLoading;
  final bool isSaved;
  final String? error;

  const ProfileEditState({
    this.username = '',
    this.phone = '',
    this.isLoading = false,
    this.isSaved = false,
    this.error,
  });

  ProfileEditState copyWith({
    String? username,
    String? phone,
    bool? isLoading,
    bool? isSaved,
    String? error,
    bool clearError = false,
  }) =>
      ProfileEditState(
        username: username ?? this.username,
        phone: phone ?? this.phone,
        isLoading: isLoading ?? this.isLoading,
        isSaved: isSaved ?? this.isSaved,
        error: clearError ? null : (error ?? this.error),
      );
}

final profileEditProvider =
    NotifierProvider<ProfileEditNotifier, ProfileEditState>(
        ProfileEditNotifier.new);

class ProfileEditNotifier extends Notifier<ProfileEditState> {
  @override
  ProfileEditState build() => const ProfileEditState();

  void init(String username, String phone) {
    state = ProfileEditState(username: username, phone: phone);
  }

  void updateUsername(String v) => state = state.copyWith(username: v);
  void updatePhone(String v) => state = state.copyWith(phone: v);

  /// Calls PUT /user/profile via AuthNotifier.
  Future<bool> save() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final authNotifier = ref.read(authProvider.notifier);
    final ok = await authNotifier.updateProfile(
      username: state.username,
      phone: state.phone,
    );
    if (ok) {
      state = state.copyWith(isLoading: false, isSaved: true);
    } else {
      final errMsg =
          ref.read(authProvider).errorMessage ?? 'Failed to update profile.';
      state = state.copyWith(isLoading: false, error: errMsg);
    }
    return ok;
  }
}

// ══════════════════════════════════════════════
// CHANGE PASSWORD STATE
// ══════════════════════════════════════════════

class ChangePasswordState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const ChangePasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) =>
      ChangePasswordState(
        isLoading: isLoading ?? this.isLoading,
        isSuccess: isSuccess ?? this.isSuccess,
        error: clearError ? null : (error ?? this.error),
      );
}

final changePasswordProvider =
    NotifierProvider<ChangePasswordNotifier, ChangePasswordState>(
        ChangePasswordNotifier.new);

class ChangePasswordNotifier extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  /// Calls PUT /user/change-password via AuthNotifier.
  /// Returns null on success, or an error message string.
  Future<String?> submit(String oldPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final authNotifier = ref.read(authProvider.notifier);
    final err = await authNotifier.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    if (err == null) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(isLoading: false, error: err);
    }
    return err;
  }

  void reset() => state = const ChangePasswordState();
}
