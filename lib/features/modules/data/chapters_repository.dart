import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/chapter.dart';

class ChaptersRepository {
  final Dio _dio = ApiClient.instance;
  final StorageService _storage = StorageService();

  Future<List<Chapter>> getChaptersByModule(String moduleId,
      {bool forceRefresh = true}) async {
    try {
      if (!forceRefresh) {
        final cachedChapters = await _getCachedChapters(moduleId);
        if (cachedChapters.isNotEmpty) return cachedChapters;
      }

      final response = await _dio.get('/modules/$moduleId/chapters');
      final chapters = (response.data as List)
          .map((json) => Chapter.fromJson(json))
          .toList();

      await _cacheChapters(moduleId, chapters);
      return chapters;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final cachedChapters = await _getCachedChapters(moduleId);
        if (cachedChapters.isNotEmpty) return cachedChapters;
      }

      if (e.error is AppException) throw e.error as AppException;
      throw AppException(message: 'Erreur lors du chargement des chapitres');
    }
  }

  Future<void> _cacheChapters(String moduleId, List<Chapter> chapters) async {
    final chaptersJson = chapters.map((chapter) => chapter.toJson()).toList();
    await _storage.saveData('chapters_$moduleId', chaptersJson);
  }

  Future<List<Chapter>> _getCachedChapters(String moduleId) async {
    try {
      final data = await _storage.getData('chapters_$moduleId');
      if (data != null) {
        return (data as List).map((json) => Chapter.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
