import 'package:dio/dio.dart';

/// Thin factory around [Dio] so every networked service shares the same
/// sensible timeouts and validation behaviour.
class DioClient {
  const DioClient._();

  static Dio create({
    String? baseUrl,
    Map<String, dynamic>? headers,
  }) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: headers,
        // We validate status codes ourselves so we can surface friendly,
        // localized error messages (e.g. Reddit 403 / 429).
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}

/// Domain-specific failure with a user-facing, localized message.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
