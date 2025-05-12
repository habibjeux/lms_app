import 'package:flutter/material.dart';
import '../../../core/services/sync_service.dart';
import '../models/activity.dart';
import '../models/resource.dart';

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

  void updateQuizDownloadStatus(String activityId, bool isDownloaded) {
    _downloadStatus[activityId] = isDownloaded;
    notifyListeners();
  }

  Future<void> downloadResource(Resource resource) async {
    if (!resource.downloadable || _isDownloading[resource.id] == true) return;

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
