import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'token_manager.dart';
import 'exceptions.dart';

/// Centralised HTTP client for all BockNexusServer API calls.
///
/// Usage:
/// ```dart
/// final client = ApiClient();
/// final data = await client.get('/product/random-products');
/// final data = await client.post('/user/login', {'email': e, 'password': p});
/// final data = await client.get('/cart', auth: true);
/// ```
///
/// Returns the decoded response body (Map / List) on success.
/// Throws a typed [AppException] subclass on any error.
class ApiClient {
  static const String baseUrl = 'http://localhost:3000';

  static const Duration _timeout = Duration(seconds: 30);

  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // ── Debug logging ────────────────────────────────────────────────────
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint('[ApiClient] $obj'),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Auth header builder
  // ─────────────────────────────────────────────────────────────────────

  Future<Options> _buildOptions({bool auth = false}) async {
    final Map<String, String> headers = {};
    if (auth) {
      final token = await TokenManager.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return Options(headers: headers);
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Error handler  (maps Dio exceptions → typed AppExceptions)
  // ─────────────────────────────────────────────────────────────────────

  /// Converts a [DioException] into a typed [AppException].
  /// Call this inside every catch block.
  AppException _handleError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return const TimeoutException();

        case DioExceptionType.connectionError:
          return const NetworkException();

        case DioExceptionType.badResponse:
          return _handleStatusCode(error.response);

        default:
          return const NetworkException();
      }
    }
    return ServerException(error.toString());
  }

  AppException _handleStatusCode(Response? response) {
    if (response == null) return const ServerException();

    final statusCode = response.statusCode ?? 0;
    final body = response.data;

    // Extract message from response body if available
    String message = 'An error occurred.';
    if (body is Map) {
      message = (body['message'] ?? body['error'] ?? message).toString();
    }

    switch (statusCode) {
      case 400:
        return ValidationException(message);
      case 401:
        // Caller is responsible for clearing token + redirecting.
        return const UnauthorizedException();
      case 404:
        return const NotFoundException();
      case >= 500:
        return const ServerException();
      default:
        return ServerException('Unexpected error ($statusCode)');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Public HTTP methods
  // ─────────────────────────────────────────────────────────────────────

  /// GET [endpoint].  Set [auth] to attach the JWT Bearer header.
  /// Returns the decoded response body.
  Future<dynamic> get(
    String endpoint, {
    bool auth = false,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final options = await _buildOptions(auth: auth);
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: options,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST [endpoint] with [body].  Set [auth] to attach the JWT Bearer header.
  /// Returns the decoded response body.
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final options = await _buildOptions(auth: auth);
      final response = await _dio.post(
        endpoint,
        data: body,
        options: options,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT [endpoint] with [body].  Set [auth] to attach the JWT Bearer header.
  /// Returns the decoded response body.
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final options = await _buildOptions(auth: auth);
      final response = await _dio.put(
        endpoint,
        data: body,
        options: options,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE [endpoint].  Set [auth] to attach the JWT Bearer header.
  /// Returns the decoded response body.
  Future<dynamic> delete(
    String endpoint, {
    bool auth = false,
    Map<String, dynamic>? body,
  }) async {
    try {
      final options = await _buildOptions(auth: auth);
      final response = await _dio.delete(
        endpoint,
        data: body,
        options: options,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
