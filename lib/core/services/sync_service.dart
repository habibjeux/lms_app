import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../../features/modules/models/activity.dart';
import '../../features/modules/models/assignment_attachment.dart';
import '../../features/modules/models/resource.dart';
import '../network/api_client.dart';
import 'download_storage_service.dart';
import 'offline_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

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

        if (activity is Resource) {
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
    try {
      final localPath = await _localPath;
      final fileName = resource.url.split('/').last;
      final file = File('$localPath/$fileName');

      if (await file.exists()) {
        await _downloadStorage.markResourceAsDownloaded(resource.id);
        return;
      }

      final response = await _apiUpload.get(
        resource.compressedUrl ?? resource.url,
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

      // 4. Synchroniser les activités du module
      if (force || await _storage.isDataStale('module_activities_$moduleId')) {
        try {
          final moduleActivitiesData =
              await _api.get('/modules/$moduleId/activities');
          await _storage.saveModuleActivities(
              moduleId, moduleActivitiesData.data['data']);
        } catch (e) {
          onError?.call(
              'Erreur lors de la synchronisation des activités du module: ${e.toString()}');
          await _useCachedDataIfAvailable(moduleId,
              dataType: 'module_activities');
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

  Future<List<Map<String, dynamic>>> getModuleActivities(
      String moduleId) async {
    try {
      if (await isOnline()) {
        final response = await _api.get('/modules/$moduleId/activities');
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return await _getOfflineModuleActivities(moduleId);
    } catch (e) {
      return await _getOfflineModuleActivities(moduleId);
    }
  }

  Future<List<Map<String, dynamic>>> _getOfflineModuleActivities(
      String moduleId) async {
    final cachedData = await _storage.getModuleActivities(moduleId);
    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(cachedData);
    }
    throw Exception('Activités du module non disponibles hors ligne');
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
    final cachedData = await _storage.getChapterActivities(chapterId);
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
      } else if (dataType == 'module_activities') {
        await _getOfflineModuleActivities(moduleId);
      }
    } catch (e) {
      rethrow;
    }
  }
}

extension AssignmentExtensions on SyncService {
  Future<void> downloadAttachment(
    AssignmentAttachment attachment, {
    void Function(double)? individualProgress,
  }) async {
    if (!await isOnline()) {
      throw Exception('Pas de connexion Internet');
    }

    try {
      final localPath = await _getAttachmentLocalPath();
      final fileName = attachment.url.split('/').last;
      final file = File('$localPath/$fileName');

      if (await file.exists()) {
        await _downloadStorage.markResourceAsDownloaded(attachment.id);
        return;
      }

      final response = await _apiUpload.get(
        attachment.url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1 && individualProgress != null) {
            individualProgress(received / total);
          }
        },
      );

      await file.writeAsBytes(response.data);
      await _downloadStorage.markResourceAsDownloaded(attachment.id);
    } catch (e) {
      print('Erreur lors du téléchargement de la pièce jointe: $e');
      rethrow;
    }
  }

  Future<String?> getLocalAttachmentPath(
      AssignmentAttachment attachment) async {
    if (!await _downloadStorage.isResourceDownloaded(attachment.id)) {
      return null;
    }

    try {
      final localPath = await _getAttachmentLocalPath();
      final fileName = attachment.url.split('/').last;
      final file = File('$localPath/$fileName');

      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String> _getAttachmentLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/attachments';
    await Directory(path).create(recursive: true);
    return path;
  }

  Future<void> syncPendingAssignmentSubmissions() async {
    if (!await isOnline()) {
      return;
    }

    try {
      final syncQueueBox = await Hive.openBox('sync_queue');
      final pendingSubmissionsBox = await Hive.openBox('pending_submissions');

      final List<dynamic> pendingSubmissions =
          syncQueueBox.get('assignments_queue', defaultValue: []);

      if (pendingSubmissions.isEmpty) {
        return;
      }

      for (String submissionId in List<String>.from(pendingSubmissions)) {
        final submission = pendingSubmissionsBox.get(submissionId);

        if (submission == null) {
          // Suppression de la référence si la soumission n'existe plus
          pendingSubmissions.remove(submissionId);
          continue;
        }

        try {
          // Préparation des fichiers pour l'upload
          List<String> localFilePaths = List<String>.from(submission['files']);

          // Soumission du devoir
          final formData = FormData();
          for (String filePath in localFilePaths) {
            final file = File(filePath);
            if (await file.exists()) {
              formData.files.add(
                MapEntry(
                  'files[]',
                  await MultipartFile.fromFile(file.path,
                      filename: file.path.split('/').last),
                ),
              );
            }
          }
          formData.fields
              .add(MapEntry('assignmentId', submission['assignmentId']));
          formData.fields.add(MapEntry('comment', submission['comment'] ?? ''));
          formData.fields
              .add(MapEntry('isLate', submission['isLate'].toString()));

          final Response response;

          response = await _api.post(
            '/assignments/submit',
            data: formData,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Mise à jour du statut de la soumission
            submission['status'] = 'completed';
            await pendingSubmissionsBox.put(submissionId, submission);

            // Suppression de la file d'attente
            pendingSubmissions.remove(submissionId);

            // Nettoyage des fichiers temporaires
            for (String filePath in localFilePaths) {
              final file = File(filePath);
              if (await file.exists()) {
                await file.delete();
              }
            }
          } else {
            throw Exception('Erreur lors de la soumission du devoir');
          }
        } catch (e) {
          print(
              'Erreur lors de la synchronisation de la soumission $submissionId: $e');
          // En cas d'erreur, on garde la soumission dans la file pour une tentative ultérieure
        }
      }

      // Mise à jour de la file d'attente
      await syncQueueBox.put('assignments_queue', pendingSubmissions);
    } catch (e) {
      print('Erreur lors de la synchronisation des soumissions de devoirs: $e');
    }
  }

  Future<int> getPendingSubmissionsCount() async {
    try {
      final syncQueueBox = await Hive.openBox('sync_queue');
      final List<dynamic> pendingSubmissions =
          syncQueueBox.get('assignments_queue', defaultValue: []);
      return pendingSubmissions.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> syncAssignmentData(String moduleId) async {
    if (!await isOnline()) {
      return;
    }

    try {
      final response = await _api.get('/modules/$moduleId/assignments');

      if (response.statusCode == 200) {
        final assignments = List<Map<String, dynamic>>.from(response.data);

        // Stockage des assignments dans Hive
        final assignmentsBox = await Hive.openBox('assignments');
        await assignmentsBox.put(moduleId, json.encode(assignments));

        // Mise à jour de la date de dernière synchronisation
        await _storage.saveLastSync('assignments_$moduleId', DateTime.now());
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des devoirs: $e');
    }
  }
}
