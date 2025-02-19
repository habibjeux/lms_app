import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../features/modules/models/activity.dart';
import '../../features/modules/models/resource.dart';
import '../network/api_client.dart';
import 'download_storage_service.dart';
import 'offline_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SyncService {
  final OfflineStorageService _storage = OfflineStorageService();
  final DownloadStorageService _downloadStorage = DownloadStorageService();
  final Dio _api = ApiClient.instance;
  final Dio _apiUpload = ApiClient.uploadInstance;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/resources';
    await Directory(path).create(recursive: true);
    return path;
  }

  Future<bool> isOnline() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> isChapterDownloaded(String chapterId) async {
    return await _downloadStorage.isChapterDownloaded(chapterId);
  }

  Future<bool> isResourceDownloaded(String resourceId) async {
    return await _downloadStorage.isResourceDownloaded(resourceId);
  }

  Future<void> downloadChapter(
    String chapterId, {
    void Function(double)? onProgress,
    void Function()? onComplete,
    void Function(String)? onError,
  }) async {
    if (!await isOnline()) {
      onError?.call('Pas de connexion Internet');
      return;
    }

    try {
      final response = await _api.get('/chapters/$chapterId/activities');
      final activities = List<Map<String, dynamic>>.from(response.data['data']);

      final resources = activities.where((a) => a['type'] == 'RESOURCE').length;
      int downloadedCount = 0;

      await _storage.saveActivities(chapterId, activities);

      for (var activityData in activities) {
        final activity = Activity.fromJson(activityData);

        if (activity is Resource && activity.downloadable) {
          try {
            await downloadResource(
              activity,
              isPartOfSync: true,
            );
            downloadedCount++;
            onProgress?.call(downloadedCount / resources);
          } catch (e) {
            onError?.call(
                'Erreur lors du téléchargement de ${activity.title}: $e');
          }
        }
      }

      await _downloadStorage.markChapterAsDownloaded(chapterId);
      onComplete?.call();
    } catch (e) {
      onError?.call('Erreur lors du téléchargement du chapitre: $e');
    }
  }

  Future<void> downloadResource(
    Resource resource, {
    void Function(double)? individualProgress,
    bool isPartOfSync = false,
  }) async {
    if (!resource.downloadable) return;

    try {
      final localPath = await _localPath;
      final fileName = resource.url.split('/').last;
      final file = File('$localPath/$fileName');

      if (await file.exists()) {
        await _downloadStorage.markResourceAsDownloaded(resource.id);
        return;
      }

      final response = await _apiUpload.get(
        resource.url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
        onReceiveProgress: (received, total) {
          if (!isPartOfSync && total != -1 && individualProgress != null) {
            individualProgress(received / total);
          }
        },
      );

      await file.writeAsBytes(response.data);
      await _downloadStorage.markResourceAsDownloaded(resource.id);
    } catch (e) {
      print('Erreur lors du téléchargement de la ressource: $e');
      rethrow;
    }
  }

  Future<String?> getLocalResourcePath(Resource resource) async {
    if (!resource.downloadable || !await isResourceDownloaded(resource.id)) {
      return null;
    }

    try {
      final localPath = await _localPath;
      final fileName = resource.url.split('/').last;
      final file = File('$localPath/$fileName');

      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> smartSync({
    void Function(double)? onProgress,
    void Function(String)? onError,
    required String moduleId,
    bool force = false,
  }) async {
    if (_isSyncing && !force) {
      onError?.call('Une synchronisation est déjà en cours');
      return;
    }

    _isSyncing = true;

    try {
      if (!await isOnline()) {
        onError?.call('Pas de connexion Internet disponible');
        return;
      }

      double progress = 0;
      onProgress?.call(progress);

      // 1. Synchronisation du module
      if (force || await _storage.isDataStale('module_$moduleId')) {
        try {
          final moduleData = await _api.get('/modules/$moduleId');
          await _storage.saveModules([moduleData.data]);
        } catch (e) {
          onError?.call(
              'Erreur lors de la synchronisation du module: ${e.toString()}');
          await _useCachedDataIfAvailable(moduleId);
        }
      }
      progress = 0.25;
      onProgress?.call(progress);

      // 2. Synchronisation des chapitres et leurs activités
      if (force || await _storage.isDataStale('chapters_$moduleId')) {
        try {
          final chaptersData = await _api.get('/modules/$moduleId/chapters');
          await _storage.saveChapters(moduleId, chaptersData.data);

          // 3. Synchroniser les activités de chaque chapitre
          for (var chapter in chaptersData.data) {
            try {
              final chapterId = chapter['id'];
              final activitiesData =
                  await _api.get('/chapters/$chapterId/activities');
              await _storage.saveActivities(
                  chapterId, activitiesData.data['data']);
            } catch (e) {
              onError?.call(
                  'Erreur lors de la synchronisation des activités du chapitre: ${e.toString()}');
              await _useCachedDataIfAvailable(moduleId,
                  dataType: 'activities', chapterId: chapter['id']);
            }
          }
        } catch (e) {
          onError?.call(
              'Erreur lors de la synchronisation des chapitres: ${e.toString()}');
          await _useCachedDataIfAvailable(moduleId, dataType: 'chapters');
        }
      }
      progress = 0.75;
      onProgress?.call(progress);

      await _manageStorage();
      progress = 1.0;
      onProgress?.call(progress);
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<Map<String, dynamic>>> getChapters(String moduleId) async {
    try {
      if (await isOnline()) {
        final response = await _api.get('/modules/$moduleId/chapters');
        return List<Map<String, dynamic>>.from(response.data);
      }
      return await _getOfflineChapters(moduleId);
    } catch (e) {
      return await _getOfflineChapters(moduleId);
    }
  }

  Future<List<Map<String, dynamic>>> getChapterActivities(
      String chapterId) async {
    try {
      if (await isOnline()) {
        final response = await _api.get('/chapters/$chapterId/activities');
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return await _getOfflineActivities(chapterId);
    } catch (e) {
      return await _getOfflineActivities(chapterId);
    }
  }

  Future<void> manualSync(String moduleId) async {
    await smartSync(moduleId: moduleId, force: true);
  }

  Future<List<Map<String, dynamic>>> _getOfflineChapters(
      String moduleId) async {
    final cachedData = await _storage.getChapters(moduleId);
    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(cachedData);
    }
    throw Exception('Chapitres non disponibles hors ligne');
  }

  Future<List<Map<String, dynamic>>> _getOfflineActivities(
      String chapterId) async {
    final cachedData = await _storage.getActivities(chapterId);
    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(cachedData);
    }
    throw Exception('Activités non disponibles hors ligne');
  }

  Future<void> _manageStorage() async {
    final storageSize = await _storage.getStorageSize();
    if (storageSize > 500 * 1024 * 1024) {
      // 500 MB
      await _storage.clearOldData(const Duration(days: 30));
    }
  }

  Future<void> _useCachedDataIfAvailable(String moduleId,
      {String? dataType, String? chapterId}) async {
    try {
      if (dataType == 'chapters') {
        await _getOfflineChapters(moduleId);
      } else if (dataType == 'activities' && chapterId != null) {
        await _getOfflineActivities(chapterId);
      }
    } catch (e) {
      rethrow;
    }
  }
}
