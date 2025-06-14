import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../models/chapter.dart';

class ChapterListItem extends StatefulWidget {
  final Chapter chapter;
  final String moduleId;
  final VoidCallback? onDownloadPressed;

  const ChapterListItem({
    super.key,
    required this.chapter,
    required this.moduleId,
    this.onDownloadPressed,
  });

  @override
  State<ChapterListItem> createState() => _ChapterListItemState();
}

class _ChapterListItemState extends State<ChapterListItem> {
  final SyncService _syncService = SyncService();
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final isDownloaded =
        await _syncService.isChapterDownloaded(widget.chapter.id);
    if (mounted) {
      setState(() => _isDownloaded = isDownloaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark),
            title: Text(widget.chapter.title),
            subtitle: Text(widget.chapter.description ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!connectivityProvider.isOnline && !_isDownloaded)
                  const Icon(
                    Icons.offline_bolt,
                    color: Colors.orange,
                    size: 20,
                  )
                else if (_isDownloaded)
                  const Icon(
                    Icons.cloud_done,
                    color: Colors.green,
                    size: 20,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.cloud_download, size: 20),
                    tooltip: 'Télécharger le chapitre',
                    onPressed: widget.onDownloadPressed,
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
            onTap: () {
              // Navigation vers le détail du chapitre
            },
          ),
        );
      },
    );
  }
}
