import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/services/sync_service.dart';
import '../../models/activity.dart';
import '../../models/chapter.dart';
import 'activity_list_item.dart';

class ChapterWidget extends StatefulWidget {
  final Chapter chapter;
  final bool isOffline;

  const ChapterWidget({
    super.key,
    required this.chapter,
    required this.isOffline,
  });

  @override
  State<ChapterWidget> createState() => _ChapterWidgetState();
}

class _ChapterWidgetState extends State<ChapterWidget> {
  final SyncService _syncService = SyncService();
  List<Activity> _activities = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  double _downloadProgress = 0;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final isDownloaded =
        await _syncService.isChapterDownloaded(widget.chapter.id);
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }
  }

  Future<void> _loadActivities() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final activitiesData =
          await _syncService.getChapterActivities(widget.chapter.id);
      final activities = activitiesData
          .map((data) => Activity.fromJson(data))
          .where((activity) => activity.visible && activity.active)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      if (mounted) {
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadChapter() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _syncService.downloadChapter(
        widget.chapter.id,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
        onComplete: () {
          setState(() {
            _isDownloaded = true;
          });
        },
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chapter.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (widget.chapter.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.chapter.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (!widget.isOffline)
                IconButton(
                  icon: Icon(
                      _isDownloaded ? Icons.cloud_done : Icons.cloud_download),
                  onPressed: _isSyncing ? null : _downloadChapter,
                  tooltip: _isDownloaded ? 'Téléchargé' : 'Télécharger',
                ),
            ],
          ),
        ),
        if (_isSyncing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 4),
                Text('${(_downloadProgress * 100).toInt()}%'),
              ],
            ),
          ),
        const Divider(),
        // Contenu du chapitre
        if (widget.chapter.content != null)
          HtmlWidget(
            widget.chapter.content!,
            onErrorBuilder: (context, element, error) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Erreur de chargement : ${error.toString()}',
                  style: TextStyle(color: Colors.red[800]),
                ),
              );
            },
            customWidgetBuilder: (element) {
              if (element.localName == 'iframe') {
                final src = element.attributes['src'];
                if (src != null) {
                  final videoId = YoutubePlayer.convertUrlToId(src);

                  if (videoId != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: YoutubePlayer(
                        controller: YoutubePlayerController(
                          initialVideoId: videoId,
                          flags: YoutubePlayerFlags(
                            autoPlay: false,
                            mute: false,
                            showLiveFullscreenButton: true,
                          ),
                        ),
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.blueAccent,
                      ),
                    );
                  }
                }
              }
              return null;
            },
          )
        else
          const Center(
            child: Text('Pas de contenu'),
          ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_activities.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Aucune activité disponible'),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activités',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activities.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    return ActivityListItem(
                      activity: activity,
                      isOffline: widget.isOffline,
                      chapterId: widget.chapter.id,
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
