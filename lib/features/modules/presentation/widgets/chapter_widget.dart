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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isExpanded ? Radius.zero : Radius.circular(16),
                  bottomRight: isExpanded ? Radius.zero : Radius.circular(16),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  chapter.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: chapter.description.isNotEmpty
                    ? Text(
                        chapter.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (activities.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${activities.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                onTap: () => onExpandChanged(!isExpanded),
              ),
            ),
            if (isExpanded) ...[
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (chapter.content != null &&
                        chapter.content!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Contenu du chapitre',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Html(
                              data: chapter.content!,
                              style: {
                                "body": Style(
                                  fontSize: FontSize(16),
                                  lineHeight: LineHeight(1.5),
                                  margin: Margins.zero,
                                ),
                                "p": Style(
                                  margin: Margins.only(bottom: 8),
                                ),
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (activities.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.assignment,
                              color: Colors.teal,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Activités (${activities.length})',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activities.length,
                          separatorBuilder: (context, index) => Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.grey[200],
                          ),
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: index == 0
                                    ? const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      )
                                    : index == activities.length - 1
                                        ? const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          )
                                        : BorderRadius.zero,
                              ),
                              child: ActivityListItem(
                                activity: activities[index],
                                chapterId: chapter.id,
                              ),
                            );
                          },
                        ),
                      ),
                    ] else if (isExpanded) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aucune activité disponible',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ce chapitre ne contient pas d\'activités pour le moment',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
