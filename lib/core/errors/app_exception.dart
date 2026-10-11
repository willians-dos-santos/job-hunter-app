export 'job_failure.dart';

/// Base exception for all application-level errors.
abstract class AppException implements Exception {
  const AppException(this.message, {this.code, this.details});

  /// Human-readable error message.
  final String message;

  /// Optional error code machine-readable.
  final String? code;

  /// Optional debug or extra details.
  final dynamic details;

  @override
  String toString() {
    if (code != null) {
      return 'AppException [$code]: $message';
    }
    return 'AppException: $message';
  }
}

/// Generic server or remote backend exception.
class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.details});
}

/// Local cache or persistent storage exception.
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.details});
}
