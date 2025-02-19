import 'package:flutter/material.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utlils/file_helper.dart';
import '../../models/activity.dart';
import '../../models/resource.dart';
import '../../models/enums/resource_type.dart';
import '../../models/enums/activity_type.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;
  final bool isOffline;
  final SyncService _syncService = SyncService();

  ActivityDetailScreen({
    super.key,
    required this.activity,
    required this.isOffline,
  });

  Widget _buildActivityContent(BuildContext context) {
    switch (activity.type) {
      case ActivityType.RESOURCE:
        if (activity is Resource) {
          return _buildResourceContent(context, activity as Resource);
        }
        return const Center(child: Text('Ressource non disponible'));
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

  Widget _buildForumContent(BuildContext context) {
    return const Center(child: Text('Contenu du forum à implémenter'));
  }

  Widget _buildResourceContent(BuildContext context, Resource resource) {
    Widget resourceTypeIcon;
    String resourceDescription;

    switch (resource.resourceType) {
      case ResourceType.PDF:
        resourceTypeIcon =
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red);
        resourceDescription = 'Document PDF';
        break;
      case ResourceType.VIDEO:
        resourceTypeIcon =
            const Icon(Icons.play_circle_fill, size: 48, color: Colors.blue);
        resourceDescription = 'Vidéo';
        break;
      case ResourceType.IMAGE:
        resourceTypeIcon =
            const Icon(Icons.image, size: 48, color: Colors.green);
        resourceDescription = 'Image';
        break;
      case ResourceType.LINK:
        resourceTypeIcon =
            const Icon(Icons.link, size: 48, color: Colors.purple);
        resourceDescription = 'Lien externe';
        break;
      case ResourceType.FILE:
        resourceTypeIcon =
            const Icon(Icons.insert_drive_file, size: 48, color: Colors.grey);
        resourceDescription = 'Fichier';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  resourceTypeIcon,
                  const SizedBox(height: 16),
                  Text(
                    resourceDescription,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (resource.fileSize != null) ...[
                    const SizedBox(height: 8),
                    Text('Taille: ${_formatFileSize(resource.fileSize!)}'),
                  ],
                  if (resource.mimeType != null) ...[
                    const SizedBox(height: 8),
                    Text('Type: ${resource.mimeType}'),
                  ],
                  const SizedBox(height: 16),
                  if (resource.offlineAvailable && isOffline)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final localPath =
                              await _syncService.getLocalResourcePath(resource);
                          if (localPath != null) {
                            await FileHelper.openResource(
                                localPath, null, resource.mimeType ?? '');
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Fichier non trouvé')),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Erreur lors de l\'ouverture: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Ouvrir'),
                    )
                  else if (!isOffline)
                    // Pour les ressources en ligne (comme les liens)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          if (resource.resourceType == ResourceType.LINK) {
                            await FileHelper.openResource(
                                null, resource.url, resource.mimeType ?? '');
                          } else if (resource.downloadable) {
                            final localPath = await _syncService
                                .getLocalResourcePath(resource);
                            if (localPath != null) {
                              await FileHelper.openResource(
                                  localPath, null, resource.mimeType ?? '');
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Téléchargez d\'abord la ressource'),
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Erreur lors de l\'ouverture: $e')),
                            );
                          }
                        }
                      },
                      icon: resource.resourceType == ResourceType.LINK
                          ? const Icon(Icons.open_in_new)
                          : const Icon(Icons.folder_open),
                      label: resource.resourceType == ResourceType.LINK
                          ? const Text('Ouvrir le lien')
                          : const Text('Ouvrir'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    return const Center(child: Text('Contenu du quiz à implémenter'));
  }

  Widget _buildAssignmentContent(BuildContext context) {
    return const Center(child: Text('Contenu du devoir à implémenter'));
  }

  Widget _buildContentActivity(BuildContext context) {
    return const Center(child: Text('Contenu de l\'activité à implémenter'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title),
        actions: [
          if (isOffline)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.offline_bolt, color: Colors.orange),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.startDate != null || activity.endDate != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activity.startDate != null)
                          Text(
                              'Début: ${_formatDateTime(activity.startDate!)}'),
                        if (activity.endDate != null) ...[
                          const SizedBox(height: 8),
                          Text('Fin: ${_formatDateTime(activity.endDate!)}'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: _buildActivityContent(context)),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
