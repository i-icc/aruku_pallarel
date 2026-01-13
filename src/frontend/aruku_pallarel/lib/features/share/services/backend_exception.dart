import 'package:dio/dio.dart';

class BackendException implements Exception {
  BackendException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'BackendException(code: $code, message: $message)';
}

BackendException backendExceptionFromDio(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final payload = data['error'];
    if (payload is Map<String, dynamic>) {
      final code = payload['code'];
      final message = payload['message'];
      if (code is String && message is String) {
        return BackendException(code, message);
      }
    }
  }

  final statusCode = error.response?.statusCode;
  final message = error.message ?? 'Request failed';
  if (statusCode != null) {
    return BackendException('HTTP_$statusCode', message);
  }
  return BackendException('NETWORK', message);
}
