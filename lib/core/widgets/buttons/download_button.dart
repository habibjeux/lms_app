import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/downloads/providers/download_provider.dart';

class DownloadButton extends StatelessWidget {
  final String moduleId;
  final VoidCallback? onComplete;

  const DownloadButton({
    super.key,
    required this.moduleId,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        final isDownloading = downloadProvider.isDownloading(moduleId);
        final progress = downloadProvider.getProgress(moduleId);

        if (isDownloading) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Text('${(progress * 100).toInt()}%'),
            ],
          );
        }

        return IconButton(
          icon: const Icon(Icons.download),
          onPressed: () =>
              downloadProvider.startDownload(moduleId, onComplete: onComplete),
          tooltip: 'Télécharger pour un accès hors ligne',
        );
      },
    );
  }
}
