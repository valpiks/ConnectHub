class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      message: json['message'] as String? ?? 'Произошла неизвестная ошибка',
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'ApiError(code: $code, message: $message, details: $details)';
}
