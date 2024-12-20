import 'package:dio/dio.dart';
import '../exceptions/app_exception.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('Response Data: ${err.response?.data}'); // Pour déboguer

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException(
              message: 'Problème de connexion au serveur',
              code: 'TIMEOUT',
            ),
          ),
        );
        break;

      case DioExceptionType.connectionError:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException(
              message: 'Vérifiez votre connexion internet',
              code: 'NO_CONNECTION',
            ),
          ),
        );
        break;

      default:
        final exception = _handleError(err);
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: exception,
          ),
        );
    }
  }

  AppException _handleError(DioException err) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;

    // Vérification plus détaillée de la réponse
    if (data is Map<String, dynamic>) {
      final message =
          data['error'] ?? data['message'] ?? 'Une erreur est survenue';

      switch (statusCode) {
        case 400:
          return ValidationException(
            message: message,
            code: 'VALIDATION_ERROR',
          );

        case 401:
          return AuthException(
            message: message,
            code: 'UNAUTHORIZED',
          );

        case 403:
          return AuthException(
            message: message,
            code: 'FORBIDDEN',
          );

        case 404:
          return NetworkException(
            message: message,
            code: 'NOT_FOUND',
          );

        default:
          return AppException(
            message: message,
            code: 'UNKNOWN',
          );
      }
    }

    return AppException(
      message: 'Une erreur est survenue',
      code: 'UNKNOWN',
    );
  }
}
