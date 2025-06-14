import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/widgets/buttons/download_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../models/module.dart';
import '../../providers/modules_provider.dart';
import '../widgets/chapter_widget.dart';
import '../widgets/module_activity.dart';
import '../../../../core/services/sync_service.dart';
import '../screens/downloads_screen.dart';
import '../widgets/chapter_list_item.dart';

class ModuleDetailScreen extends StatefulWidget {
  final Module module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final SyncService _syncService = SyncService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ModulesProvider>(context, listen: false);
      provider.setCurrentModule(widget.module);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final provider = Provider.of<ModulesProvider>(context, listen: false);

    try {
      await provider.refreshModuleContent();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contenu mis à jour avec succès')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Télécharger le module complet',
            onPressed: () => _downloadFullModule(),
          ),
          IconButton(
            icon: const Icon(Icons.download_done),
            tooltip: 'Gérer les téléchargements',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DownloadsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ModulesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!),
                  ElevatedButton(
                    onPressed: _handleRefresh,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_isDownloading)
                LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView(
                    children: [
                      if (provider.visibleChapters.isNotEmpty)
                        ...provider.visibleChapters.map((chapter) {
                          final activities =
                              provider.chapterActivities[chapter.id] ?? [];
                          return ChapterWidget(
                            chapter: chapter,
                            activities: activities,
                            isExpanded:
                                provider.expandedChapters[chapter.id] ?? false,
                            onExpandChanged: (expanded) {
                              provider.toggleChapterExpansion(chapter.id);
                            },
                          );
                        }).toList(),
                      if (provider.moduleActivities.isNotEmpty)
                        ModuleActivitiesSection(
                          activities: provider.moduleActivities,
                          moduleId: widget.module.id,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadChapter(String chapterId) async {
    if (!await _syncService.isOnline()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion Internet requise pour télécharger'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await _syncService.downloadChapter(
        chapterId,
        onProgress: (progress) {
          setState(() => _downloadProgress = progress);
        },
        onComplete: () {
          setState(() {
            _isDownloading = false;
            _downloadProgress = 0.0;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chapitre téléchargé avec succès'),
              ),
            );
          }
        },
        onError: (error) {
          setState(() {
            _isDownloading = false;
            _downloadProgress = 0.0;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors du téléchargement: $error'),
              ),
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
          ),
        );
      }
    }
  }

  Future<void> _downloadFullModule() async {
    if (!await _syncService.isOnline()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion Internet requise pour télécharger'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await _syncService.downloadFullModule(
        widget.module.id,
        onProgress: (progress) {
          setState(() => _downloadProgress = progress);
        },
        onComplete: () {
          setState(() {
            _isDownloading = false;
            _downloadProgress = 0.0;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Module téléchargé avec succès'),
              ),
            );
          }
        },
        onError: (error) {
          setState(() {
            _isDownloading = false;
            _downloadProgress = 0.0;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors du téléchargement: $error'),
              ),
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
          ),
        );
      }
    }
  }
}
