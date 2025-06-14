import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/download_storage_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../models/resource.dart';
import '../../models/activity.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  Map<String, Map<String, dynamic>> _downloadedItems = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedItems();
  }

  Future<void> _loadDownloadedItems() async {
    setState(() => _isLoading = true);
    try {
      final items =
          await context.read<DownloadStorageService>().getDownloadedItems();
      setState(() {
        _downloadedItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des téléchargements: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String id, String type) async {
    try {
      await context.read<DownloadStorageService>().deleteItem(id, type);
      await _loadDownloadedItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  Future<void> _deleteAllDownloads() async {
    try {
      await context.read<DownloadStorageService>().clearAllDownloads();
      await _loadDownloadedItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  void _navigateToItem(String id, Map<String, dynamic> data) {
    final type = data['type'] as String;
    final moduleId = data['moduleId'] as String?;
    final chapterId = data['chapterId'] as String?;

    if (type == 'resource') {
      // Ouvrir la ressource
      final filePath = data['filePath'] as String?;
      if (filePath != null) {
        // TODO: Implémenter l'ouverture du fichier
      }
    } else if (type == 'quiz') {
      // Naviguer vers le quiz
      if (moduleId != null && chapterId != null) {
        Navigator.pushNamed(
          context,
          '/quiz',
          arguments: {
            'quizId': id,
            'moduleId': moduleId,
            'chapterId': chapterId,
          },
        );
      }
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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer tous les téléchargements'),
                    content: const Text(
                        'Voulez-vous vraiment supprimer tous les téléchargements ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAllDownloads();
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
          ? const Center(child: CircularProgressIndicator())
          : _downloadedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_done,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun téléchargement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _downloadedItems.length,
                  itemBuilder: (context, index) {
                    final chapterId = _downloadedItems.keys.elementAt(index);
                    final chapterData = _downloadedItems[chapterId]!;
                    final activities = List<Map<String, dynamic>>.from(
                        chapterData['activities'] ?? []);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          chapterData['title'] ?? 'Chapitre sans titre',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '${activities.length} activité(s)',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        children: activities.map((activity) {
                          return ListTile(
                            leading: Icon(
                              activity['type'] == 'resource'
                                  ? Icons.file_present
                                  : Icons.quiz,
                              color: activity['type'] == 'resource'
                                  ? Colors.blue
                                  : Colors.orange,
                            ),
                            title: Text(activity['title'] ?? 'Sans titre'),
                            subtitle: Text(
                              activity['type'] == 'resource'
                                  ? 'Ressource'
                                  : 'Quiz',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => _navigateToItem(
                                    activity['id'],
                                    activity,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteItem(
                                    activity['id'],
                                    activity['type'],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
