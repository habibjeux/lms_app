import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utlils/file_helper.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../models/activity.dart';
import '../../models/assignment.dart';
import '../../models/resource.dart';
import '../../models/enums/resource_type.dart';
import '../../models/enums/activity_type.dart';
import '../widgets/assignment_content_widget.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;
  final SyncService _syncService = SyncService();

  ActivityDetailScreen({
    super.key,
    required this.activity,
  });

  Widget _buildActivityHeader() {
    final Color activityColor = _getActivityColor();

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            activityColor,
            activityColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: activityColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _buildActivityIcon(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getActivityTypeLabel(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (activity.startDate != null || activity.endDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (activity.startDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Début: ${_formatDateTime(activity.startDate!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  if (activity.endDate != null) ...[
                    if (activity.startDate != null) const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.stop,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fin: ${_formatDateTime(activity.endDate!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityContent(BuildContext context, bool isOffline) {
    switch (activity.type) {
      case ActivityType.RESOURCE:
        if (activity is Resource) {
          return _buildResourceContent(
              context, activity as Resource, isOffline);
        }
        return _buildEmptyContent('Ressource non disponible', Icons.error);
      case ActivityType.QUIZ:
        return _buildQuizContent(context);
      case ActivityType.ASSIGNMENT:
        return _buildAssignmentContent(context);
      case ActivityType.CONTENT:
        return _buildContentActivity(context);
      case ActivityType.FORUM:
        return _buildForumContent(context);
    }
  }

  Widget _buildEmptyContent(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForumContent(BuildContext context) {
    return _buildEmptyContent('Contenu du forum à implémenter', Icons.forum);
  }

  Widget _buildResourceContent(
      BuildContext context, Resource resource, bool isOffline) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      _getResourceColor(resource.resourceType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildResourceIcon(resource.resourceType),
              ),
              const SizedBox(height: 20),
              Text(
                _getResourceDescription(resource.resourceType),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Indicateur de disponibilité hors ligne
              if (isOffline) ...[
                const SizedBox(height: 12),
                FutureBuilder<String?>(
                  future: _syncService.getLocalResourcePath(resource),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    final isAvailableOffline = snapshot.data != null;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAvailableOffline
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isAvailableOffline ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailableOffline
                                ? Icons.offline_pin
                                : Icons.cloud_off,
                            size: 16,
                            color: isAvailableOffline
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailableOffline
                                ? 'Disponible hors ligne'
                                : 'Non téléchargée',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isAvailableOffline
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 16),
              if (resource.fileSize != null || resource.mimeType != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (resource.fileSize != null)
                        Row(
                          children: [
                            Icon(Icons.data_usage,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Taille: ${_formatFileSize(resource.fileSize!)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      if (resource.mimeType != null) ...[
                        if (resource.fileSize != null)
                          const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.description,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Type: ${resource.mimeType}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openResource(context, resource),
                  icon: Icon(_getResourceOpenIcon(resource.resourceType)),
                  label: Text(_getResourceOpenLabel(resource.resourceType)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getResourceColor(resource.resourceType),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceIcon(ResourceType type) {
    IconData iconData;
    switch (type) {
      case ResourceType.PDF:
        iconData = Icons.picture_as_pdf;
        break;
      case ResourceType.VIDEO:
        iconData = Icons.play_circle_fill;
        break;
      case ResourceType.IMAGE:
        iconData = Icons.image;
        break;
      case ResourceType.LINK:
        iconData = Icons.link;
        break;
      case ResourceType.FILE:
        iconData = Icons.insert_drive_file;
        break;
    }
    return Icon(iconData, size: 40, color: _getResourceColor(type));
  }

  Color _getResourceColor(ResourceType type) {
    switch (type) {
      case ResourceType.PDF:
        return Colors.red;
      case ResourceType.VIDEO:
        return Colors.blue;
      case ResourceType.IMAGE:
        return Colors.green;
      case ResourceType.LINK:
        return Colors.purple;
      case ResourceType.FILE:
        return Colors.orange;
    }
  }

  String _getResourceDescription(ResourceType type) {
    switch (type) {
      case ResourceType.PDF:
        return 'Document PDF';
      case ResourceType.VIDEO:
        return 'Contenu vidéo';
      case ResourceType.IMAGE:
        return 'Image';
      case ResourceType.LINK:
        return 'Lien externe';
      case ResourceType.FILE:
        return 'Fichier';
    }
  }

  IconData _getResourceOpenIcon(ResourceType type) {
    switch (type) {
      case ResourceType.LINK:
        return Icons.open_in_new;
      default:
        return Icons.folder_open;
    }
  }

  String _getResourceOpenLabel(ResourceType type) {
    switch (type) {
      case ResourceType.LINK:
        return 'Ouvrir le lien';
      default:
        return 'Ouvrir';
    }
  }

  Future<void> _openResource(BuildContext context, Resource resource) async {
    final isOnline = context.read<ConnectivityProvider>().isOnline;

    try {
      // D'abord, toujours vérifier si la ressource est disponible localement
      final localPath = await _syncService.getLocalResourcePath(resource);
      if (localPath != null) {
        print("✅ Ouverture de la ressource locale: $localPath");
        await FileHelper.openResource(localPath, null, resource.mimeType ?? '');

        // Afficher un message de confirmation pour le mode hors ligne
        if (!isOnline && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ressource ouverte depuis le stockage local'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Si pas disponible localement et en ligne, essayer le serveur
      if (isOnline) {
        final serverUrl = dotenv.env['SERVER_URL'] ?? '';
        final resourceUrl = '$serverUrl/${resource.url}';
        print("🌐 Ouverture de la ressource en ligne: $resourceUrl");
        await FileHelper.openResource(
            null, resourceUrl, resource.mimeType ?? '');
        return;
      }

      // Si hors ligne et pas de fichier local
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Ressource non disponible hors ligne. Téléchargez-la d\'abord pour y accéder sans connexion.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print("❌ Erreur lors de l'ouverture de la ressource: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erreur lors de l\'ouverture de la ressource: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildQuizContent(BuildContext context) {
    final isOffline = !context.watch<ConnectivityProvider>().isOnline;

    if (isOffline) {
      // En mode hors ligne, vérifier si le quiz est disponible localement
      return FutureBuilder<Map<String, dynamic>?>(
        future: _syncService.getOfflineQuiz(activity.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(32),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data != null) {
            // Quiz disponible hors ligne
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.quiz, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Quiz disponible hors ligne',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ce quiz a été téléchargé et est disponible pour consultation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigation vers l'écran de quiz
                        Navigator.pushNamed(
                          context,
                          '/quiz-detail',
                          arguments: {
                            'quizId': activity.id,
                            'offlineData': snapshot.data,
                          },
                        );
                      },
                      icon: const Icon(Icons.offline_pin),
                      label: const Text('Voir le quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Quiz non disponible hors ligne
            return _buildEmptyContent(
              'Quiz non disponible hors ligne.\nTéléchargez-le d\'abord pour y accéder sans connexion.',
              Icons.cloud_off,
            );
          }
        },
      );
    }

    // Mode en ligne - fonctionnalité à implémenter
    return _buildEmptyContent('Contenu du quiz à implémenter', Icons.quiz);
  }

  Widget _buildAssignmentContent(BuildContext context) {
    final isOffline = !context.watch<ConnectivityProvider>().isOnline;

    if (isOffline) {
      // En mode hors ligne, vérifier si le devoir est disponible localement
      return FutureBuilder<Map<String, dynamic>?>(
        future: _syncService.getOfflineAssignment(activity.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(32),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data != null) {
            // Devoir disponible hors ligne
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.teal.withOpacity(0.1),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.assignment, size: 48, color: Colors.teal),
                    const SizedBox(height: 16),
                    Text(
                      'Devoir disponible hors ligne',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ce devoir a été téléchargé et est disponible pour consultation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigation vers l'écran de devoir
                        Navigator.pushNamed(
                          context,
                          '/assignment-detail',
                          arguments: {
                            'assignmentId': activity.id,
                            'offlineData': snapshot.data,
                          },
                        );
                      },
                      icon: const Icon(Icons.offline_pin),
                      label: const Text('Voir le devoir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Devoir non disponible hors ligne
            return _buildEmptyContent(
              'Devoir non disponible hors ligne.\nTéléchargez-le d\'abord pour y accéder sans connexion.',
              Icons.cloud_off,
            );
          }
        },
      );
    }

    // Mode en ligne - utiliser le widget existant
    if (activity is Assignment) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: AssignmentContentWidget(
          assignment: activity as Assignment,
        ).build(context),
      );
    } else {
      return _buildEmptyContent(
          'Type de devoir non pris en charge', Icons.error);
    }
  }

  Widget _buildContentActivity(BuildContext context) {
    return _buildEmptyContent(
        'Contenu de l\'activité à implémenter', Icons.article);
  }

  Color _getActivityColor() {
    if (activity is Resource) {
      final resource = activity as Resource;
      return _getResourceColor(resource.resourceType);
    }

    switch (activity.type) {
      case ActivityType.QUIZ:
        return Colors.orange;
      case ActivityType.ASSIGNMENT:
        return Colors.teal;
      case ActivityType.CONTENT:
        return Colors.blue; // Utilisation cohérente avec la primaryColor
      default:
        return Colors.grey;
    }
  }

  Widget _buildActivityIcon() {
    if (activity is Resource) {
      final resource = activity as Resource;
      return _buildResourceIcon(resource.resourceType);
    }

    IconData iconData;
    switch (activity.type) {
      case ActivityType.QUIZ:
        iconData = Icons.quiz;
        break;
      case ActivityType.ASSIGNMENT:
        iconData = Icons.assignment;
        break;
      case ActivityType.CONTENT:
        iconData = Icons.subject;
        break;
      default:
        iconData = Icons.article;
        break;
    }
    return Icon(iconData, color: Colors.white, size: 24);
  }

  String _getActivityTypeLabel() {
    if (activity is Resource) {
      final resource = activity as Resource;
      switch (resource.resourceType) {
        case ResourceType.PDF:
          return 'PDF';
        case ResourceType.VIDEO:
          return 'Vidéo';
        case ResourceType.IMAGE:
          return 'Image';
        case ResourceType.LINK:
          return 'Lien';
        case ResourceType.FILE:
          return 'Fichier';
      }
    }

    switch (activity.type) {
      case ActivityType.QUIZ:
        return 'Quiz';
      case ActivityType.ASSIGNMENT:
        return 'Devoir';
      case ActivityType.CONTENT:
        return 'Contenu';
      case ActivityType.RESOURCE:
        return 'Ressource';
      default:
        return 'Activité';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: _getActivityColor(),
            foregroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 40,
            actions: [
              if (!connectivity.isOnline)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.offline_bolt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivityHeader(),
                _buildActivityContent(context, !connectivity.isOnline),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
