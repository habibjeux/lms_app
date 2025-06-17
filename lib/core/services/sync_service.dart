import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/modules/models/activity.dart';
import '../../features/modules/models/assignment_attachment.dart';
import '../../features/modules/models/resource.dart';
import '../../features/modules/models/enums/activity_type.dart';
import '../network/api_client.dart';
import 'download_storage_service.dart';
import 'offline_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

import '../../features/modules/models/assignment.dart';

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

  Future<ConnectionQuality> getConnectionQuality() async {
    if (!await isOnline()) {
      return ConnectionQuality.offline;
    }

    try {
      final startTime = DateTime.now();
      await _api.get('/ping');
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      if (responseTime < 1000) {
        return ConnectionQuality.good;
      } else if (responseTime < 3000) {
        return ConnectionQuality.medium;
      } else {
        return ConnectionQuality.poor;
      }
    } catch (e) {
      return ConnectionQuality.poor;
    }
  }

  Future<bool> isChapterDownloaded(String chapterId) async {
    return await _downloadStorage.isChapterDownloaded(chapterId);
  }

  Future<bool> isResourceDownloaded(String resourceId) async {
    return await _downloadStorage.isResourceDownloaded(resourceId);
  }

  Future<bool> isQuizDownloaded(String quizId) async {
    return await _downloadStorage.isQuizDownloaded(quizId);
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
      final response = await _api.get('/chapters/$chapterId');
      final chapterData = response.data['data'] as Map<String, dynamic>;
      final moduleId = chapterData['moduleId'] as String;
      final title = chapterData['title'] as String;
      final content = chapterData['content'] as String?;

      print('Téléchargement du chapitre: $title (ID: $chapterId)');

      // Sauvegarder le contenu du chapitre
      if (content != null) {
        await _storage.saveChapterContent(chapterId, content);
      }

      final activitiesResponse =
          await _api.get('/chapters/$chapterId/activities');
      final activities =
          List<Map<String, dynamic>>.from(activitiesResponse.data['data']);

      final totalItems = activities.length;
      int downloadedCount = 0;

      await _storage.saveActivities(chapterId, activities);

      for (var activityData in activities) {
        final activity = Activity.fromJson(activityData);

        if (activity is Resource) {
          try {
            print('Téléchargement de la ressource: ${activity.title}');
            await downloadResource(
              activity,
              isPartOfSync: true,
            );
            downloadedCount++;
            onProgress?.call(downloadedCount / totalItems);
          } catch (e) {
            print('Erreur lors du téléchargement de la ressource: $e');
            onError?.call(
                'Erreur lors du téléchargement de ${activity.title}: $e');
          }
        } else if (activity.type == ActivityType.QUIZ) {
          try {
            print('Téléchargement du quiz: ${activity.title}');
            await downloadQuiz(
              activity.id,
              moduleId: moduleId,
              chapterId: chapterId,
              title: activity.title,
            );
            downloadedCount++;
            onProgress?.call(downloadedCount / totalItems);
          } catch (e) {
            print('Erreur lors du téléchargement du quiz: $e');
            onError?.call(
                'Erreur lors du téléchargement du quiz ${activity.title}: $e');
          }
        }
      }

      print('Marquage du chapitre comme téléchargé: $chapterId');
      await _downloadStorage.markChapterAsDownloaded(
        chapterId,
        moduleId: moduleId,
        title: title,
      );
      onComplete?.call();
    } catch (e) {
      print('Erreur lors du téléchargement du chapitre: $e');
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
        print('La ressource existe déjà: ${resource.title}');
        await _downloadStorage.markResourceAsDownloaded(
          resource.id,
          moduleId: resource.moduleId,
          chapterId: resource.chapterId,
          title: resource.title,
        );
        return;
      }

      print('Téléchargement de la ressource: ${resource.title}');
      final connectionQuality = await getConnectionQuality();
      final url = connectionQuality == ConnectionQuality.good
          ? resource.url
          : resource.compressedUrl ?? resource.url;

      final response = await _apiUpload.get(
        url,
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
      print('Ressource téléchargée avec succès: ${resource.title}');
      await _downloadStorage.markResourceAsDownloaded(
        resource.id,
        moduleId: resource.moduleId,
        chapterId: resource.chapterId,
        title: resource.title,
      );
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

  Future<void> downloadFullModule(
    String moduleId, {
    void Function(double)? onProgress,
    void Function()? onComplete,
    void Function(String)? onError,
  }) async {
    try {
      print('Téléchargement du module complet: $moduleId');

      // 1. Télécharger les activités du module directement
      print('🔍 Téléchargement des activités du module...');
      try {
        print('🔍 Appel API: /modules/$moduleId/activities');
        final moduleActivitiesResponse =
            await _api.get('/modules/$moduleId/activities');

        print(
            '🔍 Réponse API activités module: ${moduleActivitiesResponse.data}');

        final moduleActivities = List<Map<String, dynamic>>.from(
            moduleActivitiesResponse.data['data']);

        print(
            '🔍 Nombre d\'activités du module trouvées: ${moduleActivities.length}');

        await _storage.saveModuleActivities(moduleId, moduleActivities);

        for (var activityData in moduleActivities) {
          final activity = Activity.fromJson(activityData);

          // Debug: afficher le type de l'activité
          print(
              '🔍 Activité du module: ${activity.title} - Type: ${activity.type} - Classe: ${activity.runtimeType}');

          if (activity is Resource) {
            try {
              print(
                  'Téléchargement de la ressource du module: ${activity.title}');
              await downloadResource(
                activity,
                isPartOfSync: true,
              );
            } catch (e) {
              print(
                  'Erreur lors du téléchargement de la ressource du module: $e');
            }
          } else if (activity.type == ActivityType.QUIZ) {
            try {
              print('Téléchargement du quiz du module: ${activity.title}');
              await downloadQuiz(
                activity.id,
                moduleId: moduleId,
                chapterId: null, // Activité du module, pas d'un chapitre
                title: activity.title,
              );
            } catch (e) {
              print('Erreur lors du téléchargement du quiz du module: $e');
            }
          } else if (activity is Assignment ||
              activity.type == ActivityType.ASSIGNMENT) {
            try {
              print('🎯 DÉTECTION ASSIGNMENT du module: ${activity.title}');
              print(
                  '🎯 Type: ${activity.type}, Classe: ${activity.runtimeType}');

              // Si ce n'est pas déjà un Assignment, le convertir
              Assignment assignmentToDownload;
              if (activity is Assignment) {
                assignmentToDownload = activity;
                print('🎯 Assignment déjà de la bonne classe');
              } else {
                // Créer un Assignment à partir des données de l'activité
                print('🎯 Conversion vers Assignment...');
                assignmentToDownload = Assignment.fromJson(activityData);
                print('🎯 Assignment converti avec succès');
              }

              await downloadAssignment(
                activity.id,
                moduleId: moduleId,
                chapterId: null,
                title: activity.title,
              );
            } catch (e) {
              print(
                  '🎯 ❌ Erreur lors du téléchargement du devoir du module: $e');
            }
          } else {
            print(
                '🔍 Type d\'activité non géré: ${activity.type} - ${activity.runtimeType}');
          }
        }
      } catch (e) {
        print('Erreur lors du téléchargement des activités du module: $e');
        // Continuer même si les activités du module échouent
      }

      // 2. Télécharger les chapitres et leurs activités
      final response = await _api.get('/modules/$moduleId/chapters');
      final chapters = List<Map<String, dynamic>>.from(response.data);

      if (chapters.isEmpty) {
        print(
            'Aucun chapitre trouvé dans ce module, mais les activités du module ont été téléchargées');
        onComplete?.call();
        return;
      }

      final totalChapters = chapters.length;
      int downloadedChapters = 0;

      for (var chapterData in chapters) {
        final chapterId = chapterData['id'] as String;
        final title = chapterData['title'] as String;
        final content = chapterData['content'] as String?;

        print('Téléchargement du chapitre: $title (ID: $chapterId)');

        // Sauvegarder le contenu du chapitre
        if (content != null) {
          await _storage.saveChapterContent(chapterId, content);
        }

        // Télécharger les activités du chapitre
        final activitiesResponse =
            await _api.get('/chapters/$chapterId/activities');
        final activities =
            List<Map<String, dynamic>>.from(activitiesResponse.data['data']);

        await _storage.saveActivities(chapterId, activities);

        for (var activityData in activities) {
          final activity = Activity.fromJson(activityData);

          // Debug: afficher le type de l'activité
          print(
              '🔍 Activité du chapitre: ${activity.title} - Type: ${activity.type} - Classe: ${activity.runtimeType}');

          if (activity is Resource) {
            try {
              print('Téléchargement de la ressource: ${activity.title}');
              await downloadResource(
                activity,
                isPartOfSync: true,
              );
            } catch (e) {
              print('Erreur lors du téléchargement de la ressource: $e');
              onError
                  ?.call('Erreur lors du téléchargement de la ressource: $e');
            }
          } else if (activity.type == ActivityType.QUIZ) {
            try {
              print('Téléchargement du quiz: ${activity.title}');
              await downloadQuiz(
                activity.id,
                moduleId: moduleId,
                chapterId: chapterId,
                title: activity.title,
              );
            } catch (e) {
              print('Erreur lors du téléchargement du quiz: $e');
              onError?.call('Erreur lors du téléchargement du quiz: $e');
            }
          } else if (activity is Assignment ||
              activity.type == ActivityType.ASSIGNMENT) {
            try {
              print('🎯 DÉTECTION ASSIGNMENT du chapitre: ${activity.title}');
              print(
                  '🎯 Type: ${activity.type}, Classe: ${activity.runtimeType}');

              // Si ce n'est pas déjà un Assignment, le convertir
              Assignment assignmentToDownload;
              if (activity is Assignment) {
                assignmentToDownload = activity;
                print('🎯 Assignment déjà de la bonne classe');
              } else {
                // Créer un Assignment à partir des données de l'activité
                print('🎯 Conversion vers Assignment...');
                assignmentToDownload = Assignment.fromJson(activityData);
                print('🎯 Assignment converti avec succès');
              }

              await downloadAssignment(
                activity.id,
                moduleId: moduleId,
                chapterId: chapterId,
                title: activity.title,
              );
            } catch (e) {
              print(
                  '🎯 ❌ Erreur lors du téléchargement du devoir du chapitre: $e');
              onError?.call('Erreur lors du téléchargement du devoir: $e');
            }
          } else {
            print(
                '🔍 Type d\'activité non géré: ${activity.type} - ${activity.runtimeType}');
          }
        }

        await _downloadStorage.markChapterAsDownloaded(
          chapterId,
          moduleId: moduleId,
          title: title,
        );

        downloadedChapters++;
        onProgress?.call(downloadedChapters / totalChapters);
        print('Progression: $downloadedChapters/$totalChapters chapitres');
      }

      print('Module téléchargé avec succès: $moduleId');
      onComplete?.call();
    } catch (e) {
      print('Erreur lors du téléchargement du module: $e');
      onError?.call('Erreur lors du téléchargement du module: $e');
      rethrow;
    }
  }

  Future<void> downloadQuiz(
    String quizId, {
    String? moduleId,
    String? chapterId,
    String? title,
    void Function(double)? onProgress,
  }) async {
    try {
      print('Téléchargement du quiz: $title (ID: $quizId)');
      final response = await _api.get('/quizzes/$quizId');

      // Les données sont directement dans response.data, pas dans response.data['data']
      final quizData = response.data;

      if (quizData == null) {
        throw Exception('Données du quiz vides');
      }

      // Sauvegarder le quiz localement
      await _storage.saveQuiz(quizId, quizData);
      print('Quiz sauvegardé localement: $quizId');
      await _downloadStorage.markQuizAsDownloaded(
        quizId,
        moduleId: moduleId,
        chapterId: chapterId,
        title: title,
      );
      print('Quiz marqué comme téléchargé: $quizId');

      onProgress?.call(1.0);
    } catch (e) {
      print('Erreur lors du téléchargement du quiz: $e');
      rethrow;
    }
  }

  // Téléchargement des devoirs - version simplifiée
  Future<void> downloadAssignment(
    String assignmentId, {
    String? moduleId,
    String? chapterId,
    String? title,
    void Function(double)? onProgress,
  }) async {
    try {
      print('📝 Téléchargement du devoir: $title (ID: $assignmentId)');

      // Récupérer les données complètes du devoir depuis l'API
      final response = await _api.get('/assignments/$assignmentId');

      if (response.statusCode == 200 && response.data != null) {
        // Sauvegarder les données complètes du devoir
        await _storage.saveAssignment(assignmentId, response.data);
        print('📝 Devoir sauvegardé localement: $assignmentId');

        // Télécharger les pièces jointes si elles existent
        final assignmentData = response.data;
        if (assignmentData['attachments'] != null) {
          final attachments =
              List<Map<String, dynamic>>.from(assignmentData['attachments']);
          for (var attachmentData in attachments) {
            await _downloadAssignmentAttachment(attachmentData);
          }
        }

        // Marquer comme téléchargé
        await _downloadStorage.markAssignmentAsDownloaded(
          assignmentId,
          {
            'moduleId': moduleId,
            'chapterId': chapterId,
            'title': title,
            'type': 'assignment',
            'downloadedAt': DateTime.now().toIso8601String(),
          },
        );

        print('📝 ✅ Devoir téléchargé avec succès: $assignmentId');
        onProgress?.call(1.0);
      } else {
        throw Exception('Impossible de récupérer les données du devoir');
      }
    } catch (e) {
      print('📝 ❌ Erreur lors du téléchargement du devoir: $e');
      rethrow;
    }
  }

  // Téléchargement des pièces jointes de devoir
  Future<void> _downloadAssignmentAttachment(
      Map<String, dynamic> attachmentData) async {
    try {
      final attachmentId = attachmentData['id'] as String;
      final url = attachmentData['url'] as String;
      final filename = attachmentData['filename'] as String;

      // Créer le répertoire local pour les pièces jointes
      final directory = await getApplicationDocumentsDirectory();
      final attachmentsPath = '${directory.path}/assignments/attachments';
      await Directory(attachmentsPath).create(recursive: true);

      final localFile = File('$attachmentsPath/$attachmentId-$filename');

      // Vérifier si le fichier existe déjà
      if (await localFile.exists()) {
        print('Pièce jointe déjà téléchargée: $filename');
        return;
      }

      // Télécharger le fichier
      final serverUrl = dotenv.env['SERVER_URL'] ?? '';
      final fullUrl = '$serverUrl$url';

      final response = await _apiUpload.get(
        fullUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      await localFile.writeAsBytes(response.data);
      print('Pièce jointe téléchargée: $filename');
    } catch (e) {
      print('Erreur lors du téléchargement de la pièce jointe: $e');
      // Ne pas faire échouer tout le téléchargement pour une pièce jointe
    }
  }

  // Synchronisation des soumissions en attente
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
                  'files',
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

          final response = await _apiUpload.post(
            '/assignments/submit',
            data: formData,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Marquer comme synchronisé
            submission['status'] = 'synchronized';
            await pendingSubmissionsBox.put(submissionId, submission);
            pendingSubmissions.remove(submissionId);

            // Nettoyage des fichiers temporaires
            for (String filePath in localFilePaths) {
              final file = File(filePath);
              if (await file.exists()) {
                await file.delete();
              }
            }
            print('Soumission synchronisée: $submissionId');
          }
        } catch (e) {
          print(
              'Erreur lors de la synchronisation de la soumission $submissionId: $e');
        }
      }

      await syncQueueBox.put('assignments_queue', pendingSubmissions);
    } catch (e) {
      print('Erreur lors de la synchronisation des soumissions: $e');
    }
  }

  // Obtenir le nombre de soumissions en attente
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
}

enum ConnectionQuality {
  offline,
  poor,
  medium,
  good,
}
