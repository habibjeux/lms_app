import 'package:hive/hive.dart';

class DownloadStorageService {
  static const String downloadedChaptersBox = 'downloaded_chapters';
  static const String downloadedResourcesBox = 'downloaded_resources';
  static const String downloadedQuizzesBox = 'downloaded_quizzes';

  Box<dynamic>? _resourcesBox;
  Box<dynamic>? _chaptersBox;
  Box<dynamic>? _quizzesBox;
  String? _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  Future<Box<dynamic>> _getResourcesBox() async {
    _resourcesBox ??= await Hive.openBox('downloaded_resources');
    return _resourcesBox!;
  }

  Future<Box<dynamic>> _getChaptersBox() async {
    _chaptersBox ??= await Hive.openBox('downloaded_chapters');
    return _chaptersBox!;
  }

  Future<Box<dynamic>> _getQuizzesBox() async {
    _quizzesBox ??= await Hive.openBox('downloaded_quizzes');
    return _quizzesBox!;
  }

  Future<void> markChapterAsDownloaded(String chapterId,
      {String? moduleId, String? title, String? moduleTitle}) async {
    try {
      print('Marquage du chapitre comme téléchargé: $chapterId');
      final box = await _getChaptersBox();
      await box.put(chapterId, {
        'moduleId': moduleId,
        'moduleTitle': moduleTitle,
        'title': title,
        'chapterTitle': title,
        'type': 'chapter',
        'downloadedAt': DateTime.now().toIso8601String(),
        'activities': <String>[],
      });
      print('Chapitre marqué comme téléchargé avec succès: $chapterId');
    } catch (e) {
      print('Erreur lors du marquage du chapitre: $e');
      rethrow;
    }
  }

  Future<void> markResourceAsDownloaded(String resourceId,
      {String? moduleId,
      String? chapterId,
      String? title,
      String? moduleTitle,
      String? chapterTitle}) async {
    try {
      print('Marquage de la ressource comme téléchargée: $resourceId');
      final box = await _getResourcesBox();
      await box.put(resourceId, {
        'moduleId': moduleId,
        'moduleTitle': moduleTitle,
        'chapterId': chapterId,
        'chapterTitle': chapterTitle,
        'title': title,
        'type': 'resource',
        'downloadedAt': DateTime.now().toIso8601String(),
        'filePath': 'resources/$resourceId',
      });
      print('Ressource marquée comme téléchargée avec succès: $resourceId');
    } catch (e) {
      print('Erreur lors du marquage de la ressource: $e');
      rethrow;
    }
  }

  Future<void> markQuizAsDownloaded(String quizId,
      {String? moduleId,
      String? chapterId,
      String? title,
      String? moduleTitle,
      String? chapterTitle}) async {
    try {
      print('Marquage du quiz comme téléchargé: $quizId');
      final box = await _getQuizzesBox();
      await box.put(quizId, {
        'moduleId': moduleId,
        'moduleTitle': moduleTitle,
        'chapterId': chapterId,
        'chapterTitle': chapterTitle,
        'title': title,
        'type': 'quiz',
        'downloadedAt': DateTime.now().toIso8601String(),
      });
      print('Quiz marqué comme téléchargé avec succès: $quizId');

      // Mettre à jour la liste des activités du chapitre
      if (chapterId != null) {
        final chaptersBox = await _getChaptersBox();
        final chapterData = chaptersBox.get(chapterId);
        if (chapterData != null) {
          List<String> activities;
          if (chapterData is bool) {
            activities = [];
          } else if (chapterData is Map) {
            activities = List<String>.from(chapterData['activities'] ?? []);
          } else {
            activities = [];
          }

          if (!activities.contains(quizId)) {
            activities.add(quizId);
            await chaptersBox.put(chapterId, {
              'moduleId': moduleId,
              'moduleTitle': moduleTitle,
              'title': chapterTitle ?? title,
              'chapterTitle': chapterTitle ?? title,
              'type': 'chapter',
              'downloadedAt': DateTime.now().toIso8601String(),
              'activities': activities,
            });
          }
        }
      }
    } catch (e) {
      print('Erreur lors du marquage du quiz: $e');
      rethrow;
    }
  }

  Future<bool> isChapterDownloaded(String chapterId) async {
    final box = await _getChaptersBox();
    return box.containsKey(chapterId);
  }

  Future<bool> isResourceDownloaded(String resourceId) async {
    final box = await _getResourcesBox();
    return box.containsKey(resourceId);
  }

  Future<bool> isQuizDownloaded(String quizId) async {
    final box = await _getQuizzesBox();
    return box.containsKey(quizId);
  }

