import 'package:shared_preferences/shared_preferences.dart';

/// Manages JWT token persistence via SharedPreferences.
/// All token read/write operations MUST go through this class.
class TokenManager {
  static const _tokenKey = 'auth_token';

  /// Saves [token] to SharedPreferences.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Returns the stored JWT token, or `null` if none exists.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Removes the token from SharedPreferences (logout).
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Returns `true` if a non-empty token is stored.
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
