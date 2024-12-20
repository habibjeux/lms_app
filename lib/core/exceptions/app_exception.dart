class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic data;

  AppException({
    required this.message,
    this.code,
    this.data,
  });

  @override
  String toString() => message;
}

class AuthException extends AppException {
  AuthException({required super.message, super.code, super.data});
}

class NetworkException extends AppException {
  NetworkException({required super.message, super.code, super.data});
}

class ValidationException extends AppException {
  ValidationException({required super.message, super.code, super.data});
}
