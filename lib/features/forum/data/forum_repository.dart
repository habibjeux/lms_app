// lib/features/forum/data/forum_repository.dart
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/forum.dart';

class ForumRepository {
  final Dio _dio = ApiClient.instance;
  final StorageService _storage = StorageService();

  // Clés de stockage
  String _getModuleForumKey(String moduleId) => 'module_forum_$moduleId';
  String _getChapterForumKey(String chapterId) => 'chapter_forum_$chapterId';
  String _getTopicKey(String topicId) => 'topic_$topicId';

  // Forum d'un module
  Future<Forum> getModuleForum(String moduleId,
      {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedForum = await _getCachedModuleForum(moduleId);
        if (cachedForum != null) {
          return cachedForum;
        }
      }

      final response = await _dio.get('/modules/$moduleId/discussions');
      final forum = Forum.fromJson(response.data);
      await _cacheModuleForum(moduleId, forum);
      return forum;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final cachedForum = await _getCachedModuleForum(moduleId);
        if (cachedForum != null) {
          return cachedForum;
        }
      }
      throw AppException(
          message: e.message ?? 'Erreur lors de la récupération du forum');
    }
  }

  // Forum d'un chapitre
  Future<Forum> getChapterForum(String chapterId,
      {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedForum = await _getCachedChapterForum(chapterId);
        if (cachedForum != null) {
          return cachedForum;
        }
      }

      final response = await _dio.get('/chapters/$chapterId/discussions');
      final forum = Forum.fromJson(response.data);
      await _cacheChapterForum(chapterId, forum);
      return forum;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final cachedForum = await _getCachedChapterForum(chapterId);
        if (cachedForum != null) {
          return cachedForum;
        }
      }
      throw AppException(
          message: e.message ?? 'Erreur lors de la récupération du forum');
    }
  }

  // Récupérer les détails d'un topic
  Future<Topic> getTopicDetail(String topicId) async {
    try {
      final response = await _dio.get('/forums/topics/$topicId');
      final topic = Topic.fromJson(response.data);
      await _storage.saveData(_getTopicKey(topicId), response.data);
      return topic;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final cachedData = await _storage.getData(_getTopicKey(topicId));
        if (cachedData != null) {
          return Topic.fromJson(cachedData);
        }
      }
      throw AppException(
          message: e.message ?? 'Erreur lors de la récupération du sujet');
    }
  }

  // Créer un nouveau topic
  Future<Topic> createTopic(
      String forumId, String title, String content) async {
    try {
      final response = await _dio.post(
        '/forums/$forumId/topics',
        data: {
          'title': title,
          'content': content,
        },
      );

      final newTopic = Topic.fromJson(response.data);
      await _invalidateForumCache(forumId);
      return newTopic;
    } on DioException catch (e) {
      throw AppException(
          message: e.message ?? 'Erreur lors de la création du sujet');
    }
  }

  // Créer une réponse
  Future<Reply> createReply({
    required String topicId,
    required String content,
    String? parentReplyId,
  }) async {
    try {
      final response = await _dio.post(
        '/forums/topics/$topicId/replies',
        data: {
          'content': content,
          'parentReplyId': parentReplyId,
        },
      );

      final newReply = Reply.fromJson(response.data);
      await _storage.removeData(_getTopicKey(topicId));
      return newReply;
    } on DioException catch (e) {
      throw AppException(
          message: e.message ?? 'Erreur lors de la création de la réponse');
    }
  }

  // Méthodes de cache
  Future<void> _cacheModuleForum(String moduleId, Forum forum) async {
    await _storage.saveData(_getModuleForumKey(moduleId), forum.toJson());
  }

  Future<Forum?> _getCachedModuleForum(String moduleId) async {
    try {
      final data = await _storage.getData(_getModuleForumKey(moduleId));
      if (data != null) return Forum.fromJson(data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheChapterForum(String chapterId, Forum forum) async {
    await _storage.saveData(_getChapterForumKey(chapterId), forum.toJson());
  }

  Future<Forum?> _getCachedChapterForum(String chapterId) async {
    try {
      final data = await _storage.getData(_getChapterForumKey(chapterId));
      if (data != null) return Forum.fromJson(data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _invalidateForumCache(String forumId) async {
    final moduleKey = _getModuleForumKey(forumId);
    final chapterKey = _getChapterForumKey(forumId);

    await Future.wait([
      _storage.removeData(moduleKey),
      _storage.removeData(chapterKey),
    ]);
  }
}
