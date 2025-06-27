import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/download_storage_service.dart';
import '../data/modules_repository.dart';
import '../models/module.dart';
import '../models/chapter.dart';
import '../models/activity.dart';
import '../models/enums/activity_type.dart';
import '../models/enums/activity_scope.dart';

class ModulesProvider with ChangeNotifier {
  final ModulesRepository _repository = ModulesRepository();
  final SyncService _syncService = SyncService();
  final DownloadStorageService _downloadStorage = DownloadStorageService();

  List<Module> _modules = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _searchQuery;
  static const int _itemsPerPage = 5;

  Module? _currentModule;
  List<Chapter> _visibleChapters = [];
  bool _isSyncing = false;
  final Map<String, List<Activity>> _chapterActivities = {};
  final Map<String, bool> _expandedChapters = {};
  List<Activity> _moduleActivities = [];
  Future<List<Chapter>>? _chaptersFuture;

  List<Module> get modules => _modules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMorePages => _currentPage < _totalPages;
  String? get searchQuery => _searchQuery;

  Module? get currentModule => _currentModule;
  List<Chapter> get visibleChapters => _visibleChapters;
  bool get isSyncing => _isSyncing;
  Map<String, List<Activity>> get chapterActivities => _chapterActivities;
  Map<String, bool> get expandedChapters => _expandedChapters;
  List<Activity> get moduleActivities => _moduleActivities;
  Future<List<Chapter>>? get chaptersFuture => _chaptersFuture;

