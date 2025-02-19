import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/widgets/buttons/download_button.dart';
import '../../models/module.dart';
import '../../models/chapter.dart';
import '../widgets/chapter_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ModuleDetailScreen extends StatefulWidget {
  final Module module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final SyncService _syncService = SyncService();
  final ScrollController _scrollController = ScrollController();

  late Future<List<Chapter>> _chaptersFuture;
  List<Chapter> _visibleChapters = [];
  int _currentChapterIndex = 0;
  bool _isOffline = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();
    _initializeChapters();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> isOnline() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      // Vérification via DNS lookup
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        return false;
      }

      // Vérification avec un ping (optionnel)
      final pingResult = await Process.run(
        'ping',
        ['-c', '1', 'google.com'],
        runInShell: true,
      );

      if (pingResult.exitCode == 0) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    } on ProcessException catch (_) {
      return false;
    }

    return false;
  }

  Future<void> _checkConnectivity() async {
    final isOffline = !(await isOnline());
    if (mounted) {
      setState(() {
        _isOffline = isOffline;
      });
    }
  }

  void _setupConnectivityListener() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) async {
      final isOffline = !(await isOnline());
      if (mounted) {
        setState(() {
          _isOffline = isOffline;
        });
      }
    });
  }

  void _initializeChapters() {
    _chaptersFuture = _loadChapters();
  }

  Future<List<Chapter>> _loadChapters() async {
    try {
      final chaptersData = await _syncService.getChapters(widget.module.id);
      return _processChaptersData(chaptersData);
    } catch (e) {
      // En cas d'erreur, essayer de charger depuis le cache
      try {
        final cachedChapters = await _syncService.getChapters(widget.module.id);
        return _processChaptersData(cachedChapters);
      } catch (cacheError) {
        // Si même le cache échoue, propager l'erreur
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

  void _showChaptersList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height,
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text('Sommaire'),
                ),
                body: ListView.builder(
                  itemCount: _visibleChapters.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        _visibleChapters[index].title,
                        style: TextStyle(
                          fontWeight: index == _currentChapterIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: index == _currentChapterIndex
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                        ),
                      ),
                      subtitle: _visibleChapters[index].description.isNotEmpty
                          ? Text(_visibleChapters[index].description)
                          : null,
                      onTap: () {
                        setState(() {
                          _currentChapterIndex = index;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateChapter(int direction) {
    if (direction > 0 && _currentChapterIndex >= _visibleChapters.length - 1) {
      return;
    }
    if (direction < 0 && _currentChapterIndex <= 0) {
      return;
    }

    setState(() {
      _currentChapterIndex += direction;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  if (!_isOffline) ...[
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

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refreshContent,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      title: Text(widget.module.title),
                      floating: true,
                      actions: [
                        if (_isOffline)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child:
                                Icon(Icons.offline_bolt, color: Colors.orange),
                          ),
                        if (_isSyncing)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
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
                        IconButton(
                          icon: const Icon(Icons.menu_book),
                          onPressed: _showChaptersList,
                          tooltip: 'Liste des chapitres',
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          ChapterWidget(
                            chapter: _visibleChapters[_currentChapterIndex],
                            isOffline: _isOffline,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                    top: 8,
                    left: 8,
                    right: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _currentChapterIndex > 0
                            ? () => _navigateChapter(-1)
                            : null,
                        color: _currentChapterIndex > 0
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                      Text(
                        'Chapitre ${_currentChapterIndex + 1}/${_visibleChapters.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed:
                            _currentChapterIndex < _visibleChapters.length - 1
                                ? () => _navigateChapter(1)
                                : null,
                        color:
                            _currentChapterIndex < _visibleChapters.length - 1
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
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
}
