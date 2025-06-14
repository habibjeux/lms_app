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

      // Organiser les éléments par module et chapitre
      final Map<String, Map<String, dynamic>> organizedItems = {};

      for (var entry in items.entries) {
        final itemData = entry.value;
        final moduleId = itemData['moduleId']?.toString();
        final chapterId = itemData['chapterId']?.toString();

        if (moduleId != null) {
          if (!organizedItems.containsKey(moduleId)) {
            // Récupérer le titre du module depuis les données
            String moduleTitle = 'Module';
            for (var item in items.values) {
              if (item['moduleId'] == moduleId && item['moduleTitle'] != null) {
                moduleTitle = item['moduleTitle'];
                break;
              }
            }

            organizedItems[moduleId] = {
              'type': 'module',
              'title': moduleTitle,
              'chapters': <String, Map<String, dynamic>>{},
              'activities': <Map<String, dynamic>>[],
            };
          }

          if (chapterId != null) {
            // Ajouter au chapitre
            if (!organizedItems[moduleId]!['chapters'].containsKey(chapterId)) {
              // Récupérer le titre du chapitre depuis les données
              String chapterTitle = 'Chapitre';
              for (var item in items.values) {
                if (item['chapterId'] == chapterId &&
                    item['chapterTitle'] != null) {
                  chapterTitle = item['chapterTitle'];
                  break;
                }
              }

              organizedItems[moduleId]!['chapters'][chapterId] = {
                'type': 'chapter',
                'title': chapterTitle,
                'activities': <Map<String, dynamic>>[],
              };
            }
            (organizedItems[moduleId]!['chapters'][chapterId]['activities']
                    as List)
                .add({
              ...itemData,
              'id': entry.key,
            });
          } else {
            // Ajouter aux activités du module
            (organizedItems[moduleId]!['activities'] as List).add({
              ...itemData,
              'id': entry.key,
            });
          }
        }
      }

      setState(() {
        _downloadedItems = organizedItems;
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
                    final moduleId = _downloadedItems.keys.elementAt(index);
                    final moduleData = _downloadedItems[moduleId]!;
                    final chapters = Map<String, Map<String, dynamic>>.from(
                        moduleData['chapters'] ?? {});
                    final activities = List<Map<String, dynamic>>.from(
                        moduleData['activities'] ?? []);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête du module
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        moduleData['title'] ?? 'Module',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '${chapters.length} chapitre(s), ${activities.length} activité(s)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Activités du module
                          if (activities.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              color: Colors.green.withOpacity(0.1),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.extension,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Activités du module',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            ...activities.map((activity) => ListTile(
                                  leading: Icon(
                                    activity['type'] == 'resource'
                                        ? Icons.description
                                        : Icons.quiz,
                                    color: activity['type'] == 'resource'
                                        ? Colors.blue
                                        : Colors.orange,
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
                                )),
                            const Divider(height: 1),
                          ],

                          // Chapitres
                          if (chapters.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              color: Colors.blue.withOpacity(0.1),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.menu_book,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Chapitres',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            ...chapters.entries.map((chapterEntry) {
                              final chapterId = chapterEntry.key;
                              final chapterData = chapterEntry.value;
                              final chapterActivities =
                                  List<Map<String, dynamic>>.from(
                                      chapterData['activities'] ?? []);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // En-tête du chapitre
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    color: Colors.blue.withOpacity(0.05),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.folder_open,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                chapterData['title'] ??
                                                    'Chapitre',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              Text(
                                                '${chapterActivities.length} activité(s)',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Activités du chapitre
                                  if (chapterActivities.isNotEmpty)
                                    Column(
                                      children: [
                                        // Ressources
                                        if (chapterActivities.any(
                                            (a) => a['type'] == 'resource'))
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                color: Colors.blue
                                                    .withOpacity(0.05),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.description,
                                                      color: Colors.blue,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Ressources',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: Colors.blue,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ...chapterActivities
                                                  .where((a) =>
                                                      a['type'] == 'resource')
                                                  .map((resource) => ListTile(
                                                        leading: const Icon(
                                                          Icons.description,
                                                          color: Colors.blue,
                                                        ),
                                                        title: Text(
                                                          resource['title'] ??
                                                              'Sans titre',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                        subtitle: Text(
                                                          'Ressource - ${chapterData['title']}',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                        trailing: IconButton(
                                                          icon: const Icon(
                                                              Icons.delete),
                                                          onPressed: _isDeleting
                                                              ? null
                                                              : () => _deleteItem(
                                                                  resource[
                                                                      'id'],
                                                                  'resource'),
                                                        ),
                                                      )),
                                            ],
                                          ),
                                        // Quiz
                                        if (chapterActivities
                                            .any((a) => a['type'] == 'quiz'))
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                color: Colors.orange
                                                    .withOpacity(0.05),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.quiz,
                                                      color: Colors.orange,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Quiz',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color:
                                                                Colors.orange,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ...chapterActivities
                                                  .where((a) =>
                                                      a['type'] == 'quiz')
                                                  .map((quiz) => ListTile(
                                                        leading: const Icon(
                                                          Icons.quiz,
                                                          color: Colors.orange,
                                                        ),
                                                        title: Text(
                                                          quiz['title'] ??
                                                              'Sans titre',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                        subtitle: Text(
                                                          'Quiz - ${chapterData['title']}',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                        trailing: IconButton(
                                                          icon: const Icon(
                                                              Icons.delete),
                                                          onPressed: _isDeleting
                                                              ? null
                                                              : () =>
                                                                  _deleteItem(
                                                                      quiz[
                                                                          'id'],
                                                                      'quiz'),
                                                        ),
                                                      )),
                                            ],
                                          ),
                                        // Assignments
                                        if (chapterActivities.any(
                                            (a) => a['type'] == 'assignment'))
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                color: Colors.purple
                                                    .withOpacity(0.05),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.assignment,
                                                      color: Colors.purple,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Devoirs',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color:
                                                                Colors.purple,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ...chapterActivities
                                                  .where((a) =>
                                                      a['type'] == 'assignment')
                                                  .map((assignment) => ListTile(
                                                        leading: const Icon(
                                                          Icons.assignment,
                                                          color: Colors.purple,
                                                        ),
                                                        title: Text(
                                                          assignment['title'] ??
                                                              'Sans titre',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                        subtitle: Text(
                                                          'Devoir - ${chapterData['title']}',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                        trailing: IconButton(
                                                          icon: const Icon(
                                                              Icons.delete),
                                                          onPressed: _isDeleting
                                                              ? null
                                                              : () => _deleteItem(
                                                                  assignment[
                                                                      'id'],
                                                                  'assignment'),
                                                        ),
                                                      )),
                                            ],
                                          ),
                                      ],
                                    ),
                                  const Divider(height: 1),
                                ],
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
