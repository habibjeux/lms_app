import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/course_session.dart';

class MeetingsRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<CourseSession>> getUpcomingSessions() async {
    try {
      final response = await _dio.get('/sessions/upcoming');

      if (response.data is List) {
        return (response.data as List)
            .map((item) => CourseSession.fromJson(item))
            .toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(
          message: 'Erreur lors de la récupération des séances à venir');
    }
  }

  Future<CourseSession?> getActiveSession() async {
    try {
      final response = await _dio.get('/sessions/active');

      if (response.data != null && response.data is Map<String, dynamic>) {
        return CourseSession.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(
          message: 'Erreur lors de la récupération de la séance active');
    }
  }

  Future<CourseSession> getSessionById(String sessionId) async {
    try {
      final response = await _dio.get('/sessions/$sessionId');
      return CourseSession.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(
          message: 'Erreur lors de la récupération de la séance');
    }
  }

  Future<Map<String, dynamic>> joinSession(String sessionId) async {
    try {
      final response = await _dio
          .post('/sessions/$sessionId/join', data: {'platform': 'mobile'});

      return {
        'token': response.data['token'],
        'roomName': response.data['roomName'],
        'sessionTitle': response.data['sessionTitle'],
        'courseTitle': response.data['courseTitle'],
      };
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(
          message: 'Erreur lors de la tentative de rejoindre la séance');
    }
  }
}
