/// Base class for all API-related exceptions.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// HTTP 400 — server rejected the request due to bad input.
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// HTTP 401 — token missing, expired, or invalid.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired. Please log in again.']);
}

/// HTTP 404 — the requested resource was not found.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found.']);
}

/// HTTP 500 — internal server error.
class ServerException extends AppException {
  const ServerException([super.message = 'Something went wrong. Please try again.']);
}

/// No internet / connection timeout.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection. Please check your network.']);
}

/// Request timed out (30 s threshold).
class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out. Please try again.']);
}
