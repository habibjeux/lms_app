import 'package:flutter/material.dart';
import '../../../../core/services/download_storage_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/loading_indicator.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadStorageService _downloadStorage = DownloadStorageService();
  final StorageService _storage = StorageService();
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _downloadedItems = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadDownloadedItems();
  }

  Future<void> _loadDownloadedItems() async {
    try {
      setState(() => _isLoading = true);
      final items = await _downloadStorage.getDownloadedItems();
      setState(() {
        _downloadedItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des téléchargements: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des téléchargements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(String id, String type) async {
    try {
      setState(() => _isDeleting = true);
      await _downloadStorage.deleteItem(id, type);
      await _loadDownloadedItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Élément supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  Future<void> _clearAllDownloads() async {
    try {
      setState(() => _isDeleting = true);
      await _downloadStorage.clearAllDownloads();
      await _loadDownloadedItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tous les téléchargements ont été supprimés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la suppression des téléchargements: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléchargements'),
        actions: [
          if (_downloadedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _isDeleting
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title:
                              const Text('Supprimer tous les téléchargements'),
                          content: const Text(
                              'Êtes-vous sûr de vouloir supprimer tous les téléchargements ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _clearAllDownloads();
                              },
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                    },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _downloadedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_done,
                        size: 64,
                        color: Colors.blue.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun téléchargement',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _downloadedItems.length,
                  itemBuilder: (context, index) {
                    final chapterId = _downloadedItems.keys.elementAt(index);
                    final chapterData = _downloadedItems[chapterId]!;
                    final activities = List<Map<String, dynamic>>.from(
                        chapterData['activities'] ?? []);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text(
                          chapterData['title'] ?? 'Chapitre sans titre',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          '${activities.length} activité(s)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        children: [
                          if (activities.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Aucune activité dans ce chapitre'),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activities.length,
                              itemBuilder: (context, activityIndex) {
                                final activity = activities[activityIndex];
                                return ListTile(
                                  leading: Icon(
                                    activity['type'] == 'resource'
                                        ? Icons.description
                                        : Icons.quiz,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    activity['title'] ?? 'Sans titre',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  subtitle: Text(
                                    activity['type'] == 'resource'
                                        ? 'Ressource'
                                        : 'Quiz',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: _isDeleting
                                        ? null
                                        : () => _deleteItem(
                                            activity['id'], activity['type']),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
