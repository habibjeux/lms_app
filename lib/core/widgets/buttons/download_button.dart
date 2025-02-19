import 'package:flutter/material.dart';

import '../../services/sync_service.dart';

class DownloadButton extends StatefulWidget {
  final String moduleId;
  final VoidCallback? onComplete;

  const DownloadButton({
    super.key,
    required this.moduleId,
    this.onComplete,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  final _syncService = SyncService();
  double _progress = 0;
  bool _isDownloading = false;

  Future<void> _startDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      await _syncService.smartSync(
        moduleId: widget.moduleId,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );
      widget.onComplete?.call();
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 8),
          Text('${(_progress * 100).toInt()}%'),
        ],
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: _startDownload,
      tooltip: 'Télécharger pour un accès hors ligne',
    );
  }
}
