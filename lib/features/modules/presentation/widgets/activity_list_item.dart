import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../quizzes/data/providers/quiz_provider.dart';
import '../../models/activity.dart';
import '../../models/enums/activity_type.dart';
import '../../models/enums/resource_type.dart';
import '../../models/resource.dart';
import '../../providers/activity_provider.dart';
import '../../../quizzes/presentation/screens/quiz_detail_screen.dart';
import '../screens/activity_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityListItem extends StatelessWidget {
  final Activity activity;
  final String? chapterId;
  final String? moduleId;

  const ActivityListItem({
    super.key,
    required this.activity,
    this.chapterId,
    this.moduleId,
  });

  @override
  Widget build(BuildContext context) {
    final activityProvider =
        Provider.of<ActivityProvider>(context, listen: false);

    if (activity is Resource) {
      Future.microtask(
          () => activityProvider.checkResourceDownloadStatus(activity.id));
    } else if (activity.type == ActivityType.QUIZ) {
      _checkQuizDownloadStatus(context, activityProvider);
    }

    return Consumer2<ActivityProvider, ConnectivityProvider>(
      builder: (context, activityProvider, connectivityProvider, _) {
        if (!activityProvider.shouldDisplayActivity(
            activity, chapterId, moduleId)) {
          return const SizedBox.shrink();
        }

        return ListTile(
          leading: _buildActivityIcon(),
          title: Text(activity.title),
          subtitle: activity.startDate != null || activity.endDate != null
              ? Text(
                  activity.endDate != null
                      ? 'Se termine ${_getFormattedDate(activity.endDate)}'
                      : 'Commence ${_getFormattedDate(activity.startDate)}',
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDownloadStatus(
                  context, activityProvider, connectivityProvider),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
          onTap: () => _handleActivityTap(
              context, activityProvider, connectivityProvider),
        );
      },
    );
  }

  Future<void> _checkQuizDownloadStatus(
      BuildContext context, ActivityProvider provider) async {
    if (activity.type == ActivityType.QUIZ) {
      try {
        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
        final isDownloaded = await quizProvider.isQuizDownloaded(activity.id);
        provider.updateQuizDownloadStatus(activity.id, isDownloaded);
      } catch (e) {
        // Ignorer l'erreur si la méthode n'existe pas
      }
    }
  }

  Widget _buildDownloadStatus(BuildContext context, ActivityProvider provider,
      ConnectivityProvider connectivityProvider) {
    if (activity is Resource) {
      final resource = activity as Resource;
      if (!resource.downloadable) return const SizedBox.shrink();

      if (provider.isDownloading(activity.id)) {
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: provider.downloadProgress(activity.id),
          ),
        );
      }

      if (!connectivityProvider.isOnline) {
        return Icon(
          provider.isDownloaded(activity.id)
              ? Icons.offline_pin
              : Icons.offline_bolt,
          color:
              provider.isDownloaded(activity.id) ? Colors.green : Colors.orange,
          size: 20,
        );
      }

      if (provider.isDownloaded(activity.id)) {
        return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
      }

      return IconButton(
        icon: const Icon(Icons.cloud_download, size: 20),
        onPressed: () => _handleResourceDownload(context, provider, resource),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    } else if (activity.type == ActivityType.QUIZ) {
      if (provider.isDownloading(activity.id)) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      }

      if (!connectivityProvider.isOnline) {
        return Icon(
          provider.isDownloaded(activity.id)
              ? Icons.offline_pin
              : Icons.offline_bolt,
          color:
              provider.isDownloaded(activity.id) ? Colors.green : Colors.orange,
          size: 20,
        );
      }

      if (provider.isDownloaded(activity.id)) {
        return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
      }

      return IconButton(
        icon: const Icon(Icons.cloud_download, size: 20),
        onPressed: () => _handleQuizDownload(context, provider),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _handleResourceDownload(BuildContext context,
      ActivityProvider provider, Resource resource) async {
    try {
      await provider.downloadResource(resource);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ressource téléchargée avec succès')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')),
        );
      }
    }
  }

  Future<void> _handleQuizDownload(
      BuildContext context, ActivityProvider provider) async {
    provider.startQuizDownload(activity.id);

    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);

      await quizProvider.loadQuiz(activity.id);
      await quizProvider.downloadQuizForOffline(activity.id);

      provider.completeQuizDownload(activity.id, true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz téléchargé avec succès')),
        );
      }
    } catch (e) {
      provider.completeQuizDownload(activity.id, false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')),
        );
      }
    }
  }

  Future<void> _handleActivityTap(
      BuildContext context,
      ActivityProvider provider,
      ConnectivityProvider connectivityProvider) async {
    if (!connectivityProvider.isOnline &&
        activity is Resource &&
        !provider.isDownloaded(activity.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette ressource n\'est pas disponible hors ligne'),
        ),
      );
      return;
    }

    if (!connectivityProvider.isOnline &&
        activity.type == ActivityType.QUIZ &&
        !provider.isDownloaded(activity.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce quiz n\'est pas disponible hors ligne'),
        ),
      );
      return;
    }

    if (activity.type == ActivityType.QUIZ) {
      await _navigateToQuiz(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityDetailScreen(
            activity: activity,
          ),
        ),
      );
    }
  }

  Future<void> _navigateToQuiz(BuildContext context) async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      await quizProvider.loadQuiz(activity.id);

      await quizProvider.loadQuizAttempts(activity.id);

      if (context.mounted) Navigator.pop(context);

      if (quizProvider.currentQuiz != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizDetailScreen(
              quiz: quizProvider.currentQuiz!,
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger le quiz')),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _getFormattedDate(DateTime? date) {
    if (date == null) return '';
    return timeago.format(date, locale: 'fr');
  }

  Widget _buildActivityIcon() {
    if (activity is Resource) {
      final resource = activity as Resource;
      switch (resource.resourceType) {
        case ResourceType.PDF:
          return Icon(Icons.picture_as_pdf, color: _getActivityColor());
        case ResourceType.VIDEO:
          return Icon(Icons.video_library, color: _getActivityColor());
        case ResourceType.IMAGE:
          return Icon(Icons.image, color: _getActivityColor());
        case ResourceType.LINK:
          return Icon(Icons.link, color: _getActivityColor());
        case ResourceType.FILE:
          return Icon(Icons.insert_drive_file, color: _getActivityColor());
      }
    }

    switch (activity.type) {
      case ActivityType.QUIZ:
        return Icon(Icons.quiz, color: _getActivityColor());
      case ActivityType.ASSIGNMENT:
        return Icon(Icons.assignment, color: _getActivityColor());
      case ActivityType.CONTENT:
        return Icon(Icons.subject, color: _getActivityColor());
      case ActivityType.RESOURCE:
        return Icon(Icons.article, color: _getActivityColor());
      default:
        return Icon(Icons.article, color: _getActivityColor());
    }
  }

  Color _getActivityColor() {
    if (activity is Resource) {
      final resource = activity as Resource;
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

    switch (activity.type) {
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
}
