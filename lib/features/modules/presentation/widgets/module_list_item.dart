import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../models/module.dart';

class ModuleListItem extends StatelessWidget {
  final Module module;
  final SyncService _syncService = SyncService();

  ModuleListItem({
    super.key,
    required this.module,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.book),
            title: Text(module.title),
            subtitle: Text(module.description ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  tooltip: 'Télécharger le module',
                  onPressed: () => _showDownloadDialog(context),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
            onTap: () {
              // Navigation vers le détail du module
            },
          ),
        );
      },
    );
  }

  Future<void> _showDownloadDialog(BuildContext context) async {
    final isOnline = await _syncService.isOnline();
    if (!isOnline) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion Internet requise pour télécharger'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Télécharger le module'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Que souhaitez-vous télécharger ?'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Contenu du module'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadModuleContent(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_present),
                title: const Text('Ressources du module'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadModuleResources(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Module complet'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFullModule(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadModuleContent(BuildContext context) async {
    try {
      // Logique de téléchargement du contenu
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Téléchargement du contenu en cours...')),
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

  Future<void> _downloadModuleResources(BuildContext context) async {
    try {
      // Logique de téléchargement des ressources
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Téléchargement des ressources en cours...')),
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

  Future<void> _downloadFullModule(BuildContext context) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Téléchargement du module complet en cours...')),
        );
      }

      await _syncService.downloadFullModule(
        module.id,
        onProgress: (progress) {
          // Afficher la progression si nécessaire
        },
        onComplete: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Module téléchargé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onError: (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors du téléchargement: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
