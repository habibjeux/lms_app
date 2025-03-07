import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/widgets/buttons/download_button.dart';
import '../../models/module.dart';
import '../../models/chapter.dart';
import '../../models/activity.dart';
import '../widgets/chapter_widget.dart';
import '../widgets/module_activity.dart';

class ModuleDetailScreen extends StatefulWidget {
  final Module module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final SyncService _syncService = SyncService();
  late Future<List<Chapter>> _chaptersFuture;
  List<Chapter> _visibleChapters = [];
  bool _isSyncing = false;
  final Map<String, List<Activity>> _chapterActivities = {};
  final Map<String, bool> _expandedChapters = {};
  List<Activity> _moduleActivities = [];

  @override
  void initState() {
    super.initState();
    _initializeChapters();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChapters() {
    _chaptersFuture = _loadChapters();
    _chaptersFuture.then((chapters) {
      // Précharger les activités pour tous les chapitres
      for (var chapter in chapters) {
        _loadActivitiesForChapter(chapter);
        // Par défaut, seul le premier chapitre est développé
        if (_expandedChapters.isEmpty) {
          _expandedChapters[chapter.id] = true;
        } else {
          _expandedChapters[chapter.id] = false;
        }
      }

      // Charger les activités du module (sans chapitre associé)
      _loadModuleActivities();
    });
  }

  Future<List<Chapter>> _loadChapters() async {
    try {
      final chaptersData = await _syncService.getChapters(widget.module.id);
      return _processChaptersData(chaptersData);
    } catch (e) {
      try {
        final cachedChapters = await _syncService.getChapters(widget.module.id);
        return _processChaptersData(cachedChapters);
      } catch (cacheError) {
        throw Exception('Impossible de charger les chapitres: $cacheError');
      }
    }
  }

  List<Chapter> _processChaptersData(List<Map<String, dynamic>> chaptersData) {
    final chapters = chaptersData
        .map((data) => Chapter.fromJson(data))
        .where((c) => c.visible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (mounted) {
      setState(() {
        _visibleChapters = chapters;
      });
    }
    return chapters;
  }

  Future<void> _loadActivitiesForChapter(Chapter chapter) async {
    try {
      final activitiesData =
          await _syncService.getChapterActivities(chapter.id);
      final activities = activitiesData
          .map((data) => Activity.fromJson(data))
          .where((activity) => activity.visible)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      if (mounted) {
        setState(() {
          _chapterActivities[chapter.id] = activities;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des activités: $e')),
        );
      }
    }
  }

  Future<void> _loadModuleActivities() async {
    try {
      final activitiesData =
          await _syncService.getModuleActivities(widget.module.id);
      final activities = activitiesData
          .map((data) => Activity.fromJson(data))
          .where((activity) => activity.visible)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      if (mounted) {
        setState(() {
          _moduleActivities = activities;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erreur de chargement des activités du module: $e')),
        );
      }
    }
  }

  Future<void> _refreshContent() async {
    if (_isSyncing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronisation déjà en cours...')),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await _syncService.smartSync(
        moduleId: widget.module.id,
        onProgress: (progress) {
          // Optionnel: Ajouter un indicateur de progression
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: $error')),
            );
          }
        },
      );

      _initializeChapters();
      _chapterActivities.clear();
      _moduleActivities.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contenu mis à jour avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de synchronisation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline =
        Provider.of<ConnectivityProvider>(context, listen: false).isOnline;

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        return Scaffold(
          body: FutureBuilder<List<Chapter>>(
            future: _chaptersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erreur: ${snapshot.error}'),
                      if (connectivity.isOnline) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshContent,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              if (_visibleChapters.isEmpty) {
                return const Center(
                  child: Text('Aucun chapitre disponible'),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshContent,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      title: Text(widget.module.title),
                      floating: true,
                      actions: [
                        if (_isSyncing)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        if (isOnline)
                          DownloadButton(
                            moduleId: widget.module.id,
                            onComplete: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Module disponible hors ligne'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    // Afficher les chapitres avec leurs activités
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final chapter = _visibleChapters[index];
                            final isExpanded =
                                _expandedChapters[chapter.id] ?? false;
                            final activities =
                                _chapterActivities[chapter.id] ?? [];
                            final isLoading =
                                !_chapterActivities.containsKey(chapter.id);

                            return ChapterAccordion(
                              chapter: chapter,
                              activities: activities,
                              isExpanded: isExpanded,
                              isLoading: isLoading,
                              onExpandChanged: (expanded) {
                                setState(() {
                                  _expandedChapters[chapter.id] = expanded;
                                });
                              },
                            );
                          },
                          childCount: _visibleChapters.length,
                        ),
                      ),
                    ),
                    // Afficher les activités du module (sans chapitre) en bas
                    SliverToBoxAdapter(
                      child: ModuleActivitiesSection(
                        activities: _moduleActivities,
                        moduleId: widget.module.id,
                        isLoading:
                            _chapterActivities.length < _visibleChapters.length,
                      ),
                    ),
                    // Espace en bas pour éviter que le dernier élément soit masqué par la barre de navigation
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
