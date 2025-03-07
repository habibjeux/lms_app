import 'package:flutter/material.dart';
import '../../models/enums/activity_type.dart';
import '../../models/module.dart';
import '../../models/activity.dart';
import '../screens/activity_detail_screen.dart';

class ModuleList extends StatelessWidget {
  final List<Module> modules;

  const ModuleList({super.key, required this.modules});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return ModuleCard(module: module);
      },
    );
  }
}

class ModuleCard extends StatefulWidget {
  final Module module;

  const ModuleCard({super.key, required this.module});

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.module.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${widget.module.credits} crédits'),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: Theme.of(context).primaryColor,
              ),
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded && widget.module.chapters.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.module.chapters.length,
              itemBuilder: (context, index) {
                final chapter = widget.module.chapters[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(chapter.title),
                      subtitle: Text('Chapitre ${index + 1}'),
                      leading: const Icon(Icons.article),
                    ),
                    if (chapter.activities.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: chapter.activities.length,
                          itemBuilder: (context, activityIndex) {
                            return ActivityItem(
                              activity: chapter.activities[activityIndex],
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  final Activity activity;

  const ActivityItem({super.key, required this.activity});

  IconData _getIconForType() {
    switch (activity.type) {
      case ActivityType.QUIZ:
        return Icons.quiz;
      case ActivityType.ASSIGNMENT:
        return Icons.assignment;
      case ActivityType.CONTENT:
        return Icons.subject;
      case ActivityType.RESOURCE:
        return Icons.article;
      case ActivityType.FORUM:
        return Icons.forum;
    }
  }

  Color _getColorForType(BuildContext context) {
    switch (activity.type) {
      case ActivityType.QUIZ:
        return Colors.orange;
      case ActivityType.ASSIGNMENT:
        return Colors.green;
      case ActivityType.CONTENT:
        return Colors.purple;
      case ActivityType.RESOURCE:
        return Colors.blue;
      case ActivityType.FORUM:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _getIconForType(),
        color: _getColorForType(context),
      ),
      title: Text(activity.title),
      subtitle: activity.startDate != null
          ? Text('Jusqu\'au ${_formatDate(activity.endDate)}')
          : null,
      trailing: activity.visible
          ? const Icon(Icons.chevron_right, size: 20)
          : const Icon(Icons.lock, size: 20),
      onTap: activity.visible
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityDetailScreen(
                    activity: activity,
                  ),
                ),
              );
            }
          : null,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
