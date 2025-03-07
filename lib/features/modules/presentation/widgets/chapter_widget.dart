import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/chapter.dart';
import '../../models/activity.dart';
import 'activity_list_item.dart';

class ChapterAccordion extends StatefulWidget {
  final Chapter chapter;
  final List<Activity> activities;
  final bool isExpanded;
  final bool isLoading;
  final ValueChanged<bool> onExpandChanged;

  const ChapterAccordion({
    super.key,
    required this.chapter,
    required this.activities,
    required this.isExpanded,
    required this.isLoading,
    required this.onExpandChanged,
  });

  @override
  State<ChapterAccordion> createState() => _ChapterAccordionState();
}

class _ChapterAccordionState extends State<ChapterAccordion> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // En-tête du chapitre (toujours visible)
          _buildChapterHeader(),

          // Contenu du chapitre (visible si développé)
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: _buildChapterContent(),
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterHeader() {
    return InkWell(
      onTap: () => widget.onExpandChanged(!widget.isExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chapter.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (widget.chapter.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.chapter.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (widget.isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                widget.isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          // Contenu HTML du chapitre
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
            ),

          if (widget.activities.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Activités',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            _buildActivitiesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildActivitiesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.activities.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ActivityListItem(
          activity: widget.activities[index],
          chapterId: widget.chapter.id,
        );
      },
    );
  }
}
