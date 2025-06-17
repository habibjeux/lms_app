import 'package:flutter/foundation.dart';
import '../data/modules_repository.dart';
import '../models/module.dart';

class ModuleProvider with ChangeNotifier {
  final ModulesRepository _repository;
  List<Module> _modules = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _searchQuery;
  static const int _itemsPerPage = 5;

  ModuleProvider(this._repository);

  List<Module> get modules => _modules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMorePages => _currentPage < _totalPages;
  String? get searchQuery => _searchQuery;

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

  Future<Module> getModuleDetail(String moduleId) async {
    try {
      return await _repository.getModuleDetail(moduleId);
    } catch (e) {
      _setError('Erreur lors du chargement des détails du module');
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
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
