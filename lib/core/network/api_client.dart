import 'package:dio/dio.dart';
import 'dio_interceptor.dart';

class ApiClient {
  static Dio? _dio;
  static Dio? _uploadDio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio get uploadInstance {
    _uploadDio ??= _createUploadDio();
    return _uploadDio!;
  }

  static String get baseUrl {
    return "https://mongoose-above-hornet.ngrok-free.app/api";
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      ApiInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    ]);

    return dio;
  }

  static Dio _createUploadDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.replaceFirst('/api', ''),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'multipart/form-data',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      ApiInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    ]);

    return dio;
  }
}
