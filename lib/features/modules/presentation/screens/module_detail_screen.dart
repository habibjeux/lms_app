import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/module.dart';
import '../../providers/modules_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/chapter_widget.dart';
import '../widgets/module_activity.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/widgets/expandable_text.dart';
import '../widgets/module_summary_widget.dart';
import '../../providers/module_provider.dart';
import '../widgets/module_summary_drawer.dart';
import '../../models/module_summary.dart';

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
    final moduleProvider = Provider.of<ModuleProvider>(context, listen: false);
    moduleProvider.fetchModuleSummary(widget.module.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final moduleProvider = Provider.of<ModuleProvider>(context, listen: false);
    moduleProvider.clearModuleSummary();
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

  Widget _buildModuleHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.module.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
              if (widget.module.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                ExpandableText(
                  widget.module.description,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  linkStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color ?? Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40,
        actions: [
          Consumer<ModuleProvider>(
            builder: (context, provider, child) {
              if (!provider.isLoadingSummary &&
                  provider.moduleSummary != null &&
                  provider.moduleSummary!.chapters.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.menu_book),
                  tooltip: 'Voir le résumé du module',
                  onPressed: () =>
                      _showSummaryDrawer(context, provider.moduleSummary!),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Bouton Télécharger tout le module
          IconButton(
            onPressed: _isDownloading ? null : _downloadFullModule,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download),
            tooltip: 'Télécharger le module',
          ),
          // Bouton Voir les téléchargements
          IconButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/downloads-module',
              arguments: widget.module,
            ),
            icon: const Icon(Icons.download_done),
            tooltip: 'Téléchargements du module',
          ),
        ],
      ),
      body: Consumer<ModulesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Column(
              children: [
                _buildModuleHeader(),
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }

          if (provider.error != null) {
            return Column(
              children: [
                _buildModuleHeader(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Oops! Une erreur s\'est produite',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _handleRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildModuleHeader(),
                      if (_isDownloading)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),

                // Chapitres
                if (provider.visibleChapters.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Chapitres (${provider.visibleChapters.length})',
                      Icons.menu_book,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final chapter = provider.visibleChapters[index];
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
                      },
                      childCount: provider.visibleChapters.length,
                    ),
                  ),
                ],

                // Activités du module
                if (provider.moduleActivities.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Activités complémentaires (${provider.moduleActivities.length})',
                      Icons.assignment,
                      color: Colors.teal,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ModuleActivitiesSection(
                      activities: provider.moduleActivities,
                      moduleId: widget.module.id,
                    ),
                  ),
                ],
              ],
            ),
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

  void _showSummaryDrawer(BuildContext context, ModuleSummary summary) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            ModuleSummaryDrawer(summary: summary),
      ),
    );
  }
}