  Future<Map<String, dynamic>?> getChapterInfo(String chapterId) async {
    final box = await _getChaptersBox();
    final data = box.get(chapterId);
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getResourceInfo(String resourceId) async {
    final box = await _getResourcesBox();
    final data = box.get(resourceId);
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getQuizInfo(String quizId) async {
    final box = await _getQuizzesBox();
    final data = box.get(quizId);
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> clearDownloadData() async {
    final chaptersBox = await _getChaptersBox();
    final resourcesBox = await _getResourcesBox();
    final quizzesBox = await _getQuizzesBox();
    await chaptersBox.clear();
    await resourcesBox.clear();
    await quizzesBox.clear();
  }

  Future<List<Map<String, dynamic>>> getDownloadedItems() async {
    try {
      print('Récupération des éléments téléchargés');
      final resourcesBox = await _getResourcesBox();
      final chaptersBox = await _getChaptersBox();
      final quizzesBox = await _getQuizzesBox();
      final assignmentsBox = await _getAssignmentsBox();
      final attachmentsBox = await _getAttachmentsBox();
      final submissionFilesBox = await _getSubmissionFilesBox();

      print('Contenu des boîtes:');
      print('Ressources: ${resourcesBox.toMap()}');
      print('Chapitres: ${chaptersBox.toMap()}');
      print('Quiz: ${quizzesBox.toMap()}');
      print('Assignments: ${assignmentsBox.toMap()}');
      print('Attachments: ${attachmentsBox.toMap()}');
      print('Submission Files: ${submissionFilesBox.toMap()}');

      final List<Map<String, dynamic>> items = [];

      // Récupérer les ressources
      for (var key in resourcesBox.keys) {
        final data = resourcesBox.get(key);
        if (data is Map) {
          items.add({
            'id': key.toString(),
            ...Map<String, dynamic>.from(data),
          });
        }
      }

      // Récupérer les chapitres
      for (var key in chaptersBox.keys) {
        final data = chaptersBox.get(key);
        if (data is Map) {
          items.add({
            'id': key.toString(),
            ...Map<String, dynamic>.from(data),
          });
        }
      }

      // Récupérer les quiz
      for (var key in quizzesBox.keys) {
        final data = quizzesBox.get(key);
        if (data is Map) {
          items.add({
            'id': key.toString(),
            ...Map<String, dynamic>.from(data),
          });
        } else if (data is bool) {
          items.add({
            'id': key.toString(),
            'type': 'quiz',
            'downloaded': data,
          });
        }
      }

      // Récupérer les assignments
      for (var key in assignmentsBox.keys) {
        final data = assignmentsBox.get(key);
        if (data is Map) {
          items.add({
            'id': key.toString(),
            ...Map<String, dynamic>.from(data),
          });
        }
      }

      // Récupérer les pièces jointes
      for (var key in attachmentsBox.keys) {
        final data = attachmentsBox.get(key);
        if (data is Map) {
          items.add({
            'id': key.toString(),
            ...Map<String, dynamic>.from(data),
          });
        }
      }

      // Récupérer les fichiers soumis
      for (var key in submissionFilesBox.keys) {
        final data = submissionFilesBox.get(key);
        if (data is Map) {
          items.add({
            'id': key.toString(),
            ...Map<String, dynamic>.from(data),
          });
        }
      }

      print('Éléments téléchargés récupérés: ${items.length} éléments');
      return items;
    } catch (e) {
      print('Erreur lors de la récupération des éléments téléchargés: $e');
      return [];
    }
  }

  Future<void> deleteItem(String id, String type) async {
    try {
      print('Suppression de l\'élément: $id (type: $type)');
      switch (type) {
        case 'resource':
          final box = await _getResourcesBox();
          await box.delete(id);
          break;
        case 'quiz':
          final box = await _getQuizzesBox();
          await box.delete(id);
          break;
        case 'chapter':
          final box = await _getChaptersBox();
          await box.delete(id);
          break;
        case 'assignment':
          final box = await _getAssignmentsBox();
          await box.delete(id);
          break;
        case 'attachment':
          final box = await _getAttachmentsBox();
          await box.delete(id);
          break;
        case 'submission_file':
          final box = await _getSubmissionFilesBox();
          await box.delete(id);
          break;
      }
      print('Élément supprimé avec succès: $id');
    } catch (e) {
      print('Erreur lors de la suppression de l\'élément: $e');
      rethrow;
    }
  }

  Future<void> clearAllDownloads() async {
    try {
      print('Suppression de tous les téléchargements');
      final resourcesBox = await _getResourcesBox();
      final chaptersBox = await _getChaptersBox();
      final quizzesBox = await _getQuizzesBox();
      final assignmentsBox = await _getAssignmentsBox();
      final attachmentsBox = await _getAttachmentsBox();
      final submissionFilesBox = await _getSubmissionFilesBox();

      await resourcesBox.clear();
      await chaptersBox.clear();
      await quizzesBox.clear();
      await assignmentsBox.clear();
      await attachmentsBox.clear();
      await submissionFilesBox.clear();

      print('Tous les téléchargements ont été supprimés');
    } catch (e) {
      print('Erreur lors de la suppression des téléchargements: $e');
      rethrow;
    }
  }

  Future<Box> _getAssignmentsBox() async {
    final boxName = 'assignments_${_currentUserId ?? 'default'}';
    return await Hive.openBox(boxName);
  }

  Future<void> markAssignmentAsDownloaded(
      String assignmentId, Map<String, dynamic> data) async {
    final box = await _getAssignmentsBox();

    // S'assurer que les titres de module et chapitre sont inclus
    final enrichedData = {
      ...data,
      'type': 'assignment',
      'downloadedAt': DateTime.now().toIso8601String(),
    };

    await box.put(assignmentId, enrichedData);
  }

  Future<bool> isAssignmentDownloaded(String assignmentId) async {
    final box = await _getAssignmentsBox();
    return box.containsKey(assignmentId);
  }

  Future<Map<String, dynamic>?> getAssignmentInfo(String assignmentId) async {
    final box = await _getAssignmentsBox();
    final data = box.get(assignmentId);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> deleteAssignment(String assignmentId) async {
    final box = await _getAssignmentsBox();
    await box.delete(assignmentId);
  }

  // Méthodes pour les pièces jointes
  Future<Box> _getAttachmentsBox() async {
    final boxName = 'attachments_${_currentUserId ?? 'default'}';
    return await Hive.openBox(boxName);
  }

  Future<void> saveAttachment(dynamic attachment, String moduleId,
      String? chapterId, String assignmentId,
      {String? localPath}) async {
    try {
      final box = await _getAttachmentsBox();
      final attachmentId = attachment.id ?? attachment.filename;

      // Utiliser le chemin fourni ou générer un chemin par défaut
      final filePath = localPath ??
          'attachments/$moduleId/$assignmentId/${attachment.filename}';

      await box.put(attachmentId, {
        'id': attachmentId,
        'filename': attachment.filename,
        'fileSize': attachment.fileSize,
        'url': attachment.url ?? '',
        'localPath': filePath,
        'moduleId': moduleId,
        'chapterId': chapterId,
        'assignmentId': assignmentId,
        'type': 'attachment',
        'downloadedAt': DateTime.now().toIso8601String(),
      });

      print(
          'Pièce jointe sauvegardée: $attachmentId avec chemin local: $filePath');
    } catch (e) {
      print('Erreur lors de la sauvegarde de la pièce jointe: $e');
      rethrow;
    }
  }

  Future<bool> isAttachmentDownloaded(String attachmentId) async {
    final box = await _getAttachmentsBox();
    return box.containsKey(attachmentId);
  }

  Future<Map<String, dynamic>?> getAttachmentInfo(String attachmentId) async {
    final box = await _getAttachmentsBox();
    final data = box.get(attachmentId);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> deleteAttachment(String attachmentId) async {
    final box = await _getAttachmentsBox();
    await box.delete(attachmentId);
  }

  // Méthodes pour les fichiers soumis
  Future<Box> _getSubmissionFilesBox() async {
    final boxName = 'submission_files_${_currentUserId ?? 'default'}';
    return await Hive.openBox(boxName);
  }

  Future<void> saveSubmissionFile(
      String filePath, String assignmentId, String submissionId,
      {String? localPath}) async {
    try {
      final box = await _getSubmissionFilesBox();
      final fileId = '$submissionId-${filePath.split('/').last}';

      // Utiliser le chemin fourni ou le chemin original
      final storedPath = localPath ?? filePath;

      print('💾 Sauvegarde fichier soumis:');
      print('   - filePath: $filePath');
      print('   - assignmentId: $assignmentId');
      print('   - submissionId: $submissionId');
      print('   - fileId généré: $fileId');
      print('   - localPath: $storedPath');

      await box.put(fileId, {
        'id': fileId,
        'originalPath': filePath,
        'localPath': storedPath,
        'filename': filePath.split('/').last,
        'assignmentId': assignmentId,
        'submissionId': submissionId,
        'type': 'submission_file',
        'downloadedAt': DateTime.now().toIso8601String(),
      });

      print(
          '✅ Fichier soumis sauvegardé avec succès: $fileId avec chemin: $storedPath');
      print('📦 Clés actuelles dans la boîte: ${box.keys.toList()}');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde du fichier soumis: $e');
      rethrow;
    }
  }

  Future<bool> isSubmissionFileDownloaded(
      String filePath, String submissionId) async {
    final box = await _getSubmissionFilesBox();
    final fileId = '$submissionId-${filePath.split('/').last}';
    return box.containsKey(fileId);
  }

  Future<Map<String, dynamic>?> getSubmissionFileInfo(
      String filePath, String submissionId) async {
    final box = await _getSubmissionFilesBox();
    final fileId = '$submissionId-${filePath.split('/').last}';
    print("🔍 Recherche dans Hive avec ID: '$fileId'");
    print("📦 Contenu de la boîte submission_files: ${box.keys.toList()}");

    final data = box.get(fileId);
    print("📂 Données trouvées pour '$fileId': $data");

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> deleteSubmissionFile(
      String filePath, String submissionId) async {
    final box = await _getSubmissionFilesBox();
    final fileId = '$submissionId-${filePath.split('/').last}';
    await box.delete(fileId);
  }
}
