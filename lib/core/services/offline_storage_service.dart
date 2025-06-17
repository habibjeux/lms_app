import 'package:hive/hive.dart';
import 'dart:convert';

class OfflineStorageService {
  static const String moduleBoxName = 'modules';
  static const String chapterBoxName = 'chapters';
  static const String activitiesBoxName = 'activities';
  static const String lastSyncBoxName = 'lastSync';
  static const String _quizzesBox = 'quizzes';
  static const String _assignmentsBox = 'assignments';

  Future<Box> _openBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<void> saveModules(List<dynamic> modules) async {
    final box = await _openBox(moduleBoxName);
    await box.put('all_modules', json.encode(modules));
    await _updateLastSync('modules');
  }

  Future<void> saveModuleActivities(
      String moduleId, List<dynamic> activities) async {
    final box = await _openBox(activitiesBoxName);
    await box.put(moduleId, json.encode(activities));
    await _updateLastSync('module_activities_$moduleId');
  }

  Future<List<dynamic>?> getModules() async {
    final box = await _openBox(moduleBoxName);
    final data = box.get('all_modules');
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  Future<void> saveChapters(String moduleId, List<dynamic> chapters) async {
    final box = await _openBox(chapterBoxName);
    await box.put(moduleId, json.encode(chapters));
    await _updateLastSync('chapters_$moduleId');
  }

  Future<List<dynamic>?> getChapters(String moduleId) async {
    final box = await _openBox(chapterBoxName);
    final data = box.get(moduleId);
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  Future<void> saveActivities(
      String chapterId, List<dynamic> activities) async {
    final box = await _openBox(activitiesBoxName);
    await box.put(chapterId, json.encode(activities));
    await _updateLastSync('activities_$chapterId');
  }

  Future<List<dynamic>?> getModuleActivities(String moduleId) async {
    final box = await _openBox(activitiesBoxName);
    final data = box.get(moduleId);
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  Future<List<dynamic>?> getChapterActivities(String chapterId) async {
    final box = await _openBox(activitiesBoxName);
    final data = box.get(chapterId);
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  Future<void> _updateLastSync(String key) async {
    final box = await _openBox(lastSyncBoxName);
    await box.put(key, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastSync(String key) async {
    final box = await _openBox(lastSyncBoxName);
    final dateStr = box.get(key);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  Future<bool> isDataStale(String key,
      {Duration threshold = const Duration(hours: 1)}) async {
    final lastSync = await getLastSync(key);
    if (lastSync == null) return true;

    final now = DateTime.now();
    return now.difference(lastSync) > threshold;
  }

  Future<int> getStorageSize() async {
    int totalSize = 0;
    final boxes = [
      moduleBoxName,
      chapterBoxName,
      activitiesBoxName,
      lastSyncBoxName
    ];

    for (var boxName in boxes) {
      final box = await _openBox(boxName);
      for (var key in box.keys) {
        final value = box.get(key);
        if (value is String) {
          totalSize += value.length;
        }
      }
    }

    return totalSize;
  }

  Future<void> clearOldData(Duration threshold) async {
    final now = DateTime.now();
    final boxes = [moduleBoxName, chapterBoxName, activitiesBoxName];

    for (var boxName in boxes) {
      final box = await _openBox(boxName);
      final lastSyncBox = await _openBox(lastSyncBoxName);

      for (var key in lastSyncBox.keys) {
        final lastSyncStr = lastSyncBox.get(key);
        if (lastSyncStr != null) {
          final lastSync = DateTime.parse(lastSyncStr);
          if (now.difference(lastSync) > threshold) {
            // Supprimer les données correspondantes
            if (boxName == activitiesBoxName) {
              // Pour les activités, nous devons supprimer par chapitre
              final chapterId = key.replaceAll('activities_', '');
              await box.delete(chapterId);
            } else {
              await box.delete(key.replaceAll('lastSync_', ''));
            }
            await lastSyncBox.delete(key);
          }
        }
      }
    }
  }

  Future<void> deleteAllData() async {
    final boxes = [
      moduleBoxName,
      chapterBoxName,
      activitiesBoxName,
      lastSyncBoxName
    ];
    for (var boxName in boxes) {
      final box = await _openBox(boxName);
      await box.clear();
    }
  }

  Future<void> saveLastSync(String key, DateTime dateTime) async {
    await _updateLastSync(key);
  }

  Future<void> saveQuiz(String quizId, Map<String, dynamic> quizData) async {
    final box = await Hive.openBox(_quizzesBox);
    await box.put(quizId, quizData);
  }

  Future<Map<String, dynamic>?> getQuiz(String quizId) async {
    final box = await Hive.openBox(_quizzesBox);
    final data = box.get(quizId);
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> saveAssignment(
      String assignmentId, Map<String, dynamic> assignmentData) async {
    final box = await Hive.openBox(_assignmentsBox);
    await box.put(assignmentId, assignmentData);
  }

  Future<Map<String, dynamic>?> getAssignment(String assignmentId) async {
    final box = await Hive.openBox(_assignmentsBox);
    final data = box.get(assignmentId);
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> saveChapterContent(String chapterId, String content) async {
    try {
      final box = await Hive.openBox<String>('chapter_contents');
      await box.put(chapterId, content);
      print('Contenu du chapitre sauvegardé: $chapterId');
    } catch (e) {
      print('Erreur lors de la sauvegarde du contenu du chapitre: $e');
      rethrow;
    }
  }

  Future<String?> getChapterContent(String chapterId) async {
    try {
      final box = await Hive.openBox<String>('chapter_contents');
      return box.get(chapterId);
    } catch (e) {
      print('Erreur lors de la récupération du contenu du chapitre: $e');
      return null;
    }
  }
}
