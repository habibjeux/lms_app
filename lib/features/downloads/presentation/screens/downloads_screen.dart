import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/download_storage_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../modules/models/module.dart';
import '../../../modules/providers/activity_provider.dart';
import '../../../modules/providers/modules_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class DownloadsScreen extends StatefulWidget {
  final Module? module;

  const DownloadsScreen({
    super.key,
    this.module,
  });

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadStorageService _downloadStorage = DownloadStorageService();
  final SyncService _syncService = SyncService();
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _downloadedItems = {};
  bool _isDeleting = false;

  // Cache pour les chapitres récupérés
  final Map<String, Map<String, String>> _chaptersCache =
      {}; // moduleId -> {chapterId: title}
  final Map<String, String> _moduleChapterMap = {}; // chapterId -> moduleId

  @override
  void initState() {
    super.initState();
    _loadDownloadedItems();
  }

  // Méthode pour récupérer le titre d'un module depuis les providers
  String _getModuleTitle(String moduleId) {
    try {
      final modulesProvider =
          Provider.of<ModulesProvider>(context, listen: false);
      final modules = modulesProvider.modules;
      final module =
          modules.where((m) => m.id.toString() == moduleId).firstOrNull;
      return module?.title ?? 'Module $moduleId';
    } catch (e) {
      print('Erreur lors de la récupération du titre du module: $e');
      return 'Module $moduleId';
    }
  }

  // Méthode pour charger les chapitres d'un module et les mettre en cache
  Future<void> _loadChaptersForModule(String moduleId) async {
    try {
      if (_chaptersCache.containsKey(moduleId)) {
        return; // Déjà en cache
      }

      final chapters = await _syncService.getChapters(moduleId);
      final chaptersMap = <String, String>{};

      for (var chapterData in chapters) {
        final chapterId = chapterData['id'].toString();
        final chapterTitle =
            chapterData['title']?.toString() ?? 'Chapitre $chapterId';
        chaptersMap[chapterId] = chapterTitle;

        // Maintenir le mapping inverse
        _moduleChapterMap[chapterId] = moduleId;
      }

      _chaptersCache[moduleId] = chaptersMap;
      print(
          'Chapitres chargés pour le module $moduleId: ${chaptersMap.length} chapitres');
    } catch (e) {
      print(
          'Erreur lors du chargement des chapitres pour le module $moduleId: $e');
      // En cas d'erreur, créer un cache vide pour éviter des tentatives répétées
      _chaptersCache[moduleId] = {};
    }
  }

  Future<void> _loadDownloadedItems() async {
    try {
      setState(() => _isLoading = true);
      final items = await _downloadStorage.getDownloadedItems();

      print('Éléments téléchargés récupérés: ${items.length}');
      for (var item in items) {
        print('Item: ${item}');
      }

      // Organiser les éléments par module et chapitre
      final Map<String, Map<String, dynamic>> organizedItems = {};

      // D'abord, créer des maps pour stocker les titres trouvés
      final Map<String, String> moduleTitles = {};
      final Map<String, String> chapterTitles = {};
      final Set<String> moduleIds = {};
      final Set<String> chapterIds = {};

      // Première passe : collecter tous les titres disponibles et identifier les IDs
      for (var itemData in items) {
        final moduleId = itemData['moduleId']?.toString();
        final chapterId = itemData['chapterId']?.toString();

        // Debug: Afficher les champs disponibles
        print('Module ID: $moduleId, Chapter ID: $chapterId');
        print('Champs disponibles: ${itemData.keys.toList()}');
        print('Title: ${itemData['title']}');

        // Collecter les modules IDs
        if (moduleId != null) {
          moduleIds.add(moduleId);
        }

        // Collecter les chapitres IDs et mapping
        if (chapterId != null) {
          chapterIds.add(chapterId);
          if (moduleId != null) {
            _moduleChapterMap[chapterId] = moduleId;
          }
        }

        // Collecter les titres de modules - essayer différents champs
        if (moduleId != null) {
          final moduleTitle = itemData['moduleTitle']?.toString() ??
              itemData['module_title']?.toString() ??
              itemData['moduleName']?.toString();
          if (moduleTitle != null && moduleTitle.isNotEmpty) {
            moduleTitles[moduleId] = moduleTitle;
            print('Module title trouvé: $moduleTitle pour module $moduleId');
          }
        }

        // Collecter les titres de chapitres - essayer différents champs
        if (chapterId != null) {
          final chapterTitle = itemData['chapterTitle']?.toString() ??
              itemData['chapter_title']?.toString() ??
              itemData['chapterName']?.toString();
          if (chapterTitle != null && chapterTitle.isNotEmpty) {
            chapterTitles[chapterId] = chapterTitle;
            print(
                'Chapter title trouvé: $chapterTitle pour chapitre $chapterId');
          }
        }
      }

      print('Modules trouvés: $moduleTitles');
      print('Chapitres trouvés: $chapterTitles');

      // Charger les chapitres manquants depuis l'API/cache pour tous les modules
      for (String moduleId in moduleIds) {
        await _loadChaptersForModule(moduleId);
      }

      // Maintenant récupérer les titres finaux des chapitres
      final Map<String, String> finalChapterTitles = {};
      for (String chapterId in chapterIds) {
        String chapterTitle = chapterTitles[chapterId] ?? '';

        // Si pas trouvé dans les données stockées, chercher dans le cache
        if (chapterTitle.isEmpty) {
          for (var moduleChapters in _chaptersCache.values) {
            if (moduleChapters.containsKey(chapterId)) {
              chapterTitle = moduleChapters[chapterId]!;
              print(
                  'Chapter title récupéré du cache: $chapterTitle pour chapitre $chapterId');
              break;
            }
          }
        }

        finalChapterTitles[chapterId] =
            chapterTitle.isNotEmpty ? chapterTitle : 'Chapitre $chapterId';
      }

      print('Titres de chapitres finaux: $finalChapterTitles');

      // Deuxième passe : organiser les éléments avec les vrais titres
      for (var itemData in items) {
        // Filtrer les chapitres - on ne veut afficher que les activités réelles
        if (itemData['type'] == 'chapter') {
          continue;
        }

        final moduleId = itemData['moduleId']?.toString();
        final chapterId = itemData['chapterId']?.toString();

        // Si un module spécifique est demandé, filtrer par ce module
        if (widget.module != null && moduleId != widget.module!.id.toString()) {
          continue;
        }

        if (moduleId != null) {
          if (!organizedItems.containsKey(moduleId)) {
            String moduleTitle;

            if (widget.module != null) {
              // Si on a un module spécifique, utiliser son titre
              moduleTitle = widget.module!.title;
            } else {
              // Utiliser le titre trouvé dans les données, ou essayer le provider, ou fallback
              moduleTitle = moduleTitles[moduleId] ?? _getModuleTitle(moduleId);
            }

            organizedItems[moduleId] = {
              'type': 'module',
              'title': moduleTitle,
              'chapters': <String, Map<String, dynamic>>{},
              'activities': <Map<String, dynamic>>[],
            };
          }

          if (chapterId != null) {
            if (!organizedItems[moduleId]!['chapters'].containsKey(chapterId)) {
              // Utiliser le titre final des chapitres
              final chapterTitle =
                  finalChapterTitles[chapterId] ?? 'Chapitre $chapterId';

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
              'id': itemData['id'],
            });
          } else {
            (organizedItems[moduleId]!['activities'] as List).add({
              ...itemData,
              'id': itemData['id'],
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

      _updateProviderStatus(id, type, false);

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

  // Méthode pour supprimer tous les téléchargements d'un module
  Future<void> _deleteAllModuleDownloads(String moduleId) async {
    try {
      setState(() => _isDeleting = true);

      // Récupérer toutes les activités du module
      final moduleData = _downloadedItems[moduleId];
      if (moduleData == null) return;

      final chapters =
          Map<String, Map<String, dynamic>>.from(moduleData['chapters'] ?? {});
      final activities =
          List<Map<String, dynamic>>.from(moduleData['activities'] ?? []);

      // Supprimer toutes les activités du module
      for (var activity in activities) {
        await _downloadStorage.deleteItem(activity['id'], activity['type']);
        _updateProviderStatus(activity['id'], activity['type'], false);
      }

      // Supprimer toutes les activités de tous les chapitres
      for (var chapter in chapters.values) {
        final chapterActivities =
            List<Map<String, dynamic>>.from(chapter['activities'] ?? []);
        for (var activity in chapterActivities) {
          await _downloadStorage.deleteItem(activity['id'], activity['type']);
          _updateProviderStatus(activity['id'], activity['type'], false);
        }
      }

      await _loadDownloadedItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Tous les téléchargements du module ont été supprimés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la suppression des téléchargements du module: $e');
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

  // Méthode pour supprimer tous les téléchargements
  Future<void> _deleteAllDownloads() async {
    try {
      setState(() => _isDeleting = true);

      // Supprimer toutes les activités de tous les modules
      for (var moduleEntry in _downloadedItems.entries) {
        final moduleData = moduleEntry.value;
        final chapters = Map<String, Map<String, dynamic>>.from(
            moduleData['chapters'] ?? {});
        final activities =
            List<Map<String, dynamic>>.from(moduleData['activities'] ?? []);

        // Supprimer toutes les activités du module
        for (var activity in activities) {
          await _downloadStorage.deleteItem(activity['id'], activity['type']);
          _updateProviderStatus(activity['id'], activity['type'], false);
        }

        // Supprimer toutes les activités de tous les chapitres
        for (var chapter in chapters.values) {
          final chapterActivities =
              List<Map<String, dynamic>>.from(chapter['activities'] ?? []);
          for (var activity in chapterActivities) {
            await _downloadStorage.deleteItem(activity['id'], activity['type']);
            _updateProviderStatus(activity['id'], activity['type'], false);
          }
        }
      }

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
      print('Erreur lors de la suppression de tous les téléchargements: $e');
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

  // Méthode helper pour mettre à jour les providers
  void _updateProviderStatus(String id, String type, bool status) {
    if (mounted) {
      final activityProvider =
          Provider.of<ActivityProvider>(context, listen: false);
      switch (type) {
        case 'quiz':
          activityProvider.updateQuizDownloadStatus(id, status);
          break;
        case 'resource':
          activityProvider.updateResourceDownloadStatus(id, status);
          break;
        case 'assignment':
          activityProvider.updateAssignmentDownloadStatus(id, status);
          break;
      }
    }
  }

  // Méthode pour afficher la confirmation de suppression d'un module
  void _showDeleteModuleConfirmation(String moduleId) {
    final moduleData = _downloadedItems[moduleId];
    final moduleTitle = moduleData?['title'] ?? 'ce module';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer tous les téléchargements de "$moduleTitle" ?\n\nCette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllModuleDownloads(moduleId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  // Méthode pour afficher la confirmation de suppression globale
  void _showDeleteAllConfirmation() {
    int totalItems = 0;
    for (var moduleData in _downloadedItems.values) {
      final chapters =
          Map<String, Map<String, dynamic>>.from(moduleData['chapters'] ?? {});
      final activities =
          List<Map<String, dynamic>>.from(moduleData['activities'] ?? []);
      totalItems += activities.length;
      for (var chapter in chapters.values) {
        totalItems += (chapter['activities'] as List).length;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer TOUS les téléchargements ?\n\n'
            '$totalItems élément${totalItems > 1 ? 's' : ''} '
            'ser${totalItems > 1 ? 'ont' : 'a'} supprimé${totalItems > 1 ? 's' : ''}.\n\n'
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllDownloads();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Tout supprimer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        return Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple,
                Colors.deepPurple.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.module != null
                          ? 'Téléchargements de ${widget.module!.title}'
                          : 'Mes Téléchargements 📥',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.module != null
                          ? 'Contenu téléchargé disponible hors ligne'
                          : 'Tout votre contenu disponible hors ligne',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.download_done,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color iconColor;
    String typeLabel;

    switch (activity['type']) {
      case 'quiz':
        icon = Icons.quiz;
        iconColor = Colors.orange;
        typeLabel = 'Quiz';
        break;
      case 'resource':
        icon = Icons.description;
        iconColor = Colors.blue;
        typeLabel = 'Ressource';
        break;
      case 'assignment':
        icon = Icons.assignment;
        iconColor = Colors.green;
        typeLabel = 'Devoir';
        break;
      default:
        icon = Icons.file_present;
        iconColor = Colors.grey;
        typeLabel = 'Fichier';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          activity['title'] ?? 'Sans titre',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(typeLabel),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: _isDeleting
              ? null
              : () => _deleteItem(activity['id'], activity['type']),
        ),
        onTap: () {
          // Ouvrir l'activité
        },
      ),
    );
  }

  Widget _buildModuleSection(String moduleId, Map<String, dynamic> moduleData) {
    final chapters =
        Map<String, Map<String, dynamic>>.from(moduleData['chapters'] ?? {});
    final activities =
        List<Map<String, dynamic>>.from(moduleData['activities'] ?? []);

    int totalItems = activities.length;
    for (var chapter in chapters.values) {
      totalItems += (chapter['activities'] as List).length;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.school, color: Colors.white, size: 20),
        ),
        title: Text(
          moduleData['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
            '$totalItems élément${totalItems > 1 ? 's' : ''} téléchargé${totalItems > 1 ? 's' : ''}'),
        trailing: widget.module == null
            ? IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                tooltip: 'Supprimer tous les téléchargements de ce module',
                onPressed: _isDeleting
                    ? null
                    : () => _showDeleteModuleConfirmation(moduleId),
              )
            : null,
        children: [
          // Activités du module
          if (activities.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Activités du module',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ...activities.map((activity) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildActivityItem(activity),
                )),
          ],

          // Chapitres
          ...chapters.entries.map((chapterEntry) {
            final chapterData = chapterEntry.value;
            final chapterActivities = List<Map<String, dynamic>>.from(
                chapterData['activities'] ?? []);

            if (chapterActivities.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapterData['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...chapterActivities
                      .map((activity) => _buildActivityItem(activity)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.module != null ? 'Téléchargements' : 'Mes Téléchargements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_downloadedItems.isNotEmpty && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Supprimer tous les téléchargements',
              onPressed: _isDeleting ? null : _showDeleteAllConfirmation,
            ),
        ],
      ),
      body: _isLoading
          ? Column(
              children: [
                _buildWelcomeHeader(),
                const Expanded(
                  child: Center(child: LoadingIndicator()),
                ),
              ],
            )
          : _downloadedItems.isEmpty
              ? Column(
                  children: [
                    _buildWelcomeHeader(),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.download_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.module != null
                                  ? 'Aucun téléchargement pour ce module'
                                  : 'Aucun téléchargement',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.module != null
                                  ? 'Aucun contenu téléchargé pour ce module'
                                  : 'Vous n\'avez pas encore téléchargé de contenu',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _loadDownloadedItems,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildWelcomeHeader(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${_downloadedItems.length} module${_downloadedItems.length > 1 ? 's' : ''} avec téléchargements',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry =
                                _downloadedItems.entries.elementAt(index);
                            return _buildModuleSection(entry.key, entry.value);
                          },
                          childCount: _downloadedItems.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
    );
  }
}
