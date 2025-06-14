import 'package:hive/hive.dart';

class DownloadStorageService {
  static const String downloadedChaptersBox = 'downloaded_chapters';
  static const String downloadedResourcesBox = 'downloaded_resources';
  static const String downloadedQuizzesBox = 'downloaded_quizzes';

  Box<dynamic>? _resourcesBox;
  Box<dynamic>? _chaptersBox;
  Box<dynamic>? _quizzesBox;

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
      {String? moduleId, String? title}) async {
    try {
      print('Marquage du chapitre comme téléchargé: $chapterId');
      final box = await _getChaptersBox();
      await box.put(chapterId, {
        'moduleId': moduleId,
        'title': title,
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
      {String? moduleId, String? chapterId, String? title}) async {
    try {
      print('Marquage de la ressource comme téléchargée: $resourceId');
      final box = await _getResourcesBox();
      await box.put(resourceId, {
        'moduleId': moduleId,
        'chapterId': chapterId,
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
      {String? moduleId, String? chapterId, String? title}) async {
    try {
      print('Marquage du quiz comme téléchargé: $quizId');
      final box = await _getQuizzesBox();
      await box.put(quizId, {
        'moduleId': moduleId,
        'chapterId': chapterId,
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
              'title': title,
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

  Future<Map<String, Map<String, dynamic>>> getDownloadedItems() async {
    try {
      print('Récupération des éléments téléchargés');
      final resourcesBox = await _getResourcesBox();
      final chaptersBox = await _getChaptersBox();
      final quizzesBox = await _getQuizzesBox();

      print('Contenu des boîtes:');
      print('Ressources: ${resourcesBox.toMap()}');
      print('Chapitres: ${chaptersBox.toMap()}');
      print('Quiz: ${quizzesBox.toMap()}');

      final items = <String, Map<String, dynamic>>{};

      // D'abord, ajouter les chapitres
      for (var key in chaptersBox.keys) {
        final data = chaptersBox.get(key);
        if (data != null) {
          final Map<String, dynamic> chapterData = {
            'type': 'chapter',
            'downloadedAt': DateTime.now().toIso8601String(),
            'activities': <Map<String, dynamic>>[],
          };

          if (data is Map) {
            for (var entry in data.entries) {
              if (entry.key != 'activities') {
                chapterData[entry.key.toString()] = entry.value;
              }
            }
          }

          items[key.toString()] = chapterData;
        }
      }

      // Ensuite, ajouter les ressources
      for (var key in resourcesBox.keys) {
        final data = resourcesBox.get(key);
        if (data != null) {
          final Map<String, dynamic> resourceData = {
            'type': 'resource',
            'id': key.toString(),
            'downloadedAt': DateTime.now().toIso8601String(),
          };

          if (data is Map) {
            for (var entry in data.entries) {
              resourceData[entry.key.toString()] = entry.value;
            }
          }

          final chapterId = resourceData['chapterId']?.toString();
          if (chapterId != null && items.containsKey(chapterId)) {
            final activities = List<Map<String, dynamic>>.from(
                items[chapterId]!['activities'] ?? []);
            activities.add(resourceData);
            items[chapterId]!['activities'] = activities;
          }
        }
      }

      // Enfin, ajouter les quiz
      for (var key in quizzesBox.keys) {
        final data = quizzesBox.get(key);
        if (data != null) {
          final Map<String, dynamic> quizData = {
            'type': 'quiz',
            'id': key.toString(),
            'downloadedAt': DateTime.now().toIso8601String(),
          };

          if (data is Map) {
            for (var entry in data.entries) {
              quizData[entry.key.toString()] = entry.value;
            }
          }

          final chapterId = quizData['chapterId']?.toString();
          if (chapterId != null && items.containsKey(chapterId)) {
            final activities = List<Map<String, dynamic>>.from(
                items[chapterId]!['activities'] ?? []);
            activities.add(quizData);
            items[chapterId]!['activities'] = activities;
          }
        }
      }

      print('Éléments téléchargés récupérés: ${items.length} éléments');
      return items;
    } catch (e) {
      print('Erreur lors de la récupération des éléments téléchargés: $e');
      rethrow;
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

      await resourcesBox.clear();
      await chaptersBox.clear();
      await quizzesBox.clear();

      print('Tous les téléchargements ont été supprimés');
    } catch (e) {
      print('Erreur lors de la suppression des téléchargements: $e');
      rethrow;
    }
  }
}
