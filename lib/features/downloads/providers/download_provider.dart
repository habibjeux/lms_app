import 'package:flutter/material.dart';

import '../../../core/services/sync_service.dart';

class DownloadProvider with ChangeNotifier {
  final SyncService _syncService = SyncService();

  final Map<String, double> _progressMap = {};
  final Map<String, bool> _downloadingMap = {};

  double getProgress(String moduleId) => _progressMap[moduleId] ?? 0.0;
  bool isDownloading(String moduleId) => _downloadingMap[moduleId] ?? false;

  Future<void> startDownload(String moduleId,
      {VoidCallback? onComplete}) async {
    if (_downloadingMap[moduleId] == true) return;

    _downloadingMap[moduleId] = true;
    _progressMap[moduleId] = 0.0;
    notifyListeners();

    try {
      await _syncService.smartSync(
        moduleId: moduleId,
        onProgress: (progress) {
          _progressMap[moduleId] = progress;
          notifyListeners();
        },
      );

      if (onComplete != null) {
        onComplete();
      }
    } finally {
      _downloadingMap[moduleId] = false;
      notifyListeners();
    }
  }
}
