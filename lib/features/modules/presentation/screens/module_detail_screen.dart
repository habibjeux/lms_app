import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/widgets/buttons/download_button.dart';
import '../../models/module.dart';
import '../../providers/modules_provider.dart';
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
    return Consumer2<ModulesProvider, ConnectivityProvider>(
      builder: (context, modulesProvider, connectivityProvider, _) {
        final isOnline = connectivityProvider.isOnline;

        return Scaffold(
          body: FutureBuilder<List<dynamic>>(
            future: modulesProvider.chaptersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  modulesProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || modulesProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          'Erreur: ${snapshot.error ?? modulesProvider.error}'),
                      if (connectivityProvider.isOnline) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handleRefresh,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              if (modulesProvider.visibleChapters.isEmpty &&
                  modulesProvider.moduleActivities.isEmpty) {
                return const Center(
                  child: Text('Aucun contenu disponible'),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _handleRefresh(),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      title: Text(modulesProvider.currentModule?.title ?? ''),
                      floating: true,
                      actions: [
                        if (modulesProvider.isSyncing)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        if (isOnline && modulesProvider.currentModule != null)
                          DownloadButton(
                            moduleId: modulesProvider.currentModule!.id,
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
                    if (modulesProvider.visibleChapters.isNotEmpty)
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final chapter =
                                  modulesProvider.visibleChapters[index];
                              final isExpanded = modulesProvider
                                      .expandedChapters[chapter.id] ??
                                  false;
                              final activities = modulesProvider
                                      .chapterActivities[chapter.id] ??
                                  [];
                              final isLoading = !modulesProvider
                                  .chapterActivities
                                  .containsKey(chapter.id);

                              return ChapterAccordion(
                                chapter: chapter,
                                activities: activities,
                                isExpanded: isExpanded,
                                isLoading: isLoading,
                                onExpandChanged: (expanded) {
                                  modulesProvider
                                      .toggleChapterExpansion(chapter.id);
                                },
                              );
                            },
                            childCount: modulesProvider.visibleChapters.length,
                          ),
                        ),
                      ),
                    if (modulesProvider.moduleActivities.isNotEmpty &&
                        modulesProvider.currentModule != null)
                      SliverToBoxAdapter(
                        child: ModuleActivitiesSection(
                          activities: modulesProvider.moduleActivities,
                          moduleId: modulesProvider.currentModule!.id,
                          isLoading: modulesProvider.chapterActivities.length <
                              modulesProvider.visibleChapters.length,
                        ),
                      ),
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
