import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/exceptions/app_exception.dart';

class MeetingRepository {
  final Dio _dio = ApiClient.instance;

  Future<String> getJitsiJWTToken({bool forceRefresh = false}) async {
    try {
      final response = await _dio.get('/generate-jitsi-jwt');

      final token = response.data['token'] as String;

      return token;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(
          message: 'Erreur lors de la génération du token JWT jitsi');
    }
  }
}
