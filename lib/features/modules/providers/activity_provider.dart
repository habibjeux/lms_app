import 'package:flutter/material.dart';
import '../../../core/services/sync_service.dart';
import '../models/activity.dart';
import '../models/resource.dart';
import '../models/assignment.dart';

class ActivityProvider with ChangeNotifier {
  final SyncService _syncService = SyncService();

  final Map<String, bool> _downloadStatus = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};

  bool isDownloaded(String activityId) => _downloadStatus[activityId] ?? false;
  bool isDownloading(String activityId) => _isDownloading[activityId] ?? false;
  double downloadProgress(String activityId) =>
      _downloadProgress[activityId] ?? 0.0;

  Future<void> checkResourceDownloadStatus(String activityId) async {
    try {
      final isDownloaded = await _syncService.isResourceDownloaded(activityId);
      _downloadStatus[activityId] = isDownloaded;
      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  Future<void> checkQuizDownloadStatus(String activityId) async {
    try {
      final isDownloaded = await _syncService.isQuizDownloaded(activityId);
      _downloadStatus[activityId] = isDownloaded;
      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  Future<void> checkAssignmentDownloadStatus(String activityId) async {
    try {
      final isDownloaded =
          await _syncService.isAssignmentDownloaded(activityId);
      _downloadStatus[activityId] = isDownloaded;
      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  void updateQuizDownloadStatus(String activityId, bool isDownloaded) {
    _downloadStatus[activityId] = isDownloaded;
    notifyListeners();
  }

  void updateResourceDownloadStatus(String activityId, bool isDownloaded) {
    _downloadStatus[activityId] = isDownloaded;
    notifyListeners();
  }

  void updateAssignmentDownloadStatus(String activityId, bool isDownloaded) {
    _downloadStatus[activityId] = isDownloaded;
    notifyListeners();
  }

  // Forcer la vérification du statut de téléchargement d'un quiz
  Future<void> refreshQuizDownloadStatus(String activityId) async {
    try {
      final isDownloaded = await _syncService.isQuizDownloaded(activityId);
      _downloadStatus[activityId] = isDownloaded;
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la vérification du statut du quiz $activityId: $e');
    }
  }

  // Rafraîchir le statut de tous les quiz
  Future<void> refreshAllQuizStatuses(List<String> quizIds) async {
    for (String quizId in quizIds) {
      await refreshQuizDownloadStatus(quizId);
    }
  }

  Future<void> downloadResource(Resource resource) async {
    _isDownloading[resource.id] = true;
    _downloadProgress[resource.id] = 0.0;
    notifyListeners();

    try {
      await _syncService.downloadResource(
        resource,
        individualProgress: (progress) {
          _downloadProgress[resource.id] = progress;
          notifyListeners();
        },
      );

      _downloadStatus[resource.id] = true;
      _isDownloading[resource.id] = false;
      notifyListeners();
    } catch (e) {
      _isDownloading[resource.id] = false;
      notifyListeners();
      throw Exception('Erreur lors du téléchargement: $e');
    }
  }

  void startQuizDownload(String quizId) {
    _isDownloading[quizId] = true;
    notifyListeners();
  }

  void completeQuizDownload(String quizId, bool success) {
    _isDownloading[quizId] = false;
    if (success) {
      _downloadStatus[quizId] = true;
    }
    notifyListeners();
  }

  void startAssignmentDownload(String assignmentId) {
    _isDownloading[assignmentId] = true;
    notifyListeners();
  }

  void completeAssignmentDownload(String assignmentId, bool success) {
    _isDownloading[assignmentId] = false;
    if (success) {
      _downloadStatus[assignmentId] = true;
    }
    notifyListeners();
  }

  Future<void> downloadAssignment(Assignment assignment) async {
    _isDownloading[assignment.id] = true;
    _downloadProgress[assignment.id] = 0.0;
    notifyListeners();

    try {
      await _syncService.downloadAssignment(
        assignment.id,
        moduleId: assignment.moduleId,
        chapterId: assignment.chapterId,
        title: assignment.title,
        onProgress: (progress) {
          _downloadProgress[assignment.id] = progress;
          notifyListeners();
        },
      );

      _downloadStatus[assignment.id] = true;
      _isDownloading[assignment.id] = false;
      notifyListeners();
    } catch (e) {
      _isDownloading[assignment.id] = false;
      notifyListeners();
      throw Exception('Erreur lors du téléchargement: $e');
    }
  }

  bool shouldDisplayActivity(
      Activity activity, String? chapterId, String? moduleId) {
    if (activity.chapterId == chapterId) {
      return true;
    }

    if (activity.chapterId == null &&
        moduleId != null &&
        activity.moduleId == moduleId) {
      return true;
    }

    return false;
  }
}
