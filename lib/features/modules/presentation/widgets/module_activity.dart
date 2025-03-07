import 'package:flutter/material.dart';
import '../../models/activity.dart';
import '../widgets/activity_list_item.dart';

class ModuleActivitiesSection extends StatelessWidget {
  final List<Activity> activities;
  final String moduleId;
  final bool isLoading;

  const ModuleActivitiesSection({
    super.key,
    required this.activities,
    required this.moduleId,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Activités complémentaires',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ActivityListItem(
                activity: activities[index],
                chapterId: '',
                moduleId: moduleId,
              );
            },
          ),
        ],
      ),
    );
  }
}
