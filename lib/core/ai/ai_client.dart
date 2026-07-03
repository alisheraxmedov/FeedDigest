/*
Provider-agnostic text-completion contract. A client is pure transport: it
receives the API key per call (AiRepository owns key lookup and the no_key
check), sends one request, and returns the model's text. Failures throw
AiException with a stable code the UI maps to a localized message.
*/
import 'package:dio/dio.dart';

class AiException implements Exception {
  AiException(this.code, [this.message = '']);

  /// One of: no_key, auth, rate_limit, blocked, request, parse, empty.
  final String code;
  final String message;

  @override
  String toString() => 'AiException($code): $message';
}

/// One chat turn. `user` turns come from the reader; `model` turns are prior
/// AI replies (chat history).
class AiMessage {
  const AiMessage.user(this.text) : isUser = true;
  const AiMessage.model(this.text) : isUser = false;

  final bool isUser;
  final String text;
}

abstract class AiClient {
  Future<String> complete({
    required String apiKey,
    String? system,
    required List<AiMessage> messages,
    Duration timeout = const Duration(seconds: 60),
  });
}

/// Shared HTTP-error mapping: 401/403 → auth (bad key), 429 → rate_limit,
/// anything else → request.
AiException mapDioError(DioException e) {
  final status = e.response?.statusCode;
  if (status == 401 || status == 403) return AiException('auth', '$status');
  if (status == 429) return AiException('rate_limit', '429');
  return AiException('request', e.message ?? '');
}
