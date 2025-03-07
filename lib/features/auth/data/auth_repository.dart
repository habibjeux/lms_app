import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lms_app/core/exceptions/app_exception.dart';
import 'package:lms_app/core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/user.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;
  final StorageService _storage = StorageService();

  Future<void> initializeToken() async {
    final token = await _storage.getToken();
    if (token != null) {
      _setAuthHeader(token);
    }
  }

  void _setAuthHeader(String token) {
    ApiClient.setAuthToken(token);
  }

  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['accessToken'];
      final userData = response.data['user'];

      await Future.wait([
        _storage.saveToken(token),
        _storage.saveUser(userData),
      ]);

      _setAuthHeader(token);
      return User.fromJson(userData);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final userData = await _storage.getUser();
        final token = await _storage.getToken();

        if (userData != null && token != null) {
          _setAuthHeader(token);
          return User.fromJson(userData);
        }
      }

      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(message: 'Erreur de connexion');
    }
  }

  Future<bool> isTokenValid() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return false;

      if (!await hasInternetConnection()) {
        return true;
      }

      await _dio.get('/auth/verify-token');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await Future.wait([
        _storage.deleteToken(),
        _storage.deleteUser(),
      ]);
      _dio.options.headers.remove('Authorization');
    } catch (e) {
      throw AppException(message: 'Erreur lors de la déconnexion');
    }
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
