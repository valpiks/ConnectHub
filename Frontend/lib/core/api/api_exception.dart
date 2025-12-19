import 'api_error.dart';

class ApiException implements Exception {
  final ApiError error;
  final int? statusCode;

  ApiException({
    required this.error,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException(statusCode: $statusCode, error: $error)';
}
