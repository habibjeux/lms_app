import 'package:flutter/material.dart';
import '../../../../core/services/sync_service.dart';
import '../../models/activity.dart';
import '../../models/enums/activity_type.dart';
import '../../models/enums/resource_type.dart';
import '../../models/resource.dart';
import '../screens/activity_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityListItem extends StatefulWidget {
  final Activity activity;
  final bool isOffline;
  final String chapterId;

  const ActivityListItem({
    super.key,
    required this.activity,
    required this.isOffline,
    required this.chapterId,
  });

  @override
  State<ActivityListItem> createState() => _ActivityListItemState();
}

class _ActivityListItemState extends State<ActivityListItem> {
  final SyncService _syncService = SyncService();
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    if (widget.activity is Resource) {
      final resource = widget.activity as Resource;
      final isDownloaded = await _syncService.isResourceDownloaded(resource.id);
      if (mounted) {
        setState(() {
          _isDownloaded = isDownloaded;
        });
      }
    }
  }

  // Dans _ActivityListItemState
  Future<void> _handleResourceDownload() async {
    if (_isDownloading) return;
    if (widget.activity is! Resource) return;

    final resource = widget.activity as Resource;
    if (!resource.downloadable) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      await _syncService.downloadResource(
        resource,
        individualProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ressource téléchargée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')),
        );
      }
    }
  }

  String _getFormattedDate(DateTime? date) {
    if (date == null) return '';
    return timeago.format(date, locale: 'fr');
  }

  IconData _getIconForActivity() {
    if (widget.activity is Resource) {
      final resource = widget.activity as Resource;
      switch (resource.resourceType) {
        case ResourceType.PDF:
          return Icons.picture_as_pdf;
        case ResourceType.VIDEO:
          return Icons.play_circle_outline;
        case ResourceType.IMAGE:
          return Icons.image;
        case ResourceType.LINK:
          return Icons.link;
        case ResourceType.FILE:
          return Icons.insert_drive_file;
      }
    }

    switch (widget.activity.type) {
      case ActivityType.QUIZ:
        return Icons.quiz;
      case ActivityType.ASSIGNMENT:
        return Icons.assignment;
      case ActivityType.CONTENT:
        return Icons.article;
      default:
        return Icons.info;
    }
  }

  Color _getColorForActivity(BuildContext context) {
    if (widget.activity is Resource) {
      final resource = widget.activity as Resource;
      switch (resource.resourceType) {
        case ResourceType.PDF:
          return Colors.red;
        case ResourceType.VIDEO:
          return Colors.blue;
        case ResourceType.IMAGE:
          return Colors.green;
        case ResourceType.LINK:
          return Colors.purple;
        case ResourceType.FILE:
          return Colors.grey;
      }
    }

    switch (widget.activity.type) {
      case ActivityType.QUIZ:
        return Colors.orange;
      case ActivityType.ASSIGNMENT:
        return Colors.teal;
      case ActivityType.CONTENT:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDownloadStatus() {
    if (widget.activity is! Resource) return const SizedBox.shrink();

    final resource = widget.activity as Resource;
    if (!resource.downloadable) return const SizedBox.shrink();

    if (_isDownloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: _downloadProgress,
            ),
          ),
          const SizedBox(width: 4),
          Text('${(_downloadProgress * 100).toInt()}%'),
        ],
      );
    }

    if (widget.isOffline) {
      if (_isDownloaded) {
        return const Icon(Icons.offline_pin, color: Colors.green);
      }
      return const Icon(Icons.offline_bolt, color: Colors.orange);
    }

    if (_isDownloaded) {
      return const Icon(Icons.cloud_done, color: Colors.green);
    }

    return IconButton(
      icon: const Icon(Icons.cloud_download),
      onPressed: _handleResourceDownload,
      iconSize: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activity.chapterId != widget.chapterId) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: Icon(
        _getIconForActivity(),
        color: _getColorForActivity(context),
      ),
      title: Text(widget.activity.title),
      subtitle:
          widget.activity.startDate != null || widget.activity.endDate != null
              ? Text(
                  widget.activity.endDate != null
                      ? 'Se termine ${_getFormattedDate(widget.activity.endDate!)}'
                      : 'Commence ${_getFormattedDate(widget.activity.startDate!)}',
                )
              : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDownloadStatus(),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: () async {
        if (widget.isOffline && widget.activity is Resource) {
          if (!_isDownloaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Cette ressource n\'est pas disponible hors ligne')),
            );
            return;
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(
              activity: widget.activity,
              isOffline: widget.isOffline,
            ),
          ),
        );
      },
    );
  }
}