  Future<void> loadModules({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _modules = [];
    }

    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.getModules(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchQuery,
      );

      final modulesList = result['modules'] as List<Module>;
      final total = result['total'] as int;

      if (refresh) {
        _modules = modulesList;
      } else {
        _modules.addAll(modulesList);
      }

      _totalPages = (total / _itemsPerPage).ceil();
      _currentPage++;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des modules');
      debugPrint('Erreur dans loadModules: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchModules(String query) async {
    _searchQuery = query;
    await loadModules(refresh: true);
  }

  Future<void> refreshModules() async {
    await loadModules(refresh: true);
  }

  List<Module> getActiveModules() {
    return _modules.where((module) => module.active).toList();
  }

  List<Module> filterModules(String query) {
    if (query.isEmpty) return _modules;

    return _modules.where((module) {
      return module.title.toLowerCase().contains(query.toLowerCase()) ||
          module.code.toLowerCase().contains(query.toLowerCase()) ||
          module.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  void setCurrentModule(Module module) {
    _currentModule = module;
    _initializeModuleDetail();
  }

  void _initializeModuleDetail() {
    if (_currentModule == null) return;

    _clearModuleDetailState();
    _chaptersFuture = _loadChapters();
    _chaptersFuture!.then((chapters) {
      for (var chapter in chapters) {
        _loadActivitiesForChapter(chapter);
        if (_expandedChapters.isEmpty) {
          _expandedChapters[chapter.id] = true;
        } else {
          _expandedChapters[chapter.id] = false;
        }
      }
      _loadModuleActivities();
    }).catchError((error) {
      _setError(error.toString());
    });
  }

  void _clearModuleDetailState() {
    _visibleChapters = [];
    _chapterActivities.clear();
    _expandedChapters.clear();
    _moduleActivities = [];
  }

  Future<List<Chapter>> _loadChapters() async {
    if (_currentModule == null) {
      throw AppException(message: 'Aucun module sélectionné');
    }

    print("📚 Chargement des chapitres pour le module: ${_currentModule!.id}");
    _setLoading(true);

    try {
      // Vérifier la connectivité
      final isOnline = await _isOnline();
      print(
          "📱 Mode de chargement chapitres: ${isOnline ? 'en ligne' : 'hors ligne'}");

      if (!isOnline) {
        // Mode hors ligne : créer des chapitres virtuels basés sur les contenus téléchargés
        return await _loadOfflineChapters();
      }

      // Mode en ligne : utiliser le SyncService normal
      final chaptersData = await _syncService.getChapters(_currentModule!.id);
      return _processChaptersData(chaptersData);
    } catch (e) {
      print(
          "❌ Erreur lors du chargement des chapitres en ligne, tentative hors ligne...");
      try {
        return await _loadOfflineChapters();
      } catch (offlineError) {
        print("❌ Erreur hors ligne aussi: $offlineError");
        throw AppException(
            message:
                'Impossible de charger les chapitres: ${offlineError.toString()}');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Chapter>> _loadOfflineChapters() async {
    print("🔒 Chargement des chapitres en mode hors ligne");

    try {
      // D'abord essayer de récupérer les chapitres sauvegardés
      final cachedChapters = await _syncService.getChapters(_currentModule!.id);
      print("✅ Chapitres trouvés dans le cache: ${cachedChapters.length}");
      return _processChaptersData(cachedChapters);
    } catch (e) {
      print("📁 Pas de chapitres en cache, création de chapitres virtuels...");

      // Créer des chapitres virtuels basés sur tous les contenus téléchargés
      final downloadedItems = await _downloadStorage.getDownloadedItems();
      final moduleContents = downloadedItems
          .where((item) => item['moduleId'] == _currentModule!.id)
          .toList();

      print("📋 Contenus téléchargés pour ce module:");
      for (final item in moduleContents) {
        print(
            "   - Type: ${item['type']}, Titre: ${item['title']}, ID: ${item['id']}");
      }

      if (moduleContents.isEmpty) {
        print("❌ Aucun contenu téléchargé pour ce module");
        throw AppException(
            message: 'Aucun contenu disponible hors ligne pour ce module');
      }

      // Créer un chapitre virtuel "Contenus téléchargés"
      final virtualChapter = Chapter(
        id: 'virtual_${_currentModule!.id}',
        title: 'Contenus téléchargés',
        description: 'Assignments et ressources disponibles hors ligne',
        moduleId: _currentModule!.id,
        order: 1,
        visible: true,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _visibleChapters = [virtualChapter];
      print("✅ Chapitre virtuel créé: ${virtualChapter.title}");

      // Charger les activités pour ce chapitre virtuel
      await _loadVirtualChapterActivities(virtualChapter.id, moduleContents);

      notifyListeners();
      return [virtualChapter];
    }
  }

  Future<void> _loadVirtualChapterActivities(String virtualChapterId,
      List<Map<String, dynamic>> downloadedContents) async {
    print(
        "🎯 Chargement des activités virtuelles pour le chapitre: $virtualChapterId");

    final activities = <Activity>[];

    for (final contentData in downloadedContents) {
      try {
        // Déterminer le type d'activité basé sur le type de contenu téléchargé
        ActivityType activityType;
        String activityTitle;
        String activityId;

        switch (contentData['type']) {
          case 'assignment':
            activityType = ActivityType.ASSIGNMENT;
            activityTitle = contentData['title'] ?? 'Assignment téléchargé';
            activityId = contentData['assignmentId'] ?? contentData['id'] ?? '';
            break;
          case 'resource':
            activityType = ActivityType.RESOURCE;
            activityTitle = contentData['title'] ?? 'Ressource téléchargée';
            activityId = contentData['resourceId'] ?? contentData['id'] ?? '';
            break;
          case 'quiz':
            activityType = ActivityType.QUIZ;
            activityTitle = contentData['title'] ?? 'Quiz téléchargé';
            activityId = contentData['quizId'] ?? contentData['id'] ?? '';
            break;
          default:
            print("⚠️ Type de contenu non géré: ${contentData['type']}");
            continue;
        }

        // Créer une activité virtuelle pour ce contenu
        final activity = Activity(
          id: activityId,
          title: activityTitle,
          type: activityType,
          moduleId: _currentModule!.id,
          chapterId: virtualChapterId,
          order: activities.length + 1,
          visible: true,
          active: true,
          scope: ActivityScope.CHAPTER,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        activities.add(activity);
        print(
            "✅ Activité virtuelle créée: ${activity.title} (${activityType})");
      } catch (e) {
        print("❌ Erreur lors de la création de l'activité virtuelle: $e");
        print("   Données: $contentData");
      }
    }

    _chapterActivities[virtualChapterId] = activities;
    print("📊 Total activités virtuelles créées: ${activities.length}");
    notifyListeners();
  }

  // Vérifier la connectivité Internet
  Future<bool> _isOnline() async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  List<Chapter> _processChaptersData(List<Map<String, dynamic>> chaptersData) {
    final chapters = chaptersData
        .map((data) => Chapter.fromJson(data))
        .where((c) => c.visible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    _visibleChapters = chapters;
    notifyListeners();

    return chapters;
  }

  Future<void> _loadActivitiesForChapter(Chapter chapter) async {
    // Ne pas traiter les chapitres virtuels - leurs activités sont déjà chargées
    if (chapter.id.startsWith('virtual_')) {
      print(
          "🎯 Chapitre virtuel détecté, activités déjà chargées: ${chapter.id}");
      return;
    }

    print(
        "📖 Chargement des activités pour le chapitre: ${chapter.title} (${chapter.id})");

    try {
      // Vérifier la connectivité pour ce chapitre
      final isOnline = await _isOnline();

      if (!isOnline) {
        // Mode hors ligne : essayer de récupérer les activités du cache uniquement
        print(
            "🔒 Mode hors ligne - recherche activités en cache pour: ${chapter.id}");
        try {
          final cachedActivities =
              await _syncService.getChapterActivities(chapter.id);
          final activities = cachedActivities
              .map((data) => Activity.fromJson(data))
              .where((activity) => activity.visible)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          _chapterActivities[chapter.id] = activities;
          print("✅ Activités en cache trouvées: ${activities.length}");
        } catch (e) {
          print("❌ Pas d'activités en cache pour ce chapitre: $e");
          _chapterActivities[chapter.id] = [];
        }
      } else {
        // Mode en ligne : appel API normal
        final activitiesData =
            await _syncService.getChapterActivities(chapter.id);
        final activities = activitiesData
            .map((data) => Activity.fromJson(data))
            .where((activity) => activity.visible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        _chapterActivities[chapter.id] = activities;
        print("✅ Activités en ligne chargées: ${activities.length}");
      }

      notifyListeners();
    } catch (e) {
      print("❌ Erreur lors du chargement des activités du chapitre: $e");
      _chapterActivities[chapter.id] = [];
      notifyListeners();
    }
  }

  Future<void> _loadModuleActivities() async {
    if (_currentModule == null) return;

    print("📚 Chargement des activités du module: ${_currentModule!.id}");
    _setLoading(true);

    try {
      // Vérifier la connectivité
      final isOnline = await _isOnline();

      if (!isOnline) {
        // Mode hors ligne : essayer de récupérer les activités du cache uniquement
        print("🔒 Mode hors ligne - recherche activités de module en cache");
        try {
          final cachedActivities =
              await _syncService.getModuleActivities(_currentModule!.id);
          final activities = cachedActivities
              .map((data) => Activity.fromJson(data))
              .where((activity) => activity.visible)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          _moduleActivities = activities;
          print(
              "✅ Activités de module en cache trouvées: ${activities.length}");
        } catch (e) {
          print("❌ Pas d'activités de module en cache: $e");
          _moduleActivities = [];
        }
      } else {
        // Mode en ligne : appel API normal
        final activitiesData =
            await _syncService.getModuleActivities(_currentModule!.id);
        final activities = activitiesData
            .map((data) => Activity.fromJson(data))
            .where((activity) => activity.visible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        _moduleActivities = activities;
        print("✅ Activités de module en ligne chargées: ${activities.length}");
      }

      notifyListeners();
    } catch (e) {
      print("❌ Erreur lors du chargement des activités du module: $e");
      _moduleActivities = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshModuleContent() async {
    if (_isSyncing || _currentModule == null) {
      return;
    }

    _setSyncing(true);
    _clearError();

    try {
      await _syncService.smartSync(
        moduleId: _currentModule!.id,
        onProgress: (progress) {
          // Ajouter un indicateur de progression
        },
        onError: (error) {
          _setError(error.toString());
        },
      );

      _clearModuleDetailState();
      _initializeModuleDetail();
    } catch (e) {
      _setError('Erreur de synchronisation: $e');
    } finally {
      _setSyncing(false);
    }
  }

  void toggleChapterExpansion(String chapterId) {
    _expandedChapters[chapterId] = !(_expandedChapters[chapterId] ?? false);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSyncing(bool value) {
    _isSyncing = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
