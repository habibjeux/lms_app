import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/chapter.dart';
import '../../models/activity.dart';
import 'activity_list_item.dart';

class ChapterWidget extends StatelessWidget {
  final Chapter chapter;
  final List<Activity> activities;
  final bool isExpanded;
  final Function(bool) onExpandChanged;

  const ChapterWidget({
    super.key,
    required this.chapter,
    required this.activities,
    required this.isExpanded,
    required this.onExpandChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(chapter.title),
            subtitle: Text(chapter.description),
            leading: const Icon(Icons.book),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => onExpandChanged(!isExpanded),
            ),
          ),
          if (isExpanded) ...[
            if (chapter.content != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Html(
                  data: chapter.content!,
                  style: {
                    "body": Style(
                      fontSize: FontSize(16),
                      lineHeight: LineHeight(1.5),
                    ),
                  },
                ),
              ),
            if (activities.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return ActivityListItem(
                    activity: activities[index],
                    chapterId: chapter.id,
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
