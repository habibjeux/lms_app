import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/services/sync_service.dart';
import '../data/modules_repository.dart';
import '../models/module.dart';
import '../models/chapter.dart';
import '../models/activity.dart';

class ModulesProvider with ChangeNotifier {
  final ModulesRepository _repository = ModulesRepository();
  final SyncService _syncService = SyncService();

  List<Module> _modules = [];
  bool _isLoading = false;
  String? _error;

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

  Module? get currentModule => _currentModule;
  List<Chapter> get visibleChapters => _visibleChapters;
  bool get isSyncing => _isSyncing;
  Map<String, List<Activity>> get chapterActivities => _chapterActivities;
  Map<String, bool> get expandedChapters => _expandedChapters;
  List<Activity> get moduleActivities => _moduleActivities;
  Future<List<Chapter>>? get chaptersFuture => _chaptersFuture;

  Future<void> loadModules() async {
    _setLoading(true);
    _clearError();

    try {
      _modules = await _repository.getModules();
      _clearError();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Une erreur est survenue lors du chargement des modules');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshModules() async {
    try {
      final freshModules = await _repository.getModules(forceRefresh: true);
      _modules = freshModules;
      _clearError();
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    }
  }

  List<Module> getActiveModules() {
    return _modules.where((module) => module.active).toList();
  }

  List<Module> searchModules(String query) {
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

    try {
      final chaptersData = await _syncService.getChapters(_currentModule!.id);
      return _processChaptersData(chaptersData);
    } catch (e) {
      try {
        final cachedChapters =
            await _syncService.getChapters(_currentModule!.id);
        return _processChaptersData(cachedChapters);
      } catch (cacheError) {
        throw AppException(
            message: 'Impossible de charger les chapitres: $cacheError');
      }
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
    try {
      final activitiesData =
          await _syncService.getChapterActivities(chapter.id);
      final activities = activitiesData
          .map((data) => Activity.fromJson(data))
          .where((activity) => activity.visible)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      _chapterActivities[chapter.id] = activities;
      notifyListeners();
    } catch (e) {
      _chapterActivities[chapter.id] = [];
      notifyListeners();
    }
  }

  Future<void> _loadModuleActivities() async {
    if (_currentModule == null) return;

    try {
      final activitiesData =
          await _syncService.getModuleActivities(_currentModule!.id);
      final activities = activitiesData
          .map((data) => Activity.fromJson(data))
          .where((activity) => activity.visible)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      _moduleActivities = activities;
      notifyListeners();
    } catch (e) {
      _moduleActivities = [];
      notifyListeners();
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
